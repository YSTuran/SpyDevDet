import 'package:spy_dev_det/features/scan/domain/device_observation.dart';
import 'package:spy_dev_det/features/scan/domain/scan_cancellation_token.dart';
import 'package:spy_dev_det/features/scan/domain/scan_plan.dart';
import 'package:spy_dev_det/features/scan/domain/scan_report.dart';

class DeviceDiscoveryResult {
  const DeviceDiscoveryResult({
    required this.devices,
    this.metrics = const DiscoveryMetrics(),
  });

  const DeviceDiscoveryResult.empty()
    : devices = const [],
      metrics = const DiscoveryMetrics();

  final List<DeviceObservation> devices;
  final DiscoveryMetrics metrics;
}

abstract interface class DeviceDiscovery {
  Future<DeviceDiscoveryResult> discover(
    ScanPlan plan,
    ScanCancellationToken cancellationToken,
  );
}
