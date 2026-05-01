import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ThemeNotifier extends ValueNotifier<ThemeMode> {
  static const _boxName = 'settings';
  static const _key = 'isDarkMode';

  ThemeNotifier._() : super(ThemeMode.light) {
    final box = Hive.box(_boxName);
    final isDark = box.get(_key, defaultValue: false) as bool;
    value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  static final ThemeNotifier instance = ThemeNotifier._();

  bool get isDark => value == ThemeMode.dark;

  void toggleTheme() {
    final nowDark = !isDark;
    value = nowDark ? ThemeMode.dark : ThemeMode.light;
    Hive.box(_boxName).put(_key, nowDark);
  }
}
