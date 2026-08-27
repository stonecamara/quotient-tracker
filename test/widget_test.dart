import 'package:flutter_test/flutter_test.dart';
import 'package:quotient_tracker/models/activity.dart';
import 'package:quotient_tracker/services/notification_service.dart';

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

  test('nextOccurrence respecte le prochain jour actif en répétition', () {
    final monday = DateTime(2026, 8, 24, 8, 0);
    final activity = makeActivity(
      repeatsWeekly: true,
      days: <bool>[false, false, true, false, false, false, false],
    );

    final next = NotificationService.nextOccurrence(activity, from: monday);

    expect(next, DateTime(2026, 8, 26, 9, 30));
  });

  test(
    'nextOccurrence respecte une date de début future pour une activité unique',
    () {
      final startDate = DateTime(2026, 8, 28);
      final activity = makeActivity(startDate: startDate);

      final next = NotificationService.nextOccurrence(
        activity,
        from: DateTime(2026, 8, 27, 12, 0),
      );

      expect(next, DateTime(2026, 8, 28, 9, 30));
    },
  );

  test('nextOccurrence respecte une date de début future en répétition', () {
    final startDate = DateTime(2026, 8, 28);
    final activity = makeActivity(
      startDate: startDate,
      repeatsWeekly: true,
      days: <bool>[false, false, false, false, true, false, false],
    );

    final next = NotificationService.nextOccurrence(
      activity,
      from: DateTime(2026, 8, 27, 12, 0),
    );

    expect(next, DateTime(2026, 8, 28, 9, 30));
  });

  test('nextOccurrence passe à la semaine suivante après le dernier jour', () {
    final sunday = DateTime(2026, 8, 30, 12, 0);
    final activity = makeActivity(
      repeatsWeekly: true,
      days: <bool>[true, false, false, false, false, false, false],
    );

    final next = NotificationService.nextOccurrence(activity, from: sunday);

    expect(next, DateTime(2026, 8, 31, 9, 30));
  });

  test('nextOccurrence retourne null sans jour actif en répétition', () {
    final activity = makeActivity(
      repeatsWeekly: true,
      days: List<bool>.filled(7, false),
    );
    expect(
      NotificationService.nextOccurrence(activity, from: DateTime(2026, 8, 24)),
      isNull,
    );
  });
}
