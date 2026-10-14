import 'package:spy_dev_det/features/scan/domain/device_observation.dart';
import 'package:spy_dev_det/features/scan/domain/device_scanner.dart';
import 'package:spy_dev_det/features/scan/domain/scan_cancellation_token.dart';
import 'package:spy_dev_det/features/scan/domain/scan_event.dart';
import 'package:spy_dev_det/features/scan/domain/scan_plan.dart';

class FakeDeviceScanner implements DeviceScanner {
  const FakeDeviceScanner({this.stepDelay = const Duration(milliseconds: 300)});

  final Duration stepDelay;

  @override
  Stream<ScanEvent> scan(
    ScanPlan plan,
    ScanCancellationToken cancellationToken,
  ) async* {
    final stopwatch = Stopwatch()..start();
    final observations = _demoObservations();
    yield ScanStarted(totalTargets: observations.length);

    for (var index = 0; index < observations.length; index++) {
      await Future<void>.delayed(stepDelay);
      if (cancellationToken.isCancelled) {
        yield const ScanCancelled();
        return;
      }
      yield DeviceObserved(observations[index]);
      yield ScanProgress(
        completedTargets: index + 1,
        totalTargets: observations.length,
      );
    }

    stopwatch.stop();
    yield ScanCompleted(
      completedTargets: observations.length,
      elapsed: stopwatch.elapsed,
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
        services: ['HTTP (80)', 'SSDP/UPnP'],
        discoveryMethod: 'Demo veri',
      ),
      DeviceObservation(
        id: 'demo-computer',
        ipAddress: '192.168.1.20',
        displayName: 'Demo bilgisayar',
        macStatus: MacStatus.notObserved,
        services: ['HTTPS (443)'],
        discoveryMethod: 'Demo veri',
      ),
      DeviceObservation(
        id: 'demo-unknown',
        ipAddress: '192.168.1.42',
        displayName: 'Bilinmeyen demo cihaz',
        macStatus: MacStatus.restrictedOrUnavailable,
        services: ['RTSP (554)'],
        discoveryMethod: 'Demo veri',
      ),
    ];
  }
}
