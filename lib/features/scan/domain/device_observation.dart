enum MacStatus { available, notObserved, restrictedOrUnavailable, invalid }

extension MacStatusText on MacStatus {
  String get label => switch (this) {
    MacStatus.available => 'MAC adresi bulundu',
    MacStatus.notObserved => 'MAC adresi bu taramada gözlemlenmedi',
    MacStatus.restrictedOrUnavailable =>
      'MAC adresi ağ veya Android kısıtı nedeniyle edinilemedi',
    MacStatus.invalid => 'Geçersiz MAC adresi kullanılmadı',
  };
}

class DeviceObservation {
  const DeviceObservation({
    required this.id,
    required this.ipAddress,
    required this.displayName,
    required this.macStatus,
    required this.services,
    this.discoveryMethod = 'Bilinmiyor',
    this.macAddress,
    this.vendor,
  });

  final String id;
  final String ipAddress;
  final String displayName;
  final String? macAddress;
  final MacStatus macStatus;
  final String? vendor;
  final List<String> services;
  final String discoveryMethod;

  bool get hasKnownVendor => vendor != null && vendor!.trim().isNotEmpty;
}
