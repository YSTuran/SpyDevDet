import 'package:spy_dev_det/features/scan/domain/scan_mode.dart';

enum DiscoveryMethod { reachability, tcp, mdns, ssdp, onvif, neighbor }

extension DiscoveryMethodText on DiscoveryMethod {
  String get label => switch (this) {
    DiscoveryMethod.reachability => 'Cihaz erişilebilirliği',
    DiscoveryMethod.tcp => 'TCP port kontrolü',
    DiscoveryMethod.mdns => 'mDNS servis keşfi',
    DiscoveryMethod.ssdp => 'SSDP/UPnP keşfi',
    DiscoveryMethod.onvif => 'ONVIF/WS-Discovery keşfi',
    DiscoveryMethod.neighbor => 'MAC zenginleştirme',
  };
}

class DiscoveryMetrics {
  const DiscoveryMetrics({
    this.attemptedTargets = 0,
    this.sentRequests = 0,
    this.receivedResponses = 0,
    this.acceptedResponses = 0,
    this.ignoredResponses = 0,
    this.timeoutCount = 0,
    this.multicastLockAcquired,
    this.detail,
  });

  final int attemptedTargets;
  final int sentRequests;
  final int receivedResponses;
  final int acceptedResponses;
  final int ignoredResponses;
  final int timeoutCount;
  final bool? multicastLockAcquired;
  final String? detail;

  bool get hasValues =>
      attemptedTargets > 0 ||
      sentRequests > 0 ||
      receivedResponses > 0 ||
      acceptedResponses > 0 ||
      ignoredResponses > 0 ||
      timeoutCount > 0 ||
      multicastLockAcquired != null ||
      detail != null;

  DiscoveryMetrics copyWith({
    int? attemptedTargets,
    int? sentRequests,
    int? receivedResponses,
    int? acceptedResponses,
    int? ignoredResponses,
    int? timeoutCount,
    bool? multicastLockAcquired,
    bool clearMulticastLockAcquired = false,
    String? detail,
  }) {
    return DiscoveryMetrics(
      attemptedTargets: attemptedTargets ?? this.attemptedTargets,
      sentRequests: sentRequests ?? this.sentRequests,
      receivedResponses: receivedResponses ?? this.receivedResponses,
      acceptedResponses: acceptedResponses ?? this.acceptedResponses,
      ignoredResponses: ignoredResponses ?? this.ignoredResponses,
      timeoutCount: timeoutCount ?? this.timeoutCount,
      multicastLockAcquired: clearMulticastLockAcquired
          ? null
          : multicastLockAcquired ?? this.multicastLockAcquired,
      detail: detail ?? this.detail,
    );
  }
}

enum DiscoveryMethodPhase {
  waiting,
  running,
  completed,
  platformRestricted,
  unavailable,
  failed,
  cancelled,
  skipped,
}

extension DiscoveryMethodPhaseText on DiscoveryMethodPhase {
  String get label => switch (this) {
    DiscoveryMethodPhase.waiting => 'Bekliyor',
    DiscoveryMethodPhase.running => 'Çalışıyor',
    DiscoveryMethodPhase.completed => 'Tamamlandı',
    DiscoveryMethodPhase.platformRestricted => 'Platform tarafından kısıtlı',
    DiscoveryMethodPhase.unavailable => 'Kullanılamıyor',
    DiscoveryMethodPhase.failed => 'Başarısız',
    DiscoveryMethodPhase.cancelled => 'İptal edildi',
    DiscoveryMethodPhase.skipped => 'Bu modda çalıştırılmadı',
  };
}

class DiscoveryMethodResult {
  const DiscoveryMethodResult({
    required this.method,
    required this.phase,
    this.deviceCount = 0,
    this.elapsed = Duration.zero,
    this.userMessage,
    this.metrics = const DiscoveryMetrics(),
  });

  const DiscoveryMethodResult.waiting(this.method)
    : phase = DiscoveryMethodPhase.waiting,
      deviceCount = 0,
      elapsed = Duration.zero,
      userMessage = null,
      metrics = const DiscoveryMetrics();

  final DiscoveryMethod method;
  final DiscoveryMethodPhase phase;
  final int deviceCount;
  final Duration elapsed;
  final String? userMessage;
  final DiscoveryMetrics metrics;

  bool get isProblem =>
      phase == DiscoveryMethodPhase.unavailable ||
      phase == DiscoveryMethodPhase.failed;

  bool get degradesPresenceCoverage =>
      (phase != DiscoveryMethodPhase.completed &&
          phase != DiscoveryMethodPhase.skipped &&
          phase != DiscoveryMethodPhase.platformRestricted) ||
      metrics.multicastLockAcquired == false;

  DiscoveryMethodResult copyWith({
    DiscoveryMethodPhase? phase,
    int? deviceCount,
    Duration? elapsed,
    String? userMessage,
    DiscoveryMetrics? metrics,
  }) {
    return DiscoveryMethodResult(
      method: method,
      phase: phase ?? this.phase,
      deviceCount: deviceCount ?? this.deviceCount,
      elapsed: elapsed ?? this.elapsed,
      userMessage: userMessage ?? this.userMessage,
      metrics: metrics ?? this.metrics,
    );
  }
}

class ScanReport {
  ScanReport({
    required this.startedAt,
    required Map<DiscoveryMethod, DiscoveryMethodResult> methods,
    this.completedAt,
    this.scanMode = ScanMode.detailed,
  }) : methods = Map.unmodifiable(methods);

  factory ScanReport.started(
    DateTime startedAt, {
    ScanMode scanMode = ScanMode.detailed,
  }) => ScanReport(
    startedAt: startedAt,
    scanMode: scanMode,
    methods: {
      for (final method in DiscoveryMethod.values)
        method: DiscoveryMethodResult.waiting(method),
    },
  );

  final DateTime startedAt;
  final DateTime? completedAt;
  final ScanMode scanMode;
  final Map<DiscoveryMethod, DiscoveryMethodResult> methods;

  bool get hasPresenceCoverage => const [
    DiscoveryMethod.reachability,
    DiscoveryMethod.neighbor,
  ].any((method) => methods[method]?.phase == DiscoveryMethodPhase.completed);

  bool get isPartial =>
      !hasPresenceCoverage ||
      methods.values.any((result) => result.degradesPresenceCoverage);

  bool get canComparePresence =>
      scanMode == ScanMode.detailed &&
      !isPartial &&
      DiscoveryMethod.values.every((method) {
        final phase = methods[method]?.phase;
        return phase == DiscoveryMethodPhase.completed ||
            method == DiscoveryMethod.neighbor &&
                phase == DiscoveryMethodPhase.platformRestricted;
      });

  ScanReport withMethod(DiscoveryMethodResult result) {
    return ScanReport(
      startedAt: startedAt,
      completedAt: completedAt,
      scanMode: scanMode,
      methods: {...methods, result.method: result},
    );
  }

  ScanReport complete(DateTime time) => ScanReport(
    startedAt: startedAt,
    completedAt: time,
    methods: methods,
    scanMode: scanMode,
  );

  ScanReport cancelRunning() => ScanReport(
    startedAt: startedAt,
    completedAt: completedAt,
    scanMode: scanMode,
    methods: {
      for (final entry in methods.entries)
        entry.key: entry.value.phase == DiscoveryMethodPhase.running
            ? entry.value.copyWith(phase: DiscoveryMethodPhase.cancelled)
            : entry.value,
    },
  );
}
