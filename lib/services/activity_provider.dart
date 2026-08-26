import 'package:flutter/foundation.dart';
import '../models/activity.dart';
import 'storage_service.dart';
import 'notification_service.dart';

class ActivityProvider with ChangeNotifier {
  List<Activity> _activities = [];
  bool _isLoading = false;

  List<Activity> get activities => _activities;
  bool get isLoading => _isLoading;

  List<Activity> get todayActivities {
    return _activities.where((a) => a.isScheduledForToday).toList()
      ..sort((a, b) => a.hour.compareTo(b.hour));
  }

  List<Activity> get completedToday {
    return todayActivities.where((a) => a.isCompletedToday).toList();
  }

  List<Activity> get pendingToday {
    return todayActivities.where((a) => !a.isCompletedToday).toList();
  }

  int get quotient {
    if (todayActivities.isEmpty) return 0;
    return ((completedToday.length / todayActivities.length) * 100).round();
  }

  Future<void> loadActivities() async {
    _isLoading = true;
    notifyListeners();

    _activities = await StorageService.getActivities();

    // Vérifier si on doit réinitialiser les complétions quotidiennes
    await _checkDailyReset();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _checkDailyReset() async {
    final lastReset = await StorageService.getLastResetDate();
    final now = DateTime.now();
    
    if (lastReset == null || lastReset.day != now.day || lastReset.month != now.month || lastReset.year != now.year) {
      await StorageService.resetDailyCompletions();
      await StorageService.saveLastResetDate(now);
      
      // Mettre à jour les activités en mémoire
      for (var i = 0; i < _activities.length; i++) {
        _activities[i] = _activities[i].copyWith(isCompletedToday: false);
      }
    }
  }

  Future<void> addActivity(Activity activity) async {
    await StorageService.saveActivity(activity);
    _activities.add(activity);
    
    if (activity.isScheduledForToday) {
      await NotificationService.scheduleActivityNotification(activity);
    }
    
    notifyListeners();
  }

  Future<void> updateActivity(Activity activity) async {
    await StorageService.saveActivity(activity);
    final index = _activities.indexWhere((a) => a.id == activity.id);
    if (index != -1) {
      _activities[index] = activity;
    }
    
    // Re-planifier la notification
    await NotificationService.cancelNotification(activity.id);
    if (activity.isScheduledForToday) {
      await NotificationService.scheduleActivityNotification(activity);
    }
    
    notifyListeners();
  }

  Future<void> deleteActivity(String id) async {
    await StorageService.deleteActivity(id);
    await NotificationService.cancelNotification(id);
    _activities.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  Future<void> toggleActivityCompletion(String id) async {
    try {
      final index = _activities.indexWhere((a) => a.id == id);
      if (index == -1) return;

      final activity = _activities[index];
      final newStatus = !activity.isCompletedToday;

      // Mettre à jour le state immédiatement (optimistic update)
      _activities[index] = activity.copyWith(isCompletedToday: newStatus);
      notifyListeners();

      // Persister en arrière-plan
      await StorageService.updateActivityCompletion(id, newStatus);

      if (newStatus) {
        await NotificationService.cancelNotification(id);
      }
    } catch (e) {
      debugPrint('toggleActivityCompletion error: $e');
    }
  }
}
