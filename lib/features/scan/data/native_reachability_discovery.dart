import 'dart:async';
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
    this.platformSupportedOverride,
  });

  static const _channel = MethodChannel('yusufs.turan.spydevdet/network_info');
  static int _requestSequence = 0;

  final Duration timeout;
  final bool? platformSupportedOverride;

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
    final isPlatformSupported =
        platformSupportedOverride ?? (Platform.isAndroid || Platform.isWindows);
    if (!isPlatformSupported) {
      throw const ReachabilityUnavailableException();
    }

    final requestId =
        '${DateTime.now().microsecondsSinceEpoch}-${_requestSequence++}';
    final removeCancelListener = cancellationToken.addCancelListener(() {
      unawaited(_cancelNativeRequest(requestId));
    });
    List<String>? addresses;
    try {
      addresses = await _channel
          .invokeListMethod<String>('discoverReachableHosts', {
            'requestId': requestId,
            'sourceAddress': plan.network.localIpv4,
            'targets': plan.targets,
            'timeoutMillis': timeout.inMilliseconds,
          });
    } on PlatformException {
      throw const ReachabilityUnavailableException();
    } on MissingPluginException {
      throw const ReachabilityUnavailableException();
    } finally {
      removeCancelListener();
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

  static Future<void> _cancelNativeRequest(String requestId) async {
    try {
      await _channel.invokeMethod<void>('cancelReachability', {
        'requestId': requestId,
      });
    } on Object {
      // The request may already have completed or the platform channel may be
      // shutting down. Cancellation remains best effort in either case.
    }
  }
}

class ReachabilityUnavailableException implements Exception {
  const ReachabilityUnavailableException();
}
