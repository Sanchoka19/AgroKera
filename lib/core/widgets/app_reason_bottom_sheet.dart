import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Universal, ergonomic Reason / Problem Selection Bottom Sheet
/// Used for order cancellations, status rejections, dispute reports, and inventory adjustments.
class AppReasonBottomSheet extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String confirmButtonText;
  final Color confirmButtonColor;
  final IconData icon;
  final List<String> reasons;
  final String? initialReason;
  final String customReasonHint;
  final void Function(String reason) onConfirm;

  const AppReasonBottomSheet({
    super.key,
    required this.title,
    this.subtitle,
    this.confirmButtonText = 'დადასტურება',
    this.confirmButtonColor = const Color(0xFFDC2626),
    this.icon = LucideIcons.alertTriangle,
    required this.reasons,
    this.initialReason,
    this.customReasonHint = 'დამატებითი კომენტარი (სურვილისამებრ)...',
    required this.onConfirm,
  });

  /// Standard predefined template reasons for farmer incoming orders
  static const List<String> defaultOrderCancellationReasons = [
    'მარაგი ამოიწურა',
    'ტრანსპორტირება ვერ ხორციელდება',
    'უამინდობა / ტექნიკური შეფერხება',
    'რაოდენობის / ხარისხის შეუსაბამობა',
    'დამკვეთის მოთხოვნით',
    'სხვა მიზეზი',
  ];

  /// Static helper to display the sheet modally and return the chosen reason string.
  static Future<String?> show({
    required BuildContext context,
    required String title,
    String? subtitle,
    String confirmButtonText = 'გაუქმების დადასტურება',
    Color confirmButtonColor = const Color(0xFFDC2626),
    IconData icon = LucideIcons.alertTriangle,
    List<String> reasons = defaultOrderCancellationReasons,
    String? initialReason,
    String customReasonHint = 'დამატებითი კომენტარი (სურვილისამებრ)...',
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: AppReasonBottomSheet(
          title: title,
          subtitle: subtitle,
          confirmButtonText: confirmButtonText,
          confirmButtonColor: confirmButtonColor,
          icon: icon,
          reasons: reasons,
          initialReason: initialReason,
          customReasonHint: customReasonHint,
          onConfirm: (reason) => Navigator.of(ctx).pop(reason),
        ),
      ),
    );
  }

  @override
  State<AppReasonBottomSheet> createState() => _AppReasonBottomSheetState();
}

class _AppReasonBottomSheetState extends State<AppReasonBottomSheet> {
  late String _selectedReason;
  late final TextEditingController _customController;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _selectedReason = widget.initialReason ??
        (widget.reasons.isNotEmpty ? widget.reasons.first : 'სხვა მიზეზი');
    _customController = TextEditingController();
  }

  @override
  void dispose() {
    _customController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onConfirm() {
    final note = _customController.text.trim();
    String finalReason;

    if (_selectedReason == 'სხვა მიზეზი') {
      finalReason = note.isNotEmpty ? note : 'სხვა მიზეზი';
    } else if (note.isNotEmpty) {
      finalReason = '$_selectedReason ($note)';
    } else {
      finalReason = _selectedReason;
    }

    widget.onConfirm(finalReason);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isCustomSelected = _selectedReason == 'სხვა მიზეზი';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 20),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top drag indicator
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Header: Icon + Title + Close Button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: widget.confirmButtonColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.icon,
                      size: 20,
                      color: widget.confirmButtonColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: GoogleFonts.notoSansGeorgian(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                            letterSpacing: -0.2,
                          ),
                        ),
                        if (widget.subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.subtitle!,
                            style: GoogleFonts.notoSansGeorgian(
                              fontSize: 12.5,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        LucideIcons.x,
                        size: 16,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Preset Reasons Label
              Text(
                'აირჩიეთ მიზეზი:',
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 10),

              // Reasons selectable tiles
              ...widget.reasons.map((reason) {
                final isSelected = _selectedReason == reason;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedReason = reason;
                      });
                      if (reason == 'სხვა მიზეზი') {
                        _focusNode.requestFocus();
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? widget.confirmButtonColor.withValues(alpha: 0.06)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? widget.confirmButtonColor
                              : const Color(0xFFE2E8F0),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? widget.confirmButtonColor
                                  : Colors.white,
                              border: Border.all(
                                color: isSelected
                                    ? widget.confirmButtonColor
                                    : const Color(0xFF94A3B8),
                                width: 1.5,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    size: 12,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              reason,
                              style: GoogleFonts.notoSansGeorgian(
                                fontSize: 13.5,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? const Color(0xFF0F172A)
                                    : const Color(0xFF334155),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 6),

              // Comment / Custom reason text field
              TextField(
                controller: _customController,
                focusNode: _focusNode,
                maxLines: isCustomSelected ? 3 : 2,
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 13,
                  color: const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  hintText: isCustomSelected
                      ? 'მიუთითეთ დეტალური მიზეზი...'
                      : widget.customReasonHint,
                  hintStyle: GoogleFonts.notoSansGeorgian(
                    fontSize: 12.5,
                    color: const Color(0xFF94A3B8),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: widget.confirmButtonColor, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Footer Buttons: Back & Confirm
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF64748B),
                        side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'უკან',
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _onConfirm,
                      icon: Icon(widget.icon, size: 16),
                      label: Text(
                        widget.confirmButtonText,
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.confirmButtonColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
