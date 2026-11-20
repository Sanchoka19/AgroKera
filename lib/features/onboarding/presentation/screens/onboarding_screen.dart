import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../navigation/presentation/screens/main_nav_screen.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_bottom_controls.dart';
import '../widgets/onboarding_header.dart';
import '../widgets/onboarding_slide_widget.dart';

/// Top-level Onboarding screen orchestrating user walkthrough.
/// Features a signature curtain slide transition upon completion, unveiling MainNavScreen.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _exitController;
  late final Animation<Offset> _curtainSlideAnimation;
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _curtainSlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1.05, 0.0),
    ).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: Curves.easeInOutCubic,
      ),
    );
    _exitController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _finalizeNavigation();
      }
    });

    _precacheRemainingAssets();
  }

  void _precacheRemainingAssets() {
    unawaited(Future.wait([
      const SvgAssetLoader(AppAssets.onboarding1).loadBytes(null),
      const SvgAssetLoader(AppAssets.onboarding2).loadBytes(null),
      const SvgAssetLoader(AppAssets.onboarding3).loadBytes(null),
      const SvgAssetLoader(AppAssets.logoGreen).loadBytes(null),
    ]));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_isExiting) return;
    final state = ref.read(onboardingProvider);
    if (!state.isLastPage) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _onPrevious() {
    if (_isExiting) return;
    final state = ref.read(onboardingProvider);
    if (!state.isFirstPage) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _onFinish() {
    if (_isExiting) return;
    // Mark as seen concurrently without delaying the exit animation
    unawaited(ref.read(onboardingProvider.notifier).completeOnboarding());

    setState(() {
      _isExiting = true;
    });
    _exitController.forward();
  }

  void _finalizeNavigation() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: Duration.zero,
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MainNavScreen(initialIndex: 0),
      ),
    );
  }

  void _onSignIn() {
    if (_isExiting) return;
    unawaited(ref.read(onboardingProvider.notifier).completeOnboarding());

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Base: MainNavScreen resting underneath, unveiled by the sliding curtain
        if (_isExiting)
          const RepaintBoundary(
            child: MainNavScreen(initialIndex: 0),
          ),

        // Sliding Curtain: The Onboarding Screen
        SlideTransition(
          position: _curtainSlideAnimation,
          child: RepaintBoundary(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.bgPrimary,
                boxShadow: _isExiting
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
              child: Scaffold(
                backgroundColor: AppColors.bgPrimary,
                body: AnnotatedRegion<SystemUiOverlayStyle>(
                  value: SystemUiOverlayStyle.dark,
                  child: SafeArea(
                    child: Column(
                      children: [
                        // Top Bar with AgroKera Logo on Left and Skip Action on Right
                        OnboardingHeader(
                          isLastPage: state.isLastPage,
                          onSkip: _onFinish,
                        ),

                        // Page Carousel
                        Expanded(
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: state.totalPages,
                            onPageChanged: (index) {
                              ref.read(onboardingProvider.notifier).setPage(index);
                            },
                            itemBuilder: (context, index) {
                              return OnboardingSlideWidget(
                                item: state.items[index],
                              );
                            },
                          ),
                        ),

                        // Bottom Navigation Controls with Arrow Buttons & Indicator
                        OnboardingBottomControls(
                          currentIndex: state.currentIndex,
                          totalPages: state.totalPages,
                          isLastPage: state.isLastPage,
                          onNext: _onNext,
                          onPrevious: _onPrevious,
                          onFinish: _onFinish,
                          onSignIn: _onSignIn,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
