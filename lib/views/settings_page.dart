import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    final box = Hive.box('settings');
    _darkMode = box.get('darkMode', defaultValue: false);
  }

  void _toggle(bool val) async {
    final box = Hive.box('settings');
    await box.put('darkMode', val);
    setState(() => _darkMode = val);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SwitchListTile(
        title: const Text('Dark Mode'),
        value: _darkMode,
        onChanged: _toggle,
      ),
    );
  }
}
