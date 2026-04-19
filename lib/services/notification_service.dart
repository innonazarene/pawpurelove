import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../models/pet_schedule.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();

    // flutter_timezone 5.x returns TimezoneInfo — use .identifier (not .name) for the IANA zone string
    final tzInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(tzInfo.identifier));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // flutter_local_notifications 21.0.0: initialize() now uses fully named parameters
    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap, e.g. navigate to a specific screen
      },
    );

    _isInitialized = true;
  }

  Future<void> requestPermissions() async {
    if (Platform.isIOS) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidImplementation?.requestNotificationsPermission();
      await androidImplementation?.requestExactAlarmsPermission();
    }
  }

  Future<void> schedulePetNotification(PetSchedule schedule, String petName) async {
    // Generate a unique 32-bit positive integer ID
    final int id = schedule.id.hashCode.abs() & 0x7FFFFFFF;

    // Ensure permissions are granted before scheduling
    await requestPermissions();

    final androidDetails = const AndroidNotificationDetails(
      'pawpurelove_schedules',
      'Care Schedules',
      channelDescription: 'Notifications for pet care routines and health schedules.',
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    final title = 'Time for ${schedule.title}!';
    final body = schedule.notes?.isNotEmpty == true
        ? '${schedule.notes}'
        : 'Scheduled care for $petName is due.';

    // If nextScheduledDate is in the past, skip one-time events or advance repeating ones
    DateTime scheduledDate = schedule.nextScheduledDate;

    if (scheduledDate.isBefore(DateTime.now()) &&
        schedule.frequency == ScheduleFrequency.once) {
      return;
    }

    while (scheduledDate.isBefore(DateTime.now()) &&
        schedule.frequency != ScheduleFrequency.once) {
      scheduledDate = calculateNext(scheduledDate, schedule.frequency);
    }

    final tz.TZDateTime tzDate = tz.TZDateTime.from(scheduledDate, tz.local);

    DateTimeComponents? matchComponents;
    switch (schedule.frequency) {
      case ScheduleFrequency.once:
        matchComponents = null;
        break;
      case ScheduleFrequency.daily:
        matchComponents = DateTimeComponents.time;
        break;
      case ScheduleFrequency.weekly:
        matchComponents = DateTimeComponents.dayOfWeekAndTime;
        break;
      case ScheduleFrequency.monthly:
        matchComponents = DateTimeComponents.dayOfMonthAndTime;
        break;
      case ScheduleFrequency.yearly:
        matchComponents = DateTimeComponents.dateAndTime;
        break;
    }

    try {
      // flutter_local_notifications 21.0.0: zonedSchedule() is now fully named parameters.
      // uiLocalNotificationDateInterpretation was REMOVED (iOS 10 support was dropped).
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: matchComponents,
      );
    } catch (e) {
      debugPrint('Failed to schedule notification: $e');
    }
  }

  DateTime calculateNext(DateTime current, ScheduleFrequency frequency) {
    switch (frequency) {
      case ScheduleFrequency.daily:
        return current.add(const Duration(days: 1));
      case ScheduleFrequency.weekly:
        return current.add(const Duration(days: 7));
      case ScheduleFrequency.monthly:
        return DateTime(
            current.year, current.month + 1, current.day, current.hour, current.minute);
      case ScheduleFrequency.yearly:
        return DateTime(
            current.year + 1, current.month, current.day, current.hour, current.minute);
      default:
        return current;
    }
  }

  // flutter_local_notifications 21.0.0: cancel() now takes a named 'id' parameter
  Future<void> cancelNotification(String scheduleId) async {
    final int id = scheduleId.hashCode.abs() & 0x7FFFFFFF;
    await _notificationsPlugin.cancel(id: id);
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}