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
  late final Animation<Offset> _curtainSlideAnimation;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _controller.forward();
  }

  void _setupAnimations() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2300),
    );

    // 1. Green circle expands to fill the screen (0-18% squish, 18-68% expand, 68-100% solid)
    _circleScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.92)
            .chain(CurveTween(curve: Curves.easeInOutQuad)),
        weight: 18,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.92, end: 32.0)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(32.0),
        weight: 32,
      ),
    ]).animate(_controller);

    // 2. Logo squishes slightly, then gently settles back to 1.0 and stays stable
    _logoScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.92)
            .chain(CurveTween(curve: Curves.easeInOutQuad)),
        weight: 18,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.92, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 32,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 50,
      ),
    ]).animate(_controller);

    // 3. Curtain slide: holds still (0-78%), then smoothly slides to the left (78-100%)
    _curtainSlideAnimation = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: ConstantTween<Offset>(Offset.zero),
        weight: 78,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(-1.05, 0.0),
        ).chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 22,
      ),
    ]).animate(_controller);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _finishAndNavigate();
      }
    });
  }

  void _finishAndNavigate() {
    if (_navigated || !mounted) return;
    _navigated = true;

    // Request notification permission in context upon sign-in/registration completion
    unawaited(PushNotificationService().requestPermission());

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: Duration.zero,
        pageBuilder: (context, animation, secondaryAnimation) =>
            MainNavScreen(initialIndex: widget.targetIndex),
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
            final curtainOffset = _curtainSlideAnimation.value;
            final isFullyCovered = circleScale >= 25.0;

            return Stack(
              fit: StackFit.expand,
              children: [
                // Base: MainNavScreen resting underneath, unveiled by the sliding curtain
                MainNavScreen(initialIndex: widget.targetIndex),

                // Top Layer: The Emerald Curtain with logo and success message that slides to the left
                SlideTransition(
                  position: _curtainSlideAnimation,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isFullyCovered
                          ? AppColors.primary
                          : AppColors.bgPrimary,
                      boxShadow: curtainOffset.dx < 0
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 24,
                                spreadRadius: 4,
                                offset: const Offset(8, 0),
                              ),
                            ]
                          : null,
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
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

