import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Rect;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/visit.dart';
import 'hive_service.dart';
import 'settings_service.dart';

/// Outcome of an import, so callers can tell a clean restore from one that
/// silently dropped rows — the file has already replaced stored data by then.
class ImportResult {
  const ImportResult({
    required this.cancelled,
    this.imported = 0,
    this.skipped = 0,
  });

  const ImportResult.cancelled() : this(cancelled: true);

  final bool cancelled;
  final int imported;
  final int skipped;

  bool get hasLoss => skipped > 0;
}

/// How a share attempt ended, so the UI can tell "handed to an app" from
/// "user backed out" without leaking share_plus types into the screens.
enum ShareOutcome { shared, dismissed, unknown }

/// Thrown for conditions the user can act on; the message is shown as-is,
/// so it must not be wrapped again by callers.
class BackupException implements Exception {
  const BackupException(this.message);
  final String message;

  @override
  String toString() => message;
}

class BackupService {

  // ── EXPORT ────────────────────────────────────────────────────────────────

  static Future<String> exportDataToJson() async {
    try {
      final String jsonString = _buildBackupJson(HiveService.getAllVisits());

      final Directory saveDir = await _resolveDownloadsDir();
      final String filePath = '${saveDir.path}/${_backupFileName()}';
      await File(filePath).writeAsString(jsonString, encoding: utf8);

      return filePath;
    } catch (e) {
      throw BackupException('خطأ في تصدير البيانات: $e');
    }
  }

  // ── SHARE ─────────────────────────────────────────────────────────────────

  /// Hands the backup file to the system share sheet (WhatsApp, Telegram,
  /// mail, Drive …).
  ///
  /// The payload is byte-for-byte what [exportDataToJson] writes, so a file
  /// received this way restores through "استيراد البيانات" unchanged.
  ///
  /// [sharePositionOrigin] anchors the popover on iPad and macOS; it is
  /// ignored elsewhere.
  static Future<ShareOutcome> shareBackupJson({
    Rect? sharePositionOrigin,
  }) async {
    final List<Visit> allVisits = HiveService.getAllVisits();
    if (allVisits.isEmpty) {
      throw const BackupException('لا توجد زيارات لمشاركتها');
    }

    final String filePath;
    try {
      // Staged in the cache rather than Downloads: sharing should not leave a
      // second copy behind next to the user's real exports. share_plus copies
      // the file into its own provider folder before the sheet opens, so this
      // staging copy is only needed until then.
      final Directory shareDir =
          Directory('${(await getTemporaryDirectory()).path}/share');
      if (await shareDir.exists()) {
        await shareDir.delete(recursive: true); // drop the previous attempt
      }
      await shareDir.create(recursive: true);

      filePath = '${shareDir.path}/${_backupFileName()}';
      await File(filePath)
          .writeAsString(_buildBackupJson(allVisits), encoding: utf8);
    } catch (e) {
      throw BackupException('خطأ في تجهيز ملف المشاركة: $e');
    }

    try {
      // No `text` alongside the file: several messaging apps forward either the
      // text or the attachment, and the attachment is the point here.
      final ShareResult result = await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath, mimeType: 'application/json')],
          title: 'مشاركة الزيارات',
          subject: 'نسخة احتياطية من سجل الزيارات',
          sharePositionOrigin: sharePositionOrigin,
        ),
      );

      switch (result.status) {
        case ShareResultStatus.success:
          return ShareOutcome.shared;
        case ShareResultStatus.dismissed:
          return ShareOutcome.dismissed;
        case ShareResultStatus.unavailable:
          // Android/macOS often cannot report what the user picked; the sheet
          // still opened, so this is not a failure.
          return ShareOutcome.unknown;
      }
    } catch (e) {
      throw BackupException('تعذّرت مشاركة الملف: $e');
    }
  }

  // ── IMPORT ────────────────────────────────────────────────────────────────

  static Future<ImportResult> importDataFromJson() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: 'اختر ملف النسخة الاحتياطية',
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return const ImportResult.cancelled();
      }

      final PlatformFile picked = result.files.first;
      final String jsonString;

      if (picked.bytes != null) {
        jsonString = utf8.decode(picked.bytes!);
      } else if (picked.path != null) {
        final File f = File(picked.path!);
        if (!await f.exists()) {
          throw const BackupException('الملف المحدد غير موجود');
        }
        jsonString = await f.readAsString(encoding: utf8);
      } else {
        throw const BackupException('لا يمكن قراءة الملف المحدد');
      }

      // Decoded as dynamic first: a valid-but-wrong-shaped file (e.g. a JSON
      // array) would otherwise surface as a raw Dart TypeError.
      final dynamic decoded;
      try {
        decoded = json.decode(jsonString);
      } catch (_) {
        throw const BackupException('الملف ليس بصيغة JSON صالحة');
      }

      if (decoded is! Map<String, dynamic>) {
        throw const BackupException('تنسيق ملف النسخة الاحتياطية غير صحيح');
      }
      final Map<String, dynamic> backup = decoded;

      if (backup['visits'] is! List || !backup.containsKey('version')) {
        throw const BackupException('تنسيق ملف النسخة الاحتياطية غير صحيح');
      }

      // ── Parse and validate BEFORE touching stored data ───────────────────
      // Everything is materialised up front so a malformed file can never
      // leave the user with a wiped box and nothing to restore.
      final List<Visit> parsed = <Visit>[];
      int skipped = 0;
      for (final dynamic raw in backup['visits'] as List<dynamic>) {
        try {
          final Map<String, dynamic> v = raw as Map<String, dynamic>;
          parsed.add(Visit(
            id: v['id'] as String,
            date: DateTime.parse(v['date'] as String),
            schoolName: v['schoolName'] as String,
            notes: v['notes'] as String?,
            photoPath: v['photoPath'] as String?,
            visitTime: v['visitTime'] != null
                ? DateTime.parse(v['visitTime'] as String)
                : null,
            visitDetails: v['visitDetails'] as String?,
          ));
        } catch (_) {
          skipped++;
        }
      }

      if (parsed.isEmpty) {
        throw const BackupException(
            'لم يتم العثور على زيارات صحيحة في ملف النسخة الاحتياطية');
      }

      // ── Restore visits (only now is it safe to clear) ────────────────────
      await _clearAllVisits();
      for (final Visit v in parsed) {
        await HiveService.addVisit(v);
      }

      // ── Restore settings ─────────────────────────────────────────────────
      if (backup['settings'] is Map<String, dynamic>) {
        await SettingsService.restoreFromMap(
            backup['settings'] as Map<String, dynamic>);
      }

      // Older backups may carry a 'profilePhoto' key; it is ignored now that
      // the supervisor profile has been removed.

      return ImportResult(
        cancelled: false,
        imported: parsed.length,
        skipped: skipped,
      );
    } on BackupException {
      rethrow;
    } catch (e) {
      throw BackupException('خطأ في استيراد البيانات: $e');
    }
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  /// The one place the backup payload is built, so a file saved to Downloads
  /// and a file sent through the share sheet can never drift apart.
  static String _buildBackupJson(List<Visit> visits) {
    final List<Map<String, dynamic>> visitsJson = visits.map((visit) {
      return {
        'id': visit.id,
        'date': visit.date.toIso8601String(),
        'schoolName': visit.schoolName,
        'notes': visit.notes,
        'photoPath': visit.photoPath,
        'visitTime': visit.visitTime?.toIso8601String(),
        'visitDetails': visit.visitDetails,
      };
    }).toList();

    final Map<String, dynamic> backupData = {
      'version': '2.0',
      'exportDate': DateTime.now().toIso8601String(),
      'totalVisits': visits.length,
      'visits': visitsJson,
      'settings': SettingsService.toMap(),
    };

    return const JsonEncoder.withIndent('  ').convert(backupData);
  }

  /// Timestamped so repeated backups never overwrite each other, and so a
  /// received file names the moment it was taken.
  static String _backupFileName() {
    final String timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    return 'visit_log_backup_$timestamp.json';
  }

  /// Best-effort Downloads directory, falling back to app storage.
  /// Shared with [ExportService] so the path logic exists in one place.
  static Future<Directory> resolveDownloadsDir() => _resolveDownloadsDir();

  static Future<Directory> _resolveDownloadsDir() async {
    if (Platform.isAndroid) {
      try {
        // The public Downloads dir still reports exists() == true under scoped
        // storage (API 29+) while rejecting writes, so probe it for real
        // instead of trusting existence and failing at save time.
        final Directory shared = Directory('/storage/emulated/0/Download');
        if (await shared.exists() && await _isWritable(shared)) return shared;

        final Directory? ext = await getExternalStorageDirectory();
        if (ext != null) {
          final Directory fallback = Directory('${ext.path}/Download');
          if (!await fallback.exists()) {
            await fallback.create(recursive: true);
          }
          return fallback;
        }
      } catch (_) {}
    }
    return getApplicationDocumentsDirectory();
  }

  /// Probes with a real write, since directory permissions cannot be
  /// interrogated directly on Android.
  static Future<bool> _isWritable(Directory dir) async {
    final probe = File(
        '${dir.path}/.visit_log_probe_${DateTime.now().microsecondsSinceEpoch}');
    try {
      await probe.writeAsString('');
      await probe.delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _clearAllVisits() async {
    for (final Visit v in HiveService.getAllVisits()) {
      await HiveService.deleteVisit(v.id);
    }
  }
}
