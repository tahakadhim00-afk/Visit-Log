import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../services/backup_service.dart';
import '../services/notification_service.dart';
import '../services/settings_service.dart';
import '../services/theme_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isLoading = false;
  bool _notificationsEnabled = SettingsService.notificationsEnabled;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('الإعدادات')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('المظهر'),
              const SizedBox(height: 16),
              _buildThemeCard(),
              const SizedBox(height: 24),
              _buildSectionTitle('الإشعارات'),
              const SizedBox(height: 16),
              _buildNotificationCard(),
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

  Widget _buildThemeCard() {
    return ValueListenableBuilder(
      valueListenable: ThemeNotifier.instance,
      builder: (context, _, __) {
        final isDark = ThemeNotifier.instance.isDark;
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.indigo.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isDark ? Icons.dark_mode : Icons.light_mode,
                color: Colors.indigo,
                size: 24,
              ),
            ),
            title: const Text('الوضع الليلي',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            subtitle: Text(
              isDark ? 'مفعّل' : 'معطّل',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            trailing: Switch(
              value: isDark,
              activeThumbColor: Colors.indigo,
              onChanged: (_) => ThemeNotifier.instance.toggleTheme(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationCard() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
    setState(() => _notificationsEnabled = value);
    await NotificationService.scheduleWeeklyNotifications();
  }

  Widget _buildBackupCard() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
        _showErrorDialog('خطأ في التصدير', 'فشل في تصدير البيانات: ${e.toString()}');
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
        if (result) {
          _showSuccessDialog('تم الاستيراد بنجاح', 'تم استيراد البيانات بنجاح.');
        } else {
          _showErrorDialog('لم يتم الاستيراد', 'لم يتم اختيار ملف أو تم إلغاء العملية.');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('خطأ في الاستيراد', 'فشل في استيراد البيانات: ${e.toString()}');
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
