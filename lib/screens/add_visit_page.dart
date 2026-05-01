import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  static const List<String?> _visitTypeOptions = [
    'صديق ناقد',
    'متابعة امتحانية',
    'اختصاص',
    'تحقق',
    'لجنة تحقيقية',
    'دوام',
    'ايفاد',
    'مسابقات',
    'اجتماع',
    'ندوة توجيهيه',
    'لجنة الحوانيت',
    'لجنة تنظيم الدوام',
    'لجنة تقييم الاسئلة',
    'لجنة معالجة الملاك',
    'لجنة اعتراضات',
    'لجنة تسوية الملاك',
    'لجنة تدقيق القيود',
    'لجنة التدقيق القطاعي',
    'لجنة التقييم الخارجي',
    'لجنة الاستضافة',
    'لجنة الانتساب',
    'دورة تدريبية',
    'درس تدريبي',
    'اللجنة الفرعية للامتحانات',
    'مركز فحص الدراسة الابتدائية',
    'مركز فحص الدراسة المتوسطة',
    'مركز فحص الدراسة الاعدادية',
    'ورشة تدريبية',
    'حلقة نقاشية',
    'مداولة',
    'عطلة رسمية',
    'اجازة',
    'تواجد',
    'ورشة عمل',
    null,
    'مركز امتحان وزاري',
    'مركز امتحان تمهيدي',
    'بيان رأي',
    'مطالعة',
    'لجنة الامتحان الخارجي',
    'لجنة',
    'تفرغ علمي',
    'ورشة عمل',
    'عطلة محلية',
    'مناظرة علمية',
    'لجنة تدقيق القبولات',
    'لجنة حقوق الانسان',
    'نظام EMIS',
    'تفرغ جزئي',
    'حملة العودة الى التعليم',
    'اختبار اللغة الفرنسية',
    'متابعة سير التدريسات',
    'اجراء اللازم',
    null,
    'اجراء انفكاك و مباشر',
    null,
    'تحقيق وزاري',
    'معايشة',
    'تواجد الاختصاصين الادارين',
    'لجنة وزارية',
    'غير ذلك',
  ];

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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
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
                    style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green[600]!,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue[700]!,
                    Colors.blue[400]!,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: Colors.white,
                    size: 32,
                  ),
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
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // School Name Field
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
            
            // Visit Details Field
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
                      items: List.generate(_visitTypeOptions.length, (i) {
                        final option = _visitTypeOptions[i];
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
                            _visitDetailsController.text = _visitTypeOptions[i]!;
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
            
            // Notes Field
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
            
            // Save Button
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue[700]!,
                    Colors.blue[400]!,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue[700]!.withValues(alpha: 0.3),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
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
                                style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    ));
  }
}