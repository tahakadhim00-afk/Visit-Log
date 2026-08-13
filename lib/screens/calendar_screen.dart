import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/visit.dart';
import '../widgets/day_tile.dart';
import '../services/backup_service.dart';
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

  /// Locates the share button so the iPad share popover can point at it.
  final GlobalKey _shareButtonKey = GlobalKey();

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

  /// Sends whatever month the calendar is showing. The tooltip names that
  /// month, since the icon alone cannot say which one is about to go out.
  Widget _buildShareButton() {
    return IconButton(
      key: _shareButtonKey,
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF00695C), Color(0xFF26A69A)],
          ),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
      ),
      tooltip: 'مشاركة ${arabicMonths[displayMonth.month - 1]}',
      onPressed: _shareCurrentMonth,
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
          // Under RTL the leading slot is the right-hand corner and actions is
          // the left one. The app-info sheet that used to sit on the right now
          // lives at the end of Settings.
          leading: _buildSettingsButton(),
          actions: [_buildShareButton()],
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
      _showErrorSnackBar('$e');
    }
  }

  /// Sends the month currently on screen, so choosing what to send is just a
  /// matter of navigating to it — no separate month picker needed.
  Future<void> _shareCurrentMonth() async {
    final monthName = arabicMonths[displayMonth.month - 1];
    try {
      final outcome = await BackupService.shareBackupJson(
        month: displayMonth,
        // Anchors the popover on iPad/macOS, where an unanchored sheet throws.
        sharePositionOrigin: _shareButtonOrigin(),
      );
      if (!mounted) return;
      // Success stays silent: the receiving app is already on screen saying so.
      if (outcome == ShareOutcome.dismissed) {
        _showErrorSnackBar('تم إلغاء مشاركة $monthName');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('$e');
    }
  }

  /// Global rect of the share button, or null if it has not been laid out.
  Rect? _shareButtonOrigin() {
    final box = _shareButtonKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
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
