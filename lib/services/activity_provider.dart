import 'package:flutter/foundation.dart';
import '../models/activity.dart';
import 'storage_service.dart';
import 'notification_service.dart';

class ActivityProvider with ChangeNotifier {
  List<Activity> _activities = [];
  bool _isLoading = false;

  List<Activity> get activities => List.unmodifiable(_activities);
  bool get isLoading => _isLoading;

  List<Activity> get todayActivities {
    final result = _activities.where((a) => a.isScheduledForToday).toList();
    result.sort((a, b) {
      final byHour = a.hour.compareTo(b.hour);
      return byHour != 0 ? byHour : a.minute.compareTo(b.minute);
    });
    return result;
  }

  List<Activity> get completedToday =>
      todayActivities.where((a) => a.isCompletedToday).toList();

  List<Activity> get pendingToday =>
      todayActivities.where((a) => !a.isCompletedToday).toList();

  int get quotient {
    if (todayActivities.isEmpty) return 0;
    return ((completedToday.length / todayActivities.length) * 100).round();
  }

  Future<void> loadActivities() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();
    try {
      _activities = await StorageService.getActivities();
      await _checkDailyReset();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _checkDailyReset() async {
    final lastReset = await StorageService.getLastResetDate();
    final now = DateTime.now();
    final isNewDay = lastReset == null ||
        lastReset.year != now.year ||
        lastReset.month != now.month ||
        lastReset.day != now.day;

    if (!isNewDay) return;
    await StorageService.resetDailyCompletions();
    await StorageService.saveLastResetDate(now);
    _activities = [
      for (final activity in _activities)
        activity.copyWith(isCompletedToday: false),
    ];
  }

  void _validate(Activity activity) {
    if (activity.name.trim().isEmpty) {
      throw ArgumentError('Le nom de l’activité est obligatoire');
    }
    if (activity.hour < 0 || activity.hour > 23 ||
        activity.minute < 0 || activity.minute > 59) {
      throw ArgumentError('L’heure de l’activité est invalide');
    }
    if (activity.weeklyDays.length != 7 || !activity.weeklyDays.contains(true)) {
      throw ArgumentError('Au moins un jour doit être sélectionné');
    }
  }

  Future<void> addActivity(Activity activity) async {
    _validate(activity);
    await StorageService.saveActivity(activity);
    _activities = [..._activities, activity];
    await NotificationService.scheduleActivityNotification(activity);
    notifyListeners();
  }

  Future<void> updateActivity(Activity activity) async {
    _validate(activity);
    final index = _activities.indexWhere((a) => a.id == activity.id);
    if (index == -1) return;

    await StorageService.saveActivity(activity);
    _activities = [..._activities]..[index] = activity;
    await NotificationService.cancelNotification(activity.id);
    await NotificationService.scheduleActivityNotification(activity);
    notifyListeners();
  }

  Future<void> deleteActivity(String id) async {
    await StorageService.deleteActivity(id);
    await NotificationService.cancelNotification(id);
    _activities = _activities.where((a) => a.id != id).toList();
    notifyListeners();
  }

  Future<void> toggleActivityCompletion(String id) async {
    final index = _activities.indexWhere((a) => a.id == id);
    if (index == -1) return;

    final previous = _activities[index];
    final updated = previous.copyWith(isCompletedToday: !previous.isCompletedToday);
    _activities = [..._activities]..[index] = updated;
    notifyListeners();

    try {
      await StorageService.updateActivityCompletion(id, updated.isCompletedToday);
      if (updated.isCompletedToday) {
        await NotificationService.cancelNotification(id);
      } else {
        await NotificationService.scheduleActivityNotification(updated);
      }
    } catch (error) {
      _activities = [..._activities]..[index] = previous;
      notifyListeners();
      debugPrint('toggleActivityCompletion error: $error');
    }
  }
}
