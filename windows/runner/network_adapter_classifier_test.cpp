#include "network_adapter_classifier.h"

#include <iostream>
#include <optional>
#include <string>

namespace {

bool Expect(bool condition, const std::string& message) {
  if (!condition) {
    std::cerr << message << std::endl;
  }
  return condition;
}

}  // namespace

int main() {
  bool passed = true;
  passed &= Expect(
      !spy_dev_det::IsUnsafeNetworkAdapter(false, true,
                                           L"Intel Wi-Fi 6 AX201"),
      "Physical Wi-Fi adapter must remain scannable.");
  passed &= Expect(
      spy_dev_det::IsUnsafeNetworkAdapter(false, true,
                                          L"Cloudflare WARP Adapter"),
      "Cloudflare WARP must be rejected.");
  passed &= Expect(
      spy_dev_det::IsUnsafeNetworkAdapter(false, true,
                                          L"Palo Alto GlobalProtect"),
      "GlobalProtect must be rejected.");
  passed &= Expect(
      spy_dev_det::IsUnsafeNetworkAdapter(false, false,
                                          L"Custom corporate interface"),
      "Unbranded virtual interfaces must be rejected.");
  passed &= Expect(
      spy_dev_det::IsUnsafeNetworkAdapter(true, std::nullopt,
                                          L"Unnamed interface"),
      "Tunnel and PPP interfaces must be rejected.");
  return passed ? 0 : 1;
}
