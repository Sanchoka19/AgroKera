import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';

/// Interactive Map Preview & Picker for Farmer Address step
class FarmerMapWidget extends StatelessWidget {
  final bool isFullScreen;
  final VoidCallback? onToggleFullScreen;
  final String locationText;

  const FarmerMapWidget({
    super.key,
    this.isFullScreen = false,
    this.onToggleFullScreen,
    this.locationText = 'კახეთი, გურჯაანი, 1 რაიონი',
  });

  @override
  Widget build(BuildContext context) {
    final mapContent = ClipRRect(
      borderRadius: BorderRadius.circular(isFullScreen ? 0 : 14),
      child: Stack(
        children: [
          // Custom Styled Map Canvas
          Positioned.fill(
            child: CustomPaint(
              painter: _MapCanvasPainter(),
            ),
          ),

          // Central Landmark / Metro station labels
          Positioned(
            left: isFullScreen ? 180 : 100,
            top: isFullScreen ? 260 : 35,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'M',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'Station Square',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                ),
              ],
            ),
          ),

          // Farmer Location Pin (Center)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.sprout, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        locationText,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                const Icon(
                  LucideIcons.mapPin,
                  size: 28,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),

          // Top location pill (Current Address)
          Positioned(
            top: isFullScreen ? 40 : 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(LucideIcons.navigation, size: 12, color: AppColors.primary),
                  SizedBox(width: 4),
                  Text(
                    'მიმდინარე მისამართი',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
          ),

          // Maximize / Minimize button
          Positioned(
            top: isFullScreen ? 40 : 8,
            right: 8,
            child: InkWell(
              onTap: onToggleFullScreen,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  isFullScreen ? LucideIcons.minimize2 : LucideIcons.maximize2,
                  size: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (isFullScreen) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: mapContent,
      );
    }

    return SizedBox(
      height: 120,
      width: double.infinity,
      child: mapContent,
    );
  }
}

class _MapCanvasPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Background terrain
    final bgPaint = Paint()..color = const Color(0xFFF1F5F9);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Minor streets
    final minorStreetPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path1 = Path()
      ..moveTo(0, size.height * 0.3)
      ..lineTo(size.width, size.height * 0.6);
    canvas.drawPath(path1, minorStreetPaint);

    final path2 = Path()
      ..moveTo(size.width * 0.25, 0)
      ..lineTo(size.width * 0.45, size.height);
    canvas.drawPath(path2, minorStreetPaint);

    // Major avenue (soft blue tinted road)
    final majorStreetPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 24
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final mainPath = Path()
      ..moveTo(size.width * 0.1, size.height)
      ..cubicTo(
        size.width * 0.4,
        size.height * 0.5,
        size.width * 0.6,
        size.height * 0.4,
        size.width * 0.9,
        0,
      );
    canvas.drawPath(mainPath, majorStreetPaint);

    // Inner road line
    final innerPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(mainPath, innerPaint);

    // Railway tracks
    final railPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(size.width * 0.7, 0),
      Offset(size.width * 0.85, size.height),
      railPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

