import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../services/hive_service.dart';

class ExportService {
  static const List<String> arabicMonths = [
    'كانون الثاني', 'شباط', 'آذار', 'نيسان', 'أيار', 'حزيران',
    'تموز', 'آب', 'أيلول', 'تشرين الأول', 'تشرين الثاني', 'كانون الأول'
  ];

  static const List<String> arabicDays = [
    'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'
  ];



  static String _formatArabicDate(DateTime date) {
    final dayName = arabicDays[date.weekday - 1];
    final monthName = arabicMonths[date.month - 1];
    return '$dayName ${date.day} $monthName ${date.year}';
  }


  // Export monthly visits as Word-compatible HTML file with Arabic support
  static Future<String> exportMonthlyVisits(DateTime forMonth) async {
    try {
      // Get visits data for the specific month
      final allVisits = HiveService.getVisitsByMonth(forMonth.year, forMonth.month);
      
      // Filter out Fridays (weekday 5 = Friday)
      final visits = allVisits.where((visit) => visit.date.weekday != DateTime.friday).toList();
      
      // Sort visits by date
      visits.sort((a, b) => a.date.compareTo(b.date));

      // Create HTML content with Arabic support and Word compatibility
      final StringBuffer htmlContent = StringBuffer();
      
      // HTML document with proper encoding and RTL support
      htmlContent.write('''
<!DOCTYPE html>
<html dir="rtl" lang="ar">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>تقرير زيارات المدارس</title>
    <style>
        body {
            font-family: Arial, 'Times New Roman', sans-serif;
            direction: rtl;
            text-align: right;
            margin: 20px;
            line-height: 1.6;
        }
        .header {
            text-align: center;
            margin-bottom: 30px;
        }
        .title {
            font-size: 24px;
            font-weight: bold;
            color: #333;
            margin-bottom: 10px;
        }
        .subtitle {
            font-size: 14px;
            color: #666;
            margin: 5px 0;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
            direction: rtl;
        }
        th, td {
            border: 1px solid #ddd;
            padding: 12px;
            text-align: right;
        }
        th {
            background-color: #f2f2f2;
            font-weight: bold;
            color: #333;
        }
        tr:nth-child(even) {
            background-color: #f9f9f9;
        }
        .number-cell {
            text-align: center;
            width: 50px;
        }
        .day-cell {
            width: 100px;
            text-align: center;
        }
        .date-cell {
            width: 120px;
            text-align: center;
        }
    </style>
</head>
<body>
    <div class="header">
        <div class="title">تقرير زيارات المدارس - ${arabicMonths[forMonth.month - 1]} ${forMonth.year}</div>
        <div class="subtitle">تاريخ التصدير: ${_formatArabicDate(DateTime.now())}</div>
        <div class="subtitle">إجمالي الزيارات: ${visits.length}</div>
    </div>
    
    <table>
        <thead>
            <tr>
                <th class="number-cell">ت</th>
                <th class="day-cell">اليوم</th>
                <th class="date-cell">التاريخ</th>
                <th>اسم المدرسة المزارة</th>
                <th>تفاصيل الزيارة</th>
                <th>الملاحظات</th>
            </tr>
        </thead>
        <tbody>
''');

      // Add data rows
      for (int i = 0; i < visits.length; i++) {
        final visit = visits[i];
        final dayName = arabicDays[visit.date.weekday - 1];
        final dateFormatted = '${visit.date.year}/${visit.date.month}/${visit.date.day}';
        final visitDetails = visit.visitDetails?.isEmpty ?? true 
            ? '-' 
            : visit.visitDetails!;
        final notes = visit.notes?.isEmpty ?? true ? '-' : visit.notes!;
        
        htmlContent.write('''
            <tr>
                <td class="number-cell">${i + 1}</td>
                <td class="day-cell">$dayName</td>
                <td class="date-cell">$dateFormatted</td>
                <td>${visit.schoolName}</td>
                <td>$visitDetails</td>
                <td>$notes</td>
            </tr>
''');
      }

      // Close HTML
      htmlContent.write('''
        </tbody>
    </table>
</body>
</html>
''');

      // Get external storage directory
      Directory? directory = await getExternalStorageDirectory();
      
      if (directory != null) {
        // Try to create a more accessible path
        final String downloadsPath = directory.path.replaceAll('/Android/data/com.example.visit_log/files', '/Download');
        Directory downloadsDir = Directory(downloadsPath);
        
        if (await downloadsDir.exists()) {
          directory = downloadsDir;
        }
      }
      
      // Fallback to app documents directory
      directory ??= await getApplicationDocumentsDirectory();

      // Create filename with timestamp to avoid conflicts
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'تقرير_زيارات_المدارس_${arabicMonths[forMonth.month - 1]}_${forMonth.year}_$timestamp.html';
      
      // Save the file with UTF-8 encoding
      final File file = File('${directory.path}/$fileName');
      await file.writeAsString(htmlContent.toString(), encoding: utf8);

      // Return the file path
      return file.path;

    } catch (e) {
      throw Exception('خطأ في تصدير البيانات: $e');
    }
  }
}