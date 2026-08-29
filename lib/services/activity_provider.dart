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
    return activitiesForDate(DateTime.now());
  }

  List<Activity> get completedToday {
    final today = DateTime.now();
    return todayActivities.where((a) => a.isCompletedOn(today)).toList();
  }

  List<Activity> activitiesForDate(DateTime date) {
    final result = _activities
        .where((activity) => activity.isScheduledFor(date))
        .toList();
    result.sort((a, b) {
      final byHour = a.hour.compareTo(b.hour);
      return byHour != 0 ? byHour : a.minute.compareTo(b.minute);
    });
    return result;
  }

  List<Activity> get pendingToday {
    final today = DateTime.now();
    return todayActivities.where((a) => !a.isCompletedOn(today)).toList();
  }

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
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _validate(Activity activity) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (activity.startDate.isBefore(today)) {
      throw ArgumentError('La date de début ne peut pas être dans le passé');
    }
    if (activity.name.trim().isEmpty) {
      throw ArgumentError('Le nom de l’activité est obligatoire');
    }
    if (activity.hour < 0 ||
        activity.hour > 23 ||
        activity.minute < 0 ||
        activity.minute > 59) {
      throw ArgumentError('L’heure de l’activité est invalide');
    }
    if (activity.weeklyDays.length != 7 ||
        !activity.weeklyDays.contains(true)) {
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

  Future<void> toggleActivityCompletion(String id, {DateTime? date}) async {
    final targetDate = _dateOnly(date ?? DateTime.now());
    final today = _dateOnly(DateTime.now());
    if (targetDate.isBefore(today)) return;

    final index = _activities.indexWhere((a) => a.id == id);
    if (index == -1) return;

    final previous = _activities[index];
    final updated = previous.withCompletionForDate(
      targetDate,
      !previous.isCompletedOn(targetDate),
    );
    _activities = [..._activities]..[index] = updated;
    notifyListeners();

    try {
      await StorageService.saveActivity(updated);
      if (updated.isCompletedOn(targetDate)) {
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

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
