import 'dart:math';

import 'package:flutter/material.dart';

import '../../domain/daily_targets.dart';

class ProgressLineAreaChart extends StatelessWidget {
  const ProgressLineAreaChart({
    super.key,
    required this.points,
    this.height = 220,
  });

  final List<ProgressPoint> points;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: height,
      child: Column(
        children: [
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: _ProgressLinePainter(
                points: points,
                colorScheme: Theme.of(context).colorScheme,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: points
                .map(
                  (point) => Expanded(
                    child: Column(
                      children: [
                        Text(
                          point.value
                              .toStringAsFixed(point.value >= 10 ? 0 : 1),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          point.label,
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ProgressLinePainter extends CustomPainter {
  _ProgressLinePainter({required this.points, required this.colorScheme});

  final List<ProgressPoint> points;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    const topPadding = 12.0;
    const bottomPadding = 8.0;
    final chartHeight = size.height - topPadding - bottomPadding;
    if (chartHeight <= 0 || points.isEmpty) {
      return;
    }

    var minValue = points.first.value;
    var maxValue = points.first.value;
    for (final point in points) {
      minValue = min(minValue, point.value);
      maxValue = max(maxValue, point.value);
    }
    final valueRange = max(maxValue - minValue, 1.0);
    final stepX = points.length == 1 ? 0.0 : size.width / (points.length - 1);

    final linePath = Path();
    final areaPath = Path();
    final dots = <Offset>[];

    for (var index = 0; index < points.length; index++) {
      final point = points[index];
      final x = stepX * index;
      final normalized = (point.value - minValue) / valueRange;
      final y = topPadding + chartHeight - (normalized * chartHeight);
      final offset = Offset(x, y);
      dots.add(offset);

      if (index == 0) {
        linePath.moveTo(offset.dx, offset.dy);
        areaPath.moveTo(offset.dx, size.height - bottomPadding);
        areaPath.lineTo(offset.dx, offset.dy);
      } else {
        linePath.lineTo(offset.dx, offset.dy);
        areaPath.lineTo(offset.dx, offset.dy);
      }
    }

    final last = dots.last;
    areaPath.lineTo(last.dx, size.height - bottomPadding);
    areaPath.close();

    final gridPaint = Paint()
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.25)
      ..strokeWidth = 1;
    for (var i = 0; i < 3; i++) {
      final y = topPadding + (chartHeight / 2) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final areaPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          colorScheme.primary.withValues(alpha: 0.32),
          colorScheme.tertiary.withValues(alpha: 0.06),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(areaPath, areaPaint);

    final linePaint = Paint()
      ..color = colorScheme.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    final dotPaint = Paint()..color = colorScheme.primary;
    final dotFillPaint = Paint()..color = colorScheme.surface;
    for (final dot in dots) {
      canvas.drawCircle(dot, 5, dotPaint);
      canvas.drawCircle(dot, 2.5, dotFillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressLinePainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.colorScheme != colorScheme;
  }
}
