import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agrokera/core/theme/app_colors.dart';
import 'package:agrokera/core/theme/app_typography.dart';
import '../../providers/farmer_onboarding_provider.dart';
import '../onboarding_delivery_card.dart';

/// Step 4: Delivery & Fulfillment Settings.
///
/// Orchestrates [OnboardingPickupCard] and [OnboardingDeliveryCard]
/// while reading/writing through [FarmerOnboardingNotifier].
class Step4DeliveryWidget extends ConsumerWidget {
  const Step4DeliveryWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(farmerOnboardingProvider);
    final notifier = ref.read(farmerOnboardingProvider.notifier);

    final address = state.dynamicAddress.isNotEmpty
        ? state.dynamicAddress
        : '${state.selectedRegion}, ${state.selectedCity}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Text(
          'მიწოდების პირობები',
          style: AppTypography.h1.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'აირჩიეთ როგორ მიაწვდით პროდუქციას მყიდველებს. ნაგულისხმევად მოქმედებს თვითგატანა მეურნეობიდან.',
          style: AppTypography.bodyMedium.copyWith(
            fontSize: 13.5,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),

        // Card 1 — Self-pickup (locked ON, always enabled)
        OnboardingPickupCard(
          isPickupEnabled: state.isPickupEnabled,
          address: address,
        ),
        const SizedBox(height: 16),

        // Card 2 — Courier delivery (togglable with expanded config)
        OnboardingDeliveryCard(
          isDeliveryEnabled: state.isDeliveryEnabled,
          deliveryCity: state.deliveryCity,
          deliveryDays: state.deliveryDays,
          deliveryFee: state.deliveryFee,
          isFreeDelivery: state.isFreeDelivery,
          orderCutoffHours: state.orderCutoffHours,
          onToggleDelivery: notifier.toggleDeliveryEnabled,
          onSetCity: notifier.setDeliveryCity,
          onToggleDay: notifier.toggleDeliveryDay,
          onSetFee: notifier.setDeliveryFee,
          onToggleFreeDelivery: notifier.toggleFreeDelivery,
          onSetCutoffHours: notifier.setOrderCutoffHours,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
