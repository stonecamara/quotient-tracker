import 'package:flutter_test/flutter_test.dart';
import 'package:quotient_tracker/models/activity.dart';

Activity makeActivity({
  List<bool>? days,
  String? description,
  DateTime? startDate,
  bool repeatsWeekly = false,
}) {
  return Activity.create(
    name: 'Lecture',
    description: description,
    hour: 9,
    minute: 30,
    weeklyDays: days ?? List<bool>.filled(7, true),
    repeatsWeekly: repeatsWeekly,
    startDate: startDate ?? DateTime(2026, 1, 1),
  );
}

void main() {
  test('les activités reçoivent des identifiants distincts', () {
    final first = makeActivity();
    final second = makeActivity();
    expect(first.id, isNot(second.id));
  });

  test('copyWith permet de supprimer une description', () {
    final activity = makeActivity(description: 'Ancienne description');
    final updated = activity.copyWith(description: null);
    expect(updated.description, isNull);
  });

  test('une activité unique est absente avant et après sa date', () {
    final startDate = DateTime(2026, 8, 27);
    final activity = makeActivity(startDate: startDate);

    expect(activity.isScheduledFor(DateTime(2026, 8, 26)), isFalse);
    expect(activity.isScheduledFor(startDate), isTrue);
    expect(activity.isScheduledFor(DateTime(2026, 8, 28)), isFalse);
  });

  test('une ancienne activité sans startDate ni répétition reste lisible', () {
    final activity = Activity.fromMap({
      'id': 'legacy-id',
      'name': 'Activité historique',
      'description': null,
      'hour': 9,
      'minute': 30,
      'weeklyDays': List<bool>.filled(7, true),
      'isCompletedToday': false,
      'createdAt': '2026-01-10T08:00:00.000',
    });

    expect(activity.startDate, DateTime(2026, 1, 10));
    expect(activity.repeatsWeekly, isFalse);
    expect(activity.isScheduledFor(DateTime(2026, 1, 11)), isFalse);
  });

  test('les validations sont conservées séparément par date', () {
    final activity = makeActivity();
    final yesterday = DateTime(2026, 8, 26);
    final today = DateTime(2026, 8, 27);

    final completedYesterday = activity.withCompletionForDate(yesterday, true);

    expect(completedYesterday.isCompletedOn(yesterday), isTrue);
    expect(completedYesterday.isCompletedOn(today), isFalse);
  });

  test('décocher une date ne modifie pas les autres validations', () {
    final activity = makeActivity()
        .withCompletionForDate(DateTime(2026, 8, 26), true)
        .withCompletionForDate(DateTime(2026, 8, 27), true);

    final updated = activity.withCompletionForDate(
      DateTime(2026, 8, 27),
      false,
    );

    expect(updated.isCompletedOn(DateTime(2026, 8, 26)), isTrue);
    expect(updated.isCompletedOn(DateTime(2026, 8, 27)), isFalse);
  });
}
