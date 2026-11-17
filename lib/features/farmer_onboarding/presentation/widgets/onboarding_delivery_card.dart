import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:agrokera/core/theme/app_colors.dart';
import 'package:agrokera/core/widgets/app_toast.dart';
import '../models/farmer_onboarding_state.dart';

/// Card showing the self-pickup toggle (always enabled, locked ON) and
/// the farm address pill derived from onboarding state.
class OnboardingPickupCard extends StatelessWidget {
  final bool isPickupEnabled;
  final String address;

  const OnboardingPickupCard({
    super.key,
    required this.isPickupEnabled,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isPickupEnabled
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
                  color: isPickupEnabled
                      ? AppColors.primaryLight
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  LucideIcons.store,
                  color: isPickupEnabled
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
              Switch.adaptive(
                value: true,
                activeTrackColor: AppColors.primary,
                onChanged: (_) {
                  HapticFeedback.lightImpact();
                  AppToast.info(
                    context,
                    'თვითგატანა მეურნეობიდან არის საბაზისო პირობა და მისი გათიშვა შეუძლებელია',
                  );
                },
              ),
            ],
          ),
          if (isPickupEnabled) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.mapPin, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      address,
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
    );
  }
}

/// Card showing the courier delivery toggle with expanded configuration
/// (target city, delivery days, fee and cutoff hours) when enabled.
class OnboardingDeliveryCard extends StatefulWidget {
  final bool isDeliveryEnabled;
  final String deliveryCity;
  final List<String> deliveryDays;
  final double deliveryFee;
  final bool isFreeDelivery;
  final String orderCutoffHours;
  final VoidCallback onToggleDelivery;
  final ValueChanged<String> onSetCity;
  final ValueChanged<String> onToggleDay;
  final ValueChanged<double> onSetFee;
  final ValueChanged<bool> onToggleFreeDelivery;
  final ValueChanged<String> onSetCutoffHours;

  const OnboardingDeliveryCard({
    super.key,
    required this.isDeliveryEnabled,
    required this.deliveryCity,
    required this.deliveryDays,
    required this.deliveryFee,
    required this.isFreeDelivery,
    required this.orderCutoffHours,
    required this.onToggleDelivery,
    required this.onSetCity,
    required this.onToggleDay,
    required this.onSetFee,
    required this.onToggleFreeDelivery,
    required this.onSetCutoffHours,
  });

  @override
  State<OnboardingDeliveryCard> createState() => _OnboardingDeliveryCardState();
}

class _OnboardingDeliveryCardState extends State<OnboardingDeliveryCard> {
  late final TextEditingController _customFeeCtrl;
  bool _isCustomMode = false;

  @override
  void initState() {
    super.initState();
    _isCustomMode =
        ![5.0, 7.0, 10.0, 15.0].contains(widget.deliveryFee) &&
            widget.deliveryFee > 0;
    _customFeeCtrl = TextEditingController(
      text: _isCustomMode ? widget.deliveryFee.toInt().toString() : '',
    );
  }

  @override
  void dispose() {
    _customFeeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: widget.isDeliveryEnabled
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
          // Header toggle row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: widget.isDeliveryEnabled
                      ? AppColors.primaryLight
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  LucideIcons.truck,
                  color: widget.isDeliveryEnabled
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
              Switch.adaptive(
                value: widget.isDeliveryEnabled,
                activeTrackColor: AppColors.primary,
                onChanged: (_) {
                  HapticFeedback.lightImpact();
                  widget.onToggleDelivery();
                },
              ),
            ],
          ),

          if (widget.isDeliveryEnabled) ...[
            const SizedBox(height: 18),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 16),

            // A: Target city
            _sectionLabel('სამიზნე ქალაქი / რეგიონი:'),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: FarmerOnboardingState.targetDeliveryCities.map((city) {
                  final isSelected = widget.deliveryCity == city;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        widget.onSetCity(city);
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

            // B: Delivery days
            _sectionLabel('მიტანის დღეები (მონიშნეთ თქვენი რეისის დღეები):'),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: FarmerOnboardingState.weekDays.map((day) {
                final isSelected = widget.deliveryDays.contains(day);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.5),
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        widget.onToggleDay(day);
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : const Color(0xFFCBD5E1),
                            width: 1.2,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color:
                                        AppColors.primary.withValues(alpha: 0.25),
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
                            color: isSelected
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

            // C: Fee
            _buildFeeSection(),
            const SizedBox(height: 18),

            // D: Order cutoff
            _sectionLabel('შეკვეთის მიღების ვადა რეისამდე:'),
            const SizedBox(height: 8),
            Row(
              children: [
                _cutoffPill('12 სთ ადრე', '12'),
                const SizedBox(width: 8),
                _cutoffPill('24 სთ ადრე', '24'),
                const SizedBox(width: 8),
                _cutoffPill('48 სთ ადრე', '48'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.notoSansGeorgian(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF334155),
      ),
    );
  }

  Widget _buildFeeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionLabel('მიტანის საფასური:'),
            Row(
              children: [
                _feeTypeToggle('უფასო', widget.isFreeDelivery, () {
                  setState(() => _isCustomMode = false);
                  widget.onToggleFreeDelivery(true);
                }),
                const SizedBox(width: 6),
                _feeTypeToggle('ფასიანი', !widget.isFreeDelivery,
                    () => widget.onToggleFreeDelivery(false)),
              ],
            ),
          ],
        ),
        if (!widget.isFreeDelivery) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              ...[5.0, 7.0, 10.0, 15.0].map((fee) {
                final isSelected = !_isCustomMode && widget.deliveryFee == fee;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.5),
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _isCustomMode = false;
                          _customFeeCtrl.text = fee.toInt().toString();
                        });
                        widget.onSetFee(fee);
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFE8F7EE)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : const Color(0xFFE2E8F0),
                            width: isSelected ? 1.5 : 1.2,
                          ),
                        ),
                        child: Text(
                          '${fee.toInt()} ₾',
                          style: GoogleFonts.notoSansGeorgian(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? AppColors.primaryDark
                                : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
              // "სხვა" pill
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.5),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _isCustomMode = true;
                        if (_customFeeCtrl.text.isEmpty) {
                          _customFeeCtrl.text = widget.deliveryFee > 0
                              ? widget.deliveryFee.toInt().toString()
                              : '12';
                          widget.onSetFee(
                            double.tryParse(_customFeeCtrl.text) ?? 12.0,
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
                                    .contains(widget.deliveryFee)
                            ? '${widget.deliveryFee.toInt()} ₾'
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
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
                  const Icon(LucideIcons.coins,
                      size: 17, color: AppColors.primary),
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
                      controller: _customFeeCtrl,
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
                        hintStyle:
                            const TextStyle(color: Color(0xFF94A3B8)),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 8),
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
                          widget.onSetFee(parsed);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _feeTypeToggle(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
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

  Widget _cutoffPill(String label, String value) {
    final isSelected = value == widget.orderCutoffHours;
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onSetCutoffHours(value);
        },
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFE8F7EE)
                : const Color(0xFFF8FAFC),
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
              color: isSelected
                  ? AppColors.primaryDark
                  : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }
}
