import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/visit_types.dart';
import '../models/visit.dart';
import '../services/hive_service.dart';

class AddVisitPage extends StatefulWidget {
  final DateTime selectedDate;

  const AddVisitPage({
    super.key,
    required this.selectedDate,
  });

  @override
  State<AddVisitPage> createState() => _AddVisitPageState();
}

class _AddVisitPageState extends State<AddVisitPage> {
  final _schoolController = TextEditingController();
  final _visitDetailsController = TextEditingController();
  final _notesController = TextEditingController();
  int? _selectedVisitTypeIndex;

  @override
  void dispose() {
    _schoolController.dispose();
    _visitDetailsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _showVisitTypeModal(BuildContext ctx) {
    showGeneralDialog(
      context: ctx,
      barrierDismissible: true,
      barrierLabel: 'dismiss',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (dialogCtx, _, __) {
        return Stack(
          fit: StackFit.expand,
          children: [
            BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black.withValues(alpha: 0.6),
              ),
            ),
            SafeArea(
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: kVisitTypeOptions.length,
                        itemBuilder: (_, i) {
                          final option = kVisitTypeOptions[i];
                          if (option == null) {
                            return const Divider(height: 1, color: Colors.white12, indent: 16, endIndent: 16);
                          }
                          final isSelected = _selectedVisitTypeIndex == i;
                          return ListTile(
                            title: Text(
                              option,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: isSelected ? Colors.teal[300] : Colors.white,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                fontSize: 15,
                              ),
                            ),
                            trailing: isSelected
                                ? Icon(Icons.check_circle, color: Colors.teal[300], size: 18)
                                : null,
                            onTap: () {
                              setState(() {
                                _selectedVisitTypeIndex = i;
                                _visitDetailsController.text = option;
                              });
                              Navigator.of(dialogCtx).pop();
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      transitionBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
    );
  }

  Future<void> _saveVisit() async {
    if (_schoolController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'يرجى إدخال اسم المكان',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red[600]!,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    final newVisit = Visit(
      id: HiveService.generateVisitId(widget.selectedDate),
      date: widget.selectedDate,
      schoolName: _schoolController.text.trim(),
      visitDetails: _visitDetailsController.text.trim().isNotEmpty
          ? _visitDetailsController.text.trim()
          : null,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      visitTime: null,
    );

    await HiveService.addVisit(newVisit);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'تم إضافة الزيارة بنجاح',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          backgroundColor: Colors.green[600]!,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final labelStyle = TextStyle(color: cs.onSurface, fontSize: 16, fontWeight: FontWeight.w600);
    final fieldDecor = BoxDecoration(
      color: cs.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: cs.outlineVariant, width: 1),
    );
    final inputStyle = TextStyle(color: cs.onSurface, fontSize: 16);
    final hintStyle = TextStyle(color: cs.onSurface.withValues(alpha: 0.5), fontSize: 14);

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إضافة زيارة جديدة'),
          backgroundColor: Colors.black,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal[700]!, Colors.teal[400]!],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.white, size: 32),
                    const SizedBox(height: 12),
                    Text(
                      DateFormat('EEEE', 'ar').format(widget.selectedDate),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd MMMM yyyy', 'ar').format(widget.selectedDate),
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text('اسم المكان *', textAlign: TextAlign.right, style: labelStyle),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: fieldDecor,
                    child: TextField(
                      controller: _schoolController,
                      textAlign: TextAlign.right,
                      style: inputStyle.copyWith(fontSize: 18),
                      decoration: InputDecoration(
                        hintText: 'أدخل اسم المكان',
                        hintStyle: hintStyle.copyWith(fontSize: 16),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text('تفاصيل الزيارة', textAlign: TextAlign.right, style: labelStyle),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _showVisitTypeModal(context),
                    child: Container(
                      decoration: fieldDecor,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Row(
                        children: [
                          Icon(Icons.arrow_drop_down, color: cs.onSurface.withValues(alpha: 0.6)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedVisitTypeIndex != null
                                  ? kVisitTypeOptions[_selectedVisitTypeIndex!]!
                                  : 'اختر نوع الزيارة',
                              textAlign: TextAlign.right,
                              style: _selectedVisitTypeIndex != null ? inputStyle : hintStyle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: fieldDecor,
                    child: TextField(
                      controller: _visitDetailsController,
                      textAlign: TextAlign.right,
                      style: inputStyle,
                      decoration: InputDecoration(
                        hintText: 'أو اكتب تفاصيل الزيارة يدوياً...',
                        hintStyle: hintStyle,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text('الملاحظات', textAlign: TextAlign.right, style: labelStyle),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: fieldDecor,
                    child: TextField(
                      controller: _notesController,
                      textAlign: TextAlign.right,
                      maxLines: 3,
                      style: inputStyle,
                      decoration: InputDecoration(
                        hintText: 'أضف ملاحظات إضافية إن وجدت...',
                        hintStyle: hintStyle,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal[700]!, Colors.teal[400]!],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal[700]!.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _saveVisit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save, size: 24),
                      SizedBox(width: 12),
                      Text(
                        'حفظ الزيارة',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
