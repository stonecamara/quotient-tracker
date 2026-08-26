import 'package:flutter_test/flutter_test.dart';
import 'package:quotient_tracker/models/activity.dart';
import 'package:quotient_tracker/services/notification_service.dart';

Activity makeActivity({
  List<bool>? days,
  String? description,
}) {
  return Activity.create(
    name: 'Lecture',
    description: description,
    hour: 9,
    minute: 30,
    weeklyDays: days ?? List<bool>.filled(7, true),
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

  test('nextOccurrence respecte le prochain jour actif', () {
    final monday = DateTime(2026, 8, 24, 8, 0);
    final activity = makeActivity(
      days: <bool>[false, false, true, false, false, false, false],
    );

    final next = NotificationService.nextOccurrence(activity, from: monday);

    expect(next, DateTime(2026, 8, 26, 9, 30));
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
