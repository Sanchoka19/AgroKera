import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

/// Clean blinking cursor indicator shown inside the currently active empty OTP card
class OtpBlinkingCursor extends StatefulWidget {
  final Color color;

  const OtpBlinkingCursor({
    super.key,
    this.color = AppColors.primary,
  });

  @override
  State<OtpBlinkingCursor> createState() => _OtpBlinkingCursorState();
}

class _OtpBlinkingCursorState extends State<OtpBlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 2.2,
        height: 24,
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

