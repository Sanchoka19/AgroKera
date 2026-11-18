import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'toast/toast_model.dart';
import 'toast/toast_style_resolver.dart';
import 'toast/toast_view.dart';

export 'toast/toast_model.dart' show ToastType, ToastAction, ToastConfig;
export 'toast/toast_target_registry.dart' show ToastTargetRegistry;

/// Global Toast Notification Service for AgroKera.
/// Uses organic droplet entrance and optional fly-to-bell exit animation.
abstract final class AppToast {
  static OverlayEntry? _currentEntry;

  /// Display a top-floating organic toast notification.
  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.success,
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(milliseconds: 2800),
    bool sendToBell = false,
  }) {
    if (!context.mounted) return;
    HapticFeedback.lightImpact();

    dismiss();

    final overlay =
        Overlay.maybeOf(context, rootOverlay: true) ?? Overlay.of(context);

    final config = ToastConfig(
      message: message,
      type: type,
      icon: icon,
      action: (actionLabel != null && onAction != null)
          ? ToastAction(label: actionLabel, onAction: onAction)
          : null,
      duration: duration,
      sendToBell: sendToBell,
    );

    final style = ToastStyleResolver.resolve(type);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => ToastView(
        config: config,
        style: style,
        onDismissed: () {
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
    bool sendToBell = false,
  }) {
    show(
      context,
      message,
      type: ToastType.success,
      icon: icon,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
      sendToBell: sendToBell,
    );
  }

  static void error(
    BuildContext context,
    String message, {
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(milliseconds: 2800),
    bool sendToBell = false,
  }) {
    show(
      context,
      message,
      type: ToastType.error,
      icon: icon,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
      sendToBell: sendToBell,
    );
  }

  static void info(
    BuildContext context,
    String message, {
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(milliseconds: 2800),
    bool sendToBell = false,
  }) {
    show(
      context,
      message,
      type: ToastType.info,
      icon: icon,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
      sendToBell: sendToBell,
    );
  }

  static void warning(
    BuildContext context,
    String message, {
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(milliseconds: 2800),
    bool sendToBell = false,
  }) {
    show(
      context,
      message,
      type: ToastType.warning,
      icon: icon,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
      sendToBell: sendToBell,
    );
  }
}
