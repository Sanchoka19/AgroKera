import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Clean 5-star interactive rating selector without emojis.
class StarRatingSelector extends StatelessWidget {
  final int rating;
  final ValueChanged<int> onRatingChanged;

  const StarRatingSelector({
    super.key,
    required this.rating,
    required this.onRatingChanged,
  });

  static const _labels = {
    1: 'ძალიან ცუდი',
    2: 'ცუდი',
    3: 'საშუალო',
    4: 'კარგი',
    5: 'შესანიშნავი',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final starNumber = index + 1;
            final isFilled = starNumber <= rating;

            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onRatingChanged(starNumber);
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: AnimatedScale(
                  scale: isFilled ? 1.08 : 1.0,
                  duration: const Duration(milliseconds: 140),
                  child: Icon(
                    isFilled ? LucideIcons.star : LucideIcons.star,
                    size: 34,
                    color: isFilled
                        ? const Color(0xFFF59E0B) // Amber star
                        : const Color(0xFFCBD5E1), // Gray star outline
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Text(
          _labels[rating] ?? 'შეაფასეთ',
          style: GoogleFonts.notoSansGeorgian(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFD97706),
          ),
        ),
      ],
    );
  }
}

/// Read-only star rating display
class StarRatingDisplay extends StatelessWidget {
  final int rating;
  final double size;
  final Color activeColor;
  final Color inactiveColor;

  const StarRatingDisplay({
    super.key,
    required this.rating,
    this.size = 14,
    this.activeColor = const Color(0xFFF59E0B),
    this.inactiveColor = const Color(0xFFCBD5E1),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final isFilled = (index + 1) <= rating;
        return Padding(
          padding: const EdgeInsets.only(right: 2),
          child: Icon(
            Icons.star_rounded,
            size: size,
            color: isFilled ? activeColor : inactiveColor,
          ),
        );
      }),
    );
  }
}

