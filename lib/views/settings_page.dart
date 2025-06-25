import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/app_theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  AppTheme _theme = AppTheme.light;

  @override
  void initState() {
    super.initState();
    final box = Hive.box('settings');
    _theme = AppTheme.values[box.get('theme', defaultValue: 0) as int];
  }

  void _setTheme(AppTheme val) async {
    final box = Hive.box('settings');
    await box.put('theme', val.index);
    setState(() => _theme = val);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Column(
        children: [
          RadioListTile<AppTheme>(
            title: const Text('Light Theme'),
            value: AppTheme.light,
            groupValue: _theme,
            onChanged: (val) => _setTheme(val!),
          ),
          RadioListTile<AppTheme>(
            title: const Text('Dark Theme'),
            value: AppTheme.dark,
            groupValue: _theme,
            onChanged: (val) => _setTheme(val!),
          ),
          RadioListTile<AppTheme>(
            title: const Text('Custom Theme'),
            value: AppTheme.custom,
            groupValue: _theme,
            onChanged: (val) => _setTheme(val!),
          ),
        ],
      ),
    );
  }
}
