import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'models/task.dart';
import 'models/routine.dart';
import 'models/tag.dart';
import 'views/calendar_page.dart';
import 'views/routine_page.dart';
import 'views/statistics_page.dart';
import 'views/settings_page.dart';
import 'views/history_page.dart';
import 'models/app_theme.dart';
import 'services/notification_service.dart';
import 'services/backup_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(TaskAdapter());
  Hive.registerAdapter(RoutineAdapter());
  Hive.registerAdapter(TagAdapter());
  await Future.wait([
    Hive.openBox<Task>('tasks'),
    Hive.openBox<Routine>('routines'),
    Hive.openBox<Map>('routine_done'),
    Hive.openBox<Tag>('tags'),
    Hive.openBox<Map>('routine_streaks'),
    Hive.openBox('settings'),
  ]);
  await NotificationService().init();
  await NotificationService().rescheduleEveryMorning();

  final settingsBox = Hive.box('settings');
  final auto = settingsBox.get('autoBackup', defaultValue: false) as bool;
  if (auto) {
    final today = DateTime.now();
    final key = '${today.year}-${today.month}-${today.day}';
    if (settingsBox.get('lastBackupDate') != key) {
      await BackupService().exportAll();
      await settingsBox.put('lastBackupDate', key);
    }
  }

  runApp(const PlannerApp());
}

class PlannerApp extends StatelessWidget {
  const PlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsBox = Hive.box('settings');
    return ValueListenableBuilder(
      valueListenable: settingsBox.listenable(),
      builder: (context, box, _) {
        final theme = AppTheme.values[box.get('theme', defaultValue: 0) as int];
        ThemeMode mode;
        switch (theme) {
          case AppTheme.light:
            mode = ThemeMode.light;
            break;
          case AppTheme.dark:
            mode = ThemeMode.dark;
            break;
          default:
            mode = ThemeMode.system;
        }

        return MaterialApp(
          title: 'Planner',
          themeMode: mode,
          theme: ThemeData.light(useMaterial3: true),
          darkTheme: ThemeData.dark(useMaterial3: true),
          home: const HomePage(),
        );
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;
  final List<Widget> _pages = const [
    CalendarPage(),
    RoutinePage(),
    HistoryPage(),
    StatisticsPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.calendar_today), label: 'Calendar'),
          NavigationDestination(icon: Icon(Icons.repeat), label: 'Routines'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Stats'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
