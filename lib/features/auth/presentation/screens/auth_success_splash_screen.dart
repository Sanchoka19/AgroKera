import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../navigation/presentation/screens/main_nav_screen.dart';
import '../../../splash/presentation/widgets/splash_logo_badge.dart';

/// Animated Celebration Splash Screen shown upon successful login or registration.
/// Choreography:
/// - 0% - 20%: Anticipation squish (1.0 -> 0.92)
/// - 20% - 70%: Green background circle expands outward into a screen-wide wave (0.92 -> 32.0),
///   while the logo settles cleanly at normal scale (0.92 -> 1.0) displaying the success message.
/// - 70% - 100%: Brief brand stabilization and smooth fade navigation into MainNavScreen.
class AuthSuccessSplashScreen extends ConsumerStatefulWidget {
  final String? message;
  final int targetIndex;

  const AuthSuccessSplashScreen({
    super.key,
    this.message,
    this.targetIndex = 0,
  });

  /// Convenient static navigator that replaces entire backstack cleanly.
  static Future<void> navigate(
    BuildContext context, {
    String? message,
    int targetIndex = 0,
  }) {
    return Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
          opacity: animation,
          child: AuthSuccessSplashScreen(
            message: message,
            targetIndex: targetIndex,
          ),
        ),
      ),
      (route) => false,
    );
  }

  @override
  ConsumerState<AuthSuccessSplashScreen> createState() =>
      _AuthSuccessSplashScreenState();
}

class _AuthSuccessSplashScreenState extends ConsumerState<AuthSuccessSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _circleScaleAnimation;
  late final Animation<double> _logoScaleAnimation;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Green circle expands to fill the screen
    _circleScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.92)
            .chain(CurveTween(curve: Curves.easeInOutQuad)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.92, end: 32.0)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 55,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(32.0),
        weight: 25,
      ),
    ]).animate(_controller);

    // Logo squishes slightly, then gently settles back to 1.0 and stays stable
    _logoScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.92)
            .chain(CurveTween(curve: Curves.easeInOutQuad)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.92, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 45,
      ),
    ]).animate(_controller);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _finishAndNavigate();
      }
    });

    _controller.forward();
  }

  void _finishAndNavigate() {
    if (_navigated || !mounted) return;
    _navigated = true;

    // Request notification permission in context upon sign-in/registration completion
    unawaited(PushNotificationService().requestPermission());

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
          opacity: animation,
          child: MainNavScreen(initialIndex: widget.targetIndex),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final circleScale = _circleScaleAnimation.value;
            final logoScale = _logoScaleAnimation.value;
            final isFullyCovered = circleScale >= 25.0;

            return Stack(
              fit: StackFit.expand,
              children: [
                // Solid surface once circle fills viewport
                if (isFullyCovered)
                  const ColoredBox(color: AppColors.primary),

                // Expanding green circular wave
                if (!isFullyCovered)
                  Center(
                    child: Transform.scale(
                      scale: circleScale,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),

                // Logo and success message
                Center(
                  child: Transform.scale(
                    scale: logoScale,
                    child: SplashLogoBadge(
                      iconSize: 64,
                      fontSize: 22,
                      showSubtitle: true,
                      subtitleText: widget.message ?? 'ავტორიზაცია წარმატებულია',
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

