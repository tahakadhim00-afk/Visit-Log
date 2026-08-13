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
    this.month,
  });

  const ImportResult.cancelled() : this(cancelled: true);

  final bool cancelled;
  final int imported;
  final int skipped;

  /// The single month the file covered, or null if it was a full backup.
  /// Set means every other month was left untouched.
  final DateTime? month;

  bool get hasLoss => skipped > 0;
}

/// A parsed, validated backup that has not been applied yet.
///
/// Reading is kept separate from applying so the confirmation can state what
/// the file will actually do: a month file rewrites one month, a full backup
/// erases everything. Asking the user to agree to "سيتم استبدال البيانات"
/// before the file has even been opened cannot make that distinction.
class BackupPayload {
  const BackupPayload({
    required this.visits,
    required this.skipped,
    required this.month,
    required this.settings,
  });

  final List<Visit> visits;
  final int skipped;

  /// First day of the month this file covers, or null for a full backup.
  final DateTime? month;

  /// Only ever populated for a full backup; see [applyBackup].
  final Map<String, dynamic>? settings;

  bool get isMonthScoped => month != null;
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
  /// Pass [month] to send only that month; omit it for a full backup. A month
  /// file is marked as such in the JSON so importing it rewrites that month
  /// alone instead of wiping the rest of the year.
  ///
  /// [sharePositionOrigin] anchors the popover on iPad and macOS; it is
  /// ignored elsewhere.
  static Future<ShareOutcome> shareBackupJson({
    DateTime? month,
    Rect? sharePositionOrigin,
  }) async {
    final List<Visit> allVisits = month == null
        ? HiveService.getAllVisits()
        : HiveService.getVisitsByMonth(month.year, month.month);
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

      filePath = '${shareDir.path}/${_backupFileName(month: month)}';
      await File(filePath).writeAsString(
        _buildBackupJson(allVisits, month: month),
        encoding: utf8,
      );
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

  /// Picks a file and parses it without touching stored data.
  ///
  /// Returns null if the user cancelled. Throws [BackupException] for anything
  /// the user can act on. Nothing is written until [applyBackup] is called.
  static Future<BackupPayload?> readBackupFile() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: 'اختر ملف النسخة الاحتياطية',
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return null;
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

      return parseBackupJson(jsonString);
    } on BackupException {
      rethrow;
    } catch (e) {
      throw BackupException('خطأ في قراءة ملف النسخة الاحتياطية: $e');
    }
  }

  /// Turns backup JSON into a payload, validating everything before any of it
  /// can reach storage. Split out from [readBackupFile] so the file format is
  /// verifiable without going through the platform file picker.
  static BackupPayload parseBackupJson(String jsonString) {
    try {
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

      // Every backup written before month sharing existed lacks this key, and
      // absence is exactly the full-replace behaviour those files expect.
      DateTime? month;
      if (backup['scope'] == 'month') {
        month = _parseMonthKey(backup['month']);
        if (month == null) {
          throw const BackupException(
              'الملف محدد كشهر واحد لكن تاريخ الشهر فيه غير صالح');
        }
      }

      // ── Parse and validate BEFORE touching stored data ───────────────────
      // Everything is materialised up front so a malformed file can never
      // leave the user with a wiped box and nothing to restore.
      final List<Visit> parsed = <Visit>[];
      int skipped = 0;
      for (final dynamic raw in backup['visits'] as List<dynamic>) {
        try {
          final Map<String, dynamic> v = raw as Map<String, dynamic>;
          final Visit visit = Visit(
            id: v['id'] as String,
            date: DateTime.parse(v['date'] as String),
            schoolName: v['schoolName'] as String,
            notes: v['notes'] as String?,
            photoPath: v['photoPath'] as String?,
            visitTime: v['visitTime'] != null
                ? DateTime.parse(v['visitTime'] as String)
                : null,
            visitDetails: v['visitDetails'] as String?,
          );
          // A month file that carries rows from other months would silently
          // widen its own blast radius, so those rows are refused rather than
          // written outside the month the user agreed to.
          if (month != null &&
              (visit.date.year != month.year ||
                  visit.date.month != month.month)) {
            skipped++;
            continue;
          }
          parsed.add(visit);
        } catch (_) {
          skipped++;
        }
      }

      if (parsed.isEmpty) {
        throw const BackupException(
            'لم يتم العثور على زيارات صحيحة في ملف النسخة الاحتياطية');
      }

      // Older backups may carry a 'profilePhoto' key; it is ignored now that
      // the supervisor profile has been removed.

      return BackupPayload(
        visits: parsed,
        skipped: skipped,
        month: month,
        // Only a full backup may carry settings forward; see [applyBackup].
        settings: month == null && backup['settings'] is Map<String, dynamic>
            ? backup['settings'] as Map<String, dynamic>
            : null,
      );
    } on BackupException {
      rethrow;
    } catch (e) {
      throw BackupException('خطأ في تحليل ملف النسخة الاحتياطية: $e');
    }
  }

  /// Writes a payload returned by [readBackupFile] into storage.
  ///
  /// A full backup replaces everything, as it always has. A month-scoped file
  /// rewrites only its own month, so receiving one month never costs the user
  /// the rest of their year.
  static Future<ImportResult> applyBackup(BackupPayload payload) async {
    try {
      if (payload.isMonthScoped) {
        await _clearMonth(payload.month!);
      } else {
        await _clearAllVisits();
      }

      for (final Visit v in payload.visits) {
        await HiveService.addVisit(v);
      }

      // Settings ride along with full backups only: a month file can come from
      // another supervisor, and their name must not land in the receiver's
      // report header.
      if (payload.settings != null) {
        await SettingsService.restoreFromMap(payload.settings!);
      }

      return ImportResult(
        cancelled: false,
        imported: payload.visits.length,
        skipped: payload.skipped,
        month: payload.month,
      );
    } catch (e) {
      throw BackupException('خطأ في استيراد البيانات: $e');
    }
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  /// The one place the backup payload is built, so a file saved to Downloads
  /// and a file sent through the share sheet can never drift apart.
  ///
  /// When [month] is set the file is stamped `scope: month`, which is what
  /// tells [readBackupFile] to rewrite that month alone on import.
  static String _buildBackupJson(List<Visit> visits, {DateTime? month}) {
    // Sorted so a human opening the file reads the month in order; import does
    // not depend on it.
    final ordered = [...visits]..sort((a, b) => a.date.compareTo(b.date));

    final List<Map<String, dynamic>> visitsJson = ordered.map((visit) {
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
      if (month != null) 'scope': 'month',
      if (month != null) 'month': _monthKey(month),
      'exportDate': DateTime.now().toIso8601String(),
      'totalVisits': ordered.length,
      'visits': visitsJson,
      // Deliberately absent from a month file: it may be sent to another
      // supervisor, and importing one month must not overwrite the receiver's
      // own report header.
      if (month == null) 'settings': SettingsService.toMap(),
    };

    return const JsonEncoder.withIndent('  ').convert(backupData);
  }

  /// `2026-08`, used both in month filenames and as the JSON `month` value.
  static String _monthKey(DateTime month) =>
      '${month.year}-${month.month.toString().padLeft(2, '0')}';

  /// Parses the `month` field back, returning null for anything unusable so a
  /// damaged marker is reported rather than silently treated as a full backup.
  static DateTime? _parseMonthKey(dynamic raw) {
    if (raw is! String) return null;
    final match = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(raw);
    if (match == null) return null;
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    if (month < 1 || month > 12) return null;
    return DateTime(year, month);
  }

  /// A month file is named for its month so the receiver can tell at a glance
  /// which one it is; a full backup stays timestamped so repeated backups
  /// never overwrite each other.
  static String _backupFileName({DateTime? month}) {
    if (month != null) return 'visit_log_${_monthKey(month)}.json';

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

  /// Clears one month so an imported month file becomes the record for it,
  /// leaving every other month in the box untouched.
  static Future<void> _clearMonth(DateTime month) async {
    for (final Visit v
        in HiveService.getVisitsByMonth(month.year, month.month)) {
      await HiveService.deleteVisit(v.id);
    }
  }
}
