import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/task.dart';
import '../models/routine.dart';
import '../services/task_service.dart';
import '../services/routine_service.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  final TaskService _taskSvc = TaskService();
  final RoutineService _routineSvc = RoutineService();

  Future<void> init() async {
    if (kIsWeb) return;
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
    const InitializationSettings settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _plugin.initialize(settings);
    tz.initializeTimeZones();
  }

  Future<int> scheduleTaskReminder(Task task) async {
    if (kIsWeb || task.reminderMinutes == null) return 0;
    final date = DateTime(task.date.year, task.date.month, task.date.day)
        .add(Duration(minutes: task.reminderMinutes!));
    final tz.TZDateTime tzDate = tz.TZDateTime.from(date, tz.local);
    final id = (task.key as int? ?? task.hashCode).abs();
    await _plugin.zonedSchedule(
      id,
      task.title,
      '',
      tzDate,
      const NotificationDetails(
        android: AndroidNotificationDetails('tasks', 'Tasks'),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    return id;
  }

  int _routineId(String routineKey, DateTime date) {
    final day = DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
    return routineKey.hashCode ^ day.hashCode;
  }

  Future<void> scheduleRoutineTimerNotification(
      Routine r, DateTime dateOccur, Duration duration) async {
    if (kIsWeb) return;
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
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelRoutineNotification(String routineKey, DateTime dateOccur) async {
    if (kIsWeb) return;
    await _plugin.cancel(_routineId(routineKey, dateOccur));
  }

  Future<void> cancelNotification(int id) async {
    if (kIsWeb) return;
    await _plugin.cancel(id);
  }

  Future<void> scheduleRoutineReminder(Routine r, DateTime nextOccur) async {
    if (kIsWeb || r.timeMinutes == null) return;
    final date = DateTime(nextOccur.year, nextOccur.month, nextOccur.day)
        .add(Duration(minutes: r.timeMinutes!));
    final tzDate = tz.TZDateTime.from(date, tz.local);
    await _plugin.zonedSchedule(
      r.key as int? ?? 0,
      r.title,
      '',
      tzDate,
      const NotificationDetails(
        android: AndroidNotificationDetails('routines_rem', 'Routine Reminders'),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelRoutineReminder(String routineKey) async {
    if (kIsWeb) return;
    await _plugin.cancel(routineKey.hashCode);
  }

  Future<void> rescheduleEveryMorning() async {
    final now = DateTime.now();
    await _taskSvc.moveIncompleteTasksToToday();
    final tasks = await _taskSvc.getTasksForDay(now);
    for (final t in tasks) {
      await scheduleTaskReminder(t);
    }
    final routines = await _routineSvc.getRoutinesForDay(now);
    for (final r in routines) {
      await scheduleRoutineReminder(r, now);
    }
  }
}