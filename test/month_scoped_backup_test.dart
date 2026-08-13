import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:visit_log/models/visit.dart';
import 'package:visit_log/services/backup_service.dart';
import 'package:visit_log/services/hive_service.dart';

/// Builds a month-scoped file the way [BackupService] writes one.
String monthJson(String monthKey, List<Map<String, dynamic>> visits) =>
    jsonEncode({
      'version': '2.0',
      'scope': 'month',
      'month': monthKey,
      'exportDate': DateTime(2026, 8, 20).toIso8601String(),
      'totalVisits': visits.length,
      'visits': visits,
    });

Map<String, dynamic> visitJson(String id, DateTime date, String school) => {
      'id': id,
      'date': date.toIso8601String(),
      'schoolName': school,
      'notes': null,
      'photoPath': null,
      'visitTime': null,
      'visitDetails': null,
    };

void main() {
  group('parseBackupJson', () {
    test('a file with no scope key is a full backup', () {
      // Every backup written before month sharing existed looks like this, and
      // must keep meaning "replace everything".
      final payload = BackupService.parseBackupJson(jsonEncode({
        'version': '2.0',
        'totalVisits': 1,
        'visits': [visitJson('v1', DateTime(2026, 6, 3), 'A')],
        'settings': {'supervisorName': 'سالم'},
      }));

      expect(payload.isMonthScoped, isFalse);
      expect(payload.month, isNull);
      expect(payload.settings, isNotNull,
          reason: 'a full backup still carries settings forward');
    });

    test('a month file is recognised and carries no settings', () {
      final payload = BackupService.parseBackupJson(monthJson(
        '2026-08',
        [visitJson('v1', DateTime(2026, 8, 4), 'A')],
      ));

      expect(payload.isMonthScoped, isTrue);
      expect(payload.month, DateTime(2026, 8));
      expect(payload.settings, isNull,
          reason:
              "a month file may come from another supervisor; their header "
              "must not overwrite the receiver's");
    });

    test('rows outside the declared month are refused, not written', () {
      // Otherwise a month file could quietly reach outside the month the user
      // agreed to in the confirmation dialog.
      final payload = BackupService.parseBackupJson(monthJson('2026-08', [
        visitJson('in', DateTime(2026, 8, 4), 'A'),
        visitJson('out', DateTime(2026, 7, 4), 'B'),
      ]));

      expect(payload.visits.map((v) => v.id), ['in']);
      expect(payload.skipped, 1);
    });

    test('a damaged month marker is reported, not treated as a full backup', () {
      // Falling back to "full backup" here would turn an unreadable field into
      // a wipe of every month.
      expect(
        () => BackupService.parseBackupJson(monthJson('20XX-99', [
          visitJson('v1', DateTime(2026, 8, 4), 'A'),
        ])),
        throwsA(isA<BackupException>()),
      );
    });
  });

  group('applyBackup', () {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('visit_log_month');
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async => tempDir.path,
      );
      await HiveService.init();
      await HiveService.addVisit(
          Visit(id: 'jun', date: DateTime(2026, 6, 3), schoolName: 'حزيران'));
      await HiveService.addVisit(
          Visit(id: 'jul', date: DateTime(2026, 7, 8), schoolName: 'تموز'));
      await HiveService.addVisit(
          Visit(id: 'aug_old', date: DateTime(2026, 8, 5), schoolName: 'قديم'));
    });

    tearDown(() async {
      await HiveService.dispose();
      await Hive.close();
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'), null);
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    });

    test('importing one month leaves every other month intact', () async {
      // The whole point of the scope marker: receiving August must not cost
      // the user June and July.
      final payload = BackupService.parseBackupJson(monthJson(
        '2026-08',
        [visitJson('aug_new', DateTime(2026, 8, 12), 'جديد')],
      ));

      final result = await BackupService.applyBackup(payload);

      final ids = HiveService.getAllVisits().map((v) => v.id).toSet();
      expect(ids, containsAll(<String>['jun', 'jul']),
          reason: 'other months survive a month-scoped import');
      expect(ids, contains('aug_new'));
      expect(ids, isNot(contains('aug_old')),
          reason: 'the imported month replaces the stored one');
      expect(result.month, DateTime(2026, 8));
      expect(result.imported, 1);
    });

    test('a full backup still replaces everything', () async {
      final payload = BackupService.parseBackupJson(jsonEncode({
        'version': '2.0',
        'totalVisits': 1,
        'visits': [visitJson('only', DateTime(2026, 1, 9), 'وحيد')],
      }));

      final result = await BackupService.applyBackup(payload);

      expect(HiveService.getAllVisits().map((v) => v.id), ['only']);
      expect(result.month, isNull);
    });
  });

}
