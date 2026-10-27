import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:spy_dev_det/features/history/domain/scan_report_export.dart';

enum ReportFileResult { saved, shared, cancelled }

class ReportFileService {
  const ReportFileService({
    this.temporaryStore = const ReportTemporaryFileStore(),
  });

  final ReportTemporaryFileStore temporaryStore;

  Future<void> cleanupStaleReports() => temporaryStore.cleanupStaleReports();

  Future<ReportFileResult> saveOrShare(
    GeneratedScanReport report, {
    String subject = 'SpyDevDet tarama raporu',
  }) async {
    final bytes = Uint8List.fromList(utf8.encode(report.content));
    if (Platform.isWindows) {
      final extension = report.fileName.split('.').last;
      final location = await getSaveLocation(
        suggestedName: report.fileName,
        acceptedTypeGroups: [
          XTypeGroup(label: 'SpyDevDet raporu', extensions: [extension]),
        ],
      );
      if (location == null) return ReportFileResult.cancelled;
      final file = XFile.fromData(
        bytes,
        mimeType: report.mimeType,
        name: report.fileName,
      );
      await file.saveTo(location.path);
      return ReportFileResult.saved;
    }

    await temporaryStore.cleanupStaleReports();
    final temporaryFile = await temporaryStore.write(report, bytes);
    final result = await SharePlus.instance.share(
      ShareParams(
        subject: subject,
        files: [XFile(temporaryFile.path, mimeType: report.mimeType)],
        fileNameOverrides: [report.fileName],
      ),
    );
    return result.status == ShareResultStatus.dismissed
        ? ReportFileResult.cancelled
        : ReportFileResult.shared;
  }
}

typedef TemporaryDirectoryProvider = Future<Directory> Function();

class ReportTemporaryFileStore {
  const ReportTemporaryFileStore({
    this.temporaryDirectoryProvider = getTemporaryDirectory,
  });

  static const directoryName = 'spydevdet_reports';
  static const retention = Duration(days: 1);

  final TemporaryDirectoryProvider temporaryDirectoryProvider;

  Future<File> write(GeneratedScanReport report, Uint8List bytes) async {
    final directory = await _reportDirectory();
    await directory.create(recursive: true);
    final safeName = path.basename(report.fileName);
    if (safeName.isEmpty ||
        safeName == '.' ||
        safeName == '..' ||
        safeName == path.separator) {
      throw const FormatException('Rapor dosya adı geçersiz.');
    }
    final file = File(path.join(directory.path, safeName));
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<void> cleanupStaleReports({DateTime? now}) async {
    try {
      final directory = await _reportDirectory();
      if (!await directory.exists()) return;
      final cutoff = (now ?? DateTime.now()).subtract(retention);
      await for (final entity in directory.list(followLinks: false)) {
        if (entity is! File ||
            !path.basename(entity.path).startsWith('spydevdet_')) {
          continue;
        }
        final modifiedAt = await entity.lastModified();
        if (modifiedAt.isBefore(cutoff)) {
          await entity.delete();
        }
      }
    } on Object {
      // Cache cleanup must never prevent startup or report sharing. A future
      // cleanup attempt or the operating system can remove the stale files.
    }
  }

  Future<Directory> _reportDirectory() async {
    final root = await temporaryDirectoryProvider();
    return Directory(path.join(root.path, directoryName));
  }
}
