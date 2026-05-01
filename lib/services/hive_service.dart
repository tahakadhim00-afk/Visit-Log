import 'package:hive_flutter/hive_flutter.dart';
import '../models/visit.dart';

class HiveService {
  static const String _visitBoxName = 'visits';
  static Box<Visit>? _visitBox;

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(VisitAdapter());
    _visitBox = await Hive.openBox<Visit>(_visitBoxName);
    await Hive.openBox('settings');
  }

  static Box<Visit> get visitBox {
    if (_visitBox == null || !_visitBox!.isOpen) {
      throw Exception('Visit box is not initialized');
    }
    return _visitBox!;
  }

  static Future<void> addVisit(Visit visit) async {
    await visitBox.put(visit.id, visit);
  }

  static Future<void> updateVisit(Visit visit) async {
    await visitBox.put(visit.id, visit);
  }

  static Future<void> deleteVisit(String visitId) async {
    await visitBox.delete(visitId);
  }

  static Visit? getVisit(String visitId) {
    return visitBox.get(visitId);
  }

  static Visit? getVisitByDate(DateTime date) {
    for (Visit visit in visitBox.values) {
      if (visit.date.year == date.year && 
          visit.date.month == date.month && 
          visit.date.day == date.day) {
        return visit;
      }
    }
    return null;
  }

  static List<Visit> getVisitsByDate(DateTime date) {
    return visitBox.values.where((visit) {
      return visit.date.year == date.year && 
             visit.date.month == date.month && 
             visit.date.day == date.day;
    }).toList();
  }

  static List<Visit> getAllVisits() {
    return visitBox.values.toList();
  }

  static List<Visit> getVisitsByMonth(int year, int month) {
    return visitBox.values.where((visit) {
      return visit.date.year == year && visit.date.month == month;
    }).toList();
  }


  static String generateVisitId(DateTime date) {
    return 'visit_${date.year}_${date.month}_${date.day}_${DateTime.now().millisecondsSinceEpoch}';
  }

  static Future<void> dispose() async {
    await _visitBox?.close();
  }
}