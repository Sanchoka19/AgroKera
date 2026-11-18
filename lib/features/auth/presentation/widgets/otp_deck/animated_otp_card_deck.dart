import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/theme/app_colors.dart';
import 'otp_blinking_cursor.dart';
import 'otp_deck_phase.dart';
import 'otp_glowing_spinner_painter.dart';

export 'otp_deck_phase.dart';

/// Presentation-only 5-phase Card Deck OTP Animation Widget.
///
/// Fully modularized and decoupled from business logic:
/// * Accepts a pure [onVerify] async callback returning a boolean result.
/// * Handles smooth Fan-out, Center Stacking, Glowing Spinner, Success Elastic Pop, and Error Shake.
/// * Uses AgroKera's design tokens and typography.
class AnimatedOtpCardDeck extends StatefulWidget {
  final int pinLength;
  final Future<bool> Function(String pin) onVerify;
  final VoidCallback? onSuccess;
  final ValueChanged<String>? onError;
  final ValueChanged<String>? onPinChanged;
  final ValueChanged<OtpDeckPhase>? onPhaseChanged;
  final Color accentColor;
  final Color cardBackgroundColor;
  final Color cardBorderColor;

  const AnimatedOtpCardDeck({
    super.key,
    this.pinLength = 5,
    required this.onVerify,
    this.onSuccess,
    this.onError,
    this.onPinChanged,
    this.onPhaseChanged,
    this.accentColor = AppColors.primary,
    this.cardBackgroundColor = Colors.white,
    this.cardBorderColor = const Color(0xFFCBD5E1),
  });

  @override
  State<AnimatedOtpCardDeck> createState() => AnimatedOtpCardDeckState();
}

class AnimatedOtpCardDeckState extends State<AnimatedOtpCardDeck>
    with TickerProviderStateMixin {
  final FocusNode _keyboardFocusNode = FocusNode();
  final TextEditingController _hiddenController = TextEditingController();

  OtpDeckPhase _phase = OtpDeckPhase.input;
  String _pin = '';

  late final AnimationController _fanController;
  late final AnimationController _stackController;
  late final AnimationController _spinnerController;
  late final AnimationController _successController;
  late final AnimationController _shakeController;

  late final Animation<double> _fanAnimation;
  late final Animation<double> _stackAnimation;
  late final Animation<double> _successScale;
  late final Animation<double> _shakeAnimation;

  OtpDeckPhase get phase => _phase;
  String get pin => _pin;

  @override
  void initState() {
    super.initState();

    // 1. Fan-out Animation (cards angle out like a deck of playing cards)
    _fanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _fanAnimation = CurvedAnimation(
      parent: _fanController,
      curve: Curves.easeOutBack,
    );

    // 2. Stack Animation (cards collapse inwards to a single deck in the center)
    _stackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );
    _stackAnimation = CurvedAnimation(
      parent: _stackController,
      curve: Curves.easeInOutCubic,
    );

    // 3. Verifying Spinner Animation (rotating glowing accent arc)
    _spinnerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    // 4. Success Elastic Pop Animation
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _successScale = CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    );

    // 5. Shake Error Animation
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _shakeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.linear),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _keyboardFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    _hiddenController.dispose();
    _fanController.dispose();
    _stackController.dispose();
    _spinnerController.dispose();
    _successController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _setPhase(OtpDeckPhase next) {
    if (_phase == next) return;
    setState(() => _phase = next);
    widget.onPhaseChanged?.call(next);
  }

  void _onTextChanged(String value) {
    if (_phase != OtpDeckPhase.input && _phase != OtpDeckPhase.error) {
      return;
    }

    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length > widget.pinLength) return;

    setState(() {
      _pin = digits;
      if (_phase == OtpDeckPhase.error) {
        _phase = OtpDeckPhase.input;
      }
    });
    widget.onPinChanged?.call(digits);

    if (digits.length == widget.pinLength) {
      triggerVerification(digits);
    }
  }

  /// Manually triggers or auto-triggers the 5-phase verification choreography
  Future<void> triggerVerification([String? overridePin]) async {
    final effectivePin = overridePin ?? _pin;
    if (effectivePin.length < widget.pinLength) return;
    if (_phase == OtpDeckPhase.verifying || _phase == OtpDeckPhase.success) return;

    _keyboardFocusNode.unfocus();
    HapticFeedback.lightImpact();

    // Phase 1: Fan-out
    _setPhase(OtpDeckPhase.fanOut);
    await _fanController.forward(from: 0.0);
    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) return;

    // Phase 2: Stack into center
    _setPhase(OtpDeckPhase.stacked);
    await _stackController.forward(from: 0.0);

    if (!mounted) return;

    // Phase 3: Start Verifying Spinner
    _setPhase(OtpDeckPhase.verifying);
    _spinnerController.repeat();

    // Call business logic callback
    final isSuccess = await widget.onVerify(effectivePin);

    if (!mounted) return;

    _spinnerController.stop();

    if (isSuccess) {
      // Phase 4: Success
      _setPhase(OtpDeckPhase.success);
      HapticFeedback.mediumImpact();
      await _successController.forward(from: 0.0);
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        widget.onSuccess?.call();
      }
    } else {
      // Phase 5: Error (Shake deck and return to input)
      _setPhase(OtpDeckPhase.error);
      widget.onError?.call('შეყვანილი კოდი არასწორია');
      HapticFeedback.heavyImpact();
      await _shakeController.forward(from: 0.0);
      _shakeController.reset();

      await _stackController.reverse();
      await _fanController.reverse();

      if (mounted) {
        setState(() {
          _pin = '';
          _hiddenController.clear();
          _phase = OtpDeckPhase.input;
        });
        widget.onPinChanged?.call('');
        _keyboardFocusNode.requestFocus();
      }
    }
  }

  List<double> _resolveFanRotations(int length) {
    if (length == 4) return const [-0.24, -0.08, 0.08, 0.24];
    if (length == 5) return const [-0.24, -0.12, 0.0, 0.12, 0.24];
    final mid = (length - 1) / 2.0;
    return List.generate(length, (i) => ((i - mid) / mid) * 0.24);
  }

  List<double> _resolveFanOffsets(int length) {
    if (length == 4) return const [6.0, 1.5, 1.5, 6.0];
    if (length == 5) return const [7.0, 2.0, 0.0, 2.0, 7.0];
    final mid = (length - 1) / 2.0;
    return List.generate(length, (i) {
      final diff = (i - mid).abs();
      return (diff * diff) * 1.5;
    });
  }

  @override
  Widget build(BuildContext context) {
    const totalContainerWidth = 320.0;
    final count = widget.pinLength;
    final cardWidth = count == 5 ? 52.0 : 62.0;
    final cardHeight = count == 5 ? 68.0 : 76.0;
    const cardRadius = 14.0;
    final gap = count == 5 ? 8.0 : 12.0;

    final totalInputWidth = (cardWidth * count) + (gap * (count - 1));
    final startX = (totalContainerWidth - totalInputWidth) / 2.0;
    final centerX = totalContainerWidth / 2.0;
    final cardCenterOffsetX = cardWidth / 2.0;

    final initialCenters = List.generate(count, (i) {
      return startX + (i * (cardWidth + gap)) + cardCenterOffsetX;
    });

    final fanRotations = _resolveFanRotations(count);
    final fanOffsetY = _resolveFanOffsets(count);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Hidden textfield capturing user soft keyboard input
        Offstage(
          offstage: true,
          child: TextField(
            controller: _hiddenController,
            focusNode: _keyboardFocusNode,
            keyboardType: TextInputType.number,
            maxLength: count,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: _onTextChanged,
          ),
        ),

        // Animated Card Deck Container
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (_phase == OtpDeckPhase.input || _phase == OtpDeckPhase.error) {
              _keyboardFocusNode.requestFocus();
            }
          },
          child: SizedBox(
            height: 100,
            width: totalContainerWidth,
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _fanAnimation,
                _stackAnimation,
                _spinnerController,
                _successScale,
                _shakeAnimation,
              ]),
              builder: (context, child) {
                double shakeDx = 0.0;
                if (_shakeAnimation.value > 0) {
                  shakeDx = math.sin(_shakeAnimation.value * math.pi * 6) * 12.0;
                }

                final fanT = _fanAnimation.value;
                final stackT = _stackAnimation.value;

                return Transform.translate(
                  offset: Offset(shakeDx, 0),
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: List.generate(count, (index) {
                      final char = index < _pin.length ? _pin[index] : '';
                      final isCurrentActive =
                          index == _pin.length && _phase == OtpDeckPhase.input;

                      final initX = initialCenters[index];
                      final currentX = (1.0 - stackT) *
                              (initX + (fanRotations[index] * 12.0 * fanT)) +
                          (stackT * (centerX + ((index - (count / 2.0)) * 1.5)));

                      final currentY = (fanT * (1.0 - stackT) * fanOffsetY[index]) +
                          (stackT * (index * 0.8));
                      final currentRotation =
                          (fanT * (1.0 - stackT) * fanRotations[index]);

                      final isTopCard = index == count - 1;
                      final digitOpacity = ((1.0 - stackT) * 1.0).clamp(0.0, 1.0);

                      return Positioned(
                        left: currentX - cardCenterOffsetX,
                        top: (100 - cardHeight) / 2 + currentY,
                        child: Transform.rotate(
                          angle: currentRotation,
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: cardWidth,
                            height: cardHeight,
                            decoration: BoxDecoration(
                              color: widget.cardBackgroundColor,
                              borderRadius: BorderRadius.circular(cardRadius),
                              border: Border.all(
                                color: _resolveBorderColor(index, isCurrentActive),
                                width: isCurrentActive ? 2.0 : 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isCurrentActive
                                      ? widget.accentColor.withValues(alpha: 0.20)
                                      : Colors.black.withValues(alpha: 0.05),
                                  blurRadius: isCurrentActive ? 10 : 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(cardRadius),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Normal input digit
                                  if (digitOpacity > 0.01)
                                    Opacity(
                                      opacity: digitOpacity,
                                      child: Center(
                                        child: char.isNotEmpty
                                            ? Text(
                                                char,
                                                style: GoogleFonts.spaceGrotesk(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.textPrimary,
                                                ),
                                              )
                                            : (isCurrentActive
                                                ? OtpBlinkingCursor(
                                                    color: widget.accentColor,
                                                  )
                                                : const SizedBox.shrink()),
                                      ),
                                    ),

                                  // Glowing runner during verifying
                                  if (isTopCard && _phase == OtpDeckPhase.verifying)
                                    Positioned.fill(
                                      child: CustomPaint(
                                        painter: OtpGlowingSpinnerPainter(
                                          progress: _spinnerController.value,
                                          color: widget.accentColor,
                                        ),
                                      ),
                                    ),

                                  // Success Elastic Checkmark
                                  if (isTopCard && _phase == OtpDeckPhase.success)
                                    ScaleTransition(
                                      scale: _successScale,
                                      child: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.12),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          LucideIcons.check,
                                          color: AppColors.primary,
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Color _resolveBorderColor(int index, bool isActive) {
    if (_phase == OtpDeckPhase.success) {
      return AppColors.primary;
    }
    if (_phase == OtpDeckPhase.error) {
      return AppColors.error;
    }
    if (_phase == OtpDeckPhase.verifying || _phase == OtpDeckPhase.stacked) {
      return widget.accentColor.withValues(alpha: 0.5);
    }
    if (isActive) {
      return widget.accentColor;
    }
    if (index < _pin.length) {
      return widget.accentColor.withValues(alpha: 0.7);
    }
    return widget.cardBorderColor;
  }
}

