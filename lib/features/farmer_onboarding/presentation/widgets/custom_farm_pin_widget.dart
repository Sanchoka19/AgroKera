import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';

/// 1:1 Vector Barn Pin Painter matching user's reference in AgroKera brand colors
class AgroKeraBarnPinPainter extends CustomPainter {
  final Color pinColor;
  final Color innerColor;

  const AgroKeraBarnPinPainter({
    this.pinColor = AppColors.primary,
    this.innerColor = Colors.white,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = w / 2;
    final cx = r;
    final cy = r;
    final tipX = r;
    final tipY = h;

    // 1. Soft Ground Contact Shadow (horizontal oval)
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, tipY + 2.5),
        width: w * 0.44,
        height: 5.5,
      ),
      shadowPaint,
    );

    // 2. Exact Teardrop Geometry
    final d = tipY - cy;
    final sinA = (r / d).clamp(0.0, 1.0);
    final a = math.asin(sinA);

    final leftTangentX = cx - r * sinA;
    final leftTangentY = cy + r * math.cos(a);

    final pinPath = Path()
      ..moveTo(tipX, tipY)
      ..lineTo(leftTangentX, leftTangentY)
      ..arcTo(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        math.pi / 2 + a,
        2 * math.pi - 2 * a,
        false,
      )
      ..lineTo(tipX, tipY)
      ..close();

    // Fill pin body with AgroKera emerald green
    final pinPaint = Paint()
      ..color = pinColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(pinPath, pinPaint);

    // Crisp white outer contour for high contrast over any map tiles
    final pinBorderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    canvas.drawPath(pinPath, pinBorderPaint);

    // 3. Inner White Circle
    final innerR = r * 0.74;
    final innerPaint = Paint()
      ..color = innerColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), innerR, innerPaint);

    // 4. Iconic Barn Vector Icon inside White Circle
    final wb = innerR * 1.34;
    final hb = innerR * 1.30;

    final barnBottom = cy + hb * 0.44;
    final roofApexY = cy - hb * 0.44;
    final eaveY = cy - hb * 0.04;

    final wallLeft = cx - wb * 0.36;
    final wallRight = cx + wb * 0.36;
    final roofLeft = cx - wb * 0.48;
    final roofRight = cx + wb * 0.48;

    final barnPaint = Paint()
      ..color = pinColor
      ..style = PaintingStyle.fill;

    // A) Ground line
    final groundPaint = Paint()
      ..color = pinColor
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(cx - wb * 0.50, barnBottom),
      Offset(cx + wb * 0.50, barnBottom),
      groundPaint,
    );

    // B) Outer Roof Stroke / Fascia (creates double-roof architectural silhouette)
    final outerRoofPath = Path()
      ..moveTo(roofLeft - 0.5, eaveY + 2.5)
      ..lineTo(cx, roofApexY)
      ..lineTo(roofRight + 0.5, eaveY + 2.5);
    final outerRoofPaint = Paint()
      ..color = pinColor
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(outerRoofPath, outerRoofPaint);

    // C) Main Barn Building Body (Gable + Walls)
    final barnBodyPath = Path()
      ..moveTo(wallLeft, barnBottom - 1.8)
      ..lineTo(wallLeft, eaveY + 0.5)
      ..lineTo(cx, roofApexY + 3.2)
      ..lineTo(wallRight, eaveY + 0.5)
      ..lineTo(wallRight, barnBottom - 1.8)
      ..close();
    canvas.drawPath(barnBodyPath, barnPaint);

    // D) Attic 4-Pane Square Window
    final winTop = cy - hb * 0.24;
    final paneSize = innerR * 0.12;
    final gap = innerR * 0.06;
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(cx - paneSize - gap / 2, winTop, paneSize, paneSize), whitePaint);
    canvas.drawRect(Rect.fromLTWH(cx + gap / 2, winTop, paneSize, paneSize), whitePaint);
    canvas.drawRect(Rect.fromLTWH(cx - paneSize - gap / 2, winTop + paneSize + gap, paneSize, paneSize), whitePaint);
    canvas.drawRect(Rect.fromLTWH(cx + gap / 2, winTop + paneSize + gap, paneSize, paneSize), whitePaint);

    // E) Barn Door with "X" Crossbuck Brace
    final doorW = wb * 0.36;
    final doorTop = cy + hb * 0.04;
    final doorBottom = barnBottom - 1.8;
    final doorLeft = cx - doorW / 2;
    final doorRight = cx + doorW / 2;
    final doorRect = Rect.fromLTRB(doorLeft, doorTop, doorRight, doorBottom);

    // White door surface
    canvas.drawRect(doorRect, whitePaint);

    // Door frame
    final doorFramePaint = Paint()
      ..color = pinColor
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;
    canvas.drawRect(doorRect, doorFramePaint);

    // "X" cross brace
    canvas.drawLine(Offset(doorLeft, doorTop), Offset(doorRight, doorBottom), doorFramePaint);
    canvas.drawLine(Offset(doorRight, doorTop), Offset(doorLeft, doorBottom), doorFramePaint);
  }

  @override
  bool shouldRepaint(covariant AgroKeraBarnPinPainter oldDelegate) {
    return oldDelegate.pinColor != pinColor || oldDelegate.innerColor != innerColor;
  }
}

/// Custom Farm Pin Widget with Dynamic Address Pill & 1:1 Vector Barn Pin
class CustomFarmPinWidget extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const CustomFarmPinWidget({
    super.key,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Dynamic Address Tooltip Bubble above Pin (tappable to view full address)
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary, width: 1.4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.navigation, size: 12, color: AppColors.primary),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  LucideIcons.chevronRight,
                  size: 11,
                  color: Color(0xFF64748B),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 3),

        // 1:1 Vector Barn Pin
        CustomPaint(
          size: const Size(36, 48),
          painter: const AgroKeraBarnPinPainter(
            pinColor: AppColors.primary,
            innerColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
