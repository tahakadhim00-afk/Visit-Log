import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
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

  static Future<pw.Font> _loadCairoFont({required bool bold}) async {
    final asset = bold
        ? 'lib/assets/fonts/Cairo-Bold.ttf'
        : 'lib/assets/fonts/Cairo-Regular.ttf';
    final data = await rootBundle.load(asset);
    return pw.Font.ttf(data);
  }

  static String _twoDigit(int n) => n.toString().padLeft(2, '0');

  static String _isoDate(DateTime date) =>
      '${date.year}-${_twoDigit(date.month)}-${_twoDigit(date.day)}';

  static String _footerDate(DateTime date) =>
      '${_twoDigit(date.day)}/${_twoDigit(date.month)}/${date.year}';

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

      final supervisorName = SettingsService.supervisorName;
      final specialty = SettingsService.specialty;
      final headName = SettingsService.supervisionHeadName;
      final specialtySchools = SettingsService.specialtySchoolsCount;
      final criticalFriendSchools = SettingsService.criticalFriendSchoolsCount;
      final externalEvalSchools = SettingsService.externalEvalSchoolsCount;

      final monthName = arabicMonths[forMonth.month - 1];
      final exportDate = _footerDate(DateTime.now());

      final font     = await _loadCairoFont(bold: false);
      final fontBold = await _loadCairoFont(bold: true);

      const headerBg = PdfColor(0.800, 0.878, 0.961); // #cce0f5
      const evenRowBg = PdfColor(0.969, 0.984, 1.0);  // #f7fbff

      final base     = pw.TextStyle(font: font,     fontSize: 10);
      final bold     = pw.TextStyle(font: fontBold, fontSize: 10);
      final bigBold  = pw.TextStyle(font: fontBold, fontSize: 17);
      final title    = pw.TextStyle(font: fontBold, fontSize: 14);
      final sub      = pw.TextStyle(font: font,     fontSize: 11);
      final smallBold = pw.TextStyle(font: fontBold, fontSize: 9);

      pw.Widget txt(String text, pw.TextStyle style,
              {pw.TextAlign align = pw.TextAlign.right}) =>
          pw.Text(text,
              style: style,
              textDirection: pw.TextDirection.rtl,
              textAlign: align);

      pw.Widget cell(String text,
              {bool header = false,
              PdfColor? bg,
              pw.TextAlign align = pw.TextAlign.center}) =>
          pw.Container(
            color: bg,
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            child: txt(text, header ? bold : base, align: align),
          );

      pw.Widget statsCell(String text, {bool isLabel = false}) =>
          pw.Container(
            color: isLabel ? headerBg : PdfColors.white,
            padding: const pw.EdgeInsets.all(3),
            child: txt(text, isLabel ? smallBold : base,
                align: pw.TextAlign.center),
          );

      // Build visits table rows
      // Children are reversed (leftmost in list = rightmost on page) because
      // pw.Table renders LTR regardless of MultiPage textDirection.
      final visitRows = <pw.TableRow>[
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: headerBg),
          children: [
            cell('الملاحظات',      header: true),
            cell('تفاصيل الزيارة', header: true),
            cell('اسم المدرسة',    header: true),
            cell('التاريخ',        header: true),
            cell('اليوم',          header: true),
            cell('ت',              header: true),
          ],
        ),
        ...List.generate(allMonthVisits.length, (i) {
          final visit = allMonthVisits[i];
          final dayName = arabicDays[visit.date.weekday - 1];
          final dateStr = _isoDate(visit.date);
          final details = visit.visitDetails?.trim() ?? '';
          final notes   = visit.notes?.trim() ?? '';
          final bg = i.isEven ? PdfColors.white : evenRowBg;
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: bg),
            children: [
              cell(notes,            align: pw.TextAlign.right),
              cell(details,          align: pw.TextAlign.right),
              cell(visit.schoolName, align: pw.TextAlign.right),
              cell(dateStr),
              cell(dayName),
              cell('${i + 1}'),
            ],
          );
        }),
      ];

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(0.9 * PdfPageFormat.cm),
          textDirection: pw.TextDirection.rtl,
          build: (context) => [
            // ── Top header ──
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        txt('المديرية العامة لتربية محافظة بابل', sub),
                        txt('قسم الإشراف الاختصاصي', sub),
                      ],
                    ),
                  ),
                ),
                pw.Expanded(
                  child: pw.Center(
                    child: txt('جدول رقم (1)', bigBold,
                        align: pw.TextAlign.center),
                  ),
                ),
                pw.Expanded(child: pw.SizedBox()),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Center(
                child: txt('جدول الأعمال الشهرية', title,
                    align: pw.TextAlign.center)),
            pw.SizedBox(height: 2),
            pw.Center(
                child: txt(
                    'المتحقق من الأعمال لشهر ($monthName) للعام الدراسي ($acadStart - $acadEnd)',
                    sub,
                    align: pw.TextAlign.center)),
            pw.SizedBox(height: 5),

            // ── Supervisor row ──
            pw.Row(
              children: [
                txt('المشرف الاختصاصي: $supervisorName', bold),
                pw.SizedBox(width: 40),
                txt('الاختصاص: $specialty', bold),
              ],
            ),
            pw.SizedBox(height: 5),

            // ── Stats table (reversed for RTL rendering) ──
            pw.Table(
              border: pw.TableBorder.all(width: 0.5),
              children: [
                pw.TableRow(children: [
                  statsCell('$cumulativeActual'),
                  statsCell('عدد الزيارات التراكمية', isLabel: true),
                  statsCell('$monthlyActual'),
                  statsCell('عدد الزيارات المتحققة شهريا', isLabel: true),
                  statsCell('$externalEvalSchools'),
                  statsCell('عدد مدارس التقييم الخارجي', isLabel: true),
                  statsCell('$criticalFriendSchools'),
                  statsCell('عدد مدارس الصديق الناقد', isLabel: true),
                  statsCell('$specialtySchools'),
                  statsCell('عدد مدارس الاختصاص التي بعهدته', isLabel: true),
                ]),
              ],
            ),
            pw.SizedBox(height: 6),

            // ── Visits table ──
            pw.Table(
              border: pw.TableBorder.all(width: 0.5),
              columnWidths: const {
                0: pw.FixedColumnWidth(145), // الملاحظات     (leftmost in LTR = rightmost visual RTL)
                1: pw.FixedColumnWidth(130), // تفاصيل الزيارة
                2: pw.FlexColumnWidth(),     // اسم المدرسة
                3: pw.FixedColumnWidth(75),  // التاريخ
                4: pw.FixedColumnWidth(60),  // اليوم
                5: pw.FixedColumnWidth(25),  // ت              (rightmost in LTR = leftmost visual RTL)
              },
              children: visitRows,
            ),
            pw.SizedBox(height: 16),

            // ── Footer ──
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    txt('اسم المشرف: $supervisorName', base),
                    txt('التاريخ: $exportDate', base),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    txt('مدير قسم الإشراف: $headName', base),
                    txt('التاريخ: $exportDate', base),
                  ],
                ),
              ],
            ),
          ],
        ),
      );

      // ── Save to Downloads ──
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
      final fileName =
          'جدول_الاعمال_الشهرية_${arabicMonths[forMonth.month - 1]}_${forMonth.year}_$timestamp.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(await pdf.save());
      return file.path;
    } catch (e) {
      throw Exception('خطأ في تصدير البيانات: $e');
    }
  }
}
