import 'package:flutter_test/flutter_test.dart';
import 'package:visit_log/services/backup_service.dart';

void main() {
  group('ImportResult', () {
    test('a clean import reports no loss', () {
      const r = ImportResult(cancelled: false, imported: 4, skipped: 0);
      expect(r.hasLoss, isFalse);
      expect(r.cancelled, isFalse);
      expect(r.imported, 4);
    });

    test('a partial import is distinguishable from a clean one', () {
      // Previously this case returned a bare `true` and the UI reported
      // "تم استيراد البيانات بنجاح" while half the rows were dropped.
      const r = ImportResult(cancelled: false, imported: 2, skipped: 2);
      expect(r.hasLoss, isTrue);
      expect(r.cancelled, isFalse);
      expect(r.imported, 2);
      expect(r.skipped, 2);
    });

    test('cancellation is distinguishable from failure', () {
      const r = ImportResult.cancelled();
      expect(r.cancelled, isTrue);
      expect(r.imported, 0);
      expect(r.hasLoss, isFalse);
    });
  });

  group('BackupException', () {
    test('renders its message without an "Exception:" prefix', () {
      // The UI interpolates the error directly, so a wrapped Exception would
      // surface the literal word "Exception:" mid-sentence in Arabic.
      const e = BackupException('تنسيق ملف النسخة الاحتياطية غير صحيح');
      expect('$e', 'تنسيق ملف النسخة الاحتياطية غير صحيح');
      expect('$e', isNot(contains('Exception')));
    });
  });
}
