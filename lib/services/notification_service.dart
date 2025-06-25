import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/task.dart';
import '../models/routine.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
    const InitializationSettings settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _plugin.initialize(settings);
    tz.initializeTimeZones();
  }

  Future<void> scheduleTask(Task task) async {
    if (task.reminderMinutes == null) return;
    final date = DateTime(task.date.year, task.date.month, task.date.day)
        .add(Duration(minutes: task.reminderMinutes!));
    final tz.TZDateTime tzDate = tz.TZDateTime.from(date, tz.local);
    await _plugin.zonedSchedule(
      task.key as int? ?? 0,
      task.title,
      '',
      tzDate,
      const NotificationDetails(
        android: AndroidNotificationDetails('tasks', 'Tasks'),
        iOS: DarwinNotificationDetails(),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> scheduleRoutineReminder(Routine r, DateTime nextOccur) async {}

  Future<void> cancelRoutineReminder(String routineKey) async {}
}