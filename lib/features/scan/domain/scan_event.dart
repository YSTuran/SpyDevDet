import 'package:spy_dev_det/features/scan/domain/device_observation.dart';
import 'package:spy_dev_det/features/scan/domain/scan_report.dart';

sealed class ScanEvent {
  const ScanEvent();
}

class ScanStarted extends ScanEvent {
  const ScanStarted({required this.totalTargets});

  final int totalTargets;
}

class ScanProgress extends ScanEvent {
  const ScanProgress({
    required this.completedTargets,
    required this.totalTargets,
  });

  final int completedTargets;
  final int totalTargets;
}

class ScanStageChanged extends ScanEvent {
  const ScanStageChanged(this.userMessage);

  final String userMessage;
}

class ScanMethodStatusChanged extends ScanEvent {
  const ScanMethodStatusChanged(this.result);

  final DiscoveryMethodResult result;
}

class DeviceObserved extends ScanEvent {
  const DeviceObserved(this.device);

  final DeviceObservation device;
}

class ScanCompleted extends ScanEvent {
  const ScanCompleted({
    required this.completedTargets,
    required this.elapsed,
    this.metrics = const DiscoveryMetrics(),
  });

  final int completedTargets;
  final Duration elapsed;
  final DiscoveryMetrics metrics;
}

class ScanCancelled extends ScanEvent {
  const ScanCancelled({this.metrics = const DiscoveryMetrics()});

  final DiscoveryMetrics metrics;
}

class ScanFailed extends ScanEvent {
  const ScanFailed(this.userMessage);

  final String userMessage;
}
