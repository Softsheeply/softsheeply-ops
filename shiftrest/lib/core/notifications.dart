import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _initialized = true;
  }

  void _onNotificationTap(NotificationResponse response) {}

  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    return false;
  }

  Future<void> scheduleBedtimeReminder({
    required int id,
    required DateTime bedtime,
    required int minutesBefore,
  }) async {
    final reminderTime =
        bedtime.subtract(Duration(minutes: minutesBefore));
    if (reminderTime.isBefore(DateTime.now())) return;

    await _plugin.zonedSchedule(
      id,
      'Time to wind down',
      'Your sleep window starts at ${_formatTime(bedtime)}. 🌙',
      tz.TZDateTime.from(reminderTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'bedtime_channel',
          'Bedtime Reminders',
          channelDescription: 'Reminders to prepare for sleep',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> scheduleWakeReminder({
    required int id,
    required DateTime wakeTime,
    required String shiftType,
  }) async {
    if (wakeTime.isBefore(DateTime.now())) return;

    await _plugin.zonedSchedule(
      id,
      'Wake up',
      'Your $shiftType shift starts in a few hours. Time to rise. ☀️',
      tz.TZDateTime.from(wakeTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'wake_channel',
          'Wake Reminders',
          channelDescription: 'Wake-up alarms for shifts',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> scheduleShiftReminder({
    required int id,
    required DateTime shiftStart,
    required String shiftType,
    required int hoursBefore,
  }) async {
    final reminderTime =
        shiftStart.subtract(Duration(hours: hoursBefore));
    if (reminderTime.isBefore(DateTime.now())) return;

    await _plugin.zonedSchedule(
      id,
      'Shift reminder',
      'Heads up — $shiftType starts in $hoursBefore ${hoursBefore == 1 ? "hour" : "hours"}. Eat, prep, go.',
      tz.TZDateTime.from(reminderTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'shift_channel',
          'Shift Reminders',
          channelDescription: 'Reminders before your shift starts',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> scheduleCaffeineAlert({
    required int id,
    required DateTime deadline,
  }) async {
    final alertTime = deadline.subtract(const Duration(minutes: 30));
    if (alertTime.isBefore(DateTime.now())) return;

    await _plugin.zonedSchedule(
      id,
      'Last coffee window closing',
      'Last caffeine window closes in 30 minutes. ☕',
      tz.TZDateTime.from(alertTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'caffeine_channel',
          'Caffeine Alerts',
          channelDescription: 'Caffeine cutoff reminders',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = hour < 12 ? 'AM' : 'PM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:$minute $ampm';
  }
}
