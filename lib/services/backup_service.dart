import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/visit.dart';
import 'hive_service.dart';

class BackupService {

  static Future<String> exportDataToJson() async {
    try {
      // Get all visits from Hive
      final List<Visit> allVisits = HiveService.getAllVisits();
      
      // Convert visits to JSON-serializable format
      final List<Map<String, dynamic>> visitsJson = allVisits.map((visit) {
        return {
          'id': visit.id,
          'date': visit.date.toIso8601String(),
          'schoolName': visit.schoolName,
          'notes': visit.notes,
          'photoPath': visit.photoPath,
          'visitTime': visit.visitTime?.toIso8601String(),
          'visitDetails': visit.visitDetails,
        };
      }).toList();
      
      // Create backup data with metadata
      final Map<String, dynamic> backupData = {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'totalVisits': allVisits.length,
        'visits': visitsJson,
      };
      
      // Convert to JSON string
      final String jsonString = const JsonEncoder.withIndent('  ').convert(backupData);
      
      // Create filename with timestamp
      final String timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final String fileName = 'visit_log_backup_$timestamp.json';
      
      // Save directly to Downloads folder
      Directory? downloadsDir;
      
      // Try to get Downloads directory
      if (Platform.isAndroid) {
        // For Android, try different approaches to get Downloads folder
        try {
          // Try getting external storage directory first
          final Directory? externalDir = await getExternalStorageDirectory();
          if (externalDir != null) {
            // Navigate to Downloads folder
            const String downloadsPath = '/storage/emulated/0/Download';
            downloadsDir = Directory(downloadsPath);
            
            // If Downloads doesn't exist, use Documents or app directory
            if (!await downloadsDir.exists()) {
              downloadsDir = Directory('${externalDir.path}/Download');
              if (!await downloadsDir.exists()) {
                await downloadsDir.create(recursive: true);
              }
            }
          }
        } catch (e) {
          // Fallback to app external directory
          downloadsDir = await getExternalStorageDirectory();
        }
      } else {
        // For iOS, use documents directory
        downloadsDir = await getApplicationDocumentsDirectory();
      }
      
      if (downloadsDir == null) {
        throw Exception('لا يمكن الوصول لمجلد التحميل');
      }
      
      final String filePath = '${downloadsDir.path}/$fileName';
      final File backupFile = File(filePath);
      await backupFile.writeAsString(jsonString, encoding: utf8);
      
      return filePath;
    } catch (e) {
      throw Exception('خطأ في تصدير البيانات: ${e.toString()}');
    }
  }
  
  static Future<bool> importDataFromJson() async {
    try {
      // Use file picker to select JSON file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: 'اختر ملف النسخة الاحتياطية',
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );
      
      if (result == null || result.files.isEmpty) {
        return false; // User cancelled or no file selected
      }
      
      final PlatformFile file = result.files.first;
      
      String? jsonString;
      
      // Try to read file content directly from bytes if available
      if (file.bytes != null) {
        jsonString = utf8.decode(file.bytes!);
      } else if (file.path != null) {
        // Fallback: read from file path
        final File jsonFile = File(file.path!);
        if (!await jsonFile.exists()) {
          throw Exception('الملف المحدد غير موجود');
        }
        jsonString = await jsonFile.readAsString(encoding: utf8);
      } else {
        throw Exception('لا يمكن قراءة الملف المحدد');
      }
      
      // Parse JSON
      final Map<String, dynamic> backupData = json.decode(jsonString);
      
      // Validate backup structure
      if (!backupData.containsKey('visits') || !backupData.containsKey('version')) {
        throw Exception('تنسيق ملف النسخة الاحتياطية غير صحيح');
      }
      
      final List<dynamic> visitsJson = backupData['visits'];
      
      // Clear existing data (optional - you might want to merge instead)
      await _clearAllVisits();
      
      // Import visits
      int importedCount = 0;
      for (final dynamic visitData in visitsJson) {
        try {
          final Map<String, dynamic> visitMap = visitData as Map<String, dynamic>;
          
          // Create Visit object from JSON
          final Visit visit = Visit(
            id: visitMap['id'] as String,
            date: DateTime.parse(visitMap['date'] as String),
            schoolName: visitMap['schoolName'] as String,
            notes: visitMap['notes'] as String?,
            photoPath: visitMap['photoPath'] as String?,
            visitTime: visitMap['visitTime'] != null 
              ? DateTime.parse(visitMap['visitTime'] as String)
              : null,
            visitDetails: visitMap['visitDetails'] as String?,
          );
          
          // Add visit to Hive
          await HiveService.addVisit(visit);
          importedCount++;
        } catch (e) {
          // Skip invalid visits but continue with others
          continue;
        }
      }
      
      if (importedCount == 0) {
        throw Exception('لم يتم العثور على زيارات صحيحة في ملف النسخة الاحتياطية');
      }
      
      return true;
    } catch (e) {
      throw Exception('خطأ في استيراد البيانات: ${e.toString()}');
    }
  }
  
  static Future<void> _clearAllVisits() async {
    try {
      final List<Visit> allVisits = HiveService.getAllVisits();
      for (final Visit visit in allVisits) {
        await HiveService.deleteVisit(visit.id);
      }
    } catch (e) {
      throw Exception('خطأ في مسح البيانات الحالية: ${e.toString()}');
    }
  }
  
  static Future<Map<String, dynamic>> getBackupInfo() async {
    try {
      final List<Visit> allVisits = HiveService.getAllVisits();
      
      // Calculate statistics
      final Map<int, int> visitsByYear = {};
      final Map<String, int> visitsByMonth = {};
      
      for (final Visit visit in allVisits) {
        // Count by year
        visitsByYear[visit.date.year] = (visitsByYear[visit.date.year] ?? 0) + 1;
        
        // Count by month
        final String monthKey = '${visit.date.year}-${visit.date.month.toString().padLeft(2, '0')}';
        visitsByMonth[monthKey] = (visitsByMonth[monthKey] ?? 0) + 1;
      }
      
      return {
        'totalVisits': allVisits.length,
        'visitsByYear': visitsByYear,
        'visitsByMonth': visitsByMonth,
        'oldestVisit': allVisits.isNotEmpty 
          ? allVisits.map((v) => v.date).reduce((a, b) => a.isBefore(b) ? a : b).toIso8601String()
          : null,
        'newestVisit': allVisits.isNotEmpty
          ? allVisits.map((v) => v.date).reduce((a, b) => a.isAfter(b) ? a : b).toIso8601String()
          : null,
      };
    } catch (e) {
      throw Exception('خطأ في الحصول على معلومات النسخة الاحتياطية: ${e.toString()}');
    }
  }
}