import 'package:spy_dev_det/features/scan/domain/device_observation.dart';

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

class DeviceObserved extends ScanEvent {
  const DeviceObserved(this.device);

  final DeviceObservation device;
}

class ScanCompleted extends ScanEvent {
  const ScanCompleted({required this.completedTargets, required this.elapsed});

  final int completedTargets;
  final Duration elapsed;
}

class ScanCancelled extends ScanEvent {
  const ScanCancelled();
}

class ScanFailed extends ScanEvent {
  const ScanFailed(this.userMessage);

  final String userMessage;
}
