import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'toast_model.dart';
import 'toast_style_resolver.dart';
import 'toast_target_registry.dart';

/// Interactive UI presentation widget for organic droplet toast.
class ToastView extends StatefulWidget {
  final ToastConfig config;
  final ToastStyle style;
  final VoidCallback onDismissed;

  const ToastView({
    super.key,
    required this.config,
    required this.style,
    required this.onDismissed,
  });

  @override
  State<ToastView> createState() => _ToastViewState();
}

class _ToastViewState extends State<ToastView> with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _exitController;

  Timer? _autoDismissTimer;
  bool _isExiting = false;
  bool _isFlyingToBell = false;

  final GlobalKey _badgeKey = GlobalKey();
  Offset? _flyOrigin;
  Offset? _flyTarget;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );

    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _entranceController.forward();

    _autoDismissTimer = Timer(widget.config.duration, () {
      if (mounted) {
        _startDismiss();
      }
    });
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _entranceController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  void _startDismiss() {
    if (_isExiting) return;
    _isExiting = true;
    _autoDismissTimer?.cancel();

    if (widget.config.sendToBell) {
      _startFlyToBell();
    } else {
      _startStandardDismiss();
    }
  }

  void _startStandardDismiss() {
    _entranceController.reverse().then((_) {
      if (mounted) {
        widget.onDismissed();
      }
    });
  }

  void _startFlyToBell() {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final safeTop = mediaQuery.padding.top;

    Offset start = Offset(screenWidth / 2, safeTop + 24);
    final badgeContext = _badgeKey.currentContext;
    if (badgeContext != null && badgeContext.mounted) {
      final box = badgeContext.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        start = box.localToGlobal(box.size.center(Offset.zero));
      }
    }

    final target = ToastTargetRegistry.getBellTargetPosition() ??
        Offset(screenWidth - 38, safeTop + 26);

    setState(() {
      _flyOrigin = start;
      _flyTarget = target;
      _isFlyingToBell = true;
    });

    _exitController.forward().then((_) {
      if (mounted) {
        widget.onDismissed();
      }
    });
  }

  Offset _evaluateQuadraticBezier(
    double t,
    Offset p0,
    Offset p1,
    Offset p2,
  ) {
    final u = 1.0 - t;
    final tt = t * t;
    final uu = u * u;
    return Offset(
      uu * p0.dx + 2.0 * u * t * p1.dx + tt * p2.dx,
      uu * p0.dy + 2.0 * u * t * p1.dy + tt * p2.dy,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isFlyingToBell && _flyOrigin != null && _flyTarget != null) {
      return _buildFlyingDotOverlay();
    }

    final effectiveIcon = widget.config.icon ?? widget.style.defaultIcon;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        top: true,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: AnimatedBuilder(
                animation: _entranceController,
                builder: (context, child) {
                  final progress = _entranceController.value;

                  // Phase 1: Droplet fall (0.0 to 0.40)
                  // Phase 2: Morph and expand horizontally (0.40 to 1.0)
                  final dropProgress = (progress / 0.40).clamp(0.0, 1.0);
                  final expandProgress = ((progress - 0.40) / 0.60).clamp(0.0, 1.0);

                  final verticalOffset = (1.0 - dropProgress) * -45.0;
                  final contentOpacity = expandProgress.clamp(0.0, 1.0);

                  return Transform.translate(
                    offset: Offset(0, verticalOffset),
                    child: Opacity(
                      opacity: progress.clamp(0.0, 1.0),
                      child: Material(
                        type: MaterialType.transparency,
                        child: Dismissible(
                          key: const ValueKey('toast_dismissible_capsule'),
                          direction: DismissDirection.up,
                          onDismissed: (_) {
                            if (!_isExiting) {
                              _isExiting = true;
                              _autoDismissTimer?.cancel();
                              widget.onDismissed();
                            }
                          },
                          child: GestureDetector(
                            onTap: _startDismiss,
                            child: _buildToastBody(
                              expandProgress: expandProgress,
                              contentOpacity: contentOpacity,
                              effectiveIcon: effectiveIcon,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToastBody({
    required double expandProgress,
    required double contentOpacity,
    required IconData effectiveIcon,
  }) {
    final curvedExpand = Curves.easeOutCubic.transform(expandProgress);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.style.borderColor,
          width: 0.9,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Left Organic Badge / Droplet origin
          Container(
            key: _badgeKey,
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: widget.style.badgeBgColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                effectiveIcon,
                color: widget.style.iconColor,
                size: 18,
              ),
            ),
          ),

          // Expanding text & action
          Flexible(
            child: ClipRect(
              child: Align(
                alignment: Alignment.centerLeft,
                widthFactor: curvedExpand,
                child: Opacity(
                  opacity: contentOpacity,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10, right: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            widget.config.message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.notoSansGeorgian(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: widget.style.textColor,
                              letterSpacing: -0.2,
                              height: 1.25,
                            ),
                          ),
                        ),
                        if (widget.config.action != null) ...[
                          const SizedBox(width: 10),
                          _buildActionButton(widget.config.action!),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(ToastAction action) {
    return GestureDetector(
      onTap: () {
        _startDismiss();
        action.onAction();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: widget.style.actionBgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              action.label,
              style: GoogleFonts.notoSansGeorgian(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              LucideIcons.arrowRight,
              size: 12,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlyingDotOverlay() {
    final p0 = _flyOrigin!;
    final p2 = _flyTarget!;
    final controlPoint = Offset(
      (p0.dx + p2.dx) / 2.0,
      math.min(p0.dy, p2.dy) - 30.0,
    );

    return AnimatedBuilder(
      animation: _exitController,
      builder: (context, child) {
        final t = Curves.easeInOutCubic.transform(_exitController.value);
        final currentPosition = _evaluateQuadraticBezier(t, p0, controlPoint, p2);

        // Dot scale from 1.0 down to 0.4 at the bell
        final scale = (1.0 - (t * 0.5)).clamp(0.4, 1.0);
        final opacity = (1.0 - (t * 0.2)).clamp(0.0, 1.0);

        return Positioned(
          left: currentPosition.dx - 6.0,
          top: currentPosition.dy - 6.0,
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x66EF4444),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
