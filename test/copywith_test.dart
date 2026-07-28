import 'package:flutter_test/flutter_test.dart';
import 'package:visit_log/models/visit.dart';

void main() {
  Visit base() => Visit(
        id: 'v1',
        date: DateTime(2026, 3, 4),
        schoolName: 'School A',
        notes: 'old note',
        visitDetails: 'اختصاص',
        visitTime: DateTime(2026, 3, 4, 9, 30),
      );

  test('omitted nullable fields are preserved', () {
    final r = base().copyWith(schoolName: 'School B');
    expect(r.schoolName, 'School B');
    expect(r.notes, 'old note');
    expect(r.visitDetails, 'اختصاص');
    expect(r.visitTime, DateTime(2026, 3, 4, 9, 30));
  });

  test('explicit null clears nullable fields', () {
    final r = base().copyWith(notes: null, visitDetails: null, visitTime: null);
    expect(r.notes, isNull);
    expect(r.visitDetails, isNull);
    expect(r.visitTime, isNull);
    expect(r.schoolName, 'School A'); // untouched
  });

  test('explicit values replace', () {
    final r = base().copyWith(notes: 'new note');
    expect(r.notes, 'new note');
  });
}
