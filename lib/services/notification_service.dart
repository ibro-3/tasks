import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/task.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static final StreamController<String?> _onNotificationTap = StreamController.broadcast();
  static Stream<String?> get onNotificationTap => _onNotificationTap.stream;

  @pragma('vm:entry-point')
  static void notificationTapBackground(NotificationResponse details) {}

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (d) { if (d.payload != null) _onNotificationTap.add(d.payload); },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
    tz.initializeTimeZones();
  }

  static Future<void> requestPermissions() async {
    await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
  }

  static Future<void> schedule(Task task) async {
    if (task.dueDate == null || task.isCompleted || task.dueDate!.isBefore(DateTime.now())) return;
    await _plugin.zonedSchedule(
      task.id.hashCode, 'Reminder', task.title,
      tz.TZDateTime.from(task.dueDate!, tz.local),
      NotificationDetails(android: AndroidNotificationDetails('tasks_v11', 'Task Reminders', importance: Importance.max, priority: Priority.high, groupKey: task.listName, color: Colors.indigo, actions: [const AndroidNotificationAction('open', 'View Task')]), iOS: const DarwinNotificationDetails()),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: task.id
    );
  }

  static Future<void> cancel(Task task) async => await _plugin.cancel(task.id.hashCode);
}