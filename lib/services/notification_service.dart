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

  int _routineId(String routineKey, DateTime date) {
    final day = DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
    return routineKey.hashCode ^ day.hashCode;
  }

  Future<void> scheduleRoutineTimerNotification(
      Routine r, DateTime dateOccur, Duration duration) async {
    final target = tz.TZDateTime.from(dateOccur.add(duration), tz.local);
    await _plugin.zonedSchedule(
      _routineId(r.key.toString(), dateOccur),
      r.title,
      'Timer complete',
      target,
      const NotificationDetails(
        android: AndroidNotificationDetails('routines', 'Routines'),
        iOS: DarwinNotificationDetails(),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelRoutineNotification(String routineKey, DateTime dateOccur) async {
    await _plugin.cancel(_routineId(routineKey, dateOccur));
  }

  Future<void> scheduleRoutineReminder(Routine r, DateTime nextOccur) async {}

  Future<void> cancelRoutineReminder(String routineKey) async {}
}