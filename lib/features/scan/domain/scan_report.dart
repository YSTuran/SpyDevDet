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
  unavailable,
  failed,
  cancelled,
}

extension DiscoveryMethodPhaseText on DiscoveryMethodPhase {
  String get label => switch (this) {
    DiscoveryMethodPhase.waiting => 'Bekliyor',
    DiscoveryMethodPhase.running => 'Çalışıyor',
    DiscoveryMethodPhase.completed => 'Tamamlandı',
    DiscoveryMethodPhase.unavailable => 'Kullanılamıyor',
    DiscoveryMethodPhase.failed => 'Başarısız',
    DiscoveryMethodPhase.cancelled => 'İptal edildi',
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
  }) : methods = Map.unmodifiable(methods);

  factory ScanReport.started(DateTime startedAt) => ScanReport(
    startedAt: startedAt,
    methods: {
      for (final method in DiscoveryMethod.values)
        method: DiscoveryMethodResult.waiting(method),
    },
  );

  final DateTime startedAt;
  final DateTime? completedAt;
  final Map<DiscoveryMethod, DiscoveryMethodResult> methods;

  bool get hasPresenceCoverage => const [
    DiscoveryMethod.reachability,
    DiscoveryMethod.neighbor,
  ].any((method) => methods[method]?.phase == DiscoveryMethodPhase.completed);

  bool get isPartial =>
      !hasPresenceCoverage ||
      const [
        DiscoveryMethod.tcp,
        DiscoveryMethod.mdns,
        DiscoveryMethod.ssdp,
        DiscoveryMethod.onvif,
      ].any(
        (method) => methods[method]?.phase != DiscoveryMethodPhase.completed,
      );

  bool get canComparePresence => !isPartial;

  ScanReport withMethod(DiscoveryMethodResult result) {
    return ScanReport(
      startedAt: startedAt,
      completedAt: completedAt,
      methods: {...methods, result.method: result},
    );
  }

  ScanReport complete(DateTime time) =>
      ScanReport(startedAt: startedAt, completedAt: time, methods: methods);

  ScanReport cancelRunning() => ScanReport(
    startedAt: startedAt,
    completedAt: completedAt,
    methods: {
      for (final entry in methods.entries)
        entry.key: entry.value.phase == DiscoveryMethodPhase.running
            ? entry.value.copyWith(phase: DiscoveryMethodPhase.cancelled)
            : entry.value,
    },
  );
}
