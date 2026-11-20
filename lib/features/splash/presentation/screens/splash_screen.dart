import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../navigation/presentation/screens/main_nav_screen.dart';
import '../widgets/splash_logo_badge.dart';

/// Animated Splash Screen delivering a continuous, fluid brand reveal.
/// Choreography phases (total 2300ms):
/// 1. Anticipation squish (0% - 18%): Circle & logo gently compress (1.0 -> 0.92)
/// 2. Circular expansion (18% - 68%): Green circle expands into a screen-filling wave (0.92 -> 32.0),
///    while the logo independently settles back to normal size (0.92 -> 1.0) and stays anchored.
/// 3. Brand stabilization (68% - 78%): Full emerald screen with centered AgroKera logo and slogan.
/// 4. Curtain slide reveal (78% - 100%): Top emerald layer slides gracefully to the left,
///    unveiling the MainNavScreen (Home) underneath, then cleanly completes.
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

    // 1. Background green circle: squishes to 0.92 (0-18%), floods screen up to 32.0 (18-68%), stays solid (68-100%)
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
        _navigateToHomeScreen();
      }
    });
  }

  void _navigateToHomeScreen() {
    if (_navigated || !mounted) return;
    _navigated = true;

    ref.read(secureStorageProvider).markSplashAsSeen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: Duration.zero,
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MainNavScreen(initialIndex: 0),
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
                // Base: MainNavScreen (Home) resting underneath, unveiled by the sliding curtain
                const MainNavScreen(initialIndex: 0),

                // Top Layer: The Emerald Curtain with logo that slides to the left
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
                            child: const SplashLogoBadge(
                              iconSize: 64,
                              fontSize: 22,
                              showSubtitle: true,
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
