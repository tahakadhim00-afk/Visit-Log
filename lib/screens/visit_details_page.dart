import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/visit.dart';
import '../services/hive_service.dart';
import 'edit_visit_page.dart';
import 'add_visit_page.dart';

class VisitDetailsPage extends StatefulWidget {
  final DateTime date;

  const VisitDetailsPage({
    super.key,
    required this.date,
  });

  @override
  State<VisitDetailsPage> createState() => _VisitDetailsPageState();
}

class _VisitDetailsPageState extends State<VisitDetailsPage> {
  List<Visit> visits = [];
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
    _loadVisits();
  }

  void _loadVisits() {
    visits = HiveService.getVisitsByDate(widget.date);
    visits.sort((a, b) {
      if (a.visitTime == null && b.visitTime == null) return 0;
      if (a.visitTime == null) return 1;
      if (b.visitTime == null) return -1;
      return a.visitTime!.compareTo(b.visitTime!);
    });
  }

  String _formatArabicDate(DateTime date) {
    final dayName = arabicDays[date.weekday % 7];
    final monthName = arabicMonths[date.month - 1];
    return '$dayName ${date.day} $monthName ${date.year}';
  }

  Future<void> _editVisit(Visit visit) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditVisitPage(visit: visit),
      ),
    );

    if (result != null && result is Visit) {
      _loadVisits();
      setState(() {});
    }
  }

  Future<void> _addVisit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddVisitPage(selectedDate: widget.date),
      ),
    );

    if (result == true) {
      _loadVisits();
      setState(() {});
    }
  }

  Future<void> _deleteVisit(Visit visit) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_rounded,
              color: Colors.red[600]!,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text(
              'تأكيد الحذف',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: const Text(
          'هل أنت متأكد من حذف هذه الزيارة؟\nلن تتمكن من استرجاعها بعد الحذف.',
          style: TextStyle(
            color: Colors.black54,
            fontSize: 16,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'إلغاء',
              style: TextStyle(
                color: Colors.grey[600]!,
                fontSize: 16,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600]!,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'حذف',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await HiveService.deleteVisit(visit.id);
      
      _loadVisits();
      setState(() {});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'تم حذف الزيارة بنجاح',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red[600]!,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        
        if (visits.isEmpty) {
          Navigator.pop(context, 'deleted');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
      appBar: AppBar(
        title: Text('زيارات ${_formatArabicDate(widget.date)}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addVisit,
          ),
        ],
      ),
      body: visits.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_note,
                    size: 80,
                    color: Colors.grey[400]!,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد زيارات في هذا اليوم',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600]!,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _addVisit,
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة زيارة جديدة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600]!,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Date Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue[600]!,
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
                          _formatArabicDate(widget.date),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'إجمالي الزيارات: ${visits.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Visits List
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: visits.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final visit = visits[index];
                      return _buildVisitCard(visit, index + 1);
                    },
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildVisitCard(Visit visit, int visitNumber) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Visit Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50]!,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[600]!,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$visitNumber',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    visit.schoolName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700]!,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _editVisit(visit),
                      icon: Icon(Icons.edit, color: Colors.blue[600]!),
                      tooltip: 'تعديل',
                    ),
                    IconButton(
                      onPressed: () => _deleteVisit(visit),
                      icon: Icon(Icons.delete, color: Colors.red[600]!),
                      tooltip: 'حذف',
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Visit Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (visit.visitTime != null)
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: Colors.orange[600]!,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'وقت الزيارة',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black54,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange[50]!,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          DateFormat('hh:mm a', 'ar').format(visit.visitTime!),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[700]!,
                          ),
                        ),
                      ),
                    ],
                  ),
                
                // Visit Details Section
                if (visit.visitDetails != null && visit.visitDetails!.isNotEmpty) ...[
                  if (visit.visitTime != null) const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.assignment,
                        color: Colors.blue[600]!,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'تفاصيل الزيارة',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50]!,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      visit.visitDetails!,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blue[700]!,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
                
                // Notes Section
                if (visit.notes != null && visit.notes!.isNotEmpty) ...[
                  if (visit.visitDetails != null && visit.visitDetails!.isNotEmpty || visit.visitTime != null) 
                    const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.note_alt,
                        color: Colors.purple[600]!,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'الملاحظات',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple[50]!,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      visit.notes!,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.purple[700]!,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}