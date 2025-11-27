import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/visit.dart';
import '../services/hive_service.dart';
import '../screens/add_visit_page.dart';
import '../screens/visit_details_page.dart';

class DayTile extends StatefulWidget {
  final DateTime date;
  final bool isCurrentMonth;
  final VoidCallback onVisitChanged;

  const DayTile({
    super.key,
    required this.date,
    required this.isCurrentMonth,
    required this.onVisitChanged,
  });

  @override
  State<DayTile> createState() => _DayTileState();
}

class _DayTileState extends State<DayTile> {
  List<Visit> visits = [];
  
  final List<String> arabicDays = [
    'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'
  ];

  @override
  void initState() {
    super.initState();
    _loadVisit();
  }

  @override
  void didUpdateWidget(DayTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.date != widget.date) {
      _loadVisit();
    }
  }

  void _loadVisit() {
    visits = HiveService.getVisitsByDate(widget.date);
  }

  @override
  Widget build(BuildContext context) {
    final isToday = _isToday(widget.date);
    final isFriday = _isFriday(widget.date);
    
    return GestureDetector(
      onTap: isFriday ? null : () => _onTileTap(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _getBackgroundColor(isToday, isFriday),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isFriday 
              ? Colors.red[300]! 
              : (isToday ? Colors.blue[700]! : Colors.grey[300]!),
            width: isToday ? 2 : 1,
          ),
          boxShadow: [
            if (visits.isNotEmpty || isToday)
              BoxShadow(
                color: (visits.isNotEmpty ? Colors.green[300]! : Colors.blue[300]!)
                    .withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Stack(
          children: [
            if (visits.isNotEmpty)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.green[500]!,
                    shape: visits.length == 1 ? BoxShape.circle : BoxShape.rectangle,
                    borderRadius: visits.length == 1 ? null : BorderRadius.circular(8),
                  ),
                  child: visits.length == 1
                      ? const SizedBox.shrink()
                      : Text(
                          '${visits.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        arabicDays[widget.date.weekday % 7],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: _getTextColor(isToday, isFriday).withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.date.day.toString(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _getTextColor(isToday, isFriday),
                        ),
                      ),
                    ],
                  ),
                  if (visits.isNotEmpty)
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.green[50]!,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: visits.length == 1
                              ? Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      visits.first.schoolName,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.green[700]!,
                                        fontWeight: FontWeight.w600,
                                        height: 1.3,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (visits.first.visitTime != null)
                                      Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green[100]!,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          DateFormat('HH:mm').format(visits.first.visitTime!),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.green[700]!,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                  ],
                                )
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${visits.length} زيارات',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.green[700]!,
                                        fontWeight: FontWeight.w600,
                                        height: 1.3,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      visits.map((v) => v.schoolName).join('، '),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.green[600]!,
                                        fontWeight: FontWeight.w400,
                                        height: 1.2,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    )
                  else if (widget.isCurrentMonth && !isFriday)
                    Expanded(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.grey[200]!,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.add,
                            size: 20,
                            color: Colors.grey[500]!,
                          ),
                        ),
                      ),
                    )
                  else if (isFriday)
                    Expanded(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red[100]!,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.block,
                                size: 16,
                                color: Colors.red[600]!,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'عطلة',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.red[600]!,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getBackgroundColor(bool isToday, bool isFriday) {
    if (!widget.isCurrentMonth) {
      return Colors.grey[300]!;
    } else if (isFriday) {
      return Colors.red[50]!;
    } else if (isToday) {
      return Colors.blue[50]!;
    } else if (visits.isNotEmpty) {
      return Colors.white;
    } else {
      return Colors.grey[50]!;
    }
  }

  Color _getTextColor(bool isToday, bool isFriday) {
    if (!widget.isCurrentMonth) {
      return Colors.grey[400]!;
    } else if (isFriday) {
      return Colors.red[600]!;
    } else if (isToday) {
      return Colors.blue[700]!;
    } else {
      return Colors.black87;
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
           date.month == now.month &&
           date.day == now.day;
  }
  
  bool _isFriday(DateTime date) {
    return date.weekday == DateTime.friday;
  }


  void _onTileTap(BuildContext context) async {
    if (!widget.isCurrentMonth) return;

    if (visits.isNotEmpty) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VisitDetailsPage(date: widget.date),
        ),
      );
      
      if (result == 'deleted' || result == 'updated') {
        _loadVisit();
        setState(() {});
        widget.onVisitChanged();
      }
    } else {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddVisitPage(selectedDate: widget.date),
        ),
      );
      
      if (result == true) {
        _loadVisit();
        setState(() {});
        widget.onVisitChanged();
      }
    }
  }




}