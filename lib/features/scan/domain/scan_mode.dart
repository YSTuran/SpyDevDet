enum ScanMode { quick, detailed }

extension ScanModeText on ScanMode {
  String get label => switch (this) {
    ScanMode.quick => 'Hızlı',
    ScanMode.detailed => 'Ayrıntılı',
  };

  String get description => switch (this) {
    ScanMode.quick =>
      'Erişilebilirlik, destekleniyorsa MAC ve kamera odaklı sınırlı TCP kontrolü',
    ScanMode.detailed =>
      'TCP, mDNS, SSDP, WS-Discovery/NetBIOS, erişilebilirlik ve destekleniyorsa MAC kontrolü',
  };
}
