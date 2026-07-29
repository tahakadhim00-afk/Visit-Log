import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import '../services/backup_service.dart';
import '../services/hive_service.dart';
import '../services/settings_service.dart';

class ExportService {
  static const List<String> arabicMonths = [
    'كانون الثاني', 'شباط', 'آذار', 'نيسان', 'أيار', 'حزيران',
    'تموز', 'آب', 'أيلول', 'تشرين الأول', 'تشرين الثاني', 'كانون الأول'
  ];

  static const List<String> arabicDays = [
    'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'
  ];

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

  /// Inlines the app's font as base64 `@font-face` rules.
  ///
  /// The exported file has to render correctly on any device that opens it, so
  /// it cannot reference a Flutter asset path or a web font — the app declares
  /// no INTERNET permission and the browser has no access to the APK. Embedding
  /// costs roughly 650 KB per export, which is the price of a file that prints
  /// in the right font everywhere.
  ///
  /// Returns an empty string if the assets cannot be read, in which case the
  /// stylesheet falls back to the system font stack rather than failing the
  /// whole export.
  static Future<String> _fontFaceCss() async {
    try {
      final regular = await rootBundle.load(
        'assets/fonts/thmanyahsans-Regular.otf',
      );
      final bold = await rootBundle.load(
        'assets/fonts/thmanyahsans-Bold.otf',
      );
      final regularB64 = base64Encode(regular.buffer.asUint8List());
      final boldB64 = base64Encode(bold.buffer.asUint8List());
      return '''
  @font-face {
    font-family: "ThmanyahSans";
    font-weight: 400;
    font-style: normal;
    src: url(data:font/otf;base64,$regularB64) format("opentype");
  }
  @font-face {
    font-family: "ThmanyahSans";
    font-weight: 700;
    font-style: normal;
    src: url(data:font/otf;base64,$boldB64) format("opentype");
  }''';
    } catch (_) {
      return '';
    }
  }

  static Future<String> exportMonthlyVisits(DateTime forMonth) async {
    try {
      final (acadStart, acadEnd) = _academicYear(forMonth);

      final allMonthVisits = HiveService.getVisitsByMonth(forMonth.year, forMonth.month)
          .where((v) => v.date.weekday != DateTime.friday)
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      final monthName = arabicMonths[forMonth.month - 1];
      final fontFaceCss = await _fontFaceCss();
      final supervisorName = SettingsService.supervisorName;
      final specialization = SettingsService.specialization;
      final supervisionHeadName = SettingsService.supervisionHeadName;

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
$fontFaceCss
  /* Declared at top level, not inside `@media print`: several engines ignore
     the `size` descriptor when it is nested, which is what silently produced
     portrait output. */
  @page { size: A4 landscape; margin: 0.9cm; }
  * { box-sizing: border-box; }
  body {
    font-family: "ThmanyahSans", "Segoe UI", Tahoma, Arial, sans-serif;
    /* Caps on-screen width at the A4-landscape print area so the preview in a
       browser matches the printed sheet instead of stretching to the window. */
    max-width: 27.7cm;
    margin: 0 auto;
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
  .id-row {
    display: flex;
    justify-content: flex-start;
    gap: 90px;
    font-size: 13px;
    margin: 0 0 14px;
  }
  .col-idx { width: 4%; }
  .col-day { width: 9%; }
  .col-date { width: 11%; }
  /* Keeps the narrow columns on one line so a long school name cannot force
     the day or date to wrap and stagger the row height. */
  .col-day, .col-date, tbody td:nth-child(2), tbody td:nth-child(3) {
    white-space: nowrap;
  }
  .footer {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    font-size: 13px;
    line-height: 1.9;
    margin-top: 30px;
  }
  /* Both columns carry the same three lines so the name and date rows share a
     baseline across the page; the gap under التوقيع: leaves room to sign. */
  .footer-block { flex: 1; }
  /* The block is positioned as a unit but its lines all start at the same
     right edge — centering each line individually would stagger their starts
     because the lines differ in length. */
  .footer-block.center-block { text-align: center; }
  /* inline-block shrink-wraps the stack to its widest line, and `text-align:
     right` inside makes every line — including التوقيع: — begin at that one
     shared right edge instead of being centered independently. */
  .footer-block.center-block .sig-group {
    display: inline-block;
    text-align: right;
  }
  .footer-block .sig-line { margin-bottom: 26px; }
  @media print {
    @page { size: A4 landscape; margin: 0.9cm; }
    body { padding: 0; }
    table { page-break-inside: auto; }
    tr { page-break-inside: avoid; }
    thead { display: table-header-group; }
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

  <div class="id-row">
    <div class="id-field">المشرف الاختصاصي: ${_esc(supervisorName)}</div>
    <div class="id-field">الاختصاص: ${_esc(specialization)}</div>
  </div>

  <table>
    <thead>
      <tr>
        <th class="col-idx">ت</th>
        <th class="col-day">اليوم</th>
        <th class="col-date">التاريخ</th>
        <th class="right">اسم المدرسة</th>
        <th class="right">تفاصيل الزيارة</th>
        <th class="right">الملاحظات</th>
      </tr>
    </thead>
    <tbody>
${rows.toString().trimRight()}
    </tbody>
  </table>

  <div class="footer">
    <div class="footer-block">
      <div class="sig-line">التوقيع:</div>
      <div>اسم المشرف: ${_esc(supervisorName)}</div>
      <div>التاريخ:&nbsp;&nbsp;&nbsp;&nbsp;/&nbsp;&nbsp;&nbsp;&nbsp;/&nbsp; ${forMonth.year}</div>
    </div>
    <div class="footer-block center-block">
      <div class="sig-group">
        <div class="sig-line">التوقيع:</div>
        <div>مدير قسم الإشراف: ${_esc(supervisionHeadName)}</div>
        <div>التاريخ:&nbsp;&nbsp;&nbsp;&nbsp;/&nbsp;&nbsp;&nbsp;&nbsp;/&nbsp; ${forMonth.year}</div>
      </div>
    </div>
  </div>
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
