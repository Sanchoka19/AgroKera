import 'package:flutter/material.dart';

/// Registry holding active contexts for toast flying targets (e.g. notification bell).
/// Avoids duplicate GlobalKey crashes when multiple headers exist in the navigation tree.
abstract final class ToastTargetRegistry {
  static BuildContext? _activeBellContext;

  /// Registers the most recently mounted active bell context
  static void registerBell(BuildContext context) {
    _activeBellContext = context;
  }

  /// Unregisters the bell context when disposed
  static void unregisterBell(BuildContext context) {
    if (_activeBellContext == context) {
      _activeBellContext = null;
    }
  }

  /// Resolves the global screen center coordinate of the bell icon, if visible.
  static Offset? getBellTargetPosition() {
    final context = _activeBellContext;
    if (context == null || !context.mounted) return null;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return null;

    return renderBox.localToGlobal(renderBox.size.center(Offset.zero));
  }
}
