import 'package:flutter_test/flutter_test.dart';
import 'package:quotient_tracker/models/activity.dart';
import 'package:quotient_tracker/services/notification_service.dart';

Activity makeActivity({
  List<bool>? days,
  String? description,
  DateTime? startDate,
}) {
  return Activity.create(
    name: 'Lecture',
    description: description,
    hour: 9,
    minute: 30,
    weeklyDays: days ?? List<bool>.filled(7, true),
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

  test('une activité future est absente avant sa date de début', () {
    final startDate = DateTime(2026, 8, 28);
    final activity = makeActivity(startDate: startDate);

    expect(activity.isScheduledFor(DateTime(2026, 8, 27)), isFalse);
    expect(activity.isScheduledFor(DateTime(2026, 8, 28)), isTrue);
  });

  test('une ancienne activité sans startDate reste lisible', () {
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
  });

  test('nextOccurrence respecte le prochain jour actif', () {
    final monday = DateTime(2026, 8, 24, 8, 0);
    final activity = makeActivity(
      days: <bool>[false, false, true, false, false, false, false],
    );

    final next = NotificationService.nextOccurrence(activity, from: monday);

    expect(next, DateTime(2026, 8, 26, 9, 30));
  });

  test('nextOccurrence respecte une date de début future', () {
    final startDate = DateTime(2026, 8, 28);
    final activity = makeActivity(
      startDate: startDate,
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
      days: <bool>[true, false, false, false, false, false, false],
    );

    final next = NotificationService.nextOccurrence(activity, from: sunday);

    expect(next, DateTime(2026, 8, 31, 9, 30));
  });

  test('nextOccurrence retourne null sans jour actif', () {
    final activity = makeActivity(days: List<bool>.filled(7, false));
    expect(
      NotificationService.nextOccurrence(activity, from: DateTime(2026, 8, 24)),
      isNull,
    );
  });
}
