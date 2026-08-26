import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/activity.dart';
import 'storage_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static Timer? _timer;

  static Future<void> init() async {
    if (_initialized) return;
    if (defaultTargetPlatform == TargetPlatform.linux) {
      _initialized = true;
      return;
    }

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Notification tapped: ${details.payload}');
      },
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'activity_reminders',
          "Rappels d'activités",
          description: "Notifications pour les rappels d'activités planifiées",
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('notification_sound'),
        ),
      );
    }

    _initialized = true;
    debugPrint('NotificationService initialized (v22 inexact)');
    _startTimer();
  }

  static void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _checkNow());
  }

  static Future<void> _checkNow() async {
    try {
      final box = StorageService.activitiesBox;
      final now = tz.TZDateTime.now(tz.local);
      final today = DateTime.now().weekday - 1;

      for (var i = 0; i < box.length; i++) {
        final data = box.getAt(i);
        if (data == null) continue;
        final a = Activity.fromMap(Map<String, dynamic>.from(data));
        if (!a.weeklyDays[today]) continue;
        if (a.isCompletedToday) continue;

        final diffSeconds = (a.hour * 3600 + a.minute * 60) -
            (now.hour * 3600 + now.minute * 60 + now.second);
        if (diffSeconds >= -2 && diffSeconds <= 2) {
          debugPrint('Timer: notification for ${a.name}');
          await _showNotification(a);
        }
      }
    } catch (e) {
      debugPrint('Timer error: $e');
    }
  }

  static Future<bool> requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.linux) return true;
    if (!_initialized) await init();

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      debugPrint('Notification permission: $granted');
      return granted ?? false;
    }
    return true;
  }

  static Future<void> showTestNotification() async {
    if (defaultTargetPlatform == TargetPlatform.linux) return;
    if (!_initialized) await init();

    const androidDetails = AndroidNotificationDetails(
      'activity_reminders',
      "Rappels d'activités",
      channelDescription: "Notifications pour les rappels d'activités planifiées",
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('notification_sound'),
    );

    const details = NotificationDetails(android: androidDetails);

    try {
      await _plugin.show(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: 'Test Notification',
        body: 'Les notifications fonctionnent !',
        notificationDetails: details,
      );
      debugPrint('Test notification sent!');
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  static Future<void> _showNotification(Activity activity) async {
    const androidDetails = AndroidNotificationDetails(
      'activity_reminders',
      "Rappels d'activités",
      channelDescription: "Notifications pour les rappels d'activités planifiées",
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('notification_sound'),
      fullScreenIntent: true,
    );

    const details = NotificationDetails(android: androidDetails);

    try {
      await _plugin.show(
        id: activity.id.hashCode,
        title: 'Rappel: ${activity.name}',
        body: activity.description ?? 'Il est temps de commencer votre activité!',
        notificationDetails: details,
      );
      debugPrint('Notification sent for ${activity.name}');
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  /// zonedSchedule avec mode INEXACT — fonctionne hors-app sur Samsung
  static Future<void> scheduleActivityNotification(Activity activity) async {
    if (defaultTargetPlatform == TargetPlatform.linux) return;
    if (!_initialized) await init();

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local, now.year, now.month, now.day, activity.hour, activity.minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'activity_reminders',
      "Rappels d'activités",
      channelDescription: "Notifications pour les rappels d'activités planifiées",
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('notification_sound'),
    );

    const details = NotificationDetails(android: androidDetails);

    try {
      await _plugin.zonedSchedule(
        id: activity.id.hashCode,
        title: 'Rappel: ${activity.name}',
        body: activity.description ?? 'Il est temps de commencer votre activité!',
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      debugPrint('zonedSchedule(inexact) OK for ${activity.name} at $scheduledDate');
    } catch (e) {
      debugPrint('zonedSchedule error: $e');
    }
  }

  static Future<void> cancelNotification(String activityId) async {
    if (defaultTargetPlatform == TargetPlatform.linux) return;
    await _plugin.cancel(id: activityId.hashCode);
  }

  static Future<void> cancelAllNotifications() async {
    if (defaultTargetPlatform == TargetPlatform.linux) return;
    await _plugin.cancelAll();
  }

  static Future<void> rescheduleAllNotifications(List<Activity> activities) async {
    if (defaultTargetPlatform == TargetPlatform.linux) return;
    await cancelAllNotifications();
    for (final activity in activities) {
      await scheduleActivityNotification(activity);
    }
  }
}
