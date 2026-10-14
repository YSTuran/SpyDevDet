class NetworkSnapshot {
  const NetworkSnapshot({
    required this.localIpv4,
    required this.prefixLength,
    required this.interfaceName,
    required this.isWifi,
    required this.isVpn,
    this.gatewayIpv4,
  });

  final String localIpv4;
  final int prefixLength;
  final String interfaceName;
  final bool isWifi;
  final bool isVpn;
  final String? gatewayIpv4;

  String get cidr => '$localIpv4/$prefixLength';
}
