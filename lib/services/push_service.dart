import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../firebase_options.dart';
import 'notification_service.dart';

/// Must be a top-level function: the background isolate has no access to the
/// app's state, so Firebase is re-initialised here before the payload is read.
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Android renders `notification`-type payloads itself while backgrounded,
  // so nothing further is needed here for the daily reminder.
}

/// Firebase Cloud Messaging: receives pushes sent from a server.
///
/// This is the receiving half only. Delivering the daily 12:00 reminder over
/// FCM additionally requires a server-side scheduler to call the FCM API;
/// [NotificationService] schedules the same reminder on-device with no server.
class PushService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static bool _initialized = false;
  static String? _token;

  /// The device's FCM registration token, or null if unavailable.
  /// A server targets this token (or a topic) to push to this device.
  static String? get token => _token;

  static Future<void> init() async {
    if (!Platform.isAndroid) return;
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

      // A foregrounded app receives the payload but Android does not display
      // it, so it is handed to the local plugin to show on the same channel.
      FirebaseMessaging.onMessage.listen(_showForegroundNotification);

      _initialized = true;
      await _refreshToken();
    } catch (_) {
      _initialized = false;
    }
  }

  /// Asks for POST_NOTIFICATIONS. Required on Android 13+ (API 33) before any
  /// notification — local or pushed — will be shown.
  static Future<bool> requestPermission() async {
    if (!_initialized) return false;
    try {
      final settings = await _messaging.requestPermission();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _refreshToken() async {
    try {
      _token = await _messaging.getToken();
      _messaging.onTokenRefresh.listen((t) => _token = t);
    } catch (_) {
      _token = null;
    }
  }

  /// Subscribing to a topic lets a server push to every install at once
  /// without tracking individual tokens.
  static Future<void> subscribeToReminders() async {
    if (!_initialized) return;
    try {
      await _messaging.subscribeToTopic('daily_reminder');
    } catch (_) {}
  }

  static Future<void> unsubscribeFromReminders() async {
    if (!_initialized) return;
    try {
      await _messaging.unsubscribeFromTopic('daily_reminder');
    } catch (_) {}
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await NotificationService.showNow(
      title: notification.title ?? 'سجل زياراتك',
      body: notification.body ?? '',
    );
  }
}
