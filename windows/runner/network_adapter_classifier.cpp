#include "network_adapter_classifier.h"

#include <algorithm>
#include <cwctype>
#include <vector>

namespace spy_dev_det {
namespace {

std::wstring Lowercase(std::wstring value) {
  std::transform(value.begin(), value.end(), value.begin(),
                 [](wchar_t character) { return std::towlower(character); });
  return value;
}

bool ContainsAny(const std::wstring& value,
                 const std::vector<std::wstring>& terms) {
  return std::any_of(terms.begin(), terms.end(), [&](const auto& term) {
    return value.find(term) != std::wstring::npos;
  });
}

}  // namespace

bool IsUnsafeNetworkAdapter(bool reports_tunnel_or_ppp,
                            std::optional<bool> is_hardware_interface,
                            const std::wstring& identity) {
  if (reports_tunnel_or_ppp || is_hardware_interface == false) {
    return true;
  }

  static const std::vector<std::wstring> kUnsafeTerms = {
      L"vpn",           L"wireguard",      L"wintun",
      L"openvpn",       L"tap-windows",    L"tailscale",
      L"zerotier",      L"cloudflare",     L"warp",
      L"globalprotect", L"anyconnect",     L"forticlient",
      L"fortinet",      L"pulse secure",   L"ivanti",
      L"checkpoint",    L"protonvpn",      L"nordlynx",
      L"mullvad",       L"hamachi",        L"softether",
      L"sstp",          L"l2tp",           L"pptp",
      L"virtualbox",    L"vmware",         L"hyper-v",
      L"docker",        L"wsl",            L"virtual adapter",
      L"virtual ethernet"};
  return ContainsAny(Lowercase(identity), kUnsafeTerms);
}

}  // namespace spy_dev_det
