import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:agrokera/core/theme/app_colors.dart';
import 'package:agrokera/features/cart_checkout/presentation/providers/cart_provider.dart';
import 'package:agrokera/features/cart_checkout/presentation/screens/cart_screen.dart';

/// Universal Draggable Floating Cart Widget.
/// - Can be dragged across the screen (left-to-right / right-to-left)
/// - Snaps cleanly to the nearest screen edge (left 16px or right 16px) upon release
/// - Displays live cart item count badge (supports guest & authenticated users)
/// - Performs scale bump bounce reaction when items fly into it
/// - Standardized shopping cart icon (`LucideIcons.shoppingCart`)
class DraggableFloatingCart extends ConsumerStatefulWidget {
  final int? cartCount;
  final VoidCallback? onTap;
  final double size;
  final double bottomOffset;

  const DraggableFloatingCart({
    super.key,
    this.cartCount,
    this.onTap,
    this.size = 56.0,
    this.bottomOffset = 85.0,
  });

  @override
  ConsumerState<DraggableFloatingCart> createState() =>
      DraggableFloatingCartState();
}

class DraggableFloatingCartState extends ConsumerState<DraggableFloatingCart>
    with TickerProviderStateMixin {
  double? _cartX;
  double? _cartY;
  bool _isInitialized = false;
  bool _isDragging = false;
  double _dragDistance = 0.0;
  DateTime? _panStartTime;
  DateTime _lastOpen = DateTime.fromMillisecondsSinceEpoch(0);

  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  late AnimationController _snapController;
  Animation<double>? _snapAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.32)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.32, end: 0.92)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.92, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 25,
      ),
    ]).animate(_bounceController);

    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final screenHeight = media.size.height;
    final bottomBarHeight = media.padding.bottom + widget.bottomOffset;
    final keyboardHeight = media.viewInsets.bottom;
    final hasAppBar = Scaffold.maybeOf(context)?.hasAppBar ?? false;
    final topSafe = hasAppBar ? 12.0 : (media.padding.top + kToolbarHeight);
    final availableHeight = hasAppBar
        ? (screenHeight - (media.padding.top + kToolbarHeight))
        : screenHeight;
    final maxBottom =
        availableHeight - bottomBarHeight - keyboardHeight - widget.size - 12.0;

    if (!_isInitialized) {
      _cartX = screenWidth - widget.size - 16.0;
      _cartY = maxBottom > topSafe ? maxBottom : topSafe + 20.0;
      _isInitialized = true;
    } else if (_cartY != null && _cartY! > maxBottom) {
      _cartY = maxBottom > topSafe ? maxBottom : topSafe;
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _snapController.dispose();
    super.dispose();
  }

  /// Triggered externally when a flying particle arrives
  void bounce() {
    if (mounted) {
      _bounceController.forward(from: 0.0);
    }
  }

  void _handleTap() {
    final now = DateTime.now();
    if (now.difference(_lastOpen).inMilliseconds < 400) return;
    _lastOpen = now;

    if (widget.onTap != null) {
      widget.onTap!();
    } else {
      HapticFeedback.lightImpact();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const CartScreen(),
        ),
      );
    }
  }

  void _snapToEdge(double velocityX) {
    if (!mounted || _cartX == null) return;
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final minX = 16.0;
    final maxX = screenWidth - widget.size - 16.0;

    final double targetX;
    if (velocityX.abs() > 250) {
      targetX = velocityX < 0 ? minX : maxX;
    } else {
      targetX = (_cartX! < screenWidth / 2) ? minX : maxX;
    }

    _snapAnimation = Tween<double>(begin: _cartX!, end: targetX).animate(
      CurvedAnimation(parent: _snapController, curve: Curves.easeOutCubic),
    )..addListener(() {
        if (mounted) {
          setState(() {
            _cartX = _snapAnimation!.value;
          });
        }
      });

    _snapController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    if (_cartX == null || _cartY == null) {
      return const SizedBox.shrink();
    }

    final effectiveCartCount =
        widget.cartCount ?? ref.watch(cartProvider).length;

    return Positioned(
      left: _cartX,
      top: _cartY,
      child: GestureDetector(
        onPanStart: (details) {
          _panStartTime = DateTime.now();
          _dragDistance = 0.0;
          _snapController.stop();
          HapticFeedback.selectionClick();
          setState(() {
            _isDragging = true;
          });
        },
        onPanUpdate: (details) {
          final media = MediaQuery.of(context);
          final screenWidth = media.size.width;
          final screenHeight = media.size.height;
          final bottomBarHeight = media.padding.bottom + widget.bottomOffset;
          final keyboardHeight = media.viewInsets.bottom;
          final hasAppBar = Scaffold.maybeOf(context)?.hasAppBar ?? false;
          final topSafe =
              hasAppBar ? 12.0 : (media.padding.top + kToolbarHeight);
          final availableHeight = hasAppBar
              ? (screenHeight - (media.padding.top + kToolbarHeight))
              : screenHeight;
          final maxBottom = availableHeight -
              bottomBarHeight -
              keyboardHeight -
              widget.size -
              10.0;

          _dragDistance += details.delta.distance;
          setState(() {
            _cartX = (_cartX! + details.delta.dx)
                .clamp(16.0, screenWidth - widget.size - 16.0);
            _cartY = (_cartY! + details.delta.dy)
                .clamp(topSafe, maxBottom > topSafe ? maxBottom : topSafe + 20.0);
          });
        },
        onPanEnd: (details) {
          setState(() {
            _isDragging = false;
          });
          final duration = _panStartTime != null
              ? DateTime.now().difference(_panStartTime!).inMilliseconds
              : 999;
          if (_dragDistance < 10.0 && duration < 320) {
            _handleTap();
          } else {
            _snapToEdge(details.velocity.pixelsPerSecond.dx);
          }
        },
        onTap: _handleTap,
        child: ScaleTransition(
          scale: _bounceAnimation,
          child: AnimatedScale(
            scale: _isDragging ? 1.08 : 1.0,
            duration: const Duration(milliseconds: 140),
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _isDragging
                      ? AppColors.primary
                      : const Color(0xFFE2E8F0),
                  width: _isDragging ? 2.0 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(
                      alpha: _isDragging ? 0.22 : 0.12,
                    ),
                    blurRadius: _isDragging ? 18 : 12,
                    spreadRadius: _isDragging ? 2 : 0,
                    offset: Offset(0, _isDragging ? 8 : 4),
                  ),
                  BoxShadow(
                    color: AppColors.primary.withValues(
                      alpha: _isDragging ? 0.16 : 0.08,
                    ),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  const Icon(
                    LucideIcons.shoppingCart,
                    size: 24,
                    color: AppColors.primary,
                  ),
                  if (effectiveCartCount > 0)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFDC2626)
                                  .withValues(alpha: 0.45),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            effectiveCartCount > 99
                                ? '99+'
                                : '$effectiveCartCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

