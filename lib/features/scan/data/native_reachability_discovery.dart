import 'dart:io';

import 'package:flutter/services.dart';
import 'package:spy_dev_det/features/scan/domain/device_discovery.dart';
import 'package:spy_dev_det/features/scan/domain/device_evidence.dart';
import 'package:spy_dev_det/features/scan/domain/device_observation.dart';
import 'package:spy_dev_det/features/scan/domain/scan_cancellation_token.dart';
import 'package:spy_dev_det/features/scan/domain/scan_plan.dart';
import 'package:spy_dev_det/features/scan/domain/scan_report.dart';

class NativeReachabilityDiscovery implements DeviceDiscovery {
  const NativeReachabilityDiscovery({
    this.timeout = const Duration(milliseconds: 500),
  });

  static const _channel = MethodChannel('yusufs.turan.spydevdet/network_info');

  final Duration timeout;

  @override
  Future<DeviceDiscoveryResult> discover(
    ScanPlan plan,
    ScanCancellationToken cancellationToken,
  ) async {
    if (timeout <= Duration.zero) {
      throw ArgumentError.value(timeout, 'timeout', 'Pozitif olmalıdır.');
    }
    if (cancellationToken.isCancelled) {
      return const DeviceDiscoveryResult.empty();
    }
    if (!Platform.isAndroid) {
      throw const ReachabilityUnavailableException();
    }

    List<String>? addresses;
    try {
      addresses = await _channel.invokeListMethod<String>(
        'discoverReachableHosts',
        {'targets': plan.targets, 'timeoutMillis': timeout.inMilliseconds},
      );
    } on PlatformException {
      throw const ReachabilityUnavailableException();
    } on MissingPluginException {
      throw const ReachabilityUnavailableException();
    }
    if (cancellationToken.isCancelled) {
      return const DeviceDiscoveryResult.empty();
    }

    final allowed = plan.targets.toSet();
    final devices = List<DeviceObservation>.unmodifiable(
      (addresses ?? const <String>[])
          .where(allowed.contains)
          .toSet()
          .map(
            (ipAddress) => DeviceObservation(
              id: 'device-$ipAddress',
              ipAddress: ipAddress,
              displayName: ipAddress == plan.network.gatewayIpv4
                  ? 'Yönlendirici adayı'
                  : 'Erişilebilir ağ cihazı',
              macStatus: MacStatus.notObserved,
              services: const [],
              discoveryMethod: 'Ağ erişilebilirlik kontrolü',
              evidence: const [
                DeviceEvidence(
                  source: DeviceEvidenceSource.reachability,
                  description:
                      'Cihaz yerel ağ erişilebilirlik kontrolüne yanıt verdi',
                ),
              ],
            ),
          ),
    );
    return DeviceDiscoveryResult(
      devices: devices,
      metrics: DiscoveryMetrics(
        attemptedTargets: plan.targets.length,
        receivedResponses: addresses?.length ?? 0,
        acceptedResponses: devices.length,
        ignoredResponses: (addresses?.length ?? 0) - devices.length,
        detail: 'İşletim sistemi erişilebilirlik kontrolü',
      ),
    );
  }
}

class ReachabilityUnavailableException implements Exception {
  const ReachabilityUnavailableException();
}
