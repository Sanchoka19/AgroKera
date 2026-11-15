import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum ToastType {
  success,
  error,
  info,
  warning,
}

/// Global Modern Top Toast Notification for AgroKera.
/// Renders as a top-floating Dynamic Island capsule with:
/// - Crisp white (#FFFFFF) background with subtle micro-border (#E2E8F0, 0.9px)
/// - Ambient multi-layer elevation shadow
/// - 3D Squircle Icon Badge with vibrant gradient and soft semantic glow
/// - Crisp dark slate text (#0F172A)
/// - Rounded pill quick action button (e.g. "კალათა ➔")
/// - Smooth slide-down & fade animations, auto-dismiss, and swipe-up to dismiss.
class AppToast {
  static OverlayEntry? _currentEntry;

  /// Display a top-floating pill toast.
  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.success,
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(milliseconds: 2800),
  }) {
    if (!context.mounted) return;
    HapticFeedback.lightImpact();

    // Dismiss any active toast immediately
    dismiss();

    final overlay =
        Overlay.maybeOf(context, rootOverlay: true) ?? Overlay.of(context);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _TopToastWidget(
        message: message,
        type: type,
        icon: icon,
        actionLabel: actionLabel,
        onAction: onAction,
        duration: duration,
        onDismiss: () {
          if (_currentEntry == entry) {
            _currentEntry = null;
          }
          if (entry.mounted) {
            try {
              entry.remove();
            } catch (_) {}
          }
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }

  /// Manually dismiss current active toast.
  static void dismiss() {
    if (_currentEntry != null) {
      try {
        if (_currentEntry!.mounted) {
          _currentEntry!.remove();
        }
      } catch (_) {}
      _currentEntry = null;
    }
  }

  static void success(
    BuildContext context,
    String message, {
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(milliseconds: 2800),
  }) {
    show(
      context,
      message,
      type: ToastType.success,
      icon: icon,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  static void error(
    BuildContext context,
    String message, {
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(milliseconds: 2800),
  }) {
    show(
      context,
      message,
      type: ToastType.error,
      icon: icon,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  static void info(
    BuildContext context,
    String message, {
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(milliseconds: 2800),
  }) {
    show(
      context,
      message,
      type: ToastType.info,
      icon: icon,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  static void warning(
    BuildContext context,
    String message, {
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(milliseconds: 2800),
  }) {
    show(
      context,
      message,
      type: ToastType.warning,
      icon: icon,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }
}

class _TopToastWidget extends StatefulWidget {
  final String message;
  final ToastType type;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Duration duration;
  final VoidCallback onDismiss;

  const _TopToastWidget({
    required this.message,
    required this.type,
    this.icon,
    this.actionLabel,
    this.onAction,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_TopToastWidget> createState() => _TopToastWidgetState();
}

class _TopToastWidgetState extends State<_TopToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  Timer? _autoDismissTimer;
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      reverseDuration: const Duration(milliseconds: 240),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    _controller.forward();

    _autoDismissTimer = Timer(widget.duration, () {
      if (mounted) {
        _dismissWithAnimation();
      }
    });
  }

  void _dismissWithAnimation() {
    if (_isDismissed) return;
    _isDismissed = true;
    _autoDismissTimer?.cancel();
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final IconData effectiveIcon;
    final List<Color> gradientColors;
    final Color glowColor;

    switch (widget.type) {
      case ToastType.success:
        effectiveIcon = widget.icon ?? LucideIcons.badgeCheck;
        gradientColors = const [Color(0xFF10B981), Color(0xFF059669)];
        glowColor = const Color(0xFF10B981).withValues(alpha: 0.35);
        break;
      case ToastType.error:
        effectiveIcon = widget.icon ?? LucideIcons.circleX;
        gradientColors = const [Color(0xFFEF4444), Color(0xFFDC2626)];
        glowColor = const Color(0xFFEF4444).withValues(alpha: 0.35);
        break;
      case ToastType.warning:
        effectiveIcon = widget.icon ?? LucideIcons.circleAlert;
        gradientColors = const [Color(0xFFF59E0B), Color(0xFFD97706)];
        glowColor = const Color(0xFFF59E0B).withValues(alpha: 0.35);
        break;
      case ToastType.info:
        effectiveIcon = widget.icon ?? LucideIcons.badgeInfo;
        gradientColors = const [Color(0xFF0EA5E9), Color(0xFF0284C7)];
        glowColor = const Color(0xFF0EA5E9).withValues(alpha: 0.35);
        break;
    }

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
              child: SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Material(
                    type: MaterialType.transparency,
                    child: Dismissible(
                      key: const ValueKey('app_toast_overlay_dismissible'),
                      direction: DismissDirection.up,
                      onDismissed: (_) {
                        if (!_isDismissed) {
                          _isDismissed = true;
                          _autoDismissTimer?.cancel();
                          widget.onDismiss();
                        }
                      },
                      child: GestureDetector(
                        onTap: () {
                          _dismissWithAnimation();
                        },
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              width: 0.9,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F172A)
                                    .withValues(alpha: 0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                              BoxShadow(
                                color: const Color(0xFF0F172A)
                                    .withValues(alpha: 0.03),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Modern Squircle Icon Badge with Depth & Glow
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: gradientColors,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    width: 1.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: glowColor,
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Icon(
                                    effectiveIcon,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 11),

                              // Message Text
                              Expanded(
                                child: Text(
                                  widget.message,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.notoSansGeorgian(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF0F172A),
                                    letterSpacing: -0.2,
                                    height: 1.25,
                                  ),
                                ),
                              ),

                              // Quick Action Button (Pill shape)
                              if (widget.actionLabel != null &&
                                  widget.onAction != null) ...[
                                const SizedBox(width: 10),
                                GestureDetector(
                                  onTap: () {
                                    _dismissWithAnimation();
                                    widget.onAction!();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFF0F766E),
                                          Color(0xFF0D655E),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF0F766E)
                                              .withValues(alpha: 0.28),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          widget.actionLabel!,
                                          style: GoogleFonts.notoSansGeorgian(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          LucideIcons.arrowRight,
                                          size: 13,
                                          color: Colors.white,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
