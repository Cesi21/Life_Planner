import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/app_theme.dart';
import '../models/tag.dart';
import '../services/backup_service.dart';
import '../services/tag_service.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  AppTheme _theme = AppTheme.system;
  final TagService _tagService = TagService();
  List<Tag> _tags = [];
  bool _autoBackup = false;

  @override
  void initState() {
    super.initState();
    final box = Hive.box('settings');
    _theme = AppTheme.values[box.get('theme', defaultValue: 0) as int];
    _autoBackup = box.get('autoBackup', defaultValue: false) as bool;
    _loadTags();
  }

  void _setTheme(AppTheme val) async {
    final box = Hive.box('settings');
    await box.put('theme', val.index);
    setState(() => _theme = val);
  }

  void _loadTags() async {
    _tags = await _tagService.getAllTags();
    setState(() {});
  }

  Future<void> _setAutoBackup(bool val) async {
    final box = Hive.box('settings');
    await box.put('autoBackup', val);
    setState(() => _autoBackup = val);
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
      final success =
          await _tagService.addTag(Tag(name: nameController.text, color: selected));
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tag name already exists')),
        );
      }
      _loadTags();
    }
  }

  Future<void> _editTag(Tag tag) async {
    final nameController = TextEditingController(text: tag.name);
    Color selected = tag.color;
    final colors = [Colors.red, Colors.green, Colors.blue, Colors.orange, Colors.purple, Colors.teal];
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Tag'),
        content: StatefulBuilder(
          builder: (context, setDialog) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: colors.map((c) => GestureDetector(
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
                    )).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );
    if (result == true && nameController.text.isNotEmpty) {
      tag.name = nameController.text;
      tag.color = selected;
      final success = await _tagService.updateTag(tag);
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tag name already exists')),
        );
      }
      _loadTags();
    }
  }

  Future<void> _deleteTag(Tag tag) async {
    await _tagService.deleteTag(tag);
    _loadTags();
  }

  Future<void> _export() async {
    if (kIsWeb) {
      await showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          content: Text('Not supported on web'),
        ),
      );
      return;
    }
    try {
      final path = await BackupService().exportAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported to $path')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export failed')),
        );
      }
    }
  }

  Future<void> _import() async {
    if (kIsWeb) {
      await showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          content: Text('Not supported on web'),
        ),
      );
      return;
    }
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      try {
        await BackupService().importAll(file);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Import complete')),
          );
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Import failed')),
          );
        }
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
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      onPressed: () => _editTag(t),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 18),
                      onPressed: () => _deleteTag(t),
                    ),
                  ],
                ),
              )),
          const Divider(),
          SwitchListTile(
            title: const Text('Daily auto-backup'),
            value: _autoBackup,
            onChanged: _setAutoBackup,
          ),
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
