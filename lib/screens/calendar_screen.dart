import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/visit.dart';
import '../widgets/day_tile.dart';
import '../services/export_service.dart';
import '../services/hive_service.dart';
import 'settings_page.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime currentDate = DateTime.now();
  late DateTime displayMonth;

  final List<String> arabicMonths = [
    'كانون الثاني', 'شباط', 'آذار', 'نيسان', 'أيار', 'حزيران',
    'تموز', 'آب', 'أيلول', 'تشرين الأول', 'تشرين الثاني', 'كانون الأول',
  ];

  final List<String> arabicDays = [
    'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت',
  ];

  /// Non-Friday days of [displayMonth], and that month's visits keyed by day.
  /// Both are recomputed only when the month changes or data is edited.
  List<DateTime> _monthDays = const [];
  Map<DateTime, List<Visit>> _visitsByDay = const {};

  @override
  void initState() {
    super.initState();
    displayMonth = DateTime(currentDate.year, currentDate.month, 1);
    _loadMonth();
  }

  void _loadMonth() {
    final lastDayOfMonth =
        DateTime(displayMonth.year, displayMonth.month + 1, 0);

    final days = <DateTime>[];
    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      final date = DateTime(displayMonth.year, displayMonth.month, day);
      if (date.weekday != DateTime.friday) {
        days.add(date);
      }
    }

    _monthDays = days;
    _visitsByDay = HiveService.getVisitsByMonthGroupedByDay(
        displayMonth.year, displayMonth.month);
  }

  void _showAppInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: Directionality(
              textDirection: ui.TextDirection.rtl,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.assignment_outlined, color: Colors.teal, size: 36),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'سجل زيارات المشرف',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'تطبيق متخصص للمشرفين التربويين لتسجيل ومتابعة\n'
                    'زياراتهم الميدانية للمدارس، وإدارة بياناتهم\n'
                    'الإشرافية بكل سهولة ويسر.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.7,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Divider(color: Colors.grey.withValues(alpha: 0.3)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.code, color: Colors.teal, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'تم التطوير بواسطة  Taha Kadhim',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'النسخة 2.0.0',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildSettingsButton() {
    return IconButton(
      icon: const Icon(Icons.settings_outlined, color: Colors.white),
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettingsPage()),
        );
        // A backup import can replace every visit, so refresh on return.
        if (!mounted) return;
        setState(_loadMonth);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('سجل الزيـــارات'),
          automaticallyImplyLeading: false,
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: _showAppInfo,
          ),
          actions: [_buildSettingsButton()],
        ),
        body: Builder(builder: (context) {
          return Column(
            children: [
              _buildMonthNavigation(),
              Expanded(child: _buildCalendarGrid()),
              _buildExportSection(),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildMonthNavigation() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavButton(icon: Icons.chevron_left, onPressed: _goToPreviousMonth),
          Expanded(
            child: Text(
              '${arabicMonths[displayMonth.month - 1]} ${displayMonth.year}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          _buildNavButton(icon: Icons.chevron_right, onPressed: _goToNextMonth),
        ],
      ),
    );
  }

  Widget _buildNavButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.teal[900]!.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.teal[700]!,
          width: 1,
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 24),
        style: IconButton.styleFrom(
          foregroundColor: Colors.teal[700]!,
          padding: const EdgeInsets.all(12),
        ),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      // The grid scrolls itself; wrapping it in a SingleChildScrollView with
      // shrinkWrap would build every tile up front and defeat viewport culling.
      child: GridView.builder(
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _monthDays.length,
        itemBuilder: (context, index) {
          final date = _monthDays[index];
          return DayTile(
            // Keyed by date so month changes rebind rather than reusing
            // a previous day's State.
            key: ValueKey(date),
            date: date,
            isCurrentMonth: true,
            visits: _visitsByDay[date] ?? const [],
            onVisitChanged: _onVisitChanged,
          );
        },
      ),
    );
  }

  void _goToPreviousMonth() {
    setState(() {
      displayMonth = DateTime(displayMonth.year, displayMonth.month - 1, 1);
      _loadMonth();
    });
  }

  void _goToNextMonth() {
    setState(() {
      displayMonth = DateTime(displayMonth.year, displayMonth.month + 1, 1);
      _loadMonth();
    });
  }

  void _onVisitChanged() => setState(_loadMonth);

  Widget _buildExportSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _buildExportButton(
        title: 'تصدير التقرير',
        icon: Icons.description,
        onPressed: _exportCurrentMonth,
      ),
    );
  }

  Widget _buildExportButton({
    required String title,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.teal[900]!.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.teal[700]!, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.teal[700]!, size: 24),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportCurrentMonth() async {
    try {
      _showLoadingSnackBar('جاري تصدير تقرير ${arabicMonths[displayMonth.month - 1]}...');
      final filePath = await ExportService.exportMonthlyVisits(displayMonth);
      if (!mounted) return;
      _showSuccessSnackBar('تم حفظ التقرير بنجاح في: $filePath');
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('فشل في تصدير البيانات: ${e.toString()}');
    }
  }

  void _showLoadingSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.teal[600]!,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green[600]!,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[600]!,
        duration: const Duration(seconds: 5),
      ),
    );
  }
}
