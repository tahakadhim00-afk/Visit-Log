import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../services/backup_service.dart';
import '../services/hive_service.dart';
import '../services/notification_service.dart';
import '../services/settings_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = false;
  bool _notificationsEnabled = SettingsService.notificationsEnabled;

  late int _monthlyVisits;
  late int _yearlyVisits;
  late int _uniqueSchools;
  late DateTime? _lastVisitDate;
  late Map<String, int> _typeBreakdown;

  static const Set<String> _holidayTypes = {
    'عطلة رسمية', 'اجازة', 'عطلة محلية',
  };

  bool _isHoliday(String? d) => d != null && _holidayTypes.contains(d.trim());

  (int, int) _acadYear(DateTime d) =>
      d.month >= 9 ? (d.year, d.year + 1) : (d.year - 1, d.year);

  void _computeStats() {
    final now = DateTime.now();
    final (acadStart, _) = _acadYear(now);
    final yearStart = DateTime(acadStart, 9, 1);

    final all = HiveService.getAllVisits()
        .where((v) =>
            v.date.weekday != DateTime.friday && !_isHoliday(v.visitDetails))
        .toList();

    _monthlyVisits = all
        .where((v) => v.date.year == now.year && v.date.month == now.month)
        .length;

    final yearVisits = all.where((v) => !v.date.isBefore(yearStart)).toList();
    _yearlyVisits = yearVisits.length;
    _uniqueSchools = yearVisits.map((v) => v.schoolName.trim()).toSet().length;

    final sorted = HiveService.getAllVisits()
        .where((v) => v.date.weekday != DateTime.friday)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    _lastVisitDate = sorted.isEmpty ? null : sorted.first.date;

    final breakdown = <String, int>{};
    for (final v in yearVisits) {
      final t = (v.visitDetails?.trim().isEmpty ?? true)
          ? 'غير محدد'
          : v.visitDetails!.trim();
      breakdown[t] = (breakdown[t] ?? 0) + 1;
    }
    final sorted2 = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    _typeBreakdown = Map.fromEntries(sorted2.take(6));
  }

  @override
  void initState() {
    super.initState();
    _computeStats();
  }

  bool get _hasPhoto {
    final p = SettingsService.profilePhotoPath;
    return p != null && File(p).existsSync();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    final appDir = await getApplicationDocumentsDirectory();
    final dest = '${appDir.path}/supervisor_profile.jpg';
    await File(picked.path).copy(dest);
    await SettingsService.setProfilePhotoPath(dest);
    if (mounted) setState(() {});
  }

  void _openEditSheet() {
    final nameCtrl = TextEditingController(text: SettingsService.supervisorName);
    final specCtrl = TextEditingController(text: SettingsService.specialty);
    final headCtrl = TextEditingController(text: SettingsService.supervisionHeadName);
    final s1Ctrl = TextEditingController(text: SettingsService.specialtySchoolsCount.toString());
    final s2Ctrl = TextEditingController(text: SettingsService.criticalFriendSchoolsCount.toString());
    final s3Ctrl = TextEditingController(text: SettingsService.externalEvalSchoolsCount.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.35)
                    : Colors.white.withValues(alpha: 0.40),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.white.withValues(alpha: 0.6),
                  width: 1,
                ),
              ),
              child: Directionality(
                textDirection: ui.TextDirection.rtl,
                child: Padding(
                  padding: EdgeInsets.only(
                    right: 20,
                    left: 20,
                    top: 12,
                    bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'تعديل بيانات المشرف',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(ctx).colorScheme.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        _sheetField(nameCtrl, 'اسم المشرف الاختصاصي', Icons.person_outline),
                        const SizedBox(height: 10),
                        _sheetField(specCtrl, 'الاختصاص', Icons.school_outlined),
                        const SizedBox(height: 10),
                        _sheetField(headCtrl, 'اسم مدير قسم الإشراف', Icons.manage_accounts_outlined),
                        const SizedBox(height: 10),
                        _sheetNumber(s1Ctrl, 'عدد مدارس الاختصاص'),
                        const SizedBox(height: 10),
                        _sheetNumber(s2Ctrl, 'عدد مدارس الصديق الناقد'),
                        const SizedBox(height: 10),
                        _sheetNumber(s3Ctrl, 'عدد مدارس التقييم الخارجي'),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('حفظ'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            await SettingsService.setSupervisorName(nameCtrl.text.trim());
                            await SettingsService.setSpecialty(specCtrl.text.trim());
                            await SettingsService.setSupervisionHeadName(headCtrl.text.trim());
                            await SettingsService.setSpecialtySchoolsCount(int.tryParse(s1Ctrl.text) ?? 0);
                            await SettingsService.setCriticalFriendSchoolsCount(int.tryParse(s2Ctrl.text) ?? 0);
                            await SettingsService.setExternalEvalSchoolsCount(int.tryParse(s3Ctrl.text) ?? 0);
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              setState(() {});
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('تم حفظ البيانات'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sheetField(
      TextEditingController ctrl, String label, IconData icon) {
    return TextField(
      controller: ctrl,
      textDirection: ui.TextDirection.rtl,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _sheetNumber(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      textDirection: ui.TextDirection.ltr,
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.numbers_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('بروفايل المشرف'),
          backgroundColor: Colors.black,
          elevation: 0,
        ),
        body: Stack(
          children: [
            Positioned(
              top: -80,
              right: -80,
              child: _colorBlob(size: 300, color: Colors.teal.withValues(alpha: isDark ? 0.15 : 0.12), blur: 90),
            ),
            Positioned(
              top: -60,
              left: -60,
              child: _colorBlob(size: 260, color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05), blur: 85),
            ),
            Positioned(
              top: 280,
              right: -70,
              child: _colorBlob(size: 280, color: Colors.teal.withValues(alpha: isDark ? 0.10 : 0.09), blur: 90),
            ),
            Positioned(
              top: 320,
              left: -70,
              child: _colorBlob(size: 260, color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04), blur: 85),
            ),
            Positioned(
              bottom: -80,
              right: -60,
              child: _colorBlob(size: 300, color: Colors.teal.withValues(alpha: isDark ? 0.12 : 0.10), blur: 90),
            ),
            Positioned(
              bottom: -60,
              left: -60,
              child: _colorBlob(size: 260, color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05), blur: 85),
            ),
            SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: MediaQuery.of(context).padding.top + kToolbarHeight + 12,
                bottom: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProfileCard(),
                  const SizedBox(height: 24),
                  _buildSectionLabel('إحصائيات النشاط'),
                  const SizedBox(height: 12),
                  _buildStatGrid(),
                  const SizedBox(height: 14),
                  _buildTypeBreakdown(),
                  const SizedBox(height: 20),
                  _buildSectionLabel('الإعدادات'),
                  const SizedBox(height: 12),
                  _buildNotificationCard(),
                  const SizedBox(height: 12),
                  _buildBackupCard(),
                  const SizedBox(height: 16),
                  if (_isLoading) const Center(child: CircularProgressIndicator()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _colorBlob({required double size, required Color color, required double blur}) {
    return ImageFiltered(
      imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    final photoPath = SettingsService.profilePhotoPath;
    final name = SettingsService.supervisorName;
    final specialty = SettingsService.specialty;
    final headName = SettingsService.supervisionHeadName;
    final s1 = SettingsService.specialtySchoolsCount;
    final s2 = SettingsService.criticalFriendSchoolsCount;
    final s3 = SettingsService.externalEvalSchoolsCount;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.teal[600]!,
                Colors.teal[900]!,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  GestureDetector(
                    onTap: _pickPhoto,
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      backgroundImage: _hasPhoto
                          ? FileImage(File(photoPath!))
                          : null,
                      child: !_hasPhoto
                          ? const Icon(Icons.person,
                              size: 40, color: Colors.white70)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 130,
                    child: Text(
                      name.isEmpty ? 'اسم المشرف' : name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: name.isEmpty
                            ? Colors.white60
                            : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    _infoRow(Icons.school_outlined, 'الاختصاص',
                        specialty.isEmpty ? '—' : specialty, onGradient: true),
                    _infoRow(Icons.manage_accounts_outlined, 'مدير القسم',
                        headName.isEmpty ? '—' : headName, onGradient: true),
                    Divider(height: 16, color: Colors.white.withValues(alpha: 0.3)),
                    _infoCount('مدارس الاختصاص', s1, onGradient: true),
                    _infoCount('مدارس الصديق الناقد', s2, onGradient: true),
                    _infoCount('مدارس التقييم الخارجي', s3, onGradient: true),
                  ],
                ),
              ),
            ],
          ),
        ),

        Positioned(
          top: -10,
          left: -10,
          child: GestureDetector(
            onTap: _openEditSheet,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.teal[600],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.edit, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {bool onGradient = false}) {
    final textColor = onGradient ? Colors.white : Theme.of(context).colorScheme.onSurface;
    final iconColor = onGradient ? Colors.white70 : Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: iconColor),
          const SizedBox(width: 6),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 12, color: textColor),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCount(String label, int count, {bool onGradient = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: onGradient
                  ? Colors.white.withValues(alpha: 0.80)
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: onGradient
                  ? Colors.white.withValues(alpha: 0.20)
                  : Colors.teal.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: onGradient ? Colors.white : Colors.teal[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const List<String> _arabicMonths = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
  ];

  String _formatDate(DateTime d) =>
      '${d.day} ${_arabicMonths[d.month - 1]} ${d.year}';

  Widget _buildStatGrid() {
    final lastStr = _lastVisitDate == null
        ? 'لا توجد'
        : _formatDate(_lastVisitDate!);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.55,
      children: [
        _statCard(
          icon: Icons.today_outlined,
          color: Colors.teal,
          label: 'زيارات هذا الشهر',
          value: '$_monthlyVisits',
        ),
        _statCard(
          icon: Icons.trending_up_rounded,
          color: Colors.green,
          label: 'زيارات العام الدراسي',
          value: '$_yearlyVisits',
        ),
        _statCard(
          icon: Icons.account_balance_outlined,
          color: Colors.orange,
          label: 'مدارس مزارة هذا العام',
          value: '$_uniqueSchools',
        ),
        _statCard(
          icon: Icons.event_available_outlined,
          color: Colors.teal,
          label: 'آخر زيارة',
          value: lastStr,
          smallValue: true,
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    bool smallValue = false,
  }) {
    return _blurCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: smallValue ? 13 : 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBreakdown() {
    if (_typeBreakdown.isEmpty) return const SizedBox.shrink();

    final total = _typeBreakdown.values.fold(0, (s, v) => s + v);
    final colors = [
      Colors.teal, Colors.green, Colors.orange,
      Colors.purple, Colors.teal, Colors.red,
    ];

    return _blurCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'توزيع أنواع الزيارات (العام الدراسي)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          ..._typeBreakdown.entries.toList().asMap().entries.map((e) {
            final idx = e.key;
            final type = e.value.key;
            final count = e.value.value;
            final pct = total == 0 ? 0.0 : count / total;
            final color = colors[idx % colors.length];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: Text(type,
                              style: const TextStyle(fontSize: 12))),
                      Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 6,
                      backgroundColor: color.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _blurCard({required Widget child, EdgeInsetsGeometry? padding}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.7),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildNotificationCard() {
    return _blurCard(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.teal.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _notificationsEnabled ? Icons.notifications_active : Icons.notifications_off,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
      subtitle: Text(subtitle,
          style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
      onTap: _isLoading ? null : onTap,
    );
  }

  Future<void> _exportData() async {
    setState(() => _isLoading = true);
    try {
      final filePath = await BackupService.exportDataToJson();
      if (mounted) _showSuccessDialog('تم التصدير بنجاح', 'تم حفظ البيانات في:\n$filePath');
    } catch (e) {
      if (mounted) _showErrorDialog('خطأ في التصدير', 'فشل في تصدير البيانات: ${e.toString()}');
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
      if (mounted) _showErrorDialog('خطأ في الاستيراد', 'فشل في استيراد البيانات: ${e.toString()}');
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
