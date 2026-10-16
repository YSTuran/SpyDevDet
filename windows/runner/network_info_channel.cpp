#include <winsock2.h>
#include <iphlpapi.h>
#include <ws2tcpip.h>

#include "network_info_channel.h"

#include <algorithm>
#include <cctype>
#include <cstdint>
#include <cwctype>
#include <limits>
#include <iomanip>
#include <optional>
#include <sstream>
#include <string>
#include <vector>

#include <flutter/standard_method_codec.h>

#include "utils.h"

namespace {

constexpr char kChannelName[] = "yusufs.turan.spydevdet/network_info";
constexpr char kGetNetworkSnapshot[] = "getNetworkSnapshot";
constexpr char kGetNeighborSnapshot[] = "getNeighborSnapshot";

struct NetworkCandidate {
  std::string local_ipv4;
  uint8_t prefix_length;
  std::string interface_name;
  std::optional<std::string> gateway_ipv4;
  bool is_wifi;
  bool is_ethernet;
  bool is_vpn;
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

std::wstring Lowercase(const wchar_t* value) {
  if (value == nullptr) {
    return std::wstring();
  }
  std::wstring lowered(value);
  std::transform(lowered.begin(), lowered.end(), lowered.begin(),
                 [](wchar_t character) { return std::towlower(character); });
  return lowered;
}

bool ContainsAny(const std::wstring& value,
                 const std::vector<std::wstring>& terms) {
  return std::any_of(terms.begin(), terms.end(), [&](const auto& term) {
    return value.find(term) != std::wstring::npos;
  });
}

bool IsVpnAdapter(const IP_ADAPTER_ADDRESSES* adapter) {
  if (adapter->IfType == IF_TYPE_TUNNEL || adapter->IfType == IF_TYPE_PPP ||
      adapter->TunnelType != TUNNEL_TYPE_NONE) {
    return true;
  }

  const std::wstring identity = Lowercase(adapter->FriendlyName) + L" " +
                                Lowercase(adapter->Description);
  static const std::vector<std::wstring> kVpnTerms = {
      L"vpn", L"wireguard", L"wintun", L"openvpn", L"tap-windows",
      L"tailscale", L"zerotier"};
  return ContainsAny(identity, kVpnTerms);
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

  ULONG buffer_size = 0;
  DWORD status = GetIpNetTable(nullptr, &buffer_size, FALSE);
  if (status != ERROR_INSUFFICIENT_BUFFER || buffer_size == 0) {
    return {{flutter::EncodableValue("available"),
             flutter::EncodableValue(false)},
            {flutter::EncodableValue("entries"),
             flutter::EncodableValue(flutter::EncodableList())}};
  }

  std::vector<unsigned char> buffer(buffer_size);
  auto* table = reinterpret_cast<MIB_IPNETTABLE*>(buffer.data());
  status = GetIpNetTable(table, &buffer_size, FALSE);
  if (status != NO_ERROR) {
    return {{flutter::EncodableValue("available"),
             flutter::EncodableValue(false)},
            {flutter::EncodableValue("entries"),
             flutter::EncodableValue(flutter::EncodableList())}};
  }

  flutter::EncodableList entries;
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

  return {{flutter::EncodableValue("available"),
           flutter::EncodableValue(true)},
          {flutter::EncodableValue("entries"),
           flutter::EncodableValue(entries)}};
}

}  // namespace

std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
RegisterNetworkInfoChannel(flutter::BinaryMessenger* messenger) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          messenger, kChannelName,
          &flutter::StandardMethodCodec::GetInstance());

  channel->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
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
