import 'dart:async';

import 'package:flutter/material.dart';
import '../models/routine.dart';
import '../services/routine_service.dart';

class RoutineTile extends StatefulWidget {
  final Routine routine;
  final bool? completed;
  final DateTime? date;
  final ValueChanged<bool>? onCompleted;
  final ValueChanged<bool>? onActiveChanged;
  final VoidCallback? onTap;
  final bool showActiveSwitch;

  const RoutineTile({
    super.key,
    required this.routine,
    this.completed,
    this.date,
    this.onCompleted,
    this.onActiveChanged,
    this.onTap,
    this.showActiveSwitch = false,
  });

  @override
  State<RoutineTile> createState() => _RoutineTileState();
}

class _RoutineTileState extends State<RoutineTile> {
  Timer? _timer;
  int _remaining = 0;

  bool get _running => _timer?.isActive ?? false;

  bool get _isToday {
    if (widget.date == null) return false;
    final now = DateTime.now();
    return now.year == widget.date!.year &&
        now.month == widget.date!.month &&
        now.day == widget.date!.day;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startTimer() async {
    final dur = widget.routine.duration;
    if (dur == null || !_isToday) return;
    setState(() {
      _remaining = dur.inSeconds;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining <= 1) {
        t.cancel();
        _complete();
      } else {
        setState(() => _remaining--);
      }
    });
  }

  Future<void> _complete() async {
    if (widget.date != null) {
      await RoutineService()
          .markRoutineDone(widget.routine.key.toString(), widget.date!);
      widget.onCompleted?.call(true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${widget.routine.title} complete!")),
        );
        setState(() {});
      }
    }
  }

  Future<void> _reset() async {
    if (widget.date != null) {
      await RoutineService()
          .unmarkRoutineDone(widget.routine.key.toString(), widget.date!);
      widget.onCompleted?.call(false);
      setState(() {});
    }
  }

  Widget _buildDays() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(7, (i) {
        final active = widget.routine.weekdays.contains(i + 1);
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

  Widget _buildTimerWidget() {
    final dur = widget.routine.duration!;
    final progress = 1 - _remaining / dur.inSeconds;
    final min = (_remaining ~/ 60).toString().padLeft(2, '0');
    final sec = (_remaining % 60).toString().padLeft(2, '0');
    return SizedBox(
      width: 32,
      height: 32,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(value: progress),
          Text('$min:$sec', style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final done = widget.completed ?? false;
    final widgets = <Widget>[];
    if (widget.routine.duration != null && _isToday) {
      widgets.add(
        _running
            ? _buildTimerWidget()
            : IconButton(
                icon: const Icon(Icons.play_arrow),
                onPressed: done ? null : _startTimer,
              ),
      );
    }
    if (widget.showActiveSwitch) {
      widgets.add(
        Switch(
          value: widget.routine.isActive,
          onChanged: widget.onActiveChanged,
        ),
      );
    } else {
      widgets.add(
        Checkbox(
          value: done,
          onChanged: _running || !_isToday
              ? null
              : (val) => widget.onCompleted?.call(val ?? false),
        ),
      );
    }

    return Card(
      color: widget.showActiveSwitch
          ? null
          : Colors.purpleAccent.withOpacity(0.1),
      child: ListTile(
        title: Text(widget.routine.title),
        subtitle: _buildDays(),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: widgets),
        onTap: widget.onTap,
        onLongPress: _isToday ? _reset : null,
      ),
    );
  }
}
