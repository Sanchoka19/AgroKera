import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Reusable universal Temu-style flying particle animator that shoots an item/quantity
/// badge along a smooth parabolic arc from one widget to another (e.g. Product Card "+" -> Floating Cart).
class FlyToCartAnimator {
  const FlyToCartAnimator._();

  static void run({
    required BuildContext context,
    GlobalKey? fromKey,
    BuildContext? fromContext,
    required GlobalKey toKey,
    required int quantity,
    Duration duration = const Duration(milliseconds: 550),
    VoidCallback? onComplete,
  }) {
    final RenderBox? renderFrom;
    if (fromKey != null) {
      renderFrom = fromKey.currentContext?.findRenderObject() as RenderBox?;
    } else if (fromContext != null && fromContext.mounted) {
      renderFrom = fromContext.findRenderObject() as RenderBox?;
    } else {
      renderFrom = null;
    }

    final renderTo = toKey.currentContext?.findRenderObject() as RenderBox?;

    if (renderFrom == null || renderTo == null) {
      onComplete?.call();
      return;
    }

    final startOffset =
        renderFrom.localToGlobal(renderFrom.size.center(Offset.zero));
    final endOffset = renderTo.localToGlobal(renderTo.size.center(Offset.zero));

    final overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;
    late AnimationController animController;

    animController = AnimationController(
      vsync: overlayState,
      duration: duration,
    );

    overlayEntry = OverlayEntry(
      builder: (context) {
        return AnimatedBuilder(
          animation: animController,
          builder: (context, child) {
            final t = animController.value;
            final curvedT = Curves.easeInOutCubic.transform(t);

            // Interpolated position with parabolic upward arc
            final currentX =
                startOffset.dx + (endOffset.dx - startOffset.dx) * curvedT;
            final distY = (endOffset.dy - startOffset.dy).abs();
            final arcHeight = math.max(90.0, distY * 0.35 + 50.0);
            final currentY = (startOffset.dy +
                    (endOffset.dy - startOffset.dy) * curvedT) -
                (math.sin(t * math.pi) * arcHeight);

            // Dynamic scale: pops quickly at launch, shrinks slightly entering cart
            final double scale;
            if (t < 0.2) {
              scale = 0.4 + (t / 0.2) * 0.75;
            } else if (t > 0.8) {
              scale = 1.15 - ((t - 0.8) / 0.2) * 0.45;
            } else {
              scale = 1.15;
            }

            final opacity =
                t > 0.88 ? ((1.0 - t) / 0.12).clamp(0.0, 1.0) : 1.0;

            return Positioned(
              left: currentX - 17,
              top: currentY - 17,
              child: IgnorePointer(
                child: Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF4D4F), Color(0xFFDC2626)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFFDC2626).withValues(alpha: 0.55),
                            blurRadius: 10,
                            spreadRadius: 2,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '+$quantity',
                          style: GoogleFonts.notoSansGeorgian(
                            color: Colors.white,
                            fontSize: quantity > 99 ? 10 : 12,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    overlayState.insert(overlayEntry);

    animController.forward().then((_) {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
      animController.dispose();

      HapticFeedback.mediumImpact();
      onComplete?.call();
    });
  }
}

