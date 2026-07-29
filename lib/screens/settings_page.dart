import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../services/backup_service.dart';
import '../services/notification_service.dart';
import '../services/settings_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isLoading = false;
  bool _notificationsEnabled = SettingsService.notificationsEnabled;

  final _supervisorController =
      TextEditingController(text: SettingsService.supervisorName);
  final _specializationController =
      TextEditingController(text: SettingsService.specialization);
  final _headController =
      TextEditingController(text: SettingsService.supervisionHeadName);

  @override
  void dispose() {
    _supervisorController.dispose();
    _specializationController.dispose();
    _headController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الإعـــدادات'),
          backgroundColor: Colors.black,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 16, right: 16, bottom: 16,
            top: MediaQuery.of(context).padding.top + kToolbarHeight + 8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('الإشعارات'),
              const SizedBox(height: 16),
              _buildNotificationCard(),
              const SizedBox(height: 24),
              _buildSectionTitle('بيانات التقرير'),
              const SizedBox(height: 16),
              _buildReportInfoCard(),
              const SizedBox(height: 24),
              _buildSectionTitle('نسخ احتياطي'),
              const SizedBox(height: 16),
              _buildBackupCard(),
              const SizedBox(height: 24),
              if (_isLoading) const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _blurCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: child,
    );
  }

  Widget _buildNotificationCard() {
    return _blurCard(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.teal.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _notificationsEnabled
                ? Icons.notifications_active
                : Icons.notifications_off,
            color: Colors.teal,
            size: 24,
          ),
        ),
        title: const Text('تذكير يومي',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        subtitle: Text(
          _notificationsEnabled
              ? 'مفعّل — كل يوم الساعة 12:00 مساءً (عدا الجمعة)'
              : 'معطّل',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        trailing: Switch(
          value: _notificationsEnabled,
          activeThumbColor: Colors.teal,
          onChanged: _toggleNotifications,
        ),
      ),
    );
  }

  Future<void> _toggleNotifications(bool value) async {
    if (value) {
      final granted = await NotificationService.requestPermission();
      if (!granted) {
        if (mounted) {
          _showErrorDialog('لم يتم منح الإذن',
              'يرجى السماح بالإشعارات من إعدادات الهاتف لتفعيل هذه الميزة.');
        }
        return;
      }
    }
    await SettingsService.setNotificationsEnabled(value);
    if (!mounted) return;
    setState(() => _notificationsEnabled = value);

    // Re-schedules when enabling, and cancels everything when disabling.
    await NotificationService.scheduleWeeklyNotifications();
  }

  Widget _buildReportInfoCard() {
    return _blurCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'تظهر هذه البيانات في ترويسة وتذييل جدول الأعمال الشهرية المصدَّر.',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            _buildReportField(
              controller: _supervisorController,
              label: 'المشرف الاختصاصي',
              onChanged: SettingsService.setSupervisorName,
            ),
            const SizedBox(height: 12),
            _buildReportField(
              controller: _specializationController,
              label: 'الاختصاص',
              onChanged: SettingsService.setSpecialization,
            ),
            const SizedBox(height: 12),
            _buildReportField(
              controller: _headController,
              label: 'مدير قسم الإشراف',
              onChanged: SettingsService.setSupervisionHeadName,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportField({
    required TextEditingController controller,
    required String label,
    required Future<void> Function(String) onChanged,
  }) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
      onChanged: (value) => onChanged(value),
    );
  }

  Widget _buildBackupCard() {
    return _blurCard(
      child: Column(
        children: [
          _buildBackupOption(
            icon: Icons.upload,
            title: 'تصدير البيانات',
            subtitle: 'حفظ ملف JSON في مجلد التحميل',
            color: Colors.green,
            onTap: _exportData,
          ),
          const Divider(height: 1),
          _buildBackupOption(
            icon: Icons.download,
            title: 'استيراد البيانات',
            subtitle: 'اختر ملف JSON لاستيراد البيانات',
            color: Colors.orange,
            onTap: _importData,
          ),
        ],
      ),
    );
  }

  Widget _buildBackupOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
      onTap: _isLoading ? null : onTap,
    );
  }

  Future<void> _exportData() async {
    setState(() => _isLoading = true);
    try {
      final filePath = await BackupService.exportDataToJson();
      if (mounted) {
        _showSuccessDialog('تم التصدير بنجاح', 'تم حفظ البيانات في:\n$filePath');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('خطأ في التصدير', '$e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _importData() async {
    final confirmed = await _showConfirmationDialog(
      'استيراد البيانات',
      'هل تريد استيراد البيانات؟ سيتم استبدال البيانات الحالية.\n\nسيتم فتح متصفح الملفات لاختيار ملف النسخة الاحتياطية.',
    );
    if (!confirmed) return;

    setState(() => _isLoading = true);
    try {
      final result = await BackupService.importDataFromJson();
      if (mounted) {
        if (result.cancelled) {
          _showErrorDialog('لم يتم الاستيراد', 'لم يتم اختيار ملف أو تم إلغاء العملية.');
        } else if (result.hasLoss) {
          // The old data is already replaced, so partial loss must be stated
          // rather than reported as a clean success.
          _showErrorDialog(
            'تم الاستيراد مع تجاهل بعض الزيارات',
            'تم استيراد ${result.imported} زيارة، '
                'وتم تجاهل ${result.skipped} زيارة بسبب تلف بياناتها.',
          );
        } else {
          _showSuccessDialog('تم الاستيراد بنجاح',
              'تم استيراد ${result.imported} زيارة بنجاح.');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('خطأ في الاستيراد', '$e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _showConfirmationDialog(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('إلغاء')),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('موافق'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
                backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }
}
