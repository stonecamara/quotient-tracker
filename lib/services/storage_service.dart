import 'package:hive_flutter/hive_flutter.dart';
import '../models/activity.dart';

class StorageService {
  static const String _activitiesBox = 'activities';
  static const String _settingsBox = 'settings';

  static Box get activitiesBox => Hive.box(_activitiesBox);

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_activitiesBox);
    await Hive.openBox(_settingsBox);
  }

  static Future<List<Activity>> getActivities() async {
    final activities = <Activity>[];
    final box = activitiesBox;

    for (var i = 0; i < box.length; i++) {
      final data = box.getAt(i);
      if (data is! Map) continue;
      try {
        activities.add(Activity.fromMap(Map<String, dynamic>.from(data)));
      } on FormatException {
        // Une entrée invalide ne doit pas empêcher les autres activités de se charger.
      } on TypeError {
        // Même comportement pour une ancienne structure de données incompatible.
      }
    }
    return activities;
  }

  static Future<void> saveActivity(Activity activity) async {
    await activitiesBox.put(activity.id, activity.toMap());
  }

  static Future<void> deleteActivity(String id) async {
    await activitiesBox.delete(id);
  }

  static Future<void> updateActivityCompletion(
    String id,
    bool isCompleted, {
    DateTime? date,
  }) async {
    final data = activitiesBox.get(id);
    if (data is Map) {
      final activity = Activity.fromMap(Map<String, dynamic>.from(data));
      final targetDate = date ?? DateTime.now();
      await saveActivity(
        activity.withCompletionForDate(targetDate, isCompleted),
      );
    }
  }

  // Conservée pour compatibilité avec les anciennes versions. L’historique
  // des validations ne doit plus être effacé au changement de journée.
  static Future<void> resetDailyCompletions() async {}

  static Future<void> saveLastResetDate(DateTime date) async {
    await Hive.box(_settingsBox).put('lastResetDate', date.toIso8601String());
  }

  static Future<DateTime?> getLastResetDate() async {
    final dateStr = Hive.box(_settingsBox).get('lastResetDate');
    if (dateStr is String) return DateTime.tryParse(dateStr);
    return null;
  }

  static Future<void> saveNotificationEnabled(bool enabled) async {
    await Hive.box(_settingsBox).put('notificationsEnabled', enabled);
  }

  static Future<bool> getNotificationEnabled() async {
    return Hive.box(
          _settingsBox,
        ).get('notificationsEnabled', defaultValue: true)
        as bool;
  }
}
