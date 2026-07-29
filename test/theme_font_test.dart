import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:visit_log/main.dart';
import 'package:visit_log/services/hive_service.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('visit_log_theme_test');
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => tempDir.path,
    );
    await HiveService.init();
  });

  tearDown(() async {
    await HiveService.dispose();
    await Hive.close();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'), null);
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {
      // Best-effort cleanup; a lingering handle on Windows shouldn't fail a
      // test whose assertions already ran.
    }
  });

  testWidgets('both theme slots carry the bundled font', (tester) async {
    await tester.pumpWidget(const VisitLogApp());
    await tester.pump();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));

    // `themeMode: dark` is not sufficient on its own: with `theme:` unset,
    // Flutter can fall back to a bare default ThemeData that carries no
    // fontFamily, which renders the UI in the system font.
    expect(app.theme?.textTheme.bodyMedium?.fontFamily, 'ThmanyahSans',
        reason: 'theme: must carry the font, not only darkTheme:');
    expect(app.darkTheme?.textTheme.bodyMedium?.fontFamily, 'ThmanyahSans',
        reason: 'darkTheme: must carry the font');
  });

  testWidgets('rendered text actually resolves to the bundled font',
      (tester) async {
    await tester.pumpWidget(const VisitLogApp());
    await tester.pump();

    // Asserting on ThemeData alone would not prove the font reaches the
    // screen, so check what a real RichText in the tree was built with.
    final texts = find.byType(RichText).evaluate();
    expect(texts, isNotEmpty, reason: 'expected rendered text on first screen');

    final families = texts
        .map((e) => (e.widget as RichText).text.style?.fontFamily)
        .whereType<String>()
        // Icons legitimately render from the MaterialIcons glyph font.
        .where((f) => f != 'MaterialIcons')
        .toSet();

    expect(families, isNotEmpty,
        reason: 'rendered text should carry an explicit font family');
    expect(families, everyElement('ThmanyahSans'),
        reason: 'every rendered text style must use the bundled font, '
            'found: $families');
  });
}
