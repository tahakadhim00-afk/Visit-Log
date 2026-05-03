import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'settings_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'visit_reminder';
  static const _channelName = 'تذكير الزيارات';
  static const _channelDesc = 'تذكير يومي بتسجيل الزيارات';

  static const List<int> _activeDays = [
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.saturday,
    DateTime.sunday,
  ];

  static bool _initialized = false;

  static Future<void> init() async {
    if (!Platform.isAndroid) return;
    try {
      tz.initializeTimeZones();
      try {
        final timeZoneName = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(timeZoneName));
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('UTC'));
      }

      const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
      const settings = InitializationSettings(android: androidInit);
      await _plugin.initialize(settings);
      _initialized = true;
    } catch (_) {
      _initialized = false;
    }
  }

  static Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestNotificationsPermission() ?? false;
  }

  static Future<void> scheduleWeeklyNotifications() async {
    if (!_initialized) return;
    await _plugin.cancelAll();

    if (!SettingsService.notificationsEnabled) return;

    final name = SettingsService.supervisorName;
    final nameStr = name.isNotEmpty ? name : 'المشرف';
    final body = 'مساء الخير $nameStr، تفضل وسجّل زياراتك لهذا اليوم.';
    const title = 'سجل زياراتك';

    for (final day in _activeDays) {
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(body),
        ),
      );

      final scheduled = _nextOccurrence(day, 12, 0);
      await _plugin.zonedSchedule(
        day,
        title,
        body,
        scheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  static tz.TZDateTime _nextOccurrence(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var dt = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    while (dt.weekday != weekday || !dt.isAfter(now)) {
      dt = dt.add(const Duration(days: 1));
    }
    return dt;
  }

  static Future<void> cancelAll() async {
    if (!_initialized) return;
    await _plugin.cancelAll();
  }
}
