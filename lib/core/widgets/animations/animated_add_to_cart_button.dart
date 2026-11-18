import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/app_colors.dart';

/// Interactive Add-to-Cart circular button with brief checkmark feedback animation.
/// When pressed, transitions smoothly from '+' to a confirmed checkmark for 700ms
/// before reverting, giving immediate tactile and visual satisfaction.
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
      duration: const Duration(milliseconds: 140),
      lowerBound: 0.85,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  /// Triggers the checkmark feedback state
  void triggerSuccessFeedback() {
    if (!mounted) return;
    setState(() => _isChecked = true);
    _scaleController.reverse().then((_) {
      if (mounted) _scaleController.forward();
    });

    Future.delayed(const Duration(milliseconds: 700), () {
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
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFFCBD5E1),
            width: 1,
          ),
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
                color: bgColor.withValues(alpha: 0.35),
                blurRadius: _isChecked ? 8 : 4,
                spreadRadius: _isChecked ? 1 : 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: animation,
              child: child,
            ),
            child: _isChecked
                ? const Icon(
                    LucideIcons.check,
                    key: ValueKey('checked'),
                    size: 18,
                    color: Colors.white,
                  )
                : const Icon(
                    LucideIcons.plus,
                    key: ValueKey('plus'),
                    size: 18,
                    color: AppColors.textOnPrimary,
                  ),
          ),
        ),
      ),
    );
  }
}
