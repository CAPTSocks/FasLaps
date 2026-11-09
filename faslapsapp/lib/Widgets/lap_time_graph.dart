import 'dart:math' as math;
import 'package:flutter/material.dart';

class LapTimeGraph extends StatefulWidget {
  final List<double> lapTimes;

  const LapTimeGraph({super.key, required this.lapTimes});

  @override
  State<LapTimeGraph> createState() => _LapTimeGraphState();
}

class _LapTimeGraphState extends State<LapTimeGraph>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late Animation<double> _barAnimation;
  int _lastLapCount = 0;
  double? _lastNewestLapTime;

  @override
  void initState() {
    super.initState();

    _lastLapCount = widget.lapTimes.length;
    _lastNewestLapTime = widget.lapTimes.isNotEmpty
        ? widget.lapTimes.last
        : null;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _barAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    _animationController.forward();
  }

  @override
  void didUpdateWidget(covariant LapTimeGraph oldWidget) {
    super.didUpdateWidget(oldWidget);

    final currentLapCount = widget.lapTimes.length;
    final currentNewestLapTime = widget.lapTimes.isNotEmpty
        ? widget.lapTimes.last
        : null;

    final newLapReceived =
        currentLapCount > _lastLapCount ||
        currentNewestLapTime != _lastNewestLapTime;

    // Update our saved values for the next comparison.
    _lastLapCount = currentLapCount;
    _lastNewestLapTime = currentNewestLapTime;

    if (newLapReceived) {
      _animationController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _barAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(double.infinity, 110),
          painter: LapTimeGraphPainter(
            lapTimes: widget.lapTimes,
            animationProgress: _barAnimation.value,
          ),
        );
      },
    );
  }
}

class LapTimeGraphPainter extends CustomPainter {
  final List<double> lapTimes;
  final double animationProgress;

  LapTimeGraphPainter({
    required this.lapTimes,
    required this.animationProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftPadding = 20.0;
    const rightPadding = 4.0;
    const topPadding = 5.0;
    const bottomPadding = 5.0;

    final graphRect = Rect.fromLTRB(
      leftPadding,
      topPadding,
      size.width - rightPadding,
      size.height - bottomPadding,
    );

    // Paint objects
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.25)
      ..strokeWidth = 1;

    final barPaint = Paint()..style = PaintingStyle.fill;

    // Handle empty graph
    if (lapTimes.isEmpty) {
      final emptyText = TextPainter(
        text: const TextSpan(
          text: 'Waiting for lap times...',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        textDirection: TextDirection.ltr,
      );

      emptyText.layout();
      emptyText.paint(
        canvas,
        Offset(
          (size.width - emptyText.width) / 2,
          size.height / 2 - emptyText.height / 2,
        ),
      );
      return;
    }

    // Determine graph maximum.
    final longestLap = lapTimes.reduce(math.max);
    final maxTime = math.max(1.0, (longestLap * 1.15).ceilToDouble());

    final graphHeight = graphRect.height;
    final graphWidth = graphRect.width;

    // Draw horizontal grid lines and Y-axis labels.
    const divisions = 4;

    for (int i = 0; i <= divisions; i++) {
      final fraction = i / divisions;

      final y = graphRect.bottom - (fraction * graphHeight);

      canvas.drawLine(
        Offset(graphRect.left, y),
        Offset(graphRect.right, y),
        gridPaint,
      );

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
      );

      text.layout();

      text.paint(
        canvas,
        Offset(leftPadding - text.width - 8, y - text.height / 2),
      );
    }

    // Calculate bar dimensions.
    final barSlotWidth = graphWidth / lapTimes.length;
    final barWidth = barSlotWidth * 0.62;

    // Draw each lap.
    for (int i = 0; i < lapTimes.length; i++) {
      final lapTime = lapTimes[i];

      final barHeight = (lapTime / maxTime) * graphHeight * animationProgress;

      final centerX = graphRect.left + (i * barSlotWidth) + (barSlotWidth / 2);

      final barTop = graphRect.bottom - barHeight;

      final barRect = Rect.fromLTRB(
        centerX - barWidth / 2,
        barTop,
        centerX + barWidth / 2,
        graphRect.bottom,
      );

      // Highlight the fastest lap in orange.
      // Otherwise, highlight the newest lap in green.
      // All other laps are blue.
      final fastestLap = lapTimes.reduce(math.min);

      if (lapTime == fastestLap) {
        barPaint.color = Colors.orange;
      } else if (i == lapTimes.length - 1) {
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

      // Only draw lap labels if there are 15 or fewer bars.
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
        );

        lapLabel.layout();

        lapLabel.paint(
          canvas,
          Offset(centerX - lapLabel.width / 2, barTop - lapLabel.height - 4),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant LapTimeGraphPainter oldDelegate) {
    if (oldDelegate.animationProgress != animationProgress) {
      return true;
    }

    if (oldDelegate.lapTimes.length != lapTimes.length) {
      return true;
    }

    for (int i = 0; i < lapTimes.length; i++) {
      if (oldDelegate.lapTimes[i] != lapTimes[i]) {
        return true;
      }
    }

    return false;
  }
}
