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

  // Activities CRUD
  static Future<List<Activity>> getActivities() async {
    final box = Hive.box(_activitiesBox);
    final activities = <Activity>[];
    
    for (var i = 0; i < box.length; i++) {
      final data = box.getAt(i);
      if (data != null) {
        activities.add(Activity.fromMap(Map<String, dynamic>.from(data)));
      }
    }
    
    return activities;
  }

  static Future<void> saveActivity(Activity activity) async {
    final box = Hive.box(_activitiesBox);
    await box.put(activity.id, activity.toMap());
  }

  static Future<void> deleteActivity(String id) async {
    final box = Hive.box(_activitiesBox);
    await box.delete(id);
  }

  static Future<void> updateActivityCompletion(String id, bool isCompleted) async {
    final box = Hive.box(_activitiesBox);
    final data = box.get(id);
    if (data != null) {
      final activity = Activity.fromMap(Map<String, dynamic>.from(data));
      final updated = activity.copyWith(isCompletedToday: isCompleted);
      await box.put(id, updated.toMap());
    }
  }

  static Future<void> resetDailyCompletions() async {
    final box = Hive.box(_activitiesBox);
    for (var i = 0; i < box.length; i++) {
      final data = box.getAt(i);
      if (data != null) {
        final activity = Activity.fromMap(Map<String, dynamic>.from(data));
        final updated = activity.copyWith(isCompletedToday: false);
        await box.putAt(i, updated.toMap());
      }
    }
  }

  // Settings
  static Future<void> saveLastResetDate(DateTime date) async {
    final box = Hive.box(_settingsBox);
    await box.put('lastResetDate', date.toIso8601String());
  }

  static Future<DateTime?> getLastResetDate() async {
    final box = Hive.box(_settingsBox);
    final dateStr = box.get('lastResetDate');
    if (dateStr != null) {
      return DateTime.parse(dateStr);
    }
    return null;
  }

  static Future<void> saveNotificationEnabled(bool enabled) async {
    final box = Hive.box(_settingsBox);
    await box.put('notificationsEnabled', enabled);
  }

  static Future<bool> getNotificationEnabled() async {
    final box = Hive.box(_settingsBox);
    return box.get('notificationsEnabled', defaultValue: true);
  }
}
