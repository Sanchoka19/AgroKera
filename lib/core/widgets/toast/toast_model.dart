import 'package:flutter/material.dart';

/// Semantic toast types.
enum ToastType {
  success,
  error,
  info,
  warning,
}

/// Action button specification for toasts.
class ToastAction {
  final String label;
  final VoidCallback onAction;

  const ToastAction({
    required this.label,
    required this.onAction,
  });
}

/// Immutable configuration model for an individual toast presentation.
class ToastConfig {
  final String message;
  final ToastType type;
  final IconData? icon;
  final ToastAction? action;
  final Duration duration;
  final bool sendToBell;

  const ToastConfig({
    required this.message,
    this.type = ToastType.success,
    this.icon,
    this.action,
    this.duration = const Duration(milliseconds: 2800),
    this.sendToBell = false,
  });
}
