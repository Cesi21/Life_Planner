import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/app_theme.dart';
import '../models/tag.dart';
import '../services/backup_service.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  AppTheme _theme = AppTheme.system;
  late Box<Tag> _tagBox;
  List<Tag> _tags = [];

  @override
  void initState() {
    super.initState();
    final box = Hive.box('settings');
    _theme = AppTheme.values[box.get('theme', defaultValue: 0) as int];
    _tagBox = Hive.box<Tag>('tags');
    _loadTags();
  }

  void _setTheme(AppTheme val) async {
    final box = Hive.box('settings');
    await box.put('theme', val.index);
    setState(() => _theme = val);
  }

  void _loadTags() {
    _tags = _tagBox.values.toList();
    setState(() {});
  }

  Future<void> _addTag() async {
    final nameController = TextEditingController();
    Color selected = Colors.blue;
    final colors = [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Tag'),
        content: StatefulBuilder(
          builder: (context, setDialog) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: colors.map((c) {
                  return GestureDetector(
                    onTap: () => setDialog(() => selected = c),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(color: selected == c ? Colors.black : Colors.transparent),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add')),
        ],
      ),
    );
    if (result == true && nameController.text.isNotEmpty) {
      await _tagBox.add(Tag(name: nameController.text, color: selected));
      _loadTags();
    }
  }

  Future<void> _export() async {
    final backup = await BackupService().exportAll();
    final dir = await getDownloadsDirectory();
    if (dir != null) {
      final file = File('${dir.path}/planner_backup.json');
      await file.writeAsString(backup);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported to ${file.path}')),
        );
      }
    }
  }

  Future<void> _import() async {
    final dir = await getDownloadsDirectory();
    if (dir == null) return;
    final file = File('${dir.path}/planner_backup.json');
    if (await file.exists()) {
      final content = await file.readAsString();
      await BackupService().importAll(content);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Import complete')), 
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          RadioListTile<AppTheme>(
            title: const Text('System Default'),
            value: AppTheme.system,
            groupValue: _theme,
            onChanged: (val) => _setTheme(val!),
          ),
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
          const Divider(),
          ListTile(
            title: const Text('Tags'),
            trailing: IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addTag,
            ),
          ),
          ..._tags.map((t) => ListTile(
                leading: CircleAvatar(backgroundColor: t.color),
                title: Text(t.name),
              )),
          const Divider(),
          ListTile(
            title: const Text('Export to file'),
            onTap: _export,
          ),
          ListTile(
            title: const Text('Import from file'),
            onTap: _import,
          ),
        ],
      ),
    );
  }
}
