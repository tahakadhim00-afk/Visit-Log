import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../services/backup_service.dart';
import '../services/export_service.dart';
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
              _buildSectionTitle('حول التطبيق'),
              const SizedBox(height: 16),
              _buildAboutCard(),
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
        leading: Icon(
          _notificationsEnabled
              ? Icons.notifications_active
              : Icons.notifications_off,
          color: Colors.teal,
          size: 26,
        ),
        title: const Text('تذكير يومي',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        subtitle: Text(
          _notificationsEnabled ? 'مفعّل' : 'معطّل',
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
      leading: Icon(icon, color: color, size: 26),
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

  /// App identity and credits, previously a bottom sheet behind the ⓘ icon on
  /// the calendar screen. It is reference material rather than an action, so it
  /// sits at the end of Settings instead of occupying a corner of the main
  /// screen.
  Widget _buildAboutCard() {
    return _blurCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            // The launcher icon itself, so the section identifies the app with
            // the same mark on the home screen. Its background is transparent,
            // so it needs no tile behind it.
            Image.asset(
              'lib/assets/newlogo.png',
              width: 76,
              height: 76,
              // Source is 1080², far larger than it draws; capping the decode
              // keeps ~4.5 MB of bitmap out of the image cache.
              cacheWidth: 256,
            ),
            const SizedBox(height: 14),
            const Text(
              'سجل زيارات المشرف',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
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
                color:
                    Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
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
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.8),
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
    );
  }

  /// Arabic label for a month, reusing the names the exported report prints so
  /// the import dialogs and the report never disagree on what a month is called.
  String _monthLabel(DateTime month) =>
      '${ExportService.arabicMonths[month.month - 1]} ${month.year}';

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
    // The file is read before anything is confirmed, because only its contents
    // reveal whether this touches one month or erases the whole box — and the
    // user should be asked about the one that is actually going to happen.
    setState(() => _isLoading = true);
    final BackupPayload? payload;
    try {
      payload = await BackupService.readBackupFile();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorDialog('خطأ في قراءة الملف', '$e');
      }
      return;
    }
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (payload == null) {
      _showErrorDialog(
          'لم يتم الاستيراد', 'لم يتم اختيار ملف أو تم إلغاء العملية.');
      return;
    }

    final confirmed = await _showConfirmationDialog(
      'تأكيد الاستيراد',
      payload.isMonthScoped
          ? 'الملف يحتوي على ${payload.visits.length} زيارة لشهر '
              '${_monthLabel(payload.month!)} فقط.\n\n'
              'سيتم استبدال زيارات هذا الشهر، ولن تتأثر بقية الأشهر.'
          : 'الملف نسخة احتياطية كاملة تحتوي على ${payload.visits.length} زيارة.\n\n'
              'سيتم حذف جميع الزيارات الحالية واستبدالها بالكامل.',
    );
    if (!confirmed || !mounted) return;

    setState(() => _isLoading = true);
    try {
      final result = await BackupService.applyBackup(payload);
      if (mounted) {
        final String scopeNote = result.month != null
            ? ' لشهر ${_monthLabel(result.month!)}، ولم تتأثر بقية الأشهر.'
            : ' بنجاح.';
        if (result.hasLoss) {
          // The old data is already replaced, so partial loss must be stated
          // rather than reported as a clean success.
          _showErrorDialog(
            'تم الاستيراد مع تجاهل بعض الزيارات',
            'تم استيراد ${result.imported} زيارة، '
                'وتم تجاهل ${result.skipped} زيارة بسبب تلف بياناتها '
                'أو لأنها خارج الشهر المحدد.',
          );
        } else {
          _showSuccessDialog(
              'تم الاستيراد بنجاح', 'تم استيراد ${result.imported} زيارة$scopeNote');
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
