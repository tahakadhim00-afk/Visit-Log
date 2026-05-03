import 'package:flutter/material.dart';
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
    _loadVisit();
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
              : (isToday
                  ? Colors.blue[700]!
                  : (Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF2A2A2A)
                      : Colors.grey[300]!)),
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
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.green[900]!.withValues(alpha: 0.4)
                              : Colors.green[50]!,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green[600]!,
                                size: 26,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${visits.length}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.green[700]!,
                                  fontWeight: FontWeight.bold,
                                  height: 1,
                                ),
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
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[700]!
                                : Colors.grey[200]!,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.add,
                            size: 20,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[400]!
                                : Colors.grey[500]!,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!widget.isCurrentMonth) return isDark ? Colors.grey[800]! : Colors.grey[300]!;
    if (isFriday) return isDark ? Colors.red[900]!.withValues(alpha: 0.4) : Colors.red[50]!;
    if (isToday) return isDark ? Colors.blue[900]!.withValues(alpha: 0.5) : Colors.blue[50]!;
    return isDark ? Colors.black : Colors.grey[50]!;
  }

  Color _getTextColor(bool isToday, bool isFriday) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!widget.isCurrentMonth) return isDark ? Colors.grey[500]! : Colors.grey[400]!;
    if (isFriday) return isDark ? Colors.red[300]! : Colors.red[600]!;
    if (isToday) return isDark ? Colors.blue[300]! : Colors.blue[700]!;
    return Theme.of(context).colorScheme.onSurface;
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
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VisitDetailsPage(date: widget.date),
        ),
      );
      // Always reload after returning — visits may have been added, edited, or deleted
      setState(() => _loadVisit());
      widget.onVisitChanged();
    } else {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddVisitPage(selectedDate: widget.date),
        ),
      );

      if (result == true) {
        setState(() => _loadVisit());
        widget.onVisitChanged();
      }
    }
  }




}