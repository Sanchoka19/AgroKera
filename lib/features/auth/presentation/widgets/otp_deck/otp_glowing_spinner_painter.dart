import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

/// Custom painter for the glowing accent border runner during the verifying phase
class OtpGlowingSpinnerPainter extends CustomPainter {
  final double progress;
  final Color color;

  const OtpGlowingSpinnerPainter({
    required this.progress,
    this.color = AppColors.primary,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(1.2),
      const Radius.circular(14.0),
    );

    final sweepGradient = SweepGradient(
      center: Alignment.center,
      startAngle: 0.0,
      endAngle: math.pi * 2,
      colors: [
        color.withValues(alpha: 0.0),
        color.withValues(alpha: 0.2),
        color,
        color,
      ],
      stops: const [0.0, 0.4, 0.85, 1.0],
      transform: GradientRotation(progress * math.pi * 2),
    );

    final paint = Paint()
      ..shader = sweepGradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant OtpGlowingSpinnerPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

