import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
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

  static String _footerDate(DateTime date) =>
      '${_twoDigit(date.day)}/${_twoDigit(date.month)}/${date.year}';

  // Returns (startYear, endYear) for the academic year containing [date].
  // Iraqi academic year runs Sep–Jun. Sep–Dec belongs to year/(year+1).
  static (int, int) _academicYear(DateTime date) {
    if (date.month >= 9) {
      return (date.year, date.year + 1);
    } else {
      return (date.year - 1, date.year);
    }
  }

  static Future<String> exportMonthlyVisits(DateTime forMonth) async {
    try {
      final (acadStart, acadEnd) = _academicYear(forMonth);

      // All visits for the exported month, excluding Fridays
      final allMonthVisits = HiveService.getVisitsByMonth(forMonth.year, forMonth.month)
          .where((v) => v.date.weekday != DateTime.friday)
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      // Count actual (non-holiday) visits this month
      final monthlyActual = allMonthVisits
          .where((v) => !_isHoliday(v.visitDetails))
          .length;

      // Cumulative actual visits for the entire academic year up to forMonth
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

      // Supervisor profile
      final supervisorName = SettingsService.supervisorName;
      final specialty = SettingsService.specialty;
      final headName = SettingsService.supervisionHeadName;
      final specialtySchools = SettingsService.specialtySchoolsCount;
      final criticalFriendSchools = SettingsService.criticalFriendSchoolsCount;
      final externalEvalSchools = SettingsService.externalEvalSchoolsCount;

      final monthName = arabicMonths[forMonth.month - 1];
      final exportDate = _footerDate(DateTime.now());

      final html = StringBuffer();
      html.write('''<!DOCTYPE html>
<html dir="rtl" lang="ar">
<head>
<meta charset="UTF-8">
<style>
  @page { size: A4 landscape; margin: 1.2cm 1cm; }
  * { box-sizing: border-box; }
  body {
    font-family: "Times New Roman", "Arial", serif;
    direction: rtl;
    font-size: 12px;
    margin: 0;
    padding: 0;
    color: #000;
  }
  .page-wrap { padding: 6px 8px; }

  /* ── top header ── */
  .title-area {
    position: relative;
    text-align: center;
    margin-bottom: 4px;
    min-height: 42px;
  }
  .table-number {
    font-size: 17px;
    font-weight: bold;
    text-align: center;
    padding-top: 2px;
    margin: 0;
  }
  .ministry-info {
    position: absolute;
    top: 0;
    right: 0;
    text-align: right;
    line-height: 1.6;
    font-size: 12px;
  }
  .table-title  { text-align: center; font-size: 14px; font-weight: bold; margin: 2px 0; }
  .table-sub    { text-align: center; font-size: 12px; margin: 2px 0; }
  .supervisor-row {
    display: flex;
    justify-content: flex-start;
    gap: 40px;
    font-size: 12px;
    margin: 5px 0 4px 0;
    font-weight: bold;
  }

  /* ── stats bar ── */
  .stats-table {
    width: 100%;
    border-collapse: collapse;
    margin-bottom: 6px;
    font-size: 11.5px;
  }
  .stats-table td {
    border: 1px solid #000;
    padding: 3px 6px;
    text-align: center;
  }
  .stats-label { background-color: #cce0f5; font-weight: bold; }
  .stats-value { background-color: #ffffff; min-width: 30px; }

  /* ── main visits table ── */
  .visits-table {
    width: 100%;
    border-collapse: collapse;
    font-size: 11.5px;
  }
  .visits-table th, .visits-table td {
    border: 1px solid #000;
    padding: 3px 5px;
    text-align: center;
    vertical-align: middle;
  }
  .visits-table thead tr {
    background-color: #cce0f5;
    font-weight: bold;
    font-size: 12px;
  }
  .visits-table tbody tr:nth-child(even) { background-color: #f7fbff; }
  .col-num   { width: 28px; }
  .col-day   { width: 70px; }
  .col-date  { width: 90px; }
  .col-school{ width: auto; }
  .col-detail{ width: 160px; }
  .col-notes { width: 180px; }

  /* ── footer ── */
  .footer {
    display: flex;
    justify-content: space-between;
    margin-top: 18px;
    font-size: 12px;
  }
  .footer-block { line-height: 1.9; }
</style>
</head>
<body>
<div class="page-wrap">

  <!-- Title + ministry info (same vertical area) -->
  <div class="title-area">
    <div class="table-number">جدول رقم (1)</div>
    <div class="ministry-info">
      <div>المديرية العامة لتربية محافظة بابل</div>
      <div>قسم الإشراف الاختصاصي</div>
    </div>
  </div>

  <div class="table-title">جدول الأعمال الشهرية</div>
  <div class="table-sub">المتحقق من الأعمال لشهر ($monthName) للعام الدراسي ($acadStart - $acadEnd)</div>

  <div class="supervisor-row">
    <div>المشرف الاختصاصي: $supervisorName</div>
    <div>الاختصاص: $specialty</div>
  </div>

  <!-- Stats bar -->
  <table class="stats-table">
    <tr>
      <td class="stats-label">عدد مدارس الاختصاص التي بعهدته</td>
      <td class="stats-value">$specialtySchools</td>
      <td class="stats-label">عدد مدارس الصديق الناقد</td>
      <td class="stats-value">$criticalFriendSchools</td>
      <td class="stats-label">عدد مدارس التقييم الخارجي</td>
      <td class="stats-value">$externalEvalSchools</td>
      <td class="stats-label">عدد الزيارات المتحققة شهريا</td>
      <td class="stats-value">$monthlyActual</td>
      <td class="stats-label">عدد الزيارات التراكمية</td>
      <td class="stats-value">$cumulativeActual</td>
    </tr>
  </table>

  <!-- Visits table -->
  <table class="visits-table">
    <thead>
      <tr>
        <th class="col-num">ت</th>
        <th class="col-day">اليوم</th>
        <th class="col-date">التاريخ</th>
        <th class="col-school">اسم المدرسة</th>
        <th class="col-detail">تفاصيل الزيارة</th>
        <th class="col-notes">الملاحظات</th>
      </tr>
    </thead>
    <tbody>
''');

      for (int i = 0; i < allMonthVisits.length; i++) {
        final visit = allMonthVisits[i];
        final dayName = arabicDays[visit.date.weekday - 1];
        final dateStr = _isoDate(visit.date);
        final details = (visit.visitDetails?.trim().isEmpty ?? true) ? '' : visit.visitDetails!.trim();
        final notes = (visit.notes?.trim().isEmpty ?? true) ? '' : visit.notes!.trim();

        html.write('''      <tr>
        <td class="col-num">${i + 1}</td>
        <td class="col-day">$dayName</td>
        <td class="col-date">$dateStr</td>
        <td class="col-school">${visit.schoolName}</td>
        <td class="col-detail">$details</td>
        <td class="col-notes">$notes</td>
      </tr>
''');
      }

      html.write('''    </tbody>
  </table>

  <!-- Footer -->
  <div class="footer">
    <div class="footer-block" style="text-align:right;">
      <div>اسم المشرف: $supervisorName</div>
      <div>التاريخ: $exportDate</div>
    </div>
    <div class="footer-block">
      <div>مدير قسم الإشراف: $headName</div>
      <div>التاريخ: $exportDate</div>
    </div>
  </div>

</div>
</body>
</html>
''');

      // Save file
      Directory? directory = await getExternalStorageDirectory();
      if (directory != null) {
        final downloadsPath = directory.path
            .replaceAll('/Android/data/com.example.visit_log/files', '/Download');
        final downloadsDir = Directory(downloadsPath);
        if (await downloadsDir.exists()) {
          directory = downloadsDir;
        }
      }
      directory ??= await getApplicationDocumentsDirectory();

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'جدول_الاعمال_الشهرية_${arabicMonths[forMonth.month - 1]}_${forMonth.year}_$timestamp.html';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(html.toString(), encoding: utf8);
      return file.path;
    } catch (e) {
      throw Exception('خطأ في تصدير البيانات: $e');
    }
  }
}
