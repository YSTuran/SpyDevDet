import 'dart:math' as math;

import 'package:spy_dev_det/features/network/domain/ipv4_address.dart';
import 'package:spy_dev_det/features/network/domain/network_snapshot.dart';
import 'package:spy_dev_det/features/scan/domain/scan_mode.dart';

class ScanPlan {
  ScanPlan._({
    required this.network,
    required this.networkAddress,
    required this.broadcastAddress,
    required List<String> targets,
    required this.isTruncated,
    required this.mode,
    required this.rangeLabel,
  }) : targets = List.unmodifiable(targets);

  factory ScanPlan.fromNetwork(
    NetworkSnapshot network, {
    int maxTargets = 254,
    ScanMode mode = ScanMode.detailed,
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

    final gatewayAddress = _usableGatewayAddress(
      network.gatewayIpv4,
      networkValue: networkValue,
      broadcastValue: broadcastValue,
      mask: mask,
      localAddress: localAddress,
    );
    var gatewayAddedOutsideWindow = false;
    if (gatewayAddress != null) {
      final gateway = Ipv4Address.format(gatewayAddress);
      if (!targets.contains(gateway)) {
        if (targets.length >= targetCount) {
          targets.removeAt(_farthestTargetIndex(targets, localAddress));
        }
        targets.insert(0, gateway);
        gatewayAddedOutsideWindow = true;
      }
    }

    final rangeLabel = gatewayAddedOutsideWindow
        ? '${targets.length} seçili yerel adres • ağ geçidi dahil'
        : '${targets.first} – ${targets.last}';

    return ScanPlan._(
      network: network,
      networkAddress: Ipv4Address.format(networkValue),
      broadcastAddress: Ipv4Address.format(broadcastValue),
      targets: targets,
      isTruncated: remoteHostCount > targets.length,
      mode: mode,
      rangeLabel: rangeLabel,
    );
  }

  final NetworkSnapshot network;
  final String networkAddress;
  final String broadcastAddress;
  final List<String> targets;
  final bool isTruncated;
  final ScanMode mode;
  final String rangeLabel;

  static int? _usableGatewayAddress(
    String? value, {
    required int networkValue,
    required int broadcastValue,
    required int mask,
    required int localAddress,
  }) {
    if (value == null) {
      return null;
    }
    try {
      final gateway = Ipv4Address.parse(value);
      final isUsableHost = gateway > networkValue && gateway < broadcastValue;
      return Ipv4Address.isPrivate(gateway) &&
              (gateway & mask) == networkValue &&
              gateway != localAddress &&
              isUsableHost
          ? gateway
          : null;
    } on FormatException {
      return null;
    }
  }

  static int _farthestTargetIndex(List<String> targets, int localAddress) {
    var farthestIndex = 0;
    var farthestDistance = -1;
    for (var index = 0; index < targets.length; index++) {
      final distance = (Ipv4Address.parse(targets[index]) - localAddress).abs();
      if (distance > farthestDistance) {
        farthestIndex = index;
        farthestDistance = distance;
      }
    }
    return farthestIndex;
  }

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
