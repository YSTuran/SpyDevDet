import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:share_plus/share_plus.dart';
import 'package:spy_dev_det/features/history/domain/scan_report_export.dart';

enum ReportFileResult { saved, shared, cancelled }

class ReportFileService {
  const ReportFileService();

  Future<ReportFileResult> saveOrShare(GeneratedScanReport report) async {
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

    final result = await SharePlus.instance.share(
      ShareParams(
        subject: 'SpyDevDet tarama raporu',
        files: [
          XFile.fromData(
            bytes,
            mimeType: report.mimeType,
            name: report.fileName,
          ),
        ],
        fileNameOverrides: [report.fileName],
      ),
    );
    return result.status == ShareResultStatus.dismissed
        ? ReportFileResult.cancelled
        : ReportFileResult.shared;
  }
}
