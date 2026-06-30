import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Thin wrapper over flutter_local_notifications for focus-session alerts.
/// Schedules a single notification (id 1) at the session end so it fires even
/// if the app is backgrounded; cancels it on pause/reset.
class Notify {
  static final _p = FlutterLocalNotificationsPlugin();
  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'focus',
      'Focus sessions',
      channelDescription: 'Alerts when a focus session completes',
      importance: Importance.max,
      priority: Priority.high,
    ),
  );

  static Future<void> init() async {
    tzdata.initializeTimeZones();
    await _p.initialize(const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ));
    await _p
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // tz.UTC is fine: we schedule relative to "now", so the absolute instant is
  // correct regardless of the device's local zone — saves a flutter_timezone dep.
  static Future<void> scheduleFocusEnd(Duration after, int minutes) =>
      _p.zonedSchedule(
        1,
        'Focus complete ✦',
        'Your $minutes-minute session is done. Nice orbit.',
        tz.TZDateTime.now(tz.UTC).add(after),
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

  static Future<void> cancelFocus() => _p.cancel(1);
}
