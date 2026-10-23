import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:spy_dev_det/features/history/data/report_file_service.dart';
import 'package:spy_dev_det/features/history/domain/scan_report_export.dart';

void main() {
  late Directory root;
  late ReportTemporaryFileStore store;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('spydevdet_report_test_');
    store = ReportTemporaryFileStore(
      temporaryDirectoryProvider: () async => root,
    );
  });

  tearDown(() async {
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
  });

  test('raporu yalnızca uygulamaya ait geçici klasöre yazar', () async {
    const report = GeneratedScanReport(
      fileName: '../spydevdet_test.csv',
      mimeType: 'text/csv',
      content: 'güvenli içerik',
    );

    final file = await store.write(
      report,
      Uint8List.fromList(utf8.encode(report.content)),
    );

    expect(
      path.normalize(file.parent.path),
      path.normalize(
        path.join(root.path, ReportTemporaryFileStore.directoryName),
      ),
    );
    expect(await file.readAsString(), report.content);
    expect(await File(path.join(root.path, report.fileName)).exists(), isFalse);
  });

  test('geçersiz üst klasör dosya adını reddeder', () async {
    const report = GeneratedScanReport(
      fileName: '..',
      mimeType: 'text/plain',
      content: 'içerik',
    );

    await expectLater(
      store.write(report, Uint8List.fromList(utf8.encode(report.content))),
      throwsFormatException,
    );
  });

  test('eski raporları siler, yeni ve ilişkisiz dosyaları korur', () async {
    final directory = Directory(
      path.join(root.path, ReportTemporaryFileStore.directoryName),
    );
    await directory.create(recursive: true);
    final oldReport = File(path.join(directory.path, 'spydevdet_old.csv'));
    final freshReport = File(path.join(directory.path, 'spydevdet_fresh.csv'));
    final unrelated = File(path.join(directory.path, 'unrelated.txt'));
    await oldReport.writeAsString('old');
    await freshReport.writeAsString('fresh');
    await unrelated.writeAsString('keep');
    final now = DateTime(2026, 10, 22, 12);
    await oldReport.setLastModified(now.subtract(const Duration(days: 2)));
    await freshReport.setLastModified(now.subtract(const Duration(hours: 2)));
    await unrelated.setLastModified(now.subtract(const Duration(days: 2)));

    await store.cleanupStaleReports(now: now);

    expect(await oldReport.exists(), isFalse);
    expect(await freshReport.exists(), isTrue);
    expect(await unrelated.exists(), isTrue);
  });
}
