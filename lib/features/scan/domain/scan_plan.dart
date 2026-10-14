import 'dart:math' as math;

import 'package:spy_dev_det/features/network/domain/ipv4_address.dart';
import 'package:spy_dev_det/features/network/domain/network_snapshot.dart';

class ScanPlan {
  ScanPlan._({
    required this.network,
    required this.networkAddress,
    required this.broadcastAddress,
    required List<String> targets,
    required this.isTruncated,
  }) : targets = List.unmodifiable(targets);

  factory ScanPlan.fromNetwork(
    NetworkSnapshot network, {
    int maxTargets = 254,
  }) {
    if (maxTargets < 1 || maxTargets > 254) {
      throw RangeError.range(maxTargets, 1, 254, 'maxTargets');
    }
    if (network.isVpn) {
      throw const ScanPlanningException(
        'VPN_ACTIVE',
        'VPN açıkken yanlış ağın taranmasını önlemek için tarama durduruldu.',
      );
    }
    if (!network.isWifi && !network.isEthernet) {
      throw const ScanPlanningException(
        'LOCAL_NETWORK_REQUIRED',
        'Yerel ağ taraması için Wi-Fi veya Ethernet bağlantısı gereklidir.',
      );
    }
    if (network.prefixLength < 1 || network.prefixLength > 30) {
      throw const ScanPlanningException(
        'UNSUPPORTED_PREFIX',
        'Bu ağın adres aralığı güvenli tarama için uygun değil.',
      );
    }

    final localAddress = _parseLocalAddress(network.localIpv4);
    if (!Ipv4Address.isPrivate(localAddress)) {
      throw const ScanPlanningException(
        'PUBLIC_RANGE_BLOCKED',
        'Güvenlik nedeniyle yalnızca özel yerel IPv4 ağları taranabilir.',
      );
    }

    final minimumPrefix = Ipv4Address.minimumPrivatePrefix(localAddress);
    if (network.prefixLength < minimumPrefix) {
      throw const ScanPlanningException(
        'RANGE_LEAVES_PRIVATE_NETWORK',
        'Ağ aralığı özel adres alanının dışına çıktığı için tarama engellendi.',
      );
    }

    final mask = Ipv4Address.maskForPrefix(network.prefixLength);
    final networkValue = localAddress & mask;
    final broadcastValue = networkValue | (~mask & Ipv4Address.maxValue);
    final firstUsable = networkValue + 1;
    final lastUsable = broadcastValue - 1;
    final remoteHostCount = lastUsable - firstUsable;
    if (remoteHostCount < 1) {
      throw const ScanPlanningException(
        'NO_REMOTE_TARGETS',
        'Bu ağda taranabilecek başka bir IPv4 adresi yok.',
      );
    }

    final targetCount = math.min(remoteHostCount, maxTargets);
    final windowLength = targetCount + 1;
    var windowStart = localAddress - (windowLength ~/ 2);
    windowStart = math.max(windowStart, firstUsable);
    windowStart = math.min(windowStart, lastUsable - windowLength + 1);
    windowStart = math.max(windowStart, firstUsable);

    final targets = <String>[];
    for (
      var candidate = windowStart;
      candidate <= lastUsable && targets.length < targetCount;
      candidate++
    ) {
      if (candidate != localAddress) {
        targets.add(Ipv4Address.format(candidate));
      }
    }

    return ScanPlan._(
      network: network,
      networkAddress: Ipv4Address.format(networkValue),
      broadcastAddress: Ipv4Address.format(broadcastValue),
      targets: targets,
      isTruncated: remoteHostCount > targets.length,
    );
  }

  final NetworkSnapshot network;
  final String networkAddress;
  final String broadcastAddress;
  final List<String> targets;
  final bool isTruncated;

  String get rangeLabel => '${targets.first} – ${targets.last}';

  static int _parseLocalAddress(String value) {
    try {
      return Ipv4Address.parse(value);
    } on FormatException {
      throw const ScanPlanningException(
        'INVALID_IPV4',
        'Cihazın geçerli bir IPv4 adresi bulunamadı.',
      );
    }
  }
}

class ScanPlanningException implements Exception {
  const ScanPlanningException(this.code, this.userMessage);

  final String code;
  final String userMessage;

  @override
  String toString() => 'ScanPlanningException($code)';
}
