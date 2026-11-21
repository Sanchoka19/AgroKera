import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/auth/auth_state_provider.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../navigation/presentation/screens/main_nav_screen.dart';
import '../../../onboarding/presentation/screens/onboarding_screen.dart';
import '../widgets/splash_logo_badge.dart';

/// Animated Splash Screen delivering a continuous, fluid, optimized brand reveal.
/// Choreography phases (smooth 2200ms total):
/// 1. Anticipation squish (0% - 18%): Circle & logo gently compress (1.0 -> 0.92)
/// 2. Circular expansion (18% - 68%): Green circle expands into a screen-filling wave (0.92 -> 25.0),
///    while the logo independently settles back to normal size (0.92 -> 1.0) and stays anchored.
/// 3. Brand stabilization (68% - 78%): Full emerald screen with centered AgroKera logo and slogan.
/// 4. Curtain slide reveal (78% - 100%): Top emerald layer slides gracefully to the left,
///    unveiling the destination screen underneath with zero navigation delay.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _circleScaleAnimation;
  late final Animation<double> _logoScaleAnimation;
  late final Animation<Offset> _curtainSlideAnimation;

  bool _navigated = false;
  Widget? _destinationScreen;

  @override
  void initState() {
    super.initState();
    // 1. Immediately determine destination (takes < 2ms) so it's ready long before curtain slides
    _determineDestination();
    // 2. Pre-cache vector graphics in background without blocking destination resolution
    _precacheAssets();
    // 3. Setup and start animations
    _setupAnimations();
    _controller.forward();
  }

  Future<void> _determineDestination() async {
    try {
      final storage = ref.read(secureStorageProvider);
      final hasSeenOnboarding = await storage.hasSeenOnboarding();
      final isAuthenticated = ref.read(authStateProvider).isAuthenticated;

      if (mounted) {
        setState(() {
          _destinationScreen = (!isAuthenticated && !hasSeenOnboarding)
              ? const OnboardingScreen()
              : const MainNavScreen(initialIndex: 0);
        });
      }
    } catch (_) {
      if (mounted && _destinationScreen == null) {
        setState(() {
          _destinationScreen = const OnboardingScreen();
        });
      }
    }
  }

  void _precacheAssets() {
    unawaited(Future.wait([
      const SvgAssetLoader(AppAssets.onboarding1).loadBytes(null),
      const SvgAssetLoader(AppAssets.onboarding2).loadBytes(null),
      const SvgAssetLoader(AppAssets.onboarding3).loadBytes(null),
      const SvgAssetLoader(AppAssets.logoGreen).loadBytes(null),
      const SvgAssetLoader(AppAssets.logoWhite).loadBytes(null),
    ]));
  }

  void _setupAnimations() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    );

    // 1. Background green circle: squishes to 0.92 (0-18%), floods screen up to 25.0 (18-68%), stays solid (68-100%)
    _circleScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.92)
            .chain(CurveTween(curve: Curves.easeInOutQuad)),
        weight: 18,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.92, end: 25.0)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(25.0),
        weight: 32,
      ),
    ]).animate(_controller);

    // 2. Foreground logo: squishes to 0.92 (0-18%), settles to 1.0 (18-50%), stays anchored (50-100%)
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
        _navigateToNextScreen();
      }
    });
  }

  Future<void> _navigateToNextScreen() async {
    if (_navigated || !mounted) return;
    _navigated = true;

    // Asynchronously record that splash was seen without blocking navigation
    unawaited(ref.read(secureStorageProvider).markSplashAsSeen());

    Widget? target = _destinationScreen;
    if (target == null) {
      final storage = ref.read(secureStorageProvider);
      final hasSeenOnboarding = await storage.hasSeenOnboarding();
      final isAuthenticated = ref.read(authStateProvider).isAuthenticated;
      target = (!isAuthenticated && !hasSeenOnboarding)
          ? const OnboardingScreen()
          : const MainNavScreen(initialIndex: 0);
    }

    if (!mounted) return;

    // Instant switch since the curtain has already slid completely off screen
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: Duration.zero,
        pageBuilder: (context, animation, secondaryAnimation) => target!,
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
          builder: (context, child) {
            final circleScale = _circleScaleAnimation.value;
            final logoScale = _logoScaleAnimation.value;
            final curtainOffset = _curtainSlideAnimation.value;
            final isFullyCovered = circleScale >= 20.0;
            final isCurtainSliding = curtainOffset.dx < 0;

            return Stack(
              fit: StackFit.expand,
              children: [
                // Base: Pre-mount destination screen while screen is 100% solid emerald (from 68% onwards)
                // This warms up and layouts MainNavScreen completely in the background before the curtain starts sliding at 78%!
                if (_destinationScreen != null && (isFullyCovered || isCurtainSliding))
                  RepaintBoundary(
                    child: _destinationScreen!,
                  ),

                // Top Layer: The Emerald Curtain with logo that slides to the left
                SlideTransition(
                  position: _curtainSlideAnimation,
                  child: RepaintBoundary(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isFullyCovered
                            ? AppColors.primary
                            : AppColors.bgPrimary,
                        boxShadow: isCurtainSliding
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
                          // Expanding green background circle
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

                          // Foreground Logo & Slogan (anchored at center)
                          Center(
                            child: Transform.scale(
                              scale: logoScale,
                              child: child,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
          // Cache the logo badge so it does not rebuild every frame
          child: const SplashLogoBadge(
            iconSize: 64,
            fontSize: 22,
            showSubtitle: true,
          ),
        ),
      ),
    );
  }
}
