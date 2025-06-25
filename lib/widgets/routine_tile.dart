import 'dart:async';

import 'package:flutter/material.dart';
import '../models/routine.dart';
import '../services/routine_service.dart';
import '../services/notification_service.dart';
import '../services/tag_service.dart';
import '../models/tag.dart';

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
  bool _paused = false;
  int _streak = 0;
  bool _done = false;

  bool get _running => _timer?.isActive ?? false;

  bool get _isToday {
    if (widget.date == null) return false;
    final now = DateTime.now();
    return now.year == widget.date!.year &&
        now.month == widget.date!.month &&
        now.day == widget.date!.day;
  }

  @override
  void initState() {
    super.initState();
    final remaining = RoutineService().getRemaining(widget.routine.key.toString());
    if (remaining != null) {
      _remaining = remaining;
      _paused = true;
    }
    RoutineService()
        .getCurrentStreak(widget.routine.key.toString())
        .then((value) => setState(() => _streak = value));
    if (widget.date != null) {
      RoutineService()
          .isRoutineDone(widget.routine.key.toString(), widget.date!)
          .then((d) => setState(() => _done = d));
    } else {
      _done = widget.completed ?? false;
    }
  }

  @override
  void didUpdateWidget(covariant RoutineTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.date != oldWidget.date && _running) {
      _stopTimer();
    }
  }

  @override
  void dispose() {
    if (_timer != null || _paused) {
      NotificationService()
          .cancelRoutineNotification(widget.routine.key.toString(), widget.date ?? DateTime.now());
    }
    _timer?.cancel();
    super.dispose();
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    if (widget.date != null) {
      NotificationService()
          .cancelRoutineNotification(widget.routine.key.toString(), widget.date!);
    }
    RoutineService().clearRemaining(widget.routine.key.toString());
    setState(() {
      _remaining = 0;
      _paused = false;
    });
  }

  Future<void> _startTimer() async {
    final dur = widget.routine.duration;
    if (dur == null || !_isToday) return;
    setState(() {
      _remaining = dur.inSeconds;
      _paused = false;
    });
    _startPeriodic();
    if (widget.date != null) {
      await NotificationService().scheduleRoutineTimerNotification(
          widget.routine, widget.date!, Duration(seconds: _remaining));
    }
  }

  void _startPeriodic() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining <= 1) {
        t.cancel();
        _manualComplete();
      } else {
        setState(() => _remaining--);
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    _timer = null;
    if (widget.date != null) {
      NotificationService()
          .cancelRoutineNotification(widget.routine.key.toString(), widget.date!);
    }
    RoutineService().saveRemaining(widget.routine.key.toString(), _remaining);
    setState(() {
      _paused = true;
    });
  }

  Future<void> _resumeTimer() async {
    if (_remaining <= 0) return;
    _startPeriodic();
    setState(() {
      _paused = false;
    });
    RoutineService().clearRemaining(widget.routine.key.toString());
    if (widget.date != null) {
      await NotificationService().scheduleRoutineTimerNotification(
          widget.routine, widget.date!, Duration(seconds: _remaining));
    }
  }

  Future<void> _complete() async {
    if (widget.date != null) {
      _stopTimer();
      await RoutineService()
          .markRoutineDone(widget.routine.key.toString(), widget.date!);
      RoutineService().clearRemaining(widget.routine.key.toString());
      widget.onCompleted?.call(true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${widget.routine.title} complete!")),
        );
        setState(() {});
      }
    }
  }

  Future<void> _manualComplete() async {
    await _complete();
  }

  Future<void> _reset() async {
    if (widget.date != null) {
      _stopTimer();
      await RoutineService()
          .unmarkRoutineDone(widget.routine.key.toString(), widget.date!);
      RoutineService().clearRemaining(widget.routine.key.toString());
      widget.onCompleted?.call(false);
      setState(() {});
    }
  }

  Widget _buildDays() {
    return Tooltip(
      message: 'Scheduled days',
      child: Row(
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
      ),
    );
  }

  Widget _buildStreak() {
    final icon = _streak > 0
        ? Icons.local_fire_department
        : Icons.local_fire_department_outlined;
    return Tooltip(
      message: 'Current streak',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.orange),
          const SizedBox(width: 2),
          Text('$_streak', style: const TextStyle(fontSize: 12)),
        ],
      ),
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
    final widgets = <Widget>[];
    if (widget.routine.duration != null) {
      if (_running) {
        widgets.addAll([
          _buildTimerWidget(),
          IconButton(
            icon: const Icon(Icons.pause),
            tooltip: 'Pause',
            onPressed: _pauseTimer,
          ),
          IconButton(
            icon: const Icon(Icons.stop),
            tooltip: 'Stop',
            onPressed: _stopTimer,
          ),
        ]);
      } else if (_paused) {
        widgets.addAll([
          _buildTimerWidget(),
          IconButton(
            icon: const Icon(Icons.play_arrow),
            tooltip: 'Resume',
            onPressed: _resumeTimer,
          ),
          IconButton(
            icon: const Icon(Icons.stop),
            tooltip: 'Stop',
            onPressed: _stopTimer,
          ),
        ]);
      } else if (_isToday) {
        widgets.add(
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: _done ? null : _startTimer,
          ),
        );
      } else {
        widgets.add(
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: null,
          ),
        );
      }
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
          value: _done,
          onChanged: _running || !_isToday
              ? null
              : (val) async {
                  _done = val ?? false;
                  setState(() {});
                  await RoutineService()
                      .toggleComplete(widget.routine, widget.date!, _done);
                  widget.onCompleted?.call(_done);
                },
        ),
      );
    }

    final theme = Theme.of(context);
    final baseColor = widget.showActiveSwitch
        ? null
        : Colors.purpleAccent.withOpacity(0.1);
    final completedColor = theme.brightness == Brightness.dark
        ? Colors.grey.shade800.withOpacity(0.3)
        : Colors.grey.shade300;
    final bg = _done ? completedColor : baseColor;

    final titleStyle = TextStyle(
      color: _done
          ? theme.colorScheme.onSurface.withOpacity(0.6)
          : null,
    );

    final child = ListTile(
      leading: _done ? const Icon(Icons.check_circle, color: Colors.green) : null,
      title: Row(
        children: [
          Expanded(child: Text(widget.routine.title, style: titleStyle)),
          if (widget.routine.tagId != null)
            Builder(builder: (context) {
              final tag = TagService().getTagById(widget.routine.tagId!);
              if (tag == null) return const SizedBox();
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                margin: const EdgeInsets.only(left: 4),
                decoration: BoxDecoration(
                  color: tag.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(tag.name, style: const TextStyle(fontSize: 12)),
              );
            }),
        ],
      ),
      subtitle: Row(
        children: [
          _buildDays(),
          const SizedBox(width: 8),
          _buildStreak(),
        ],
      ),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: widgets),
      onTap: widget.onTap,
      onLongPress: _isToday ? _reset : null,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          child,
          if (_done)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.check, color: Colors.green),
            ),
        ],
      ),
    );
  }
}
