#include <winsock2.h>
#include <ws2tcpip.h>
#include <iphlpapi.h>
#include <iptypes.h>
#include <icmpapi.h>

#include "network_adapter_classifier.h"
#include "network_info_channel.h"

#include <algorithm>
#include <atomic>
#include <cctype>
#include <condition_variable>
#include <cstdint>
#include <iomanip>
#include <limits>
#include <memory>
#include <mutex>
#include <optional>
#include <sstream>
#include <string>
#include <thread>
#include <unordered_map>
#include <vector>

#include <flutter/standard_method_codec.h>

#include "utils.h"

namespace {

constexpr char kChannelName[] = "yusufs.turan.spydevdet/network_info";
constexpr char kGetNetworkSnapshot[] = "getNetworkSnapshot";
constexpr char kGetNeighborSnapshot[] = "getNeighborSnapshot";
constexpr char kDiscoverReachableHosts[] = "discoverReachableHosts";
constexpr char kCancelReachability[] = "cancelReachability";
constexpr size_t kMaxReachabilityTargets = 254;
constexpr size_t kReachabilityWorkers = 32;
constexpr int kMinReachabilityTimeoutMs = 100;
constexpr int kMaxReachabilityTimeoutMs = 2000;

struct ReachabilityJob {
  std::atomic_bool cancelled{false};
};

std::mutex g_reachability_mutex;
std::condition_variable g_reachability_condition;
bool g_reachability_shutting_down = false;
std::unordered_map<std::string, std::shared_ptr<ReachabilityJob>>
    g_reachability_jobs;

struct NetworkCandidate {
  std::string local_ipv4;
  uint8_t prefix_length;
  std::string interface_name;
  std::optional<std::string> gateway_ipv4;
  bool is_wifi;
  bool is_ethernet;
  bool is_vpn;
  std::optional<std::string> physical_address;
  ULONG interface_index;
  ULONG metric;
};

bool IsPrivateIpv4(const sockaddr_in* address) {
  const uint32_t host = ntohl(address->sin_addr.S_un.S_addr);
  const uint8_t first = static_cast<uint8_t>((host >> 24) & 0xff);
  const uint8_t second = static_cast<uint8_t>((host >> 16) & 0xff);
  return first == 10 || (first == 172 && second >= 16 && second <= 31) ||
         (first == 192 && second == 168);
}

bool ParsePrivateIpv4(const std::string& value, IN_ADDR* address) {
  if (InetPtonA(AF_INET, value.c_str(), address) != 1) {
    return false;
  }
  sockaddr_in socket_address = {};
  socket_address.sin_family = AF_INET;
  socket_address.sin_addr = *address;
  return IsPrivateIpv4(&socket_address);
}

std::optional<std::string> StringArgument(const flutter::EncodableMap& map,
                                          const char* name) {
  const auto iterator = map.find(flutter::EncodableValue(name));
  if (iterator == map.end()) {
    return std::nullopt;
  }
  const auto* value = std::get_if<std::string>(&iterator->second);
  if (value == nullptr || value->empty()) {
    return std::nullopt;
  }
  return *value;
}

int IntArgument(const flutter::EncodableMap& map, const char* name,
                int fallback) {
  const auto iterator = map.find(flutter::EncodableValue(name));
  if (iterator == map.end()) {
    return fallback;
  }
  if (const auto* value = std::get_if<int32_t>(&iterator->second)) {
    return *value;
  }
  if (const auto* value = std::get_if<int64_t>(&iterator->second)) {
    return static_cast<int>(std::clamp<int64_t>(
        *value, std::numeric_limits<int>::min(),
        std::numeric_limits<int>::max()));
  }
  return fallback;
}

std::optional<std::vector<std::string>> ReachabilityTargets(
    const flutter::EncodableMap& map) {
  const auto iterator = map.find(flutter::EncodableValue("targets"));
  if (iterator == map.end()) {
    return std::nullopt;
  }
  const auto* values = std::get_if<flutter::EncodableList>(&iterator->second);
  if (values == nullptr || values->size() > kMaxReachabilityTargets) {
    return std::nullopt;
  }
  std::vector<std::string> targets;
  targets.reserve(values->size());
  for (const auto& value : *values) {
    const auto* target = std::get_if<std::string>(&value);
    IN_ADDR address = {};
    if (target != nullptr && ParsePrivateIpv4(*target, &address) &&
        std::find(targets.begin(), targets.end(), *target) == targets.end()) {
      targets.push_back(*target);
    }
  }
  return targets;
}

bool SendIcmpEcho(HANDLE handle, ULONG source_address,
                  const std::string& target, int timeout_millis) {
  IN_ADDR destination = {};
  if (!ParsePrivateIpv4(target, &destination)) {
    return false;
  }
  constexpr char request_data[] = "SpyDevDet";
  std::vector<unsigned char> reply(sizeof(ICMP_ECHO_REPLY) + 64);
  const DWORD reply_count = IcmpSendEcho2Ex(
      handle, nullptr, nullptr, nullptr, source_address,
      destination.S_un.S_addr,
      const_cast<char*>(request_data),
      static_cast<WORD>(sizeof(request_data) - 1), nullptr, reply.data(),
      static_cast<DWORD>(reply.size()), static_cast<DWORD>(timeout_millis));
  if (reply_count == 0) {
    return false;
  }
  const auto* echo_reply =
      reinterpret_cast<const ICMP_ECHO_REPLY*>(reply.data());
  return echo_reply->Status == IP_SUCCESS;
}

void StartReachability(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const auto* arguments =
      std::get_if<flutter::EncodableMap>(call.arguments());
  if (arguments == nullptr) {
    result->Error("INVALID_REACHABILITY_REQUEST",
                  "Erişilebilirlik isteği geçersiz.");
    return;
  }
  const auto request_id = StringArgument(*arguments, "requestId");
  const auto source_address_value = StringArgument(*arguments, "sourceAddress");
  const auto targets = ReachabilityTargets(*arguments);
  IN_ADDR source_address = {};
  if (!request_id.has_value() || request_id->size() > 128 ||
      !source_address_value.has_value() ||
      !ParsePrivateIpv4(*source_address_value, &source_address) ||
      !targets.has_value()) {
    result->Error("INVALID_REACHABILITY_REQUEST",
                  "Erişilebilirlik isteği geçersiz.");
    return;
  }
  const int timeout_millis = std::clamp(
      IntArgument(*arguments, "timeoutMillis", 500),
      kMinReachabilityTimeoutMs, kMaxReachabilityTimeoutMs);
  const auto job = std::make_shared<ReachabilityJob>();
  {
    std::lock_guard<std::mutex> lock(g_reachability_mutex);
    if (g_reachability_shutting_down) {
      result->Error("REACHABILITY_SHUTTING_DOWN",
                    "Erişilebilirlik servisi kapatılıyor.");
      return;
    }
    if (g_reachability_jobs.find(*request_id) != g_reachability_jobs.end()) {
      result->Error("DUPLICATE_REACHABILITY_REQUEST",
                    "Erişilebilirlik isteği zaten çalışıyor.");
      return;
    }
    g_reachability_jobs[*request_id] = job;
  }

  std::thread([request_id = *request_id, targets = *targets, timeout_millis,
               source_address = source_address.S_un.S_addr, job,
               result = std::move(result)]() mutable {
    std::atomic_size_t next_target{0};
    std::mutex reachable_mutex;
    std::vector<std::string> reachable;
    const size_t worker_count =
        std::min(kReachabilityWorkers, targets.size());
    std::vector<std::thread> workers;
    workers.reserve(worker_count);
    for (size_t worker = 0; worker < worker_count; ++worker) {
      workers.emplace_back([&]() {
        const HANDLE icmp_handle = IcmpCreateFile();
        if (icmp_handle == INVALID_HANDLE_VALUE) {
          return;
        }
        while (!job->cancelled.load()) {
          const size_t index = next_target.fetch_add(1);
          if (index >= targets.size()) {
            break;
          }
          if (SendIcmpEcho(icmp_handle, source_address, targets[index],
                           timeout_millis)) {
            std::lock_guard<std::mutex> lock(reachable_mutex);
            reachable.push_back(targets[index]);
          }
        }
        IcmpCloseHandle(icmp_handle);
      });
    }
    for (auto& worker : workers) {
      worker.join();
    }

    flutter::EncodableList response;
    if (!job->cancelled.load()) {
      std::sort(reachable.begin(), reachable.end());
      for (const auto& target : reachable) {
        response.emplace_back(target);
      }
    }
    bool should_reply = false;
    {
      std::lock_guard<std::mutex> lock(g_reachability_mutex);
      should_reply = !g_reachability_shutting_down;
    }
    if (should_reply) {
      result->Success(flutter::EncodableValue(response));
    }
    result.reset();

    {
      std::lock_guard<std::mutex> lock(g_reachability_mutex);
      const auto iterator = g_reachability_jobs.find(request_id);
      if (iterator != g_reachability_jobs.end() &&
          iterator->second == job) {
        g_reachability_jobs.erase(iterator);
      }
    }
    g_reachability_condition.notify_all();
  }).detach();
}

void CancelReachability(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const auto* arguments =
      std::get_if<flutter::EncodableMap>(call.arguments());
  const auto request_id = arguments == nullptr
                              ? std::nullopt
                              : StringArgument(*arguments, "requestId");
  if (request_id.has_value()) {
    std::lock_guard<std::mutex> lock(g_reachability_mutex);
    const auto iterator = g_reachability_jobs.find(*request_id);
    if (iterator != g_reachability_jobs.end()) {
      iterator->second->cancelled.store(true);
    }
  }
  result->Success();
}

std::optional<std::string> Ipv4FromSockaddr(const SOCKADDR* address) {
  if (address == nullptr || address->sa_family != AF_INET) {
    return std::nullopt;
  }

  char buffer[INET_ADDRSTRLEN] = {};
  const auto* ipv4 = reinterpret_cast<const sockaddr_in*>(address);
  if (InetNtopA(AF_INET, const_cast<IN_ADDR*>(&ipv4->sin_addr), buffer,
                INET_ADDRSTRLEN) == nullptr) {
    return std::nullopt;
  }
  return std::string(buffer);
}

std::optional<std::string> FirstGateway(
    const IP_ADAPTER_ADDRESSES* adapter) {
  for (auto* gateway = adapter->FirstGatewayAddress; gateway != nullptr;
       gateway = gateway->Next) {
    const auto value = Ipv4FromSockaddr(gateway->Address.lpSockaddr);
    if (value.has_value() && value.value() != "0.0.0.0") {
      return value;
    }
  }
  return std::nullopt;
}

bool IsVpnAdapter(const IP_ADAPTER_ADDRESSES* adapter) {
  MIB_IF_ROW2 interface_row = {};
  interface_row.InterfaceIndex = adapter->IfIndex;
  std::optional<bool> is_hardware_interface;
  if (GetIfEntry2(&interface_row) == NO_ERROR) {
    is_hardware_interface =
        interface_row.InterfaceAndOperStatusFlags.HardwareInterface != 0;
  }

  const std::wstring identity =
      std::wstring(adapter->FriendlyName == nullptr ? L""
                                                    : adapter->FriendlyName) +
      L" " +
      std::wstring(adapter->Description == nullptr ? L""
                                                   : adapter->Description) +
      L" " +
      std::wstring(adapter->DnsSuffix == nullptr ? L"" : adapter->DnsSuffix);
  const bool reports_tunnel_or_ppp =
      adapter->IfType == IF_TYPE_TUNNEL || adapter->IfType == IF_TYPE_PPP ||
      adapter->TunnelType != TUNNEL_TYPE_NONE;
  return spy_dev_det::IsUnsafeNetworkAdapter(
      reports_tunnel_or_ppp, is_hardware_interface, identity);
}

std::optional<std::string> PhysicalAddress(
    const IP_ADAPTER_ADDRESSES* adapter) {
  if (adapter->PhysicalAddressLength != 6) {
    return std::nullopt;
  }
  bool all_zero = true;
  bool all_broadcast = true;
  for (ULONG index = 0; index < adapter->PhysicalAddressLength; ++index) {
    all_zero = all_zero && adapter->PhysicalAddress[index] == 0;
    all_broadcast =
        all_broadcast && adapter->PhysicalAddress[index] == 0xff;
  }
  if (all_zero || all_broadcast) {
    return std::nullopt;
  }

  std::ostringstream mac;
  mac << std::uppercase << std::hex << std::setfill('0');
  for (ULONG index = 0; index < adapter->PhysicalAddressLength; ++index) {
    if (index > 0) {
      mac << ':';
    }
    mac << std::setw(2)
        << static_cast<int>(adapter->PhysicalAddress[index]);
  }
  return mac.str();
}

std::optional<ULONG> DefaultRouteInterfaceIndex() {
  IN_ADDR destination = {};
  if (InetPtonA(AF_INET, "1.1.1.1", &destination) != 1) {
    return std::nullopt;
  }

  ULONG interface_index = 0;
  if (GetBestInterface(destination.S_un.S_addr, &interface_index) != NO_ERROR) {
    return std::nullopt;
  }
  return interface_index;
}

std::optional<NetworkCandidate> ReadNetworkSnapshot(std::string* error_code,
                                                    std::string* error_message) {
  ULONG buffer_size = 15 * 1024;
  std::vector<unsigned char> buffer(buffer_size);
  auto* adapters =
      reinterpret_cast<IP_ADAPTER_ADDRESSES*>(buffer.data());
  constexpr ULONG flags = GAA_FLAG_INCLUDE_PREFIX |
                          GAA_FLAG_INCLUDE_GATEWAYS |
                          GAA_FLAG_SKIP_ANYCAST |
                          GAA_FLAG_SKIP_MULTICAST |
                          GAA_FLAG_SKIP_DNS_SERVER;

  ULONG status = GetAdaptersAddresses(AF_INET, flags, nullptr, adapters,
                                      &buffer_size);
  if (status == ERROR_BUFFER_OVERFLOW) {
    buffer.resize(buffer_size);
    adapters = reinterpret_cast<IP_ADAPTER_ADDRESSES*>(buffer.data());
    status = GetAdaptersAddresses(AF_INET, flags, nullptr, adapters,
                                  &buffer_size);
  }
  if (status != NO_ERROR) {
    *error_code = "WINDOWS_NETWORK_QUERY_FAILED";
    *error_message = "Windows ağ bağlantılarını okuyamadı.";
    return std::nullopt;
  }

  std::vector<NetworkCandidate> candidates;
  for (auto* adapter = adapters; adapter != nullptr; adapter = adapter->Next) {
    if (adapter->OperStatus != IfOperStatusUp ||
        adapter->IfType == IF_TYPE_SOFTWARE_LOOPBACK) {
      continue;
    }

    const bool is_vpn = IsVpnAdapter(adapter);
    const bool is_wifi = adapter->IfType == IF_TYPE_IEEE80211 && !is_vpn;
    const bool is_ethernet =
        adapter->IfType == IF_TYPE_ETHERNET_CSMACD && !is_vpn;
    const std::string interface_name = Utf8FromUtf16(adapter->FriendlyName);
    const auto gateway = FirstGateway(adapter);

    for (auto* unicast = adapter->FirstUnicastAddress; unicast != nullptr;
         unicast = unicast->Next) {
      if (unicast->Address.lpSockaddr == nullptr ||
          unicast->Address.lpSockaddr->sa_family != AF_INET ||
          unicast->OnLinkPrefixLength < 1 ||
          unicast->OnLinkPrefixLength > 30) {
        continue;
      }

      const auto* ipv4 = reinterpret_cast<const sockaddr_in*>(
          unicast->Address.lpSockaddr);
      if (!IsPrivateIpv4(ipv4)) {
        continue;
      }
      const auto local_ipv4 = Ipv4FromSockaddr(unicast->Address.lpSockaddr);
      if (!local_ipv4.has_value()) {
        continue;
      }

      candidates.push_back(NetworkCandidate{
          local_ipv4.value(),
          unicast->OnLinkPrefixLength,
          interface_name.empty() ? "Bilinmeyen bağdaştırıcı" : interface_name,
          gateway,
          is_wifi,
          is_ethernet,
          is_vpn,
          PhysicalAddress(adapter),
          adapter->IfIndex,
          adapter->Ipv4Metric,
      });
    }
  }

  if (candidates.empty()) {
    *error_code = "NO_PRIVATE_IPV4";
    *error_message = "Etkin bir özel IPv4 ağ bağlantısı bulunamadı.";
    return std::nullopt;
  }

  const auto default_interface = DefaultRouteInterfaceIndex();
  std::sort(candidates.begin(), candidates.end(),
            [&](const NetworkCandidate& first,
                const NetworkCandidate& second) {
              const bool first_is_default =
                  default_interface.has_value() &&
                  first.interface_index == default_interface.value();
              const bool second_is_default =
                  default_interface.has_value() &&
                  second.interface_index == default_interface.value();
              if (first_is_default != second_is_default) {
                return first_is_default;
              }
              if (first.gateway_ipv4.has_value() !=
                  second.gateway_ipv4.has_value()) {
                return first.gateway_ipv4.has_value();
              }
              const bool first_supported = first.is_wifi || first.is_ethernet;
              const bool second_supported = second.is_wifi || second.is_ethernet;
              if (first_supported != second_supported) {
                return first_supported;
              }
              return first.metric < second.metric;
            });
  return candidates.front();
}

flutter::EncodableMap EncodeSnapshot(const NetworkCandidate& snapshot) {
  flutter::EncodableMap result = {
      {flutter::EncodableValue("localIpv4"),
       flutter::EncodableValue(snapshot.local_ipv4)},
      {flutter::EncodableValue("prefixLength"),
       flutter::EncodableValue(static_cast<int32_t>(snapshot.prefix_length))},
      {flutter::EncodableValue("interfaceName"),
       flutter::EncodableValue(snapshot.interface_name)},
      {flutter::EncodableValue("isWifi"),
       flutter::EncodableValue(snapshot.is_wifi)},
      {flutter::EncodableValue("isEthernet"),
       flutter::EncodableValue(snapshot.is_ethernet)},
      {flutter::EncodableValue("isVpn"),
       flutter::EncodableValue(snapshot.is_vpn)},
  };
  if (snapshot.gateway_ipv4.has_value()) {
    result[flutter::EncodableValue("gatewayIpv4")] =
        flutter::EncodableValue(snapshot.gateway_ipv4.value());
  }
  return result;
}

flutter::EncodableMap ReadNeighborSnapshot() {
  std::string error_code;
  std::string error_message;
  const auto active_network =
      ReadNetworkSnapshot(&error_code, &error_message);
  if (!active_network.has_value()) {
    return {{flutter::EncodableValue("available"),
             flutter::EncodableValue(false)},
            {flutter::EncodableValue("entries"),
             flutter::EncodableValue(flutter::EncodableList())}};
  }

  flutter::EncodableList entries;
  if (active_network->physical_address.has_value()) {
    entries.push_back(flutter::EncodableValue(flutter::EncodableMap{
        {flutter::EncodableValue("ipAddress"),
         flutter::EncodableValue(active_network->local_ipv4)},
        {flutter::EncodableValue("macAddress"),
         flutter::EncodableValue(active_network->physical_address.value())},
    }));
  }
  const auto build_result = [&entries](bool available) {
    return flutter::EncodableMap{
        {flutter::EncodableValue("available"),
         flutter::EncodableValue(available)},
        {flutter::EncodableValue("entries"),
         flutter::EncodableValue(entries)}};
  };

  ULONG buffer_size = 0;
  DWORD status = GetIpNetTable(nullptr, &buffer_size, FALSE);
  if (status == ERROR_NO_DATA) {
    return build_result(true);
  }
  if (status != ERROR_INSUFFICIENT_BUFFER || buffer_size == 0) {
    return build_result(false);
  }

  std::vector<unsigned char> buffer(buffer_size);
  auto* table = reinterpret_cast<MIB_IPNETTABLE*>(buffer.data());
  status = GetIpNetTable(table, &buffer_size, FALSE);
  if (status == ERROR_NO_DATA) {
    return build_result(true);
  }
  if (status != NO_ERROR) {
    return build_result(false);
  }

  for (DWORD index = 0; index < table->dwNumEntries; ++index) {
    const MIB_IPNETROW& row = table->table[index];
    if (row.dwIndex != active_network->interface_index ||
        row.dwPhysAddrLen != 6 ||
        (row.dwType != MIB_IPNET_TYPE_DYNAMIC &&
         row.dwType != MIB_IPNET_TYPE_STATIC)) {
      continue;
    }
    bool all_zero = true;
    bool all_broadcast = true;
    for (DWORD byte = 0; byte < 6; ++byte) {
      all_zero = all_zero && row.bPhysAddr[byte] == 0;
      all_broadcast = all_broadcast && row.bPhysAddr[byte] == 0xff;
    }
    if (all_zero || all_broadcast) {
      continue;
    }

    IN_ADDR address = {};
    address.S_un.S_addr = row.dwAddr;
    char address_buffer[INET_ADDRSTRLEN] = {};
    if (InetNtopA(AF_INET, &address, address_buffer, INET_ADDRSTRLEN) ==
        nullptr) {
      continue;
    }
    if (std::string(address_buffer) == active_network->local_ipv4) {
      continue;
    }

    std::ostringstream mac;
    mac << std::uppercase << std::hex << std::setfill('0');
    for (DWORD byte = 0; byte < 6; ++byte) {
      if (byte > 0) {
        mac << ':';
      }
      mac << std::setw(2) << static_cast<int>(row.bPhysAddr[byte]);
    }
    entries.push_back(flutter::EncodableValue(flutter::EncodableMap{
        {flutter::EncodableValue("ipAddress"),
         flutter::EncodableValue(std::string(address_buffer))},
        {flutter::EncodableValue("macAddress"),
         flutter::EncodableValue(mac.str())},
    }));
  }

  return build_result(true);
}

}  // namespace

std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
RegisterNetworkInfoChannel(flutter::BinaryMessenger* messenger) {
  {
    std::lock_guard<std::mutex> lock(g_reachability_mutex);
    g_reachability_shutting_down = false;
  }
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          messenger, kChannelName,
          &flutter::StandardMethodCodec::GetInstance());

  channel->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        if (call.method_name() == kDiscoverReachableHosts) {
          StartReachability(call, std::move(result));
          return;
        }
        if (call.method_name() == kCancelReachability) {
          CancelReachability(call, std::move(result));
          return;
        }
        if (call.method_name() == kGetNeighborSnapshot) {
          result->Success(flutter::EncodableValue(ReadNeighborSnapshot()));
          return;
        }
        if (call.method_name() != kGetNetworkSnapshot) {
          result->NotImplemented();
          return;
        }

        std::string error_code;
        std::string error_message;
        const auto snapshot =
            ReadNetworkSnapshot(&error_code, &error_message);
        if (!snapshot.has_value()) {
          result->Error(error_code, error_message);
          return;
        }
        result->Success(flutter::EncodableValue(EncodeSnapshot(*snapshot)));
      });

  return channel;
}

void ShutdownNetworkInfoChannel() {
  std::unique_lock<std::mutex> lock(g_reachability_mutex);
  g_reachability_shutting_down = true;
  for (const auto& entry : g_reachability_jobs) {
    entry.second->cancelled.store(true);
  }
  g_reachability_condition.wait(
      lock, [] { return g_reachability_jobs.empty(); });
}
