import 'package:spy_dev_det/features/scan/domain/device_observation.dart';

enum ScanPhase { idle, scanning, completed, cancelled, failed }

class ScanState {
  const ScanState({
    required this.phase,
    required this.progress,
    required this.devices,
    required this.statusMessage,
  });

  const ScanState.idle()
    : phase = ScanPhase.idle,
      progress = 0,
      devices = const [],
      statusMessage = 'Tarama başlatılmayı bekliyor';

  final ScanPhase phase;
  final double progress;
  final List<DeviceObservation> devices;
  final String statusMessage;

  bool get isScanning => phase == ScanPhase.scanning;

  ScanState copyWith({
    ScanPhase? phase,
    double? progress,
    List<DeviceObservation>? devices,
    String? statusMessage,
  }) {
    return ScanState(
      phase: phase ?? this.phase,
      progress: progress ?? this.progress,
      devices: devices ?? this.devices,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}
