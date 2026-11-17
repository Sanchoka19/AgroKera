import 'package:flutter/material.dart';
import 'package:agrokera/core/theme/app_colors.dart';

/// Progress bar indicator displaying the current step out of 3 steps.
class ProductWizardProgressBar extends StatelessWidget {
  final int currentStep;

  const ProductWizardProgressBar({
    super.key,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: List.generate(3, (index) {
              final isCompletedOrActive = index < currentStep;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index < 2 ? 6.0 : 0.0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeInOutCubic,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isCompletedOrActive
                          ? AppColors.primary
                          : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              '$currentStep/3',
              key: ValueKey<int>(currentStep),
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
                height: 1.1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

