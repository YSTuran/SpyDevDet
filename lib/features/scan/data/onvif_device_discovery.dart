import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:spy_dev_det/features/scan/domain/device_discovery.dart';
import 'package:spy_dev_det/features/scan/domain/device_evidence.dart';
import 'package:spy_dev_det/features/scan/domain/device_observation.dart';
import 'package:spy_dev_det/features/scan/domain/device_observation_merger.dart';
import 'package:spy_dev_det/features/scan/domain/scan_cancellation_token.dart';
import 'package:spy_dev_det/features/scan/domain/scan_plan.dart';
import 'package:spy_dev_det/features/scan/domain/scan_report.dart';
import 'package:xml/xml.dart';

class OnvifDeviceDiscovery implements DeviceDiscovery {
  const OnvifDeviceDiscovery({
    this.listenDuration = const Duration(milliseconds: 2500),
    this.retransmitDelay = const Duration(milliseconds: 140),
  });

  static final InternetAddress _multicastAddress = InternetAddress(
    '239.255.255.250',
  );
  static const _port = 3702;
  static const _maxDatagramBytes = 16384;
  static const _maxReceivedResponses = 512;
  static const _maxAcceptedMatches = 128;

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

    RawDatagramSocket? socket;
    StreamSubscription<RawSocketEvent>? subscription;
    Timer? timer;
    final done = Completer<void>();
    final observations = <String, DeviceObservation>{};
    final probes = [
      _ProbeRequest.modern('urn:uuid:${_uuidV4()}'),
      _ProbeRequest.legacy('urn:uuid:${_uuidV4()}'),
    ];
    var sentRequests = 0;
    var receivedResponses = 0;
    var acceptedResponses = 0;
    var ignoredResponses = 0;

    void finish() {
      if (!done.isCompleted) {
        done.complete();
      }
    }

    final removeCancelListener = cancellationToken.addCancelListener(finish);
    try {
      socket = await RawDatagramSocket.bind(
        InternetAddress(plan.network.localIpv4),
        0,
        reuseAddress: true,
      );
      socket.multicastHops = 1;
      subscription = socket.listen((event) {
        if (event != RawSocketEvent.read) {
          return;
        }
        Datagram? datagram;
        while ((datagram = socket?.receive()) != null) {
          if (receivedResponses >= _maxReceivedResponses) {
            ignoredResponses++;
            finish();
            break;
          }
          receivedResponses++;
          final current = datagram!;
          if (current.data.length > _maxDatagramBytes ||
              !_isAllowed(current.address.address, plan)) {
            ignoredResponses++;
            continue;
          }
          final matches = OnvifProbeResponse.tryParse(
            current.data,
            expectedRelatesTo: probes.map((probe) => probe.messageId),
          );
          if (matches == null || matches.isEmpty) {
            ignoredResponses++;
            continue;
          }
          for (final match in matches) {
            if (acceptedResponses >= _maxAcceptedMatches) {
              ignoredResponses++;
              finish();
              break;
            }
            acceptedResponses++;
            final observation = _observation(current.address.address, match);
            final existing = observations[observation.ipAddress];
            observations[observation.ipAddress] = existing == null
                ? observation
                : const DeviceObservationMerger().merge(existing, observation);
          }
        }
      }, onError: (_) => finish());

      for (final probe in probes) {
        final request = utf8.encode(_probeEnvelope(probe));
        for (var attempt = 0; attempt < 2; attempt++) {
          if (cancellationToken.isCancelled) {
            break;
          }
          if (socket.send(request, _multicastAddress, _port) > 0) {
            sentRequests++;
          }
          if (attempt == 0) {
            await Future<void>.delayed(retransmitDelay);
          }
        }
      }
      timer = Timer(listenDuration, finish);
      await done.future;
      return DeviceDiscoveryResult(
        devices: List.unmodifiable(observations.values),
        metrics: DiscoveryMetrics(
          sentRequests: sentRequests,
          receivedResponses: receivedResponses,
          acceptedResponses: acceptedResponses,
          ignoredResponses: ignoredResponses,
          detail: 'WS-Discovery Probe/ProbeMatch',
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
    if (ipAddress == plan.network.localIpv4) {
      return false;
    }
    return plan.targets.contains(ipAddress) ||
        ipAddress == plan.network.gatewayIpv4;
  }

  DeviceObservation _observation(String ipAddress, OnvifProbeMatch match) {
    final isVideoTransmitter = match.types.any(
      (type) => type.toLowerCase().contains('networkvideotransmitter'),
    );
    final displayName = match.deviceName ?? 'ONVIF cihazı';
    return DeviceObservation(
      id: 'device-$ipAddress',
      ipAddress: ipAddress,
      displayName: displayName,
      macStatus: MacStatus.notObserved,
      services: List.unmodifiable({
        'ONVIF WS-Discovery',
        ...match.types.map((type) => 'ONVIF $type'),
      }),
      discoveryMethod: 'ONVIF/WS-Discovery',
      evidence: [
        DeviceEvidence(
          source: DeviceEvidenceSource.onvif,
          description: isVideoTransmitter
              ? 'ONVIF NetworkVideoTransmitter duyurusu'
              : 'ONVIF WS-Discovery duyurusu',
          serviceType: match.types.join(' '),
          port: _port,
          identifier: match.endpointAddress,
        ),
      ],
    );
  }

  String _probeEnvelope(_ProbeRequest probe) =>
      '<?xml version="1.0" encoding="UTF-8"?>'
      '<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope" '
      'xmlns:a="${probe.addressingNamespace}" '
      'xmlns:d="${probe.discoveryNamespace}" '
      'xmlns:dn="http://www.onvif.org/ver10/network/wsdl">'
      '<s:Header>'
      '<a:Action>${probe.discoveryNamespace}/Probe</a:Action>'
      '<a:MessageID>${probe.messageId}</a:MessageID>'
      '<a:ReplyTo><a:Address>${probe.anonymousAddress}</a:Address></a:ReplyTo>'
      '<a:To>${probe.destination}</a:To>'
      '</s:Header>'
      '<s:Body><d:Probe><d:Types>dn:NetworkVideoTransmitter</d:Types>'
      '</d:Probe></s:Body></s:Envelope>';

  String _uuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}

class OnvifProbeResponse {
  const OnvifProbeResponse._();

  static List<OnvifProbeMatch>? tryParse(
    List<int> bytes, {
    required Iterable<String> expectedRelatesTo,
  }) {
    if (bytes.isEmpty ||
        bytes.length > OnvifDeviceDiscovery._maxDatagramBytes) {
      return null;
    }
    final source = utf8.decode(bytes, allowMalformed: true);
    if (RegExp(
      r'<!\s*(DOCTYPE|ENTITY)',
      caseSensitive: false,
    ).hasMatch(source)) {
      return null;
    }
    try {
      final document = XmlDocument.parse(source);
      final relatesTo = _firstText(document, 'RelatesTo');
      final expectedIds = expectedRelatesTo
          .map((value) => value.trim().toLowerCase())
          .toSet();
      if (relatesTo == null ||
          !expectedIds.contains(relatesTo.trim().toLowerCase())) {
        return null;
      }
      final matches = <OnvifProbeMatch>[];
      for (final element in document.descendants.whereType<XmlElement>()) {
        if (element.name.local != 'ProbeMatch') {
          continue;
        }
        final endpoint = _firstText(element, 'Address');
        if (endpoint == null || endpoint.trim().isEmpty) {
          continue;
        }
        final types = _words(_firstText(element, 'Types'));
        final scopes = _words(_firstText(element, 'Scopes'));
        final xAddrs = _words(
          _firstText(element, 'XAddrs'),
        ).where(_isSafeAdvertisedAddress).take(8).toList(growable: false);
        matches.add(
          OnvifProbeMatch(
            endpointAddress: _sanitize(endpoint, 256),
            types: List.unmodifiable(types.take(16)),
            scopes: List.unmodifiable(scopes.take(32)),
            xAddrs: List.unmodifiable(xAddrs),
            deviceName: _deviceName(scopes),
          ),
        );
      }
      return List.unmodifiable(matches.take(128));
    } on XmlParserException {
      return null;
    } on FormatException {
      return null;
    }
  }

  static String? _firstText(XmlNode node, String localName) {
    for (final element in node.descendants.whereType<XmlElement>()) {
      if (element.name.local == localName) {
        return element.innerText;
      }
    }
    return null;
  }

  static List<String> _words(String? value) => value == null
      ? const []
      : value
            .split(RegExp(r'\s+'))
            .map((item) => _sanitize(item, 512))
            .where((item) => item.isNotEmpty)
            .toList(growable: false);

  static String? _deviceName(List<String> scopes) {
    for (final scope in scopes) {
      final marker = '/name/';
      final index = scope.toLowerCase().indexOf(marker);
      if (index == -1) {
        continue;
      }
      final raw = scope.substring(index + marker.length);
      try {
        final name = _sanitize(Uri.decodeComponent(raw), 80);
        if (name.isNotEmpty) {
          return name;
        }
      } on FormatException {
        continue;
      }
    }
    return null;
  }

  static bool _isSafeAdvertisedAddress(String value) {
    final uri = Uri.tryParse(value);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  static String _sanitize(String value, int maxLength) {
    final sanitized = value.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '').trim();
    return sanitized.length <= maxLength
        ? sanitized
        : sanitized.substring(0, maxLength);
  }
}

class _ProbeRequest {
  const _ProbeRequest({
    required this.messageId,
    required this.addressingNamespace,
    required this.discoveryNamespace,
    required this.anonymousAddress,
    required this.destination,
  });

  factory _ProbeRequest.modern(String messageId) => _ProbeRequest(
    messageId: messageId,
    addressingNamespace: 'http://www.w3.org/2005/08/addressing',
    discoveryNamespace: 'http://docs.oasis-open.org/ws-dd/ns/discovery/2009/01',
    anonymousAddress: 'http://www.w3.org/2005/08/addressing/anonymous',
    destination: 'urn:docs-oasis-open-org:ws-dd:ns:discovery:2009:01',
  );

  factory _ProbeRequest.legacy(String messageId) => _ProbeRequest(
    messageId: messageId,
    addressingNamespace: 'http://schemas.xmlsoap.org/ws/2004/08/addressing',
    discoveryNamespace: 'http://schemas.xmlsoap.org/ws/2005/04/discovery',
    anonymousAddress:
        'http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous',
    destination: 'urn:schemas-xmlsoap-org:ws:2005:04:discovery',
  );

  final String messageId;
  final String addressingNamespace;
  final String discoveryNamespace;
  final String anonymousAddress;
  final String destination;
}

class OnvifProbeMatch {
  const OnvifProbeMatch({
    required this.endpointAddress,
    required this.types,
    required this.scopes,
    required this.xAddrs,
    required this.deviceName,
  });

  final String endpointAddress;
  final List<String> types;
  final List<String> scopes;
  final List<String> xAddrs;
  final String? deviceName;
}
