import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:agrokera/core/theme/app_colors.dart';
import 'package:agrokera/core/theme/app_typography.dart';
import 'package:agrokera/core/widgets/app_toast.dart';
import '../../models/farmer_onboarding_state.dart';
import '../../providers/farmer_onboarding_provider.dart';

/// Step 4: Delivery & Fulfillment Settings with interactive Toggle Buttons
class Step4DeliveryWidget extends ConsumerStatefulWidget {
  const Step4DeliveryWidget({super.key});

  @override
  ConsumerState<Step4DeliveryWidget> createState() =>
      _Step4DeliveryWidgetState();
}

class _Step4DeliveryWidgetState extends ConsumerState<Step4DeliveryWidget> {
  late final TextEditingController _customFeeController;
  bool _isCustomMode = false;

  @override
  void initState() {
    super.initState();
    final fee = ref.read(farmerOnboardingProvider).deliveryFee;
    _isCustomMode = ![5.0, 7.0, 10.0, 15.0].contains(fee) && fee > 0;
    _customFeeController = TextEditingController(
      text: _isCustomMode ? fee.toInt().toString() : '',
    );
  }

  @override
  void dispose() {
    _customFeeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(farmerOnboardingProvider);
    final notifier = ref.read(farmerOnboardingProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header Text
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

        // ==========================================
        // CARD 1: თვითგატანა მეურნეობიდან (Toggle Card)
        // ==========================================
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: state.isPickupEnabled
                  ? AppColors.primary.withValues(alpha: 0.45)
                  : const Color(0xFFE2E8F0),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: state.isPickupEnabled
                          ? AppColors.primaryLight
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      LucideIcons.store,
                      color: state.isPickupEnabled
                          ? AppColors.primary
                          : const Color(0xFF64748B),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'თვითგატანა მეურნეობიდან',
                          style: GoogleFonts.notoSansGeorgian(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'მყიდველი თავად მოდის თქვენს ფერმაში',
                          style: GoogleFonts.notoSansGeorgian(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              LucideIcons.shieldCheck,
                              size: 13,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'საბაზისო პირობა • მუდმივად აქტიური',
                                style: GoogleFonts.notoSansGeorgian(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Non-turnoffable Toggle Switch Button
                  Switch.adaptive(
                    value: true,
                    activeTrackColor: AppColors.primary,
                    onChanged: (val) {
                      HapticFeedback.lightImpact();
                      AppToast.info(
                        context,
                        'თვითგატანა მეურნეობიდან არის საბაზისო პირობა და მისი გათიშვა შეუძლებელია',
                      );
                    },
                  ),
                ],
              ),
              if (state.isPickupEnabled) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.mapPin,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.dynamicAddress.isNotEmpty
                              ? state.dynamicAddress
                              : '${state.selectedRegion}, ${state.selectedCity}',
                          style: GoogleFonts.notoSansGeorgian(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF334155),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '0 ₾ • უფასო',
                          style: GoogleFonts.notoSansGeorgian(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF16A34A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ==========================================
        // CARD 2: ფერმერის მიტანა გრაფიკით (Toggle Card)
        // ==========================================
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: state.isDeliveryEnabled
                  ? AppColors.primary.withValues(alpha: 0.6)
                  : const Color(0xFFE2E8F0),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: state.isDeliveryEnabled
                          ? AppColors.primaryLight
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      LucideIcons.truck,
                      color: state.isDeliveryEnabled
                          ? AppColors.primary
                          : const Color(0xFF64748B),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ჩემი მიტანის სერვისი (რეისები)',
                          style: GoogleFonts.notoSansGeorgian(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'გაქვთ ტრანსპორტი და ჩამოგაქვთ ქალაქში',
                          style: GoogleFonts.notoSansGeorgian(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Toggle Switch Button
                  Switch.adaptive(
                    value: state.isDeliveryEnabled,
                    activeTrackColor: AppColors.primary,
                    onChanged: (val) {
                      HapticFeedback.lightImpact();
                      notifier.toggleDeliveryEnabled();
                    },
                  ),
                ],
              ),

              // Expanded Configuration when Delivery is toggled ON
              if (state.isDeliveryEnabled) ...[
                const SizedBox(height: 18),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 16),

                // SECTION A: სამიზნე ქალაქი / ზონა (Toggle Buttons)
                Text(
                  'სამიზნე ქალაქი / რეგიონი:',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: FarmerOnboardingState.targetDeliveryCities
                        .map((city) {
                      final isSelected = state.deliveryCity == city;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            notifier.setDeliveryCity(city);
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Text(
                              city,
                              style: GoogleFonts.notoSansGeorgian(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF475569),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 18),

                // SECTION B: მიტანის დღეები (7 Day Toggle Buttons)
                Text(
                  'მიტანის დღეები (მონიშნეთ თქვენი რეისის დღეები):',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: FarmerOnboardingState.weekDays.map((day) {
                    final isDaySelected = state.deliveryDays.contains(day);
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.5),
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            notifier.toggleDeliveryDay(day);
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 42,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isDaySelected
                                  ? AppColors.primary
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDaySelected
                                    ? AppColors.primary
                                    : const Color(0xFFCBD5E1),
                                width: 1.2,
                              ),
                              boxShadow: isDaySelected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.25),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              day,
                              style: GoogleFonts.notoSansGeorgian(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: isDaySelected
                                    ? Colors.white
                                    : const Color(0xFF334155),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),

                // SECTION C: მიტანის საფასური (Toggle Pills)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'მიტანის საფასური:',
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF334155),
                      ),
                    ),
                    // Toggle Free vs Fixed
                    Row(
                      children: [
                        _buildFeeTypeToggle(
                          label: 'უფასო',
                          isSelected: state.isFreeDelivery,
                          onTap: () {
                            setState(() => _isCustomMode = false);
                            notifier.toggleFreeDelivery(true);
                          },
                        ),
                        const SizedBox(width: 6),
                        _buildFeeTypeToggle(
                          label: 'ფასიანი',
                          isSelected: !state.isFreeDelivery,
                          onTap: () => notifier.toggleFreeDelivery(false),
                        ),
                      ],
                    ),
                  ],
                ),
                if (!state.isFreeDelivery) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ...[5.0, 7.0, 10.0, 15.0].map((fee) {
                        final isFeeSelected =
                            !_isCustomMode && state.deliveryFee == fee;
                        return Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 2.5),
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _isCustomMode = false;
                                  _customFeeController.text =
                                      fee.toInt().toString();
                                });
                                notifier.setDeliveryFee(fee);
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                height: 38,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isFeeSelected
                                      ? const Color(0xFFE8F7EE)
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isFeeSelected
                                        ? AppColors.primary
                                        : const Color(0xFFE2E8F0),
                                    width: isFeeSelected ? 1.5 : 1.2,
                                  ),
                                ),
                                child: Text(
                                  '${fee.toInt()} ₾',
                                  style: GoogleFonts.notoSansGeorgian(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: isFeeSelected
                                        ? AppColors.primaryDark
                                        : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      // 5th pill: "სხვა" (Custom price)
                      Expanded(
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 2.5),
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _isCustomMode = true;
                                if (_customFeeController.text.isEmpty) {
                                  _customFeeController.text =
                                      state.deliveryFee > 0
                                          ? state.deliveryFee.toInt().toString()
                                          : '12';
                                  notifier.setDeliveryFee(
                                    double.tryParse(_customFeeController.text) ??
                                        12.0,
                                  );
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: 38,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _isCustomMode
                                    ? const Color(0xFFE8F7EE)
                                    : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _isCustomMode
                                      ? AppColors.primary
                                      : const Color(0xFFE2E8F0),
                                  width: _isCustomMode ? 1.5 : 1.2,
                                ),
                              ),
                              child: Text(
                                _isCustomMode &&
                                        ![5.0, 7.0, 10.0, 15.0]
                                            .contains(state.deliveryFee)
                                    ? '${state.deliveryFee.toInt()} ₾'
                                    : 'სხვა',
                                style: GoogleFonts.notoSansGeorgian(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _isCustomMode
                                      ? AppColors.primaryDark
                                      : const Color(0xFF475569),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_isCustomMode) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.8),
                          width: 1.3,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.coins,
                            size: 17,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'საკუთარი საფასური:',
                            style: GoogleFonts.notoSansGeorgian(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          const Spacer(),
                          SizedBox(
                            width: 84,
                            height: 38,
                            child: TextField(
                              controller: _customFeeController,
                              autofocus: true,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(3),
                              ],
                              style: GoogleFonts.notoSansGeorgian(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDark,
                              ),
                              decoration: InputDecoration(
                                hintText: '12',
                                hintStyle: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                suffixText: '₾ ',
                                suffixStyle: GoogleFonts.notoSansGeorgian(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFCBD5E1),
                                    width: 1.2,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFCBD5E1),
                                    width: 1.2,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: AppColors.primary,
                                    width: 1.8,
                                  ),
                                ),
                              ),
                              onChanged: (val) {
                                final parsed = double.tryParse(val.trim());
                                if (parsed != null && parsed >= 0) {
                                  notifier.setDeliveryFee(parsed);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 18),

                // SECTION D: შეკვეთის მიღების ბოლო ვადა (Cut-off Toggle Buttons)
                Text(
                  'შეკვეთის მიღების ვადა რეისამდე:',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildCutoffToggle(
                      label: '12 სთ ადრე',
                      value: '12',
                      selectedValue: state.orderCutoffHours,
                      onTap: () => notifier.setOrderCutoffHours('12'),
                    ),
                    const SizedBox(width: 8),
                    _buildCutoffToggle(
                      label: '24 სთ ადრე',
                      value: '24',
                      selectedValue: state.orderCutoffHours,
                      onTap: () => notifier.setOrderCutoffHours('24'),
                    ),
                    const SizedBox(width: 8),
                    _buildCutoffToggle(
                      label: '48 სთ ადრე',
                      value: '48',
                      selectedValue: state.orderCutoffHours,
                      onTap: () => notifier.setOrderCutoffHours('48'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFeeTypeToggle({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.notoSansGeorgian(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildCutoffToggle({
    required String label,
    required String value,
    required String selectedValue,
    required VoidCallback onTap,
  }) {
    final isSelected = value == selectedValue;
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE8F7EE) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.notoSansGeorgian(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isSelected ? AppColors.primaryDark : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }
}

