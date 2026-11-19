import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/app_colors.dart';

/// Interactive Add-to-Cart circular button with smooth spring-pop feedback animation.
/// On tap, single continuous elastic movement: compresses to 0.88, springs to 1.06,
/// and smoothly settles to 1.0 with a soft checkmark transition and tactile haptic impact.
class AnimatedAddToCartButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isOwner;
  final bool isOutOfStock;
  final double size;

  const AnimatedAddToCartButton({
    super.key,
    required this.onPressed,
    this.isOwner = false,
    this.isOutOfStock = false,
    this.size = 32.0,
  });

  @override
  State<AnimatedAddToCartButton> createState() =>
      AnimatedAddToCartButtonState();
}

class AnimatedAddToCartButtonState extends State<AnimatedAddToCartButton>
    with SingleTickerProviderStateMixin {
  bool _isChecked = false;
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );

    // Continuous single-phase elastic spring sequence: 1.0 -> 0.88 -> 1.06 -> 1.0
    _scaleAnimation = TweenSequence<double>([
      // 1. Soft compression on press
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.88)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 28.0,
      ),
      // 2. Spring pop & overshoot
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.88, end: 1.06)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 42.0,
      ),
      // 3. Smooth settling to resting scale
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.06, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 30.0,
      ),
    ]).animate(_scaleController);
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  /// Triggers the spring pop checkmark feedback state
  void triggerSuccessFeedback() {
    if (!mounted) return;
    setState(() => _isChecked = true);
    HapticFeedback.lightImpact();
    _scaleController.forward(from: 0.0);

    Future.delayed(const Duration(milliseconds: 750), () {
      if (mounted) {
        setState(() => _isChecked = false);
      }
    });
  }

  void _handleTap() {
    if (widget.isOwner || widget.isOutOfStock) {
      widget.onPressed?.call();
      return;
    }

    triggerSuccessFeedback();
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isOwner) {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: const BoxDecoration(
          color: Color(0xFFF1F5F9),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Icon(
          LucideIcons.ban,
          size: 15,
          color: Color(0xFF94A3B8),
        ),
      );
    }

    final bgColor = _isChecked ? const Color(0xFF16A34A) : AppColors.primary;

    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: bgColor.withValues(alpha: _isChecked ? 0.38 : 0.25),
                blurRadius: _isChecked ? 8 : 4,
                spreadRadius: _isChecked ? 1 : 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutBack,
                ),
                child: child,
              ),
            ),
            child: _isChecked
                ? const Icon(
                    LucideIcons.check,
                    key: ValueKey('checked'),
                    size: 17,
                    color: Colors.white,
                  )
                : const Icon(
                    LucideIcons.plus,
                    key: ValueKey('plus'),
                    size: 17,
                    color: AppColors.textOnPrimary,
                  ),
          ),
        ),
      ),
    );
  }
}
