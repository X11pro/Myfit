import 'dart:math' as math;

import 'package:flutter/material.dart';

class CrystalProgressRing extends StatelessWidget {
  const CrystalProgressRing({
    required this.progress,
    required this.child,
    super.key,
    this.size = 150,
  });

  final double progress;
  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CrystalProgressPainter(progress: progress.clamp(0.0, 1.0)),
        child: Center(child: child),
      ),
    );
  }
}

class _CrystalProgressPainter extends CustomPainter {
  const _CrystalProgressPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 16.0;
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const startAngle = -math.pi / 2;
    final sweepAngle = math.pi * 2 * progress;

    final trackShadow = Paint()
      ..color = const Color(0xFF68718B).withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 4
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
    canvas.drawArc(rect, 0, math.pi * 2, false, trackShadow);

    final track = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFFFF), Color(0xFFDCE2ED), Color(0xFFF8FAFE)],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);

    if (progress == 0) {
      return;
    }

    final progressShadow = Paint()
      ..color = const Color(0xFF6551DC).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawArc(rect, startAngle, sweepAngle, false, progressShadow);

    final ring = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF35CFE0), Color(0xFF3187E7), Color(0xFF7750DD)],
        stops: [0, 0.56, 1],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, startAngle, sweepAngle, false, ring);

    final highlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, startAngle, sweepAngle, false, highlight);
  }

  @override
  bool shouldRepaint(_CrystalProgressPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
