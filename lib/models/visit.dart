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

  Visit copyWith({
    String? id,
    DateTime? date,
    String? schoolName,
    String? notes,
    String? photoPath,
    DateTime? visitTime,
    String? visitDetails,
  }) {
    return Visit(
      id: id ?? this.id,
      date: date ?? this.date,
      schoolName: schoolName ?? this.schoolName,
      notes: notes ?? this.notes,
      photoPath: photoPath ?? this.photoPath,
      visitTime: visitTime ?? this.visitTime,
      visitDetails: visitDetails ?? this.visitDetails,
    );
  }

  @override
  String toString() {
    return 'Visit{id: $id, date: $date, schoolName: $schoolName, notes: $notes, photoPath: $photoPath, visitTime: $visitTime, visitDetails: $visitDetails}';
  }
}