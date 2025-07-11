import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:planner/models/task.dart';
import 'package:planner/services/notification_service.dart';

void main() {
  const MethodChannel channel = MethodChannel('dexterous.com/flutter_local_notifications');

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    final TestDefaultBinaryMessengerBinding binding =
        TestDefaultBinaryMessengerBinding.instance;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (call) async => null,
    );
  });

  tearDown(() {
    final TestDefaultBinaryMessengerBinding binding =
        TestDefaultBinaryMessengerBinding.instance;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('scheduleTaskReminder returns id', () async {
    final service = NotificationService();
    await service.init();
    final task = Task(title: 't', date: DateTime.now(), reminderMinutes: 1);
    final id = await service.scheduleTaskReminder(task);
    expect(id, greaterThan(0));
  });
}
