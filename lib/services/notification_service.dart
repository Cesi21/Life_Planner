import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/task.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const IOSInitializationSettings iosSettings = IOSInitializationSettings();
    const InitializationSettings settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _plugin.initialize(settings);
  }

  Future<void> scheduleTask(Task task) async {
    if (task.reminderMinutes == null) return;
    final date = DateTime(task.date.year, task.date.month, task.date.day)
        .add(Duration(minutes: task.reminderMinutes!));
    await _plugin.schedule(
      task.key as int? ?? 0,
      task.title,
      '',
      date,
      const NotificationDetails(
        android: AndroidNotificationDetails('tasks', 'Tasks'),
        iOS: IOSNotificationDetails(),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
