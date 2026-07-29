import 'package:hive/hive.dart';

class SettingsService {
  static Box get _box => Hive.box('settings');

  // ── export / import ───────────────────────────────────────────────────────

  static Map<String, dynamic> toMap() => {
        'notificationsEnabled': notificationsEnabled,
        'supervisorName': supervisorName,
        'specialization': specialization,
        'supervisionHeadName': supervisionHeadName,
      };

  static Future<void> restoreFromMap(Map<String, dynamic> map) async {
    if (map['notificationsEnabled'] is bool) {
      await setNotificationsEnabled(map['notificationsEnabled'] as bool);
    }
    if (map['supervisorName'] is String) {
      await setSupervisorName(map['supervisorName'] as String);
    }
    if (map['specialization'] is String) {
      await setSpecialization(map['specialization'] as String);
    }
    if (map['supervisionHeadName'] is String) {
      await setSupervisionHeadName(map['supervisionHeadName'] as String);
    }
  }

  static bool get notificationsEnabled =>
      _box.get('notificationsEnabled', defaultValue: true);

  static Future<void> setNotificationsEnabled(bool v) =>
      _box.put('notificationsEnabled', v);

  // ── report header / footer ────────────────────────────────────────────────
  // Printed on the exported monthly report; blank means the line is left
  // empty for hand-writing.

  static String get supervisorName =>
      _box.get('supervisorName', defaultValue: '');

  static Future<void> setSupervisorName(String v) =>
      _box.put('supervisorName', v.trim());

  static String get specialization =>
      _box.get('specialization', defaultValue: '');

  static Future<void> setSpecialization(String v) =>
      _box.put('specialization', v.trim());

  static String get supervisionHeadName =>
      _box.get('supervisionHeadName', defaultValue: '');

  static Future<void> setSupervisionHeadName(String v) =>
      _box.put('supervisionHeadName', v.trim());
}
