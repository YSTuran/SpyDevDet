enum DiscoveryMethod { tcp, mdns, ssdp, neighbor }

extension DiscoveryMethodText on DiscoveryMethod {
  String get label => switch (this) {
    DiscoveryMethod.tcp => 'TCP port kontrolü',
    DiscoveryMethod.mdns => 'mDNS servis keşfi',
    DiscoveryMethod.ssdp => 'SSDP/UPnP keşfi',
    DiscoveryMethod.neighbor => 'MAC zenginleştirme',
  };
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
  });

  const DiscoveryMethodResult.waiting(this.method)
    : phase = DiscoveryMethodPhase.waiting,
      deviceCount = 0,
      elapsed = Duration.zero,
      userMessage = null;

  final DiscoveryMethod method;
  final DiscoveryMethodPhase phase;
  final int deviceCount;
  final Duration elapsed;
  final String? userMessage;

  bool get isProblem =>
      phase == DiscoveryMethodPhase.unavailable ||
      phase == DiscoveryMethodPhase.failed;

  DiscoveryMethodResult copyWith({
    DiscoveryMethodPhase? phase,
    int? deviceCount,
    Duration? elapsed,
    String? userMessage,
  }) {
    return DiscoveryMethodResult(
      method: method,
      phase: phase ?? this.phase,
      deviceCount: deviceCount ?? this.deviceCount,
      elapsed: elapsed ?? this.elapsed,
      userMessage: userMessage ?? this.userMessage,
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

  bool get isPartial => methods.values.any((result) => result.isProblem);

  bool get canComparePresence => const [
    DiscoveryMethod.tcp,
    DiscoveryMethod.mdns,
    DiscoveryMethod.ssdp,
  ].every((method) => methods[method]?.phase == DiscoveryMethodPhase.completed);

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
