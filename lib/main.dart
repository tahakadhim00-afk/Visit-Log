import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/hive_service.dart';
import 'services/notification_service.dart';
import 'services/push_service.dart';
import 'services/settings_service.dart';
import 'screens/calendar_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();
  await NotificationService.init();
  await PushService.init();

  try {
    // Reminders default to on, but Android 13+ silently drops every
    // notification until POST_NOTIFICATIONS is granted — so ask up front
    // rather than only when the settings switch is toggled.
    if (SettingsService.notificationsEnabled) {
      await PushService.requestPermission();
      await PushService.subscribeToReminders();
    }
    await NotificationService.scheduleWeeklyNotifications();
  } catch (_) {}

  runApp(const VisitLogApp());
}

class VisitLogApp extends StatelessWidget {
  const VisitLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'سجل زيارات ',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar', 'SA'),
      supportedLocales: const [
        Locale('ar', 'SA'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark().copyWith(
        // Bundled ThmanyahSans; see the fonts: section in pubspec.yaml.
        textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'ThmanyahSans'),
        primaryTextTheme:
            ThemeData.dark().primaryTextTheme.apply(fontFamily: 'ThmanyahSans'),
        primaryColor: Colors.teal[400],
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
          surface: const Color(0xFF1A1A1A),
          surfaceContainerHighest: const Color(0xFF1A1A1A),
          onSurface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            fontFamily: 'ThmanyahSans',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        scaffoldBackgroundColor: Colors.black,
        cardColor: const Color(0xFF1A1A1A),
        drawerTheme: const DrawerThemeData(
          backgroundColor: Color(0xFF1A1A1A),
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: Color(0xFF1A1A1A),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Color(0xFF1A1A1A),
        ),
        dividerColor: const Color(0xFF2A2A2A),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal[400],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ),
      home: const CalendarScreen(),
    );
  }
}
