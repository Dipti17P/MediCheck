import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Using dynamic to bypass strict signature checks on web/mismatched stubs
  final dynamic _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    if (kIsWeb) return;

    tz.initializeTimeZones();
    try {
      final dynamic tzInfo = await FlutterTimezone.getLocalTimezone();
      final String timeZoneName = tzInfo is String ? tzInfo : (tzInfo.name ?? 'UTC');
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      print('Could not get local timezone: $e');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        print('Notification tapped: ${details.payload}');
      },
    );

    // Request permissions for Android 13+
    try {
      await _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (e) {
      print('Permission request error: $e');
    }
  }

  Future<void> scheduleMedicineReminder(
      int id, String medicineName, int hour, int minute) async {
    if (kIsWeb) return;

    final dynamic plugin = _localNotificationsPlugin;
    await plugin.zonedSchedule(
      id,
      'Time for your medicine',
      'Please take $medicineName now',
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'medicine_reminders',
          'Medicine Reminders',
          channelDescription: 'Notifications for medicine reminders',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          styleInformation: BigTextStyleInformation(''),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: null, 
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelReminder(int id) async {
    if (kIsWeb) return;
    await _localNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAll() async {
    if (kIsWeb) return;
    await _localNotificationsPlugin.cancelAll();
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
