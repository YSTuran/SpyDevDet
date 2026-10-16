import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:spy_dev_det/features/scan/domain/device_discovery.dart';
import 'package:spy_dev_det/features/scan/domain/device_evidence.dart';
import 'package:spy_dev_det/features/scan/domain/device_observation.dart';
import 'package:spy_dev_det/features/scan/domain/device_observation_merger.dart';
import 'package:spy_dev_det/features/scan/domain/scan_cancellation_token.dart';
import 'package:spy_dev_det/features/scan/domain/scan_plan.dart';
import 'package:spy_dev_det/features/scan/domain/scan_report.dart';

class SsdpDeviceDiscovery implements DeviceDiscovery {
  const SsdpDeviceDiscovery({
    this.listenDuration = const Duration(milliseconds: 2200),
  });

  static const _request =
      'M-SEARCH * HTTP/1.1\r\n'
      'HOST: 239.255.255.250:1900\r\n'
      'MAN: "ssdp:discover"\r\n'
      'MX: 1\r\n'
      'ST: ssdp:all\r\n\r\n';

  final Duration listenDuration;

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
    var receivedResponses = 0;
    var acceptedResponses = 0;
    var ignoredResponses = 0;
    var sentRequests = 0;

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
        if (event != RawSocketEvent.read || observations.length >= 128) {
          return;
        }
        final datagram = socket?.receive();
        if (datagram == null) {
          return;
        }
        receivedResponses++;
        if (datagram.data.length > 16384) {
          ignoredResponses++;
          return;
        }
        final ipAddress = datagram.address.address;
        if (!_isAllowed(ipAddress, plan)) {
          ignoredResponses++;
          return;
        }
        final response = SsdpResponse.tryParse(datagram.data);
        if (response == null) {
          ignoredResponses++;
          return;
        }
        acceptedResponses++;
        final observation = _observation(ipAddress, response);
        final existing = observations[ipAddress];
        observations[ipAddress] = existing == null
            ? observation
            : const DeviceObservationMerger().merge(existing, observation);
      }, onError: (_) => finish());

      if (socket.send(
            ascii.encode(_request),
            InternetAddress('239.255.255.250'),
            1900,
          ) >
          0) {
        sentRequests++;
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
          detail: 'SSDP M-SEARCH yanıtları',
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

  DeviceObservation _observation(String ipAddress, SsdpResponse response) {
    final identity = response.server ?? response.searchTarget ?? 'SSDP cihazı';
    final services = <String>{
      if (response.searchTarget != null) response.searchTarget!,
      if (response.server != null) response.server!,
    }.toList();
    return DeviceObservation(
      id: 'device-$ipAddress',
      ipAddress: ipAddress,
      displayName: identity,
      macStatus: MacStatus.notObserved,
      services: services,
      discoveryMethod: 'SSDP',
      evidence: [
        DeviceEvidence(
          source: DeviceEvidenceSource.ssdp,
          description: 'SSDP duyurusu: $identity',
          serviceType: response.searchTarget,
          identifier: response.uniqueServiceName,
        ),
      ],
    );
  }
}

class SsdpResponse {
  const SsdpResponse({
    this.searchTarget,
    this.server,
    this.uniqueServiceName,
    this.location,
  });

  final String? searchTarget;
  final String? server;
  final String? uniqueServiceName;
  final String? location;

  static SsdpResponse? tryParse(List<int> bytes) {
    final text = latin1.decode(bytes, allowInvalid: true);
    final lines = const LineSplitter().convert(text);
    if (lines.isEmpty ||
        !lines.first.toUpperCase().startsWith('HTTP/1.1 200')) {
      return null;
    }

    final headers = <String, String>{};
    for (final line in lines.skip(1).take(64)) {
      final separator = line.indexOf(':');
      if (separator <= 0) {
        continue;
      }
      final name = line.substring(0, separator).trim().toLowerCase();
      if (!const {'st', 'server', 'usn', 'location'}.contains(name)) {
        continue;
      }
      headers[name] = _sanitize(line.substring(separator + 1));
    }
    if (headers.isEmpty) {
      return null;
    }
    return SsdpResponse(
      searchTarget: _notEmpty(headers['st']),
      server: _notEmpty(headers['server']),
      uniqueServiceName: _notEmpty(headers['usn']),
      location: _notEmpty(headers['location']),
    );
  }

  static String _sanitize(String value) {
    final sanitized = value.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '').trim();
    return sanitized.length <= 256 ? sanitized : sanitized.substring(0, 256);
  }

  static String? _notEmpty(String? value) =>
      value == null || value.isEmpty ? null : value;
}
