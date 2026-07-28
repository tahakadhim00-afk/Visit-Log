import 'package:flutter/material.dart';
import '../models/visit.dart';
import '../screens/add_visit_page.dart';
import '../screens/visit_details_page.dart';

class DayTile extends StatefulWidget {
  final DateTime date;
  final bool isCurrentMonth;
  final VoidCallback onVisitChanged;

  /// Supplied by the calendar, which loads the whole month in one pass so
  /// each tile doesn't scan the box on its own.
  final List<Visit> visits;

  const DayTile({
    super.key,
    required this.date,
    required this.isCurrentMonth,
    required this.onVisitChanged,
    required this.visits,
  });

  @override
  State<DayTile> createState() => _DayTileState();
}

class _DayTileState extends State<DayTile> {
  static const List<String> arabicDays = [
    'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'
  ];

  List<Visit> get visits => widget.visits;

  @override
  Widget build(BuildContext context) {
    final isToday = _isToday(widget.date);
    final isFriday = _isFriday(widget.date);
    
    return GestureDetector(
      onTap: isFriday ? null : () => _onTileTap(context),
      onLongPress: visits.isNotEmpty ? () => _showQuickPreview(context) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _getBackgroundColor(isToday, isFriday),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isFriday
              ? Colors.red[300]!
              : (isToday ? Colors.teal[700]! : const Color(0xFF2A2A2A)),
            width: isToday ? 2 : 1,
          ),
          boxShadow: [
            if (isToday)
              BoxShadow(
                color: Colors.teal[300]!.withValues(alpha: 0.2),
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
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.teal[400]!,
                                size: 26,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${visits.length}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Theme.of(context).colorScheme.onSurface,
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
                            color: Colors.grey[700]!,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.add,
                            size: 20,
                            color: Color(0xFF9E9E9E),
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
    if (isToday) return Colors.teal.withValues(alpha: 0.10);
    if (isFriday) return Colors.red.withValues(alpha: 0.08);
    return Colors.transparent;
  }

  Color _getTextColor(bool isToday, bool isFriday) {
    if (!widget.isCurrentMonth) return Colors.grey[500]!;
    if (isFriday) return Colors.red[300]!;
    if (isToday) return Colors.teal[300]!;
    return Colors.white;
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

  void _showQuickPreview(BuildContext context) {
    final dayName = arabicDays[widget.date.weekday % 7];
    final dateLabel = '$dayName ${widget.date.day}/${widget.date.month}/${widget.date.year}';

    showDialog(
      context: context,
      barrierColor: Colors.black38,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 0),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 300),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.teal[700],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        dateLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      '${visits.length} زيارة',
                      style: TextStyle(
                        color: Colors.teal[100],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: visits.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    color: Color(0xFF2A2A2A),
                  ),
                  itemBuilder: (_, i) {
                    final v = visits[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.teal[700]!.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal[700],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  v.schoolName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                if (v.visitTime != null)
                                  Text(
                                    '${v.visitTime!.hour.toString().padLeft(2, '0')}:${v.visitTime!.minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Icon(Icons.school, size: 16, color: Colors.teal[400]),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
      if (!mounted) return;
      widget.onVisitChanged();
    } else {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddVisitPage(selectedDate: widget.date),
        ),
      );

      if (!mounted) return;
      if (result == true) {
        widget.onVisitChanged();
      }
    }
  }
}