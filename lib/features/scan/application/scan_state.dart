import 'package:spy_dev_det/features/history/domain/reference_scan_comparison.dart';
import 'package:spy_dev_det/features/network/domain/network_snapshot.dart';
import 'package:spy_dev_det/features/scan/domain/device_observation.dart';
import 'package:spy_dev_det/features/scan/domain/scan_mode.dart';
import 'package:spy_dev_det/features/scan/domain/scan_report.dart';

enum ScanPhase {
  idle,
  preparing,
  scanning,
  saving,
  completed,
  cancelled,
  failed,
}

class ScanState {
  const ScanState({
    required this.phase,
    required this.progress,
    required this.devices,
    required this.statusMessage,
    required this.scannedTargets,
    required this.totalTargets,
    required this.rangeTruncated,
    this.scanMode = ScanMode.detailed,
    this.network,
    this.scanRange,
    this.elapsed,
    this.estimatedRemaining,
    this.errorCode,
    this.report,
    this.referenceComparison,
  });

  const ScanState.idle()
    : phase = ScanPhase.idle,
      progress = 0,
      devices = const [],
      statusMessage = 'Yerel ağ taraması başlatılmayı bekliyor',
      scannedTargets = 0,
      totalTargets = 0,
      rangeTruncated = false,
      scanMode = ScanMode.detailed,
      network = null,
      scanRange = null,
      elapsed = null,
      estimatedRemaining = null,
      errorCode = null,
      report = null,
      referenceComparison = null;

  final ScanPhase phase;
  final double progress;
  final List<DeviceObservation> devices;
  final String statusMessage;
  final int scannedTargets;
  final int totalTargets;
  final bool rangeTruncated;
  final ScanMode scanMode;
  final NetworkSnapshot? network;
  final String? scanRange;
  final Duration? elapsed;
  final Duration? estimatedRemaining;
  final String? errorCode;
  final ScanReport? report;
  final ReferenceScanComparison? referenceComparison;

  bool get isBusy =>
      phase == ScanPhase.preparing ||
      phase == ScanPhase.scanning ||
      phase == ScanPhase.saving;

  bool get canCancel =>
      phase == ScanPhase.preparing || phase == ScanPhase.scanning;

  ScanState copyWith({
    ScanPhase? phase,
    double? progress,
    List<DeviceObservation>? devices,
    String? statusMessage,
    int? scannedTargets,
    int? totalTargets,
    bool? rangeTruncated,
    ScanMode? scanMode,
    NetworkSnapshot? network,
    String? scanRange,
    Duration? elapsed,
    Duration? estimatedRemaining,
    bool clearEstimatedRemaining = false,
    String? errorCode,
    bool clearErrorCode = false,
    ScanReport? report,
    ReferenceScanComparison? referenceComparison,
    bool clearReferenceComparison = false,
  }) {
    return ScanState(
      phase: phase ?? this.phase,
      progress: progress ?? this.progress,
      devices: devices ?? this.devices,
      statusMessage: statusMessage ?? this.statusMessage,
      scannedTargets: scannedTargets ?? this.scannedTargets,
      totalTargets: totalTargets ?? this.totalTargets,
      rangeTruncated: rangeTruncated ?? this.rangeTruncated,
      scanMode: scanMode ?? this.scanMode,
      network: network ?? this.network,
      scanRange: scanRange ?? this.scanRange,
      elapsed: elapsed ?? this.elapsed,
      estimatedRemaining: clearEstimatedRemaining
          ? null
          : estimatedRemaining ?? this.estimatedRemaining,
      errorCode: clearErrorCode ? null : errorCode ?? this.errorCode,
      report: report ?? this.report,
      referenceComparison: clearReferenceComparison
          ? null
          : referenceComparison ?? this.referenceComparison,
    );
  }
}
