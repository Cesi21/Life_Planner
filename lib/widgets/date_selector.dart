import 'package:flutter/material.dart';

class DateSelector extends StatelessWidget {
  final DateTime selected;
  final ValueChanged<DateTime> onChanged;

  const DateSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final startOfWeek = selected.subtract(Duration(days: selected.weekday - 1));
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (i) {
        final date = startOfWeek.add(Duration(days: i));
        final isSelected = date.year == selected.year &&
            date.month == selected.month &&
            date.day == selected.day;
        return GestureDetector(
          onTap: () => onChanged(date),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected
                  ? (() {
                      final c = Theme.of(context).colorScheme.primary;
                      return c.withAlpha((c.alpha * 0.2).round());
                    })()
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][i],
                    style: const TextStyle(fontSize: 12)),
                Text('${date.day}'),
              ],
            ),
          ),
        );
      }),
    );
  }
}
