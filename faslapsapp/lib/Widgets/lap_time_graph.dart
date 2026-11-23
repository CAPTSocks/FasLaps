import 'dart:math' as math;
import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';

class LapTimeGraph extends StatefulWidget {
  final List<double> lapTimes;

  const LapTimeGraph({super.key, required this.lapTimes});

  @override
  State<LapTimeGraph> createState() => _LapTimeGraphState();
}

class _LapTimeGraphState extends State<LapTimeGraph>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curve;
  late List<double> _displayedLaps;
  List<double>? _previousLaps;
  bool _animateNewest = false;
  bool _droppedOldest = false;

  @override
  void initState() {
    super.initState();
    _displayedLaps = List<double>.of(widget.lapTimes);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _curve = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    // Existing data (including raceSync restores) appears immediately.
    _controller.value = 1;
  }

  @override
  void didUpdateWidget(covariant LapTimeGraph oldWidget) {
    super.didUpdateWidget(oldWidget);

    final next = List<double>.of(widget.lapTimes);
    if (_sameValues(_displayedLaps, next)) return;

    // Animate only an ordinary single-lap append. When the list is full,
    // the first lap falls off as the new one enters from the right.
    final appended = next.length == _displayedLaps.length + 1 &&
        _sameValues(_displayedLaps, next.take(next.length - 1).toList());

    final shifted = next.length == _displayedLaps.length &&
        next.isNotEmpty &&
        _sameValues(_displayedLaps.skip(1).toList(),
            next.take(next.length - 1).toList());

    if (appended || shifted) {
      _previousLaps = List<double>.of(_displayedLaps);
      _animateNewest = true;
      _droppedOldest = shifted;
      _displayedLaps = next;
      _controller.forward(from: 0);
    } else {
      // Race sync, replacement, race reset, and other bulk changes.
      _displayedLaps = next;
      _previousLaps = null;
      _animateNewest = false;
      _droppedOldest = false;
      _controller.value = 1;
    }
  }

  static bool _sameValues(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: AnimatedBuilder(
        animation: _curve,
        builder: (context, _) => CustomPaint(
          painter: LapTimeGraphPainter(
            lapTimes: _displayedLaps,
            previousLaps: _animateNewest ? _previousLaps : null,
            droppedOldest: _droppedOldest,
            animationProgress: _curve.value,
          ),
        ),
      ),
    );
  }
}

class LapTimeGraphPainter extends CustomPainter {
  final List<double> lapTimes;
  final List<double>? previousLaps;
  final bool droppedOldest;
  final double animationProgress;

  LapTimeGraphPainter({
    required this.lapTimes,
    this.previousLaps,
    this.droppedOldest = false,
    required this.animationProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftPadding = 28.0;
    const rightPadding = 4.0;
    const topPadding = 5.0;
    const bottomPadding = 5.0;

    final graphRect = Rect.fromLTRB(
      leftPadding,
      topPadding,
      size.width - rightPadding,
      size.height - bottomPadding,
    );
    if (graphRect.width <= 0 || graphRect.height <= 0) return;

    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.25)
      ..strokeWidth = 1;
    final barPaint = Paint()..style = PaintingStyle.fill;

    if (lapTimes.isEmpty) {
      final emptyText = TextPainter(
        text: const TextSpan(
          text: 'Waiting for lap times...',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      emptyText.paint(
        canvas,
        Offset((size.width - emptyText.width) / 2,
            (size.height - emptyText.height) / 2),
      );
      return;
    }

    final oldLaps = previousLaps;
    final animating = oldLaps != null && animationProgress < 1;
    // Keep the scale stable during the transition so old bars don't jump.
    final maxLap = math.max(
      lapTimes.reduce(math.max),
      animating && oldLaps.isNotEmpty ? oldLaps.reduce(math.max) : 0.0,
    );
    final maxTime = math.max(1.0, (maxLap * 1.15).ceilToDouble());
    final graphHeight = graphRect.height;
    final graphWidth = graphRect.width;

    const divisions = 4;
    for (int i = 0; i <= divisions; i++) {
      final fraction = i / divisions;
      final y = graphRect.bottom - fraction * graphHeight;
      canvas.drawLine(Offset(graphRect.left, y),
          Offset(graphRect.right, y), gridPaint);

      final timeValue = maxTime * fraction;
      final label = timeValue == timeValue.roundToDouble()
          ? '${timeValue.toInt()}s'
          : '${timeValue.toStringAsFixed(1)}s';
      final text = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(color: Colors.grey, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas,
          Offset(leftPadding - text.width - 8, y - text.height / 2));
    }

    // Clip bars and labels to avoid painting outside the graph while moving.
    canvas.save();
    canvas.clipRect(graphRect.inflate(0.5));

    final newSlotWidth = graphWidth / lapTimes.length;
    final oldSlotWidth = oldLaps == null || oldLaps.isEmpty
        ? newSlotWidth
        : graphWidth / oldLaps.length;
    final barWidth = newSlotWidth * 0.62;
    final fastestLap = lapTimes.reduce(math.min);

    for (int i = 0; i < lapTimes.length; i++) {
      final lapTime = lapTimes[i];
      final targetX = graphRect.left + (i + 0.5) * newSlotWidth;
      final isNewest = i == lapTimes.length - 1;

      double centerX = targetX;
      if (animating && !isNewest) {
        final oldIndex = droppedOldest ? i + 1 : i;
        final startX = graphRect.left + (oldIndex + 0.5) * oldSlotWidth;
        centerX = lerpDouble(startX, targetX, animationProgress)!;
      }

      // All existing bars stay at full height. Only the new bar grows.
      final heightFraction = animating && isNewest ? animationProgress : 1.0;
      final barHeight = (lapTime / maxTime) * graphHeight * heightFraction;
      final barTop = graphRect.bottom - barHeight;
      final barRect = Rect.fromLTRB(
        centerX - barWidth / 2,
        barTop,
        centerX + barWidth / 2,
        graphRect.bottom,
      );

      if (lapTime == fastestLap) {
        barPaint.color = Colors.orange;
      } else if (isNewest) {
        barPaint.color = const Color(0xFF22C55E);
      } else {
        barPaint.color = const Color(0xFF3987C9);
      }

      canvas.drawRRect(
        RRect.fromRectAndCorners(
          barRect,
          topLeft: const Radius.circular(4),
          topRight: const Radius.circular(4),
        ),
        barPaint,
      );

      if (lapTimes.length <= 15) {
        final lapLabel = TextPainter(
          text: TextSpan(
            text: '${lapTime.toStringAsFixed(2)}s',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        lapLabel.paint(
          canvas,
          Offset(centerX - lapLabel.width / 2, barTop - lapLabel.height - 4),
        );
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant LapTimeGraphPainter oldDelegate) {
    if (oldDelegate.animationProgress != animationProgress ||
        oldDelegate.droppedOldest != droppedOldest ||
        oldDelegate.previousLaps != previousLaps ||
        oldDelegate.lapTimes.length != lapTimes.length) {
      return true;
    }
    for (int i = 0; i < lapTimes.length; i++) {
      if (oldDelegate.lapTimes[i] != lapTimes[i]) return true;
    }
    return false;
  }
}
