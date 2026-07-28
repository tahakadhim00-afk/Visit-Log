import 'dart:convert';
import 'dart:io';
import '../services/backup_service.dart';
import '../services/hive_service.dart';

class ExportService {
  static const List<String> arabicMonths = [
    'كانون الثاني', 'شباط', 'آذار', 'نيسان', 'أيار', 'حزيران',
    'تموز', 'آب', 'أيلول', 'تشرين الأول', 'تشرين الثاني', 'كانون الأول'
  ];

  static const List<String> arabicDays = [
    'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'
  ];

  static const List<String> _holidayTypes = [
    'عطلة رسمية', 'اجازة', 'عطلة محلية',
  ];

  static bool _isHoliday(String? visitDetails) {
    if (visitDetails == null) return false;
    return _holidayTypes.contains(visitDetails.trim());
  }

  static String _twoDigit(int n) => n.toString().padLeft(2, '0');

  static String _isoDate(DateTime date) =>
      '${date.year}-${_twoDigit(date.month)}-${_twoDigit(date.day)}';

  static (int, int) _academicYear(DateTime date) {
    if (date.month >= 9) {
      return (date.year, date.year + 1);
    } else {
      return (date.year - 1, date.year);
    }
  }

  /// Escapes text for safe embedding in HTML — every visit field is
  /// free-form user input and must not be interpreted as markup.
  static String _esc(String text) => text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');

  static Future<String> exportMonthlyVisits(DateTime forMonth) async {
    try {
      final (acadStart, acadEnd) = _academicYear(forMonth);

      final allMonthVisits = HiveService.getVisitsByMonth(forMonth.year, forMonth.month)
          .where((v) => v.date.weekday != DateTime.friday)
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      final monthlyActual = allMonthVisits
          .where((v) => !_isHoliday(v.visitDetails))
          .length;

      final acadYearStart = DateTime(acadStart, 9, 1);
      final acadYearEnd = DateTime(forMonth.year, forMonth.month + 1, 1)
          .subtract(const Duration(days: 1));
      final cumulativeActual = HiveService.getAllVisits()
          .where((v) =>
              !v.date.isBefore(acadYearStart) &&
              !v.date.isAfter(acadYearEnd) &&
              v.date.weekday != DateTime.friday &&
              !_isHoliday(v.visitDetails))
          .length;

      final monthName = arabicMonths[forMonth.month - 1];

      final rows = StringBuffer();
      for (int i = 0; i < allMonthVisits.length; i++) {
        final visit = allMonthVisits[i];
        final dayName = arabicDays[visit.date.weekday - 1];
        final dateStr = _isoDate(visit.date);
        final details = visit.visitDetails?.trim() ?? '';
        final notes = visit.notes?.trim() ?? '';
        rows.writeln('''
        <tr>
          <td>${i + 1}</td>
          <td>${_esc(dayName)}</td>
          <td>$dateStr</td>
          <td class="right">${_esc(visit.schoolName)}</td>
          <td class="right">${_esc(details)}</td>
          <td class="right">${_esc(notes)}</td>
        </tr>''');
      }

      final html = '''
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
<meta charset="UTF-8">
<title>جدول الأعمال الشهرية - $monthName ${forMonth.year}</title>
<style>
  * { box-sizing: border-box; }
  body {
    font-family: "Cairo", "Segoe UI", Tahoma, Arial, sans-serif;
    margin: 0;
    padding: 24px;
    color: #111;
    background: #fff;
  }
  .top-row {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
  }
  .top-row .side { flex: 1; font-size: 13px; }
  .top-row .side.left { text-align: left; }
  .top-row .center { flex: 1; text-align: center; font-size: 19px; font-weight: 700; }
  h1 {
    text-align: center;
    font-size: 16px;
    margin: 6px 0 2px;
  }
  .subtitle {
    text-align: center;
    font-size: 12px;
    color: #333;
    margin: 0 0 14px;
  }
  table {
    width: 100%;
    border-collapse: collapse;
    margin-bottom: 16px;
  }
  th, td {
    border: 0.5px solid #666;
    padding: 5px 6px;
    font-size: 12px;
    text-align: center;
  }
  td.right, th.right { text-align: right; }
  thead th {
    background: #cce0f5;
    font-weight: 700;
  }
  tbody tr:nth-child(even) { background: #f7fbff; }
  .stats-table td {
    font-size: 11px;
  }
  .stats-table td.label {
    background: #cce0f5;
    font-weight: 700;
  }
  @media print {
    @page { size: A4 landscape; margin: 0.9cm; }
    body { padding: 0; }
  }
</style>
</head>
<body>
  <div class="top-row">
    <div class="side right">
      المديرية العامة لتربية محافظة بابل<br>
      قسم الإشراف الاختصاصي
    </div>
    <div class="center">جدول رقم (1)</div>
    <div class="side left"></div>
  </div>

  <h1>جدول الأعمال الشهرية</h1>
  <p class="subtitle">المتحقق من الأعمال لشهر ($monthName) للعام الدراسي ($acadStart - $acadEnd)</p>

  <table class="stats-table">
    <tr>
      <td class="label">عدد الزيارات المتحققة شهريا</td>
      <td>$monthlyActual</td>
      <td class="label">عدد الزيارات التراكمية</td>
      <td>$cumulativeActual</td>
    </tr>
  </table>

  <table>
    <thead>
      <tr>
        <th>ت</th>
        <th>اليوم</th>
        <th>التاريخ</th>
        <th class="right">اسم المدرسة</th>
        <th class="right">تفاصيل الزيارة</th>
        <th class="right">الملاحظات</th>
      </tr>
    </thead>
    <tbody>
${rows.toString().trimRight()}
    </tbody>
  </table>
</body>
</html>
''';

      final directory = await BackupService.resolveDownloadsDir();

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName =
          'جدول_الاعمال_الشهرية_${arabicMonths[forMonth.month - 1]}_${forMonth.year}_$timestamp.html';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(html, encoding: utf8);
      return file.path;
    } catch (e) {
      throw BackupException('خطأ في تصدير التقرير: $e');
    }
  }
}
