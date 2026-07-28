import 'package:hive/hive.dart';

part 'visit.g.dart';

@HiveType(typeId: 0)
class Visit extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  String schoolName;

  @HiveField(3)
  String? notes;

  @HiveField(4)
  String? photoPath;

  @HiveField(5)
  DateTime? visitTime;

  @HiveField(6)
  String? visitDetails;

  Visit({
    required this.id,
    required this.date,
    required this.schoolName,
    this.notes,
    this.photoPath,
    this.visitTime,
    this.visitDetails,
  });

  /// Marks an argument as "not supplied" so that passing an explicit `null`
  /// clears the field instead of being read as "leave unchanged".
  static const Object _unset = Object();

  Visit copyWith({
    String? id,
    DateTime? date,
    String? schoolName,
    Object? notes = _unset,
    Object? photoPath = _unset,
    Object? visitTime = _unset,
    Object? visitDetails = _unset,
  }) {
    return Visit(
      id: id ?? this.id,
      date: date ?? this.date,
      schoolName: schoolName ?? this.schoolName,
      notes: identical(notes, _unset) ? this.notes : notes as String?,
      photoPath:
          identical(photoPath, _unset) ? this.photoPath : photoPath as String?,
      visitTime: identical(visitTime, _unset)
          ? this.visitTime
          : visitTime as DateTime?,
      visitDetails: identical(visitDetails, _unset)
          ? this.visitDetails
          : visitDetails as String?,
    );
  }

  @override
  String toString() {
    return 'Visit{id: $id, date: $date, schoolName: $schoolName, notes: $notes, photoPath: $photoPath, visitTime: $visitTime, visitDetails: $visitDetails}';
  }
}