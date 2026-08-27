import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/activity.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized || defaultTargetPlatform == TargetPlatform.linux) return;

    tz.initializeTimeZones();
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Notification tapped: ${details.payload}');
      },
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'activity_reminders',
        "Rappels d'activités",
        description: 'Notifications pour les rappels d’activités planifiées',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('notification_sound'),
      ),
    );

    _initialized = true;
  }

  static int _notificationId(String activityId) {
    var hash = 2166136261;
    for (final codeUnit in activityId.codeUnits) {
      hash = (hash ^ codeUnit) * 16777619 & 0x7fffffff;
    }
    return hash == 0 ? 1 : hash;
  }

  /// Retourne la prochaine occurrence sur un jour réellement sélectionné.
  static DateTime? nextOccurrence(Activity activity, {DateTime? from}) {
    final current = from ?? DateTime.now();

    if (!activity.repeatsWeekly) {
      final occurrence = DateTime(
        activity.startDate.year,
        activity.startDate.month,
        activity.startDate.day,
        activity.hour,
        activity.minute,
      );
      return occurrence.isAfter(current) ? occurrence : null;
    }

    final start = activity.startDate.isAfter(current)
        ? activity.startDate
        : current;

    for (var offset = 0; offset <= 7; offset++) {
      final candidateDate = DateTime(
        start.year,
        start.month,
        start.day + offset,
        activity.hour,
        activity.minute,
      );
      final weekdayIndex = candidateDate.weekday - 1;
      if (!activity.weeklyDays[weekdayIndex]) continue;
      if (candidateDate.isAfter(current) &&
          !candidateDate.isBefore(activity.startDate)) {
        return candidateDate;
      }
    }
    return null;
  }

  static Future<bool> requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.linux) return true;
    if (!_initialized) await init();

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final androidGranted = await android?.requestNotificationsPermission();
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final iosGranted = await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    return androidGranted ?? iosGranted ?? true;
  }

  static NotificationDetails get _details => const NotificationDetails(
    android: AndroidNotificationDetails(
      'activity_reminders',
      "Rappels d'activités",
      channelDescription:
          'Notifications pour les rappels d’activités planifiées',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('notification_sound'),
    ),
    iOS: DarwinNotificationDetails(),
  );

  static Future<void> showTestNotification() async {
    if (defaultTargetPlatform == TargetPlatform.linux) return;
    if (!_initialized) await init();
    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: 'Test Notification',
      body: 'Les notifications fonctionnent !',
      notificationDetails: _details,
    );
  }

  static Future<void> scheduleActivityNotification(Activity activity) async {
    if (defaultTargetPlatform == TargetPlatform.linux) return;
    if (!_initialized) await init();

    final occurrence = nextOccurrence(activity);
    if (occurrence == null) return;
    final scheduledDate = tz.TZDateTime(
      tz.local,
      occurrence.year,
      occurrence.month,
      occurrence.day,
      occurrence.hour,
      occurrence.minute,
    );

    await _plugin.zonedSchedule(
      id: _notificationId(activity.id),
      title: 'Rappel: ${activity.name}',
      body:
          activity.description ?? 'Il est temps de commencer votre activité !',
      scheduledDate: scheduledDate,
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: activity.id,
    );
  }

  static Future<void> cancelNotification(String activityId) async {
    if (defaultTargetPlatform == TargetPlatform.linux) return;
    await _plugin.cancel(id: _notificationId(activityId));
  }

  static Future<void> cancelAllNotifications() async {
    if (defaultTargetPlatform == TargetPlatform.linux) return;
    await _plugin.cancelAll();
  }

  static Future<void> rescheduleAllNotifications(
    List<Activity> activities,
  ) async {
    if (defaultTargetPlatform == TargetPlatform.linux) return;
    if (!_initialized) await init();
    await cancelAllNotifications();
    for (final activity in activities) {
      if (!activity.isCompletedToday) {
        await scheduleActivityNotification(activity);
      }
    }
  }
}
