import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/auth/auth_state_provider.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_toast.dart';
import '../../../../profile/presentation/widgets/profile_image_view.dart';
import '../../../domain/models/farmer_order_model.dart';

/// Card showing customer contact info and delivery destination details
class FarmerOrderCustomerCard extends ConsumerWidget {
  final FarmerOrder order;
  final VoidCallback onOpenChat;

  const FarmerOrderCustomerCard({
    super.key,
    required this.order,
    required this.onOpenChat,
  });

  void _onCopyPhone(BuildContext context, String phone) {
    Clipboard.setData(ClipboardData(text: phone));
    AppToast.info(context, 'ტელეფონის ნომერი დაკოპირდა: $phone');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPhone = order.contactPhone.trim().isNotEmpty;
    final auth = ref.watch(authStateProvider);
    final effectiveCustomerAvatar = (order.customerAvatarUrl != null &&
            order.customerAvatarUrl!.trim().isNotEmpty)
        ? order.customerAvatarUrl!.trim()
        : (auth.userId == order.clientId ? auth.userAvatarUrl : null);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  LucideIcons.user,
                  size: 16,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'მომხმარებლის ინფორმაცია',
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Customer Identity & Contact Action Buttons
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                ),
                child: ClipOval(
                  child: (effectiveCustomerAvatar != null &&
                          effectiveCustomerAvatar.trim().isNotEmpty)
                      ? ProfileImageView.avatar(
                          avatarUrl: effectiveCustomerAvatar,
                          size: 44,
                          backgroundColor: const Color(0xFFF1F5F9),
                          iconColor: const Color(0xFF334155),
                        )
                      : Container(
                          color: const Color(0xFFF1F5F9),
                          alignment: Alignment.center,
                          child: Text(
                            order.customerName.isNotEmpty
                                ? order.customerName[0].toUpperCase()
                                : 'მ',
                            style: GoogleFonts.notoSansGeorgian(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF334155),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.customerName,
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    if (order.contactPerson.isNotEmpty &&
                        order.contactPerson != order.customerName) ...[
                      const SizedBox(height: 2),
                      Text(
                        order.contactPerson,
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Action Buttons: Chat & Phone
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasPhone) ...[
                    IconButton(
                      tooltip: 'ნომრის კოპირება / დარეკვა',
                      onPressed: () => _onCopyPhone(context, order.contactPhone),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFF0FDF4),
                        foregroundColor: const Color(0xFF16A34A),
                        side: const BorderSide(color: Color(0xFFBBF7D0)),
                        padding: const EdgeInsets.all(8),
                        minimumSize: const Size(36, 36),
                      ),
                      icon: const Icon(LucideIcons.phone, size: 16),
                    ),
                    const SizedBox(width: 6),
                  ],
                  IconButton(
                    tooltip: 'ჩათი მყიდველთან',
                    onPressed: onOpenChat,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFEFF6FF),
                      foregroundColor: const Color(0xFF2563EB),
                      side: const BorderSide(color: Color(0xFFBFDBFE)),
                      padding: const EdgeInsets.all(8),
                      minimumSize: const Size(36, 36),
                    ),
                    icon: const Icon(LucideIcons.messageSquare, size: 16),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),

          // Delivery Method / Address
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                order.isPickup ? LucideIcons.store : LucideIcons.mapPin,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.isPickup ? 'თვითგატანა ადგილზე' : 'მიწოდების ინფორმაცია',
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.isPickup
                          ? 'მყიდველი თავად გაიტანს პროდუქციას'
                          : (order.deliveryAddress ?? 'თბილისი'),
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Delivery Time Window (if specified)
          if (order.deliveryTimeWindow != null &&
              order.deliveryTimeWindow!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  LucideIcons.clock,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'მიწოდების დრო',
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.deliveryTimeWindow!,
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

