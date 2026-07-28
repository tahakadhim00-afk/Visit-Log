import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/visit.dart';
import 'hive_service.dart';
import 'settings_service.dart';

class BackupService {

  // ── EXPORT ────────────────────────────────────────────────────────────────

  static Future<String> exportDataToJson() async {
    try {
      final List<Visit> allVisits = HiveService.getAllVisits();

      final List<Map<String, dynamic>> visitsJson = allVisits.map((visit) {
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
        'totalVisits': allVisits.length,
        'visits': visitsJson,
        'settings': SettingsService.toMap(),
      };

      final String jsonString =
          const JsonEncoder.withIndent('  ').convert(backupData);

      final String timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
      final String fileName = 'visit_log_backup_$timestamp.json';

      final Directory saveDir = await _resolveDownloadsDir();
      final String filePath = '${saveDir.path}/$fileName';
      await File(filePath).writeAsString(jsonString, encoding: utf8);

      return filePath;
    } catch (e) {
      throw Exception('خطأ في تصدير البيانات: ${e.toString()}');
    }
  }

  // ── IMPORT ────────────────────────────────────────────────────────────────

  static Future<bool> importDataFromJson() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: 'اختر ملف النسخة الاحتياطية',
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return false;

      final PlatformFile picked = result.files.first;
      final String jsonString;

      if (picked.bytes != null) {
        jsonString = utf8.decode(picked.bytes!);
      } else if (picked.path != null) {
        final File f = File(picked.path!);
        if (!await f.exists()) throw Exception('الملف المحدد غير موجود');
        jsonString = await f.readAsString(encoding: utf8);
      } else {
        throw Exception('لا يمكن قراءة الملف المحدد');
      }

      final Map<String, dynamic> backup = json.decode(jsonString);

      if (!backup.containsKey('visits') || !backup.containsKey('version')) {
        throw Exception('تنسيق ملف النسخة الاحتياطية غير صحيح');
      }

      // ── Parse and validate BEFORE touching stored data ───────────────────
      // Everything is materialised up front so a malformed file can never
      // leave the user with a wiped box and nothing to restore.
      final List<Visit> parsed = <Visit>[];
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
          continue;
        }
      }

      if (parsed.isEmpty) {
        throw Exception(
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

      return true;
    } catch (e) {
      throw Exception('خطأ في استيراد البيانات: ${e.toString()}');
    }
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  /// Best-effort Downloads directory, falling back to app storage.
  /// Shared with [ExportService] so the path logic exists in one place.
  static Future<Directory> resolveDownloadsDir() => _resolveDownloadsDir();

  static Future<Directory> _resolveDownloadsDir() async {
    if (Platform.isAndroid) {
      try {
        final Directory? ext = await getExternalStorageDirectory();
        if (ext != null) {
          const String dl = '/storage/emulated/0/Download';
          final Directory dlDir = Directory(dl);
          if (await dlDir.exists()) return dlDir;
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

  static Future<void> _clearAllVisits() async {
    for (final Visit v in HiveService.getAllVisits()) {
      await HiveService.deleteVisit(v.id);
    }
  }
}
