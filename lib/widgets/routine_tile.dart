import 'package:flutter/material.dart';
import '../models/routine.dart';

class RoutineTile extends StatelessWidget {
  final Routine routine;
  final ValueChanged<bool>? onActiveChanged;
  final VoidCallback? onTap;

  const RoutineTile({
    super.key,
    required this.routine,
    this.onActiveChanged,
    this.onTap,
  });

  Widget _buildDays() {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(7, (i) {
        final active = routine.weekdays.contains(i + 1);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: CircleAvatar(
            radius: 6,
            backgroundColor: active ? Colors.green : Colors.grey.shade300,
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(routine.title),
        subtitle: _buildDays(),
        trailing: Switch(
          value: routine.isActive,
          onChanged: onActiveChanged,
        ),
        onTap: onTap,
      ),
    );
  }
}
