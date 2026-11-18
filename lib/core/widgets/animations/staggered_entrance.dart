import 'package:flutter/material.dart';
import '../../network/api_client.dart';

/// Staggered Entrance Animation for list and grid items.
/// Gently fades and slides items up sequentially (40ms offset per item)
/// upon screen entrance for a smooth, high-end visual experience.
class StaggeredEntrance extends StatefulWidget {
  final int index;
  final Widget child;
  final Duration delayPerItem;
  final Duration duration;
  final Offset slideOffset;
  final Curve curve;

  const StaggeredEntrance({
    super.key,
    required this.index,
    required this.child,
    this.delayPerItem = const Duration(milliseconds: 35),
    this.duration = const Duration(milliseconds: 320),
    this.slideOffset = const Offset(0.0, 0.08),
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    _slideAnimation = Tween<Offset>(
      begin: widget.slideOffset,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ),
    );

    if (isFlutterTestEnv) {
      _controller.value = 1.0;
    } else {
      final cappedIndex = widget.index.clamp(0, 8);
      final initialDelay = widget.delayPerItem * cappedIndex;
      Future.delayed(initialDelay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isFlutterTestEnv) {
      return widget.child;
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
