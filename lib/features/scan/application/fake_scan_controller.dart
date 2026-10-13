import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spy_dev_det/features/scan/application/scan_state.dart';
import 'package:spy_dev_det/features/scan/domain/device_observation.dart';

final fakeScanControllerProvider =
    NotifierProvider<FakeScanController, ScanState>(FakeScanController.new);

class FakeScanController extends Notifier<ScanState> {
  int _generation = 0;

  @override
  ScanState build() {
    ref.onDispose(() => _generation++);
    return const ScanState.idle();
  }

  Future<void> startScan() async {
    final generation = ++_generation;
    state = const ScanState(
      phase: ScanPhase.scanning,
      progress: 0,
      devices: [],
      statusMessage: 'Demo cihazlar aranıyor',
    );

    final observations = _demoObservations();
    for (var index = 0; index < observations.length; index++) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (generation != _generation) {
        return;
      }

      final devices = [...state.devices, observations[index]];
      state = state.copyWith(
        devices: devices,
        progress: devices.length / observations.length,
        statusMessage: '${devices.length} demo cihaz bulundu',
      );
    }

    if (generation == _generation) {
      state = state.copyWith(
        phase: ScanPhase.completed,
        progress: 1,
        statusMessage: 'Demo tarama tamamlandı',
      );
    }
  }

  void cancelScan() {
    if (!state.isScanning) {
      return;
    }

    _generation++;
    state = state.copyWith(
      phase: ScanPhase.cancelled,
      statusMessage: 'Tarama iptal edildi',
    );
  }

  List<DeviceObservation> _demoObservations() {
    return const [
      DeviceObservation(
        id: 'demo-router',
        ipAddress: '192.168.1.1',
        displayName: 'Demo yönlendirici',
        macAddress: '02:00:00:00:00:01',
        macStatus: MacStatus.available,
        vendor: 'Demo üreticisi',
        services: ['HTTP', 'SSDP/UPnP'],
      ),
      DeviceObservation(
        id: 'demo-computer',
        ipAddress: '192.168.1.20',
        displayName: 'Demo bilgisayar',
        macStatus: MacStatus.notObserved,
        services: ['mDNS workstation', 'HTTPS'],
      ),
      DeviceObservation(
        id: 'demo-unknown',
        ipAddress: '192.168.1.42',
        displayName: 'Bilinmeyen demo cihaz',
        macStatus: MacStatus.restrictedOrUnavailable,
        services: ['RTSP adayı'],
      ),
    ];
  }
}
