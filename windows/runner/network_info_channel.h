#ifndef RUNNER_NETWORK_INFO_CHANNEL_H_
#define RUNNER_NETWORK_INFO_CHANNEL_H_

#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>

#include <memory>

std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
RegisterNetworkInfoChannel(flutter::BinaryMessenger* messenger);

// Cancels and waits for native reachability work before the Flutter messenger
// is destroyed.
void ShutdownNetworkInfoChannel();

#endif  // RUNNER_NETWORK_INFO_CHANNEL_H_
