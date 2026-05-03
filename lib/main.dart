import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/hive_service.dart';
import 'services/notification_service.dart';
import 'services/theme_service.dart';
import 'screens/calendar_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();
  await NotificationService.init();
  await NotificationService.scheduleWeeklyNotifications();
  runApp(const VisitLogApp());
}

class VisitLogApp extends StatelessWidget {
  const VisitLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeNotifier.instance,
      builder: (context, themeMode, _) {
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
          themeMode: themeMode,
          theme: ThemeData.light().copyWith(
            primaryColor: Colors.teal[600],
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.teal,
              brightness: Brightness.light,
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.teal[600],
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
              iconTheme: const IconThemeData(color: Colors.white),
              titleTextStyle: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            scaffoldBackgroundColor: Colors.grey[50],
            textTheme: GoogleFonts.cairoTextTheme(
              ThemeData.light().textTheme,
            ),
            primaryTextTheme: GoogleFonts.cairoTextTheme(
              ThemeData.light().primaryTextTheme,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),
          darkTheme: ThemeData.dark().copyWith(
            primaryColor: Colors.teal[400],
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.teal,
              brightness: Brightness.dark,
              surface: const Color(0xFF1A1A1A),
              surfaceContainerHighest: const Color(0xFF1A1A1A),
              onSurface: Colors.white,
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
              iconTheme: const IconThemeData(color: Colors.white),
              titleTextStyle: GoogleFonts.cairo(
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
            textTheme: GoogleFonts.cairoTextTheme(
              ThemeData.dark().textTheme,
            ),
            primaryTextTheme: GoogleFonts.cairoTextTheme(
              ThemeData.dark().primaryTextTheme,
            ),
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
      },
    );
  }
}
