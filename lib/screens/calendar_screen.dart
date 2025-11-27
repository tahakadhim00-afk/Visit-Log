import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../widgets/day_tile.dart';
import '../services/export_service.dart';
import 'settings_page.dart';
import 'feedback_page.dart';

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
    'تموز', 'آب', 'أيلول', 'تشرين الأول', 'تشرين الثاني', 'كانون الأول'
  ];

  final List<String> arabicDays = [
    'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'
  ];

  @override
  void initState() {
    super.initState();
    displayMonth = DateTime(currentDate.year, currentDate.month, 1);
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue,
                  Colors.blueAccent,
                ],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 48,
                    color: Colors.white,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'سجل الزيارات',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.blue),
            title: const Text(
              'الإعدادات',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.feedback, color: Colors.purple),
            title: const Text(
              'إرسال ملاحظات',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FeedbackPage(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.orange),
            title: const Text(
              'معلومات التطبيق',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              _showDeveloperInfo(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
      appBar: AppBar(
        title: const Text('سجل الزيارات'),
      ),
      drawer: _buildDrawer(),
      body: Column(
        children: [
          _buildMonthNavigation(),
          Expanded(child: _buildCalendarGrid()),
          _buildExportSection(),
        ],
      ),
    ));
  }

  Widget _buildMonthNavigation() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavButton(
            icon: Icons.chevron_left,
            onPressed: _goToPreviousMonth,
          ),
          Expanded(
            child: Text(
              '${arabicMonths[displayMonth.month - 1]} ${displayMonth.year}',
              
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          _buildNavButton(
            icon: Icons.chevron_right,
            onPressed: _goToNextMonth,
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue[50]!,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.blue[300]!,
          width: 1,
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 24),
        style: IconButton.styleFrom(
          foregroundColor: Colors.blue[700]!,
          padding: const EdgeInsets.all(12),
        ),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final lastDayOfMonth = DateTime(displayMonth.year, displayMonth.month + 1, 0);
    
    // Create list of all days in the month
    List<DateTime> monthDays = [];
    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      monthDays.add(DateTime(displayMonth.year, displayMonth.month, day));
    }

    return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // 3 columns layout
              childAspectRatio: 0.75, // Better aspect ratio for content
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: monthDays.length,
            itemBuilder: (context, index) {
              final date = monthDays[index];
              
              return DayTile(
                date: date,
                isCurrentMonth: true,
                onVisitChanged: _onVisitChanged,
              );
            },
          ),
        ),
    );
  }

  void _goToPreviousMonth() {
    setState(() {
      displayMonth = DateTime(displayMonth.year, displayMonth.month - 1, 1);
    });
  }

  void _goToNextMonth() {
    setState(() {
      displayMonth = DateTime(displayMonth.year, displayMonth.month + 1, 1);
    });
  }

  void _onVisitChanged() {
    setState(() {
      // Refresh the calendar when a visit is added/updated/deleted
    });
  }

  void _showDeveloperInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'معلومات التطبيق',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'تطبيق سجل الزيارات',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'تم تطوير هذا التطبيق خصيصًا للمشرفين التربويين، ليساعدهم على تسجيل زياراتهم وأنشطتهم بسهولة ومرونة، مع إمكانية تصدير سجل كامل للزيارات الشهرية بشكل منظم وجاهز للطباعة.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Developer: Taha Kadhim',
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue[700]!,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Version: 1.0',
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue[700]!,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'موافق',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildExportSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _buildExportButton(
        title: 'تصدير التقرير',
        icon: Icons.description,
        onPressed: () => _exportCurrentMonth(),
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
          color: Colors.blue[50]!,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Colors.blue[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.blue[700]!,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              
              style: const TextStyle(
                color: Colors.black87,
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
      _showSuccessSnackBar('تم حفظ التقرير بنجاح في: $filePath');
    } catch (e) {
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
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
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
        backgroundColor: Colors.blue[600]!,
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