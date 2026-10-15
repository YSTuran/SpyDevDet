import 'package:spy_dev_det/features/network/domain/network_snapshot.dart';
import 'package:spy_dev_det/features/scan/domain/device_observation.dart';
import 'package:spy_dev_det/features/scan/domain/scan_report.dart';

enum ScanPhase { idle, preparing, scanning, completed, cancelled, failed }

class ScanState {
  const ScanState({
    required this.phase,
    required this.progress,
    required this.devices,
    required this.statusMessage,
    required this.scannedTargets,
    required this.totalTargets,
    required this.rangeTruncated,
    this.network,
    this.scanRange,
    this.elapsed,
    this.report,
  });

  const ScanState.idle()
    : phase = ScanPhase.idle,
      progress = 0,
      devices = const [],
      statusMessage = 'Yerel ağ taraması başlatılmayı bekliyor',
      scannedTargets = 0,
      totalTargets = 0,
      rangeTruncated = false,
      network = null,
      scanRange = null,
      elapsed = null,
      report = null;

  final ScanPhase phase;
  final double progress;
  final List<DeviceObservation> devices;
  final String statusMessage;
  final int scannedTargets;
  final int totalTargets;
  final bool rangeTruncated;
  final NetworkSnapshot? network;
  final String? scanRange;
  final Duration? elapsed;
  final ScanReport? report;

  bool get isBusy =>
      phase == ScanPhase.preparing || phase == ScanPhase.scanning;

  ScanState copyWith({
    ScanPhase? phase,
    double? progress,
    List<DeviceObservation>? devices,
    String? statusMessage,
    int? scannedTargets,
    int? totalTargets,
    bool? rangeTruncated,
    NetworkSnapshot? network,
    String? scanRange,
    Duration? elapsed,
    ScanReport? report,
  }) {
    return ScanState(
      phase: phase ?? this.phase,
      progress: progress ?? this.progress,
      devices: devices ?? this.devices,
      statusMessage: statusMessage ?? this.statusMessage,
      scannedTargets: scannedTargets ?? this.scannedTargets,
      totalTargets: totalTargets ?? this.totalTargets,
      rangeTruncated: rangeTruncated ?? this.rangeTruncated,
      network: network ?? this.network,
      scanRange: scanRange ?? this.scanRange,
      elapsed: elapsed ?? this.elapsed,
      report: report ?? this.report,
    );
  }
}
