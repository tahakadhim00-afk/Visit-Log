import 'package:hive/hive.dart';

class SettingsService {
  static Box get _box => Hive.box('settings');

  // ── export / import ───────────────────────────────────────────────────────

  static Map<String, dynamic> toMap() => {
        'notificationsEnabled': notificationsEnabled,
      };

  static Future<void> restoreFromMap(Map<String, dynamic> map) async {
    if (map['notificationsEnabled'] is bool) {
      await setNotificationsEnabled(map['notificationsEnabled'] as bool);
    }
  }

  static bool get notificationsEnabled =>
      _box.get('notificationsEnabled', defaultValue: true);

  static Future<void> setNotificationsEnabled(bool v) =>
      _box.put('notificationsEnabled', v);
}
