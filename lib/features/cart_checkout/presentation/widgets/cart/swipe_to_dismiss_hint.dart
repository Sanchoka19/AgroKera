import 'package:flutter/material.dart';

/// Subtle "Peek" hint animation that slides the first item slightly left
/// to reveal the delete action, then bounces back, teaching the user the swipe gesture.
class SwipeToDismissHint extends StatefulWidget {
  final Widget child;
  final VoidCallback? onHintCompleted;

  const SwipeToDismissHint({
    super.key,
    required this.child,
    this.onHintCompleted,
  });

  @override
  State<SwipeToDismissHint> createState() => _SwipeToDismissHintState();
}

class _SwipeToDismissHintState extends State<SwipeToDismissHint>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _animation = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(-0.09, 0.0),
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(-0.09, 0.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 60,
      ),
    ]).animate(_controller);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _controller.forward().then((_) {
          widget.onHintCompleted?.call();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _animation,
      child: widget.child,
    );
  }
}

