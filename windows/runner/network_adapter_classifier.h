#ifndef RUNNER_NETWORK_ADAPTER_CLASSIFIER_H_
#define RUNNER_NETWORK_ADAPTER_CLASSIFIER_H_

#include <optional>
#include <string>

namespace spy_dev_det {

// Returns true when an adapter is a VPN/tunnel or a virtual interface that
// should not be selected for a local physical-network scan.
bool IsUnsafeNetworkAdapter(bool reports_tunnel_or_ppp,
                            std::optional<bool> is_hardware_interface,
                            const std::wstring& identity);

}  // namespace spy_dev_det

#endif  // RUNNER_NETWORK_ADAPTER_CLASSIFIER_H_
