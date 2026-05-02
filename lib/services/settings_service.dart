import 'package:hive/hive.dart';

class SettingsService {
  static Box get _box => Hive.box('settings');

  // ── export / import ───────────────────────────────────────────────────────

  static Map<String, dynamic> toMap() => {
        'supervisorName': supervisorName,
        'specialty': specialty,
        'supervisionHeadName': supervisionHeadName,
        'specialtySchoolsCount': specialtySchoolsCount,
        'criticalFriendSchoolsCount': criticalFriendSchoolsCount,
        'externalEvalSchoolsCount': externalEvalSchoolsCount,
        'isDarkMode': _box.get('isDarkMode', defaultValue: false),
      };

  static Future<void> restoreFromMap(Map<String, dynamic> map) async {
    if (map['supervisorName'] is String) {
      await setSupervisorName(map['supervisorName'] as String);
    }
    if (map['specialty'] is String) {
      await setSpecialty(map['specialty'] as String);
    }
    if (map['supervisionHeadName'] is String) {
      await setSupervisionHeadName(map['supervisionHeadName'] as String);
    }
    if (map['specialtySchoolsCount'] is int) {
      await setSpecialtySchoolsCount(map['specialtySchoolsCount'] as int);
    }
    if (map['criticalFriendSchoolsCount'] is int) {
      await setCriticalFriendSchoolsCount(
          map['criticalFriendSchoolsCount'] as int);
    }
    if (map['externalEvalSchoolsCount'] is int) {
      await setExternalEvalSchoolsCount(
          map['externalEvalSchoolsCount'] as int);
    }
    if (map['isDarkMode'] is bool) {
      await _box.put('isDarkMode', map['isDarkMode'] as bool);
    }
  }

  static String get supervisorName => _box.get('supervisorName', defaultValue: '');
  static String get specialty => _box.get('specialty', defaultValue: '');
  static String get supervisionHeadName => _box.get('supervisionHeadName', defaultValue: '');
  static int get specialtySchoolsCount => _box.get('specialtySchoolsCount', defaultValue: 0);
  static int get criticalFriendSchoolsCount => _box.get('criticalFriendSchoolsCount', defaultValue: 0);
  static int get externalEvalSchoolsCount => _box.get('externalEvalSchoolsCount', defaultValue: 0);
  static String? get profilePhotoPath => _box.get('profilePhotoPath');
  static bool get notificationsEnabled =>
      _box.get('notificationsEnabled', defaultValue: true);

  static Future<void> setSupervisorName(String v) => _box.put('supervisorName', v);
  static Future<void> setSpecialty(String v) => _box.put('specialty', v);
  static Future<void> setSupervisionHeadName(String v) => _box.put('supervisionHeadName', v);
  static Future<void> setSpecialtySchoolsCount(int v) => _box.put('specialtySchoolsCount', v);
  static Future<void> setCriticalFriendSchoolsCount(int v) => _box.put('criticalFriendSchoolsCount', v);
  static Future<void> setExternalEvalSchoolsCount(int v) => _box.put('externalEvalSchoolsCount', v);
  static Future<void> setProfilePhotoPath(String v) => _box.put('profilePhotoPath', v);
  static Future<void> setNotificationsEnabled(bool v) =>
      _box.put('notificationsEnabled', v);
}
