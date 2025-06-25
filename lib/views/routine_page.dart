import 'package:flutter/material.dart';
import '../models/routine.dart';
import '../services/routine_service.dart';
import '../widgets/routine_tile.dart';

class RoutinePage extends StatefulWidget {
  const RoutinePage({super.key});

  @override
  State<RoutinePage> createState() => _RoutinePageState();
}

class _RoutinePageState extends State<RoutinePage> {
  final RoutineService _service = RoutineService();
  List<Routine> _routines = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final routines = await _service.getRoutines();
    setState(() {
      _routines = routines;
    });
  }

  String _weekdayLabel(int day) => ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][day-1];


  Future<void> _openForm({Routine? routine}) async {
    final bool isNew = routine == null;
    final nameController = TextEditingController(text: routine?.title ?? '');
    RepeatType type = routine?.repeatType ?? RepeatType.daily;
    Set<int> selected = {
      ...(routine?.weekdays ?? (type == RepeatType.daily ? [1, 2, 3, 4, 5, 6, 7] : []))
    };
    bool active = routine?.isActive ?? true;
    final durationController =
        TextEditingController(text: routine?.durationMinutes?.toString() ?? '');

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: StatefulBuilder(
            builder: (context, setModal) {
              Widget daySelector() {
                return Wrap(
                  spacing: 4,
                  children: List.generate(7, (index) {
                    final day = index + 1;
                    final sel = selected.contains(day);
                    return FilterChip(
                      label: Text(_weekdayLabel(day)),
                      selected: sel,
                      onSelected: (val) {
                        setModal(() {
                          if (val) {
                            selected.add(day);
                          } else {
                            selected.remove(day);
                          }
                        });
                      },
                    );
                  }),
                );
              }

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    const SizedBox(height: 8),
                    RadioListTile<RepeatType>(
                      title: const Text('Daily'),
                      value: RepeatType.daily,
                      groupValue: type,
                      onChanged: (val) => setModal(() => type = val!),
                    ),
                    RadioListTile<RepeatType>(
                      title: const Text('Weekly'),
                      value: RepeatType.weekly,
                      groupValue: type,
                      onChanged: (val) => setModal(() => type = val!),
                    ),
                    RadioListTile<RepeatType>(
                      title: const Text('Custom'),
                      value: RepeatType.custom,
                      groupValue: type,
                      onChanged: (val) => setModal(() => type = val!),
                    ),
                    if (type != RepeatType.daily)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: daySelector(),
                      ),
                    TextField(
                      controller: durationController,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Duration (minutes)'),
                    ),
                    SwitchListTile(
                      title: const Text('Active'),
                      value: active,
                      onChanged: (val) => setModal(() => active = val),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (!isNew)
                          TextButton(
                            onPressed: () => Navigator.pop(context, 'delete'),
                            child: const Text('Delete'),
                          ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, 'save'),
                          child: Text(isNew ? 'Add' : 'Save'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    if (result == 'delete' && routine != null) {
      await _service.deleteRoutine(routine);
      _load();
    } else if (result == 'save') {
      final list = <int>[];
      switch (type) {
        case RepeatType.daily:
          list.addAll([1,2,3,4,5,6,7]);
          break;
        case RepeatType.weekly:
          if (selected.isNotEmpty) {
            list.add(selected.first);
          }
          break;
        case RepeatType.custom:
          list.addAll(selected.toList()..sort());
          break;
      }
      int? dur;
      if (durationController.text.trim().isNotEmpty) {
        final val = int.tryParse(durationController.text.trim());
        if (val == null || val < 5 || val > 300) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Duration must be between 5 and 300')),
            );
          }
          return;
        }
        dur = val;
      }
      if (isNew) {
        final r = Routine(
          title: nameController.text,
          repeatType: type,
          weekdays: list,
          isActive: active,
          durationMinutes: dur,
        );
        await _service.addRoutine(r);
      } else {
        routine.title = nameController.text;
        routine.repeatType = type;
        routine.weekdays = list;
        routine.isActive = active;
        routine.durationMinutes = dur;
        await _service.updateRoutine(routine);
      }
      _load();
    }
  }

  Widget _buildItem(Routine r) {
    return RoutineTile(
      routine: r,
      showActiveSwitch: true,
      onActiveChanged: (val) async {
        r.isActive = val;
        await _service.updateRoutine(r);
        setState(() {});
      },
      onTap: () => _openForm(routine: r),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Routines')),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: _routines.map(_buildItem).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
