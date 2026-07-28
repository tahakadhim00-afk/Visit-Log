import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/visit_types.dart';
import '../models/visit.dart';
import '../services/hive_service.dart';

class EditVisitPage extends StatefulWidget {
  final Visit visit;

  const EditVisitPage({
    super.key,
    required this.visit,
  });

  @override
  State<EditVisitPage> createState() => _EditVisitPageState();
}

class _EditVisitPageState extends State<EditVisitPage> {
  late TextEditingController _schoolController;
  late TextEditingController _visitDetailsController;
  late TextEditingController _notesController;
  int? _selectedVisitTypeIndex;

  @override
  void initState() {
    super.initState();
    _schoolController = TextEditingController(text: widget.visit.schoolName);
    _visitDetailsController = TextEditingController(text: widget.visit.visitDetails ?? '');
    _notesController = TextEditingController(text: widget.visit.notes ?? '');
    final existing = widget.visit.visitDetails;
    if (existing != null) {
      final idx = kVisitTypeOptions.indexOf(existing);
      if (idx != -1) _selectedVisitTypeIndex = idx;
    }
  }

  @override
  void dispose() {
    _schoolController.dispose();
    _visitDetailsController.dispose();
    _notesController.dispose();
    super.dispose();
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

    final updatedVisit = widget.visit.copyWith(
      schoolName: _schoolController.text.trim(),
      visitDetails: _visitDetailsController.text.trim().isNotEmpty
          ? _visitDetailsController.text.trim()
          : null,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      visitTime: null,
    );

    await HiveService.updateVisit(updatedVisit);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'تم تحديث الزيارة بنجاح',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          backgroundColor: Colors.green[600]!,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      Navigator.pop(context, updatedVisit);
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
          title: const Text('تعديل الزيـــارة'),
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
                    colors: [Colors.teal[600]!, Colors.teal[400]!],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.edit_calendar, color: Colors.white, size: 32),
                    const SizedBox(height: 12),
                    Text(
                      DateFormat('EEEE', 'ar').format(widget.visit.date),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd MMMM yyyy', 'ar').format(widget.visit.date),
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
                  Container(
                    decoration: fieldDecor,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedVisitTypeIndex,
                        isExpanded: true,
                        dropdownColor: cs.surface,
                        hint: Text('اختر نوع الزيارة', textAlign: TextAlign.right, style: hintStyle),
                        items: List.generate(kVisitTypeOptions.length, (i) {
                          final option = kVisitTypeOptions[i];
                          if (option == null) {
                            return DropdownMenuItem<int>(
                              value: -(i + 1),
                              enabled: false,
                              child: const Divider(height: 1),
                            );
                          }
                          return DropdownMenuItem<int>(
                            value: i,
                            child: Text(
                              option,
                              textAlign: TextAlign.right,
                              style: TextStyle(color: cs.onSurface, fontSize: 15),
                            ),
                          );
                        }),
                        onChanged: (int? i) {
                          if (i != null && i >= 0) {
                            setState(() {
                              _selectedVisitTypeIndex = i;
                              _visitDetailsController.text = kVisitTypeOptions[i]!;
                            });
                          }
                        },
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
                    colors: [Colors.teal[600]!, Colors.teal[400]!],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal[600]!.withValues(alpha: 0.3),
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
                        'حفظ التغييرات',
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
