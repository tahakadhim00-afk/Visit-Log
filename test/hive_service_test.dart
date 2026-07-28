import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:visit_log/models/visit.dart';
import 'package:visit_log/services/hive_service.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('visit_log_hive');
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => tempDir.path,
    );
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

  test('init() is safe to call twice (engine restart re-enters main)', () async {
    await HiveService.init();
    await HiveService.addVisit(Visit(
      id: 'v1',
      date: DateTime(2026, 3, 4),
      schoolName: 'A',
    ));

    // Previously threw: HiveError: There is already a TypeAdapter for typeId 0
    await expectLater(HiveService.init(), completes);

    expect(HiveService.getAllVisits().length, 1,
        reason: 'existing data survives a repeat init');
  });

  test('init() recovers after dispose()', () async {
    await HiveService.init();
    await HiveService.dispose();
    await expectLater(HiveService.init(), completes);
    expect(HiveService.getAllVisits(), isEmpty);
  });
}
