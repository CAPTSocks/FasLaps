import 'dart:math' as math;
import 'package:flutter/material.dart';

class HistoryLapTimeGraph extends StatefulWidget {
  final List<double> lapTimes;

  const HistoryLapTimeGraph({super.key, required this.lapTimes});

  @override
  State<HistoryLapTimeGraph> createState() => _HistoryLapTimeGraphState();
}

class _HistoryLapTimeGraphState extends State<HistoryLapTimeGraph> {
  static const int maxVisibleLaps = 30;
  static const double axisWidth = 40.0;

  final ScrollController _scrollController = ScrollController();

  double _scrollProgress = 0.0;
  bool _isScrollable = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateScrollProgress);
  }

  void _updateScrollProgress() {
    if (!_scrollController.hasClients) return;

    final maxExtent = _scrollController.position.maxScrollExtent;

    setState(() {
      _isScrollable = maxExtent > 0;
      _scrollProgress = maxExtent > 0
          ? (_scrollController.offset / maxExtent).clamp(0.0, 1.0)
          : 0.0;
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateScrollProgress);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lapTimes.isEmpty) {
      return const SizedBox(
        height: 110,
        child: Center(
          child: Text(
            'No lap times available',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final lapTimes = widget.lapTimes;

    return SizedBox(
      height: 136,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;
          final graphViewportWidth = availableWidth - axisWidth;

          final lapWidth = graphViewportWidth / maxVisibleLaps;

          final graphWidth = math.max(
            graphViewportWidth,
            lapWidth * lapTimes.length,
          );

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || !_scrollController.hasClients) return;

            final scrollable = _scrollController.position.maxScrollExtent > 0;

            if (_isScrollable != scrollable) {
              setState(() {
                _isScrollable = scrollable;
              });
            }
          });

          return Column(
            children: [
              SizedBox(
                height: 130,
                child: Row(
                  children: [
                    // Fixed Y-axis labels.
                    SizedBox(
                      width: axisWidth,
                      height: 130,
                      child: CustomPaint(
                        painter: HistoryLapTimeAxisPainter(lapTimes: lapTimes),
                      ),
                    ),

                    // Scrollable graph bars.
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: graphWidth,
                          height: 130,
                          child: CustomPaint(
                            painter: HistoryLapTimeGraphPainter(
                              lapTimes: lapTimes,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (_isScrollable)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _scrollProgress,
                      minHeight: 3,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color.fromARGB(255, 10, 113, 240),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class HistoryLapTimeAxisPainter extends CustomPainter {
  final List<double> lapTimes;

  HistoryLapTimeAxisPainter({required this.lapTimes});

  @override
  void paint(Canvas canvas, Size size) {
    const topPadding = 20.0;
    const bottomPadding = 18.0;

    if (lapTimes.isEmpty) return;

    final longestLap = lapTimes.reduce(math.max);
    final maxTime = math.max(1.0, (longestLap * 1.15).ceilToDouble());

    final graphHeight = size.height - topPadding - bottomPadding;

    const divisions = 4;

    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.25)
      ..strokeWidth = 1;

    for (int i = 0; i <= divisions; i++) {
      final fraction = i / divisions;
      final y = size.height - bottomPadding - fraction * graphHeight;

      // Draw the grid line up to the edge of the axis.
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);

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
        Offset(size.width - text.width - 4, y - text.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant HistoryLapTimeAxisPainter oldDelegate) {
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

class HistoryLapTimeGraphPainter extends CustomPainter {
  final List<double> lapTimes;

  HistoryLapTimeGraphPainter({required this.lapTimes});

  double _calculateMedian() {
    final sortedTimes = List<double>.of(lapTimes)..sort();

    final middle = sortedTimes.length ~/ 2;

    if (sortedTimes.length.isOdd) {
      return sortedTimes[middle];
    }

    return (sortedTimes[middle - 1] + sortedTimes[middle]) / 2;
  }

  @override
  void paint(Canvas canvas, Size size) {
    const rightPadding = 4.0;
    const topPadding = 20.0;
    const bottomPadding = 18.0;

    final graphRect = Rect.fromLTRB(
      0,
      topPadding,
      size.width - rightPadding,
      size.height - bottomPadding,
    );

    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.25)
      ..strokeWidth = 1;

    final barPaint = Paint()..style = PaintingStyle.fill;

    if (lapTimes.isEmpty) return;

    final longestLap = lapTimes.reduce(math.max);
    final maxTime = math.max(1.0, (longestLap * 1.15).ceilToDouble());

    final graphHeight = graphRect.height;
    final graphWidth = graphRect.width;

    // Draw horizontal grid lines.
    const divisions = 4;

    for (int i = 0; i <= divisions; i++) {
      final fraction = i / divisions;
      final y = graphRect.bottom - fraction * graphHeight;

      canvas.drawLine(
        Offset(graphRect.left, y),
        Offset(graphRect.right, y),
        gridPaint,
      );

      // Draw median lap time line.
      final medianLap = _calculateMedian();

      final medianY = graphRect.bottom - (medianLap / maxTime) * graphHeight;

      final medianPaint = Paint()
        ..color = Colors.purpleAccent
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      const dashWidth = 6.0;
      const dashSpace = 4.0;

      double startX = graphRect.left;

      while (startX < graphRect.right) {
        final endX = math.min(startX + dashWidth, graphRect.right);

        canvas.drawLine(
          Offset(startX, medianY),
          Offset(endX, medianY),
          medianPaint,
        );

        startX += dashWidth + dashSpace;
      }
    }

    // Calculate bar dimensions.
    final barSlotWidth = graphWidth / lapTimes.length;
    final barWidth = barSlotWidth * 0.62;

    final fastestLap = lapTimes.reduce(math.min);

    // Draw bars.
    for (int i = 0; i < lapTimes.length; i++) {
      final lapTime = lapTimes[i];

      final barHeight = (lapTime / maxTime) * graphHeight;

      final centerX = graphRect.left + (i * barSlotWidth) + (barSlotWidth / 2);

      final barTop = graphRect.bottom - barHeight;

      final barRect = Rect.fromLTRB(
        centerX - barWidth / 2,
        barTop,
        centerX + barWidth / 2,
        graphRect.bottom,
      );

      if (lapTime == fastestLap) {
        barPaint.color = Colors.orange;
      // } else if (i == lapTimes.length - 1) {
      //   barPaint.color = const Color(0xFF22C55E);
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
    }
  }

  @override
  bool shouldRepaint(covariant HistoryLapTimeGraphPainter oldDelegate) {
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
