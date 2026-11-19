import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../navigation/presentation/screens/main_nav_screen.dart';
import '../widgets/splash_logo_badge.dart';

/// Animated Splash Screen delivering a continuous, fluid brand reveal.
/// Choreography phases:
/// 1. Anticipation squish (0% - 20%): Circle & logo gently compress (1.0 -> 0.92)
/// 2. Circular expansion (20% - 75%): Green circle expands into a screen-filling wave (0.92 -> 32.0),
///    while the logo independently settles back to normal size (0.92 -> 1.0) and stays anchored.
/// 3. Brand stabilization (75% - 100%): Full emerald screen with centered AgroKera logo.
/// 4. Seamless transition directly into MainNavScreen in Guest Profile mode (initialIndex: 2).
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
      duration: const Duration(milliseconds: 1700),
    );

    // 1. Background green circle: squishes to 0.92, then floods the screen up to 32.0
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

    // 2. Foreground logo: squishes to 0.92, then gently settles back to 1.0 and STAYS at 1.0.
    // The logo never blows up with the background circle.
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
        _navigateToGuestProfile();
      }
    });
  }

  void _navigateToGuestProfile() {
    if (_navigated || !mounted) return;
    _navigated = true;

    ref.read(secureStorageProvider).markSplashAsSeen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
          opacity: animation,
          child: const MainNavScreen(initialIndex: 2),
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
                // Layer 1: Solid background once fully covered to prevent any subpixel clipping
                if (isFullyCovered)
                  const ColoredBox(color: AppColors.primary),

                // Layer 2: Expanding green background circle
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

                // Layer 3: Foreground Logo (anchored at center, stays at readable size)
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
            );
          },
        ),
      ),
    );
  }
}
