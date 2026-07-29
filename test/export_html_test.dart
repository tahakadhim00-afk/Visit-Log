import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:visit_log/models/visit.dart';
import 'package:visit_log/services/hive_service.dart';
import 'package:visit_log/services/export_service.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('visit_log_test');

    // path_provider talks to the platform over a MethodChannel; stub it so
    // getApplicationDocumentsDirectory() resolves to a real temp dir instead
    // of throwing MissingPluginException under flutter test.
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => tempDir.path,
    );

    await HiveService.init();
  });

  tearDown(() async {
    await HiveService.dispose();
    await Hive.close();
    binding.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'), null);
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {
      // Best-effort cleanup; a lingering handle on Windows shouldn't fail
      // the test since the assertions above already ran.
    }
  });

  test('exportMonthlyVisits writes a well-formed, escaped HTML file', () async {
    final box = HiveService.visitBox;
    await box.put('v1', Visit(
      id: 'v1',
      date: DateTime(2026, 3, 4),
      schoolName: '<School> "A" & B',
      notes: "note with 'quotes' & <tags>",
      visitDetails: 'اختصاص',
    ));
    await box.put('v2', Visit(
      id: 'v2',
      date: DateTime(2026, 3, 10),
      schoolName: 'Normal School',
    ));

    final path = await ExportService.exportMonthlyVisits(DateTime(2026, 3, 1));
    expect(path.endsWith('.html'), isTrue);

    final content = await File(path).readAsString();
    expect(content, contains('<!DOCTYPE html>'));
    expect(content, contains('dir="rtl"'));
    expect(content, contains('&lt;School&gt; &quot;A&quot; &amp; B'));
    expect(content, contains('&#39;quotes&#39;'));
    expect(content, isNot(contains('<tags>')));
    expect(content, contains('Normal School'));
    expect(content, contains('@page { size: A4 portrait'));
    // Two @page rules exist (top level and inside @media print) and must not
    // disagree, or the sheet prints in the wrong orientation.
    expect(content, isNot(contains('landscape')));

    await File(path).delete();
  });
}
