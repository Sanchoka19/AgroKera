import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../domain/models/farmer_order_model.dart';

/// Modal bottom sheet for verifying delivery PIN before order completion
class OrderPinVerificationBottomSheet extends StatefulWidget {
  final FarmerOrder order;

  const OrderPinVerificationBottomSheet({
    super.key,
    required this.order,
  });

  static Future<bool> show({
    required BuildContext context,
    required FarmerOrder order,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: OrderPinVerificationBottomSheet(order: order),
      ),
    );
    return result ?? false;
  }

  @override
  State<OrderPinVerificationBottomSheet> createState() =>
      _OrderPinVerificationBottomSheetState();
}

class _OrderPinVerificationBottomSheetState
    extends State<OrderPinVerificationBottomSheet> {
  final _pinController = TextEditingController();
  final _focusNode = FocusNode();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _verifyAndSubmit() {
    final inputPin = _pinController.text.trim();
    if (inputPin.length != 4) {
      setState(() {
        _errorMessage = 'გთხოვთ შეიყვანოთ 4-ნიშნა კოდი სრულად';
      });
      return;
    }

    if (inputPin == widget.order.deliveryPin) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _errorMessage = 'არასწორი PIN კოდი! გადაამოწმეთ მყიდველთან.';
      });
      AppToast.error(context, 'არასწორი PIN კოდი!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Icon badge
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F7EE),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
            ),
            child: const Icon(
              LucideIcons.shieldCheck,
              size: 28,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            'ჩაბარების PIN კოდი',
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansGeorgian(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle
          Text(
            'შეიყვანეთ 4-ნიშნა კოდი, რომელიც მყიდველმა მოგაწოდათ პროდუქციის გადაცემისას:',
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansGeorgian(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // PIN Input Field
          Container(
            width: 200,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _errorMessage != null
                    ? const Color(0xFFDC2626)
                    : const Color(0xFFCBD5E1),
                width: 1.5,
              ),
            ),
            child: TextField(
              controller: _pinController,
              focusNode: _focusNode,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: GoogleFonts.firaCode(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: 12,
                color: const Color(0xFF0F172A),
              ),
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
                hintText: '••••',
              ),
              onChanged: (_) {
                if (_errorMessage != null) {
                  setState(() => _errorMessage = null);
                }
              },
              onSubmitted: (_) => _verifyAndSubmit(),
            ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: GoogleFonts.notoSansGeorgian(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFDC2626),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'გაუქმება',
                    style: GoogleFonts.notoSansGeorgian(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _verifyAndSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'დადასტურება',
                    style: GoogleFonts.notoSansGeorgian(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
