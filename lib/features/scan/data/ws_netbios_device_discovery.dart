import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:spy_dev_det/features/scan/domain/device_discovery.dart';
import 'package:spy_dev_det/features/scan/domain/device_evidence.dart';
import 'package:spy_dev_det/features/scan/domain/device_observation.dart';
import 'package:spy_dev_det/features/scan/domain/scan_cancellation_token.dart';
import 'package:spy_dev_det/features/scan/domain/scan_plan.dart';
import 'package:spy_dev_det/features/scan/domain/scan_report.dart';

class NetbiosDeviceDiscovery implements DeviceDiscovery {
  const NetbiosDeviceDiscovery({
    this.listenDuration = const Duration(milliseconds: 1400),
    this.retransmitDelay = const Duration(milliseconds: 180),
  });

  static const _port = 137;
  static const _maxDatagramBytes = 8192;
  static const _maxReceivedResponses = 256;
  static const _maxAcceptedResponses = 128;

  final Duration listenDuration;
  final Duration retransmitDelay;

  @override
  Future<DeviceDiscoveryResult> discover(
    ScanPlan plan,
    ScanCancellationToken cancellationToken,
  ) async {
    if (cancellationToken.isCancelled) {
      return const DeviceDiscoveryResult.empty();
    }

    final transactionId = Random.secure().nextInt(0x10000);
    final query = NetbiosNodeStatusResponse.buildQuery(transactionId);
    final broadcastAddress = InternetAddress(
      plan.broadcastAddress,
      type: InternetAddressType.IPv4,
    );
    RawDatagramSocket? socket;
    StreamSubscription<RawSocketEvent>? subscription;
    Timer? timer;
    final done = Completer<void>();
    final devices = <String, DeviceObservation>{};
    var sentRequests = 0;
    var receivedResponses = 0;
    var acceptedResponses = 0;
    var ignoredResponses = 0;

    void finish() {
      if (!done.isCompleted) done.complete();
    }

    final removeCancelListener = cancellationToken.addCancelListener(finish);
    try {
      socket = await RawDatagramSocket.bind(
        InternetAddress(plan.network.localIpv4),
        0,
        reuseAddress: true,
      );
      socket.broadcastEnabled = true;
      subscription = socket.listen((event) {
        if (event != RawSocketEvent.read) return;
        Datagram? datagram;
        while ((datagram = socket?.receive()) != null) {
          if (receivedResponses >= _maxReceivedResponses) {
            ignoredResponses++;
            finish();
            break;
          }
          receivedResponses++;
          final current = datagram!;
          final ipAddress = current.address.address;
          if (current.data.length > _maxDatagramBytes ||
              current.port != _port ||
              !_isAllowed(ipAddress, plan)) {
            ignoredResponses++;
            continue;
          }
          final response = NetbiosNodeStatusResponse.tryParse(
            current.data,
            expectedTransactionId: transactionId,
          );
          if (response == null) {
            ignoredResponses++;
            continue;
          }
          if (acceptedResponses >= _maxAcceptedResponses) {
            ignoredResponses++;
            finish();
            break;
          }
          acceptedResponses++;
          devices[ipAddress] = _observation(ipAddress, response);
        }
      }, onError: (_) => finish());

      for (var attempt = 0; attempt < 2; attempt++) {
        if (cancellationToken.isCancelled) break;
        if (socket.send(query, broadcastAddress, _port) > 0) {
          sentRequests++;
        }
        if (attempt == 0) {
          await Future<void>.delayed(retransmitDelay);
        }
      }
      timer = Timer(listenDuration, finish);
      await done.future;
      return DeviceDiscoveryResult(
        devices: List.unmodifiable(devices.values),
        metrics: DiscoveryMetrics(
          sentRequests: sentRequests,
          receivedResponses: receivedResponses,
          acceptedResponses: acceptedResponses,
          ignoredResponses: ignoredResponses,
          detail:
              'Yerel yayın adresine iki sınırlı NetBIOS Node Status sorgusu',
        ),
      );
    } finally {
      removeCancelListener();
      timer?.cancel();
      await subscription?.cancel();
      socket?.close();
    }
  }

  bool _isAllowed(String ipAddress, ScanPlan plan) {
    if (ipAddress == plan.network.localIpv4) return false;
    return plan.targets.contains(ipAddress) ||
        ipAddress == plan.network.gatewayIpv4;
  }

  DeviceObservation _observation(
    String ipAddress,
    NetbiosNodeStatusResponse response,
  ) => DeviceObservation(
    id: 'device-$ipAddress',
    ipAddress: ipAddress,
    displayName: response.computerName ?? 'NetBIOS cihazı',
    macStatus: MacStatus.notObserved,
    services: const ['NetBIOS ad servisi (137)'],
    discoveryMethod: 'NetBIOS Node Status',
    evidence: [
      DeviceEvidence(
        source: DeviceEvidenceSource.netbios,
        description: 'NetBIOS Node Status sorgusuna yanıt verdi',
        serviceType: 'NBSTAT',
        port: _port,
        identifier: response.computerName,
      ),
    ],
  );
}

class NetbiosNodeStatusResponse {
  const NetbiosNodeStatusResponse({required this.computerName});

  final String? computerName;

  static Uint8List buildQuery(int transactionId) {
    if (transactionId < 0 || transactionId > 0xffff) {
      throw RangeError.range(transactionId, 0, 0xffff, 'transactionId');
    }
    final bytes = BytesBuilder(copy: false);
    bytes.add([
      transactionId >> 8,
      transactionId & 0xff,
      0x01,
      0x10,
      0x00,
      0x01,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x20,
    ]);
    final name = <int>[0x2a, ...List<int>.filled(15, 0)];
    for (final byte in name) {
      bytes.add([0x41 + ((byte >> 4) & 0x0f), 0x41 + (byte & 0x0f)]);
    }
    bytes.add([0x00, 0x00, 0x21, 0x00, 0x01]);
    return bytes.takeBytes();
  }

  static NetbiosNodeStatusResponse? tryParse(
    List<int> source, {
    required int expectedTransactionId,
  }) {
    if (source.length < 12 ||
        source.length > NetbiosDeviceDiscovery._maxDatagramBytes) {
      return null;
    }
    final bytes = Uint8List.fromList(source);
    final data = ByteData.sublistView(bytes);
    int read16(int offset) => data.getUint16(offset, Endian.big);
    if (read16(0) != expectedTransactionId || read16(2) & 0x8000 == 0) {
      return null;
    }
    final questionCount = read16(4);
    final answerCount = read16(6);
    if (questionCount > 4 || answerCount < 1 || answerCount > 32) return null;

    var offset = 12;
    for (var index = 0; index < questionCount; index++) {
      offset = _skipName(bytes, offset) ?? -1;
      if (offset < 0 || offset + 4 > bytes.length) return null;
      offset += 4;
    }
    for (var index = 0; index < answerCount; index++) {
      offset = _skipName(bytes, offset) ?? -1;
      if (offset < 0 || offset + 10 > bytes.length) return null;
      final type = read16(offset);
      final dataLength = read16(offset + 8);
      offset += 10;
      if (dataLength < 1 || offset + dataLength > bytes.length) return null;
      if (type == 0x21) {
        final parsed = _parseNodeStatus(bytes, offset, dataLength);
        if (parsed != null) return parsed;
      }
      offset += dataLength;
    }
    return null;
  }

  static NetbiosNodeStatusResponse? _parseNodeStatus(
    Uint8List bytes,
    int offset,
    int length,
  ) {
    final count = bytes[offset];
    if (count > 64 || 1 + count * 18 > length) return null;
    String? fallback;
    for (var index = 0; index < count; index++) {
      final start = offset + 1 + index * 18;
      final name = _sanitizeName(bytes.sublist(start, start + 15));
      final suffix = bytes[start + 15];
      final flags = (bytes[start + 16] << 8) | bytes[start + 17];
      final isGroup = flags & 0x8000 != 0;
      final isActive = flags & 0x0400 != 0;
      if (name == null || isGroup || !isActive) continue;
      fallback ??= name;
      if (suffix == 0x00) {
        return NetbiosNodeStatusResponse(computerName: name);
      }
    }
    return fallback == null
        ? null
        : NetbiosNodeStatusResponse(computerName: fallback);
  }

  static int? _skipName(Uint8List bytes, int offset) {
    var cursor = offset;
    for (var labels = 0; labels < 128; labels++) {
      if (cursor >= bytes.length) return null;
      final length = bytes[cursor];
      if (length & 0xc0 == 0xc0) {
        return cursor + 2 <= bytes.length ? cursor + 2 : null;
      }
      cursor++;
      if (length == 0) return cursor;
      if (length > 63 || cursor + length > bytes.length) return null;
      cursor += length;
    }
    return null;
  }

  static String? _sanitizeName(List<int> bytes) {
    final value = latin1
        .decode(bytes, allowInvalid: true)
        .replaceAll(RegExp(r'[^\x20-\x7E]'), '')
        .trim();
    if (value.isEmpty) return null;
    return value.length <= 15 ? value : value.substring(0, 15);
  }
}
