import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';

enum ToastType {
  success,
  error,
  info,
  warning,
}

/// Global Modern Top Toast Notification for AgroKera (Option A).
/// Renders as a top-floating Dynamic Island style card with:
/// - Clean white (#FFFFFF) background
/// - Delicate micro-border (#E2E8F0) and ambient shadow
/// - Semantic icon with soft circle badge
/// - Crisp dark slate text (#0F172A)
/// - Deep Emerald Teal (#0F766E) quick action button (e.g. "კალათა ➔")
/// - Smooth slide-down & fade animations, auto-dismiss, and swipe-up to dismiss.
class AppToast {
  static OverlayEntry? _currentEntry;

  /// Display a top-floating pill toast.
  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.success,
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
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(milliseconds: 2800),
  }) {
    show(
      context,
      message,
      type: ToastType.success,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  static void error(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(milliseconds: 2800),
  }) {
    show(
      context,
      message,
      type: ToastType.error,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  static void info(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(milliseconds: 2800),
  }) {
    show(
      context,
      message,
      type: ToastType.info,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  static void warning(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(milliseconds: 2800),
  }) {
    show(
      context,
      message,
      type: ToastType.warning,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }
}

class _TopToastWidget extends StatefulWidget {
  final String message;
  final ToastType type;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Duration duration;
  final VoidCallback onDismiss;

  const _TopToastWidget({
    required this.message,
    required this.type,
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
    IconData icon;
    Color iconColor;
    Color iconBgColor;

    switch (widget.type) {
      case ToastType.success:
        icon = LucideIcons.check;
        iconColor = AppColors.primary; // Deep Emerald Teal (#0F766E)
        iconBgColor = const Color(0xFFCCFBF1); // Soft Mint / Teal 100
        break;
      case ToastType.error:
        icon = LucideIcons.x;
        iconColor = const Color(0xFFDC2626);
        iconBgColor = const Color(0xFFFEE2E2);
        break;
      case ToastType.warning:
        icon = LucideIcons.triangleAlert;
        iconColor = const Color(0xFFD97706);
        iconBgColor = const Color(0xFFFEF3C7);
        break;
      case ToastType.info:
        icon = LucideIcons.info;
        iconColor = const Color(0xFF0284C7);
        iconBgColor = const Color(0xFFE0F2FE);
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
              constraints: const BoxConstraints(maxWidth: 500),
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
                          // Tap anywhere on toast dismisses it
                          _dismissWithAnimation();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F172A)
                                    .withValues(alpha: 0.10),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                              BoxShadow(
                                color: const Color(0xFF0F172A)
                                    .withValues(alpha: 0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Semantic Icon Badge
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: iconBgColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(icon, color: iconColor, size: 16),
                              ),
                              const SizedBox(width: 12),

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

                              // Quick Action Button (e.g. "კალათა ➔")
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
                                      horizontal: 11,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.25),
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
