import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../services/hive_service.dart';
import '../services/settings_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // ── stats ─────────────────────────────────────────────────────────────────
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

  // ── photo ─────────────────────────────────────────────────────────────────
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

  // ── edit bottom sheet ─────────────────────────────────────────────────────
  void _openEditSheet() {
    final nameCtrl =
        TextEditingController(text: SettingsService.supervisorName);
    final specCtrl = TextEditingController(text: SettingsService.specialty);
    final headCtrl =
        TextEditingController(text: SettingsService.supervisionHeadName);
    final s1Ctrl = TextEditingController(
        text: SettingsService.specialtySchoolsCount.toString());
    final s2Ctrl = TextEditingController(
        text: SettingsService.criticalFriendSchoolsCount.toString());
    final s3Ctrl = TextEditingController(
        text: SettingsService.externalEvalSchoolsCount.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Directionality(
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
                _sheetField(nameCtrl, 'اسم المشرف الاختصاصي',
                    Icons.person_outline),
                const SizedBox(height: 10),
                _sheetField(
                    specCtrl, 'الاختصاص', Icons.school_outlined),
                const SizedBox(height: 10),
                _sheetField(headCtrl, 'اسم مدير قسم الإشراف',
                    Icons.manage_accounts_outlined),
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
                    await SettingsService.setSupervisorName(
                        nameCtrl.text.trim());
                    await SettingsService.setSpecialty(specCtrl.text.trim());
                    await SettingsService.setSupervisionHeadName(
                        headCtrl.text.trim());
                    await SettingsService.setSpecialtySchoolsCount(
                        int.tryParse(s1Ctrl.text) ?? 0);
                    await SettingsService.setCriticalFriendSchoolsCount(
                        int.tryParse(s2Ctrl.text) ?? 0);
                    await SettingsService.setExternalEvalSchoolsCount(
                        int.tryParse(s3Ctrl.text) ?? 0);
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

  // ── build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('بروفايل المشرف')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildProfileCard(),
              const SizedBox(height: 20),
              _buildSectionLabel('إحصائيات النشاط'),
              const SizedBox(height: 12),
              _buildStatGrid(),
              const SizedBox(height: 14),
              _buildTypeBreakdown(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ── profile card ──────────────────────────────────────────────────────────
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
        // main card
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.10),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── photo + name ──────────────────────────────────────────
              Column(
                children: [
                  GestureDetector(
                    onTap: _pickPhoto,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: Colors.blue[100],
                          backgroundImage: _hasPhoto
                              ? FileImage(File(photoPath!))
                              : null,
                          child: !_hasPhoto
                              ? Icon(Icons.person,
                                  size: 48, color: Colors.blue[400])
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.blue[600],
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt,
                                color: Colors.white, size: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 100,
                    child: Text(
                      name.isEmpty ? 'اسم المشرف' : name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: name.isEmpty
                            ? Colors.grey
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 16),

              // ── info ──────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    _infoRow(Icons.school_outlined, 'الاختصاص',
                        specialty.isEmpty ? '—' : specialty),
                    _infoRow(Icons.manage_accounts_outlined, 'مدير القسم',
                        headName.isEmpty ? '—' : headName),
                    const Divider(height: 16),
                    _infoCount('مدارس الاختصاص', s1),
                    _infoCount('مدارس الصديق الناقد', s2),
                    _infoCount('مدارس التقييم الخارجي', s3),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── floating pencil icon ──────────────────────────────────────────
        Positioned(
          top: -10,
          left: -10,
          child: GestureDetector(
            onTap: _openEditSheet,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[600],
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.4),
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

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15,
              color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 6),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface),
                children: [
                  TextSpan(
                      text: '$label: ',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600)),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCount(String label, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.65))),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700]),
            ),
          ),
        ],
      ),
    );
  }

  // ── stat grid ─────────────────────────────────────────────────────────────
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
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.55,
      children: [
        _statCard(
          icon: Icons.today_outlined,
          color: Colors.blue,
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
          color: Colors.purple,
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
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border:
            Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
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

  // ── visit-type breakdown ──────────────────────────────────────────────────
  Widget _buildTypeBreakdown() {
    if (_typeBreakdown.isEmpty) return const SizedBox.shrink();

    final total = _typeBreakdown.values.fold(0, (s, v) => s + v);
    final colors = [
      Colors.blue, Colors.green, Colors.orange,
      Colors.purple, Colors.teal, Colors.red,
    ];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
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
}
