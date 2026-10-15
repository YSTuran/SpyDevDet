import 'package:spy_dev_det/features/scan/domain/device_observation.dart';
import 'package:spy_dev_det/features/scan/domain/scan_cancellation_token.dart';
import 'package:spy_dev_det/features/scan/domain/scan_plan.dart';

abstract interface class DeviceDiscovery {
  Future<List<DeviceObservation>> discover(
    ScanPlan plan,
    ScanCancellationToken cancellationToken,
  );
}
