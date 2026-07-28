import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/hive_service.dart';
import 'services/notification_service.dart';
import 'services/settings_service.dart';
import 'screens/calendar_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // A corrupt box (interrupted write, full disk) would otherwise throw before
  // runApp and leave the user on a black screen with no way back.
  Object? storageError;
  try {
    await HiveService.init();
  } catch (e) {
    storageError = e;
  }

  if (storageError != null) {
    runApp(StorageFailureApp(error: storageError));
    return;
  }

  await NotificationService.init();

  try {
    // Reminders default to on, but Android 13+ silently drops every
    // notification until POST_NOTIFICATIONS is granted — so ask up front
    // rather than only when the settings switch is toggled.
    if (SettingsService.notificationsEnabled) {
      await NotificationService.requestPermission();
    }
    await NotificationService.scheduleWeeklyNotifications();
  } catch (_) {}

  runApp(const VisitLogApp());
}

/// Shown when local storage cannot be opened, so the failure is visible and
/// actionable instead of a silent black screen.
class StorageFailureApp extends StatelessWidget {
  const StorageFailureApp({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                  const SizedBox(height: 20),
                  const Text(
                    'تعذّر فتح بيانات التطبيق',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'قد تكون مساحة التخزين ممتلئة أو الملفات تالفة.\n'
                    'حاول إعادة تشغيل التطبيق، وإن استمرت المشكلة '
                    'أعد تثبيته مع الاحتفاظ بنسخة احتياطية.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.7,
                      color: Colors.grey[400],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '$error',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
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
