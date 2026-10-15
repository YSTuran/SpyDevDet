enum DeviceEvidenceSource { reachability, tcp, mdns, ssdp, network, neighbor }

extension DeviceEvidenceSourceText on DeviceEvidenceSource {
  String get label => switch (this) {
    DeviceEvidenceSource.reachability => 'Erişilebilirlik',
    DeviceEvidenceSource.tcp => 'TCP',
    DeviceEvidenceSource.mdns => 'mDNS',
    DeviceEvidenceSource.ssdp => 'SSDP',
    DeviceEvidenceSource.network => 'Ağ bilgisi',
    DeviceEvidenceSource.neighbor => 'Komşu tablosu',
  };
}

class DeviceEvidence {
  const DeviceEvidence({
    required this.source,
    required this.description,
    this.serviceType,
    this.port,
    this.identifier,
  });

  final DeviceEvidenceSource source;
  final String description;
  final String? serviceType;
  final int? port;
  final String? identifier;

  String get identity =>
      '${source.name}|${serviceType ?? ''}|${port ?? ''}|'
      '${identifier ?? ''}|$description';
}

enum DeviceCategory {
  router,
  cameraCandidate,
  printer,
  mediaDevice,
  computerOrPhone,
  unknown,
}

extension DeviceCategoryText on DeviceCategory {
  String get label => switch (this) {
    DeviceCategory.router => 'Yönlendirici',
    DeviceCategory.cameraCandidate => 'Kamera adayı',
    DeviceCategory.printer => 'Yazıcı adayı',
    DeviceCategory.mediaDevice => 'Medya/akıllı ev cihazı',
    DeviceCategory.computerOrPhone => 'Bilgisayar veya telefon adayı',
    DeviceCategory.unknown => 'Türü bilinmiyor',
  };
}

enum ConfidenceLevel { none, low, medium, high }

extension ConfidenceLevelText on ConfidenceLevel {
  String get label => switch (this) {
    ConfidenceLevel.none => 'Sınıflandırılmadı',
    ConfidenceLevel.low => 'Düşük güven',
    ConfidenceLevel.medium => 'Orta güven',
    ConfidenceLevel.high => 'Yüksek güven',
  };
}
