import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:agrokera/core/theme/app_colors.dart';
import 'package:agrokera/features/profile/domain/models/user_address_model.dart';

/// Card widget presenting a single saved user address with actions.
class AddressCardTile extends StatelessWidget {
  final UserAddress address;
  final VoidCallback onSetDefault;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AddressCardTile({
    super.key,
    required this.address,
    required this.onSetDefault,
    required this.onEdit,
    required this.onDelete,
  });

  IconData _iconForTitle(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('სახლ')) return LucideIcons.home;
    if (lower.contains('სამსახურ') || lower.contains('ოფის')) {
      return LucideIcons.briefcase;
    }
    if (lower.contains('ფერმ') || lower.contains('მეურნეობ')) {
      return LucideIcons.tractor;
    }
    if (lower.contains('აგარაკ')) return LucideIcons.trees;
    return LucideIcons.mapPin;
  }

  @override
  Widget build(BuildContext context) {
    final isDefault = address.isDefault;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDefault
              ? AppColors.primary
              : const Color(0xFFE2E8F0),
          width: isDefault ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDefault ? 0.05 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: isDefault ? null : onSetDefault,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Title, Icon, Default Badge, and Actions
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDefault
                            ? AppColors.primaryLight
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _iconForTitle(address.title),
                        size: 18,
                        color: isDefault
                            ? AppColors.primary
                            : const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              address.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.notoSansGeorgian(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          if (isDefault) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'ძირითადი',
                                style: GoogleFonts.notoSansGeorgian(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Edit & Delete Icon Buttons
                    IconButton(
                      icon: const Icon(
                        LucideIcons.pencil,
                        size: 16,
                        color: Color(0xFF64748B),
                      ),
                      visualDensity: VisualDensity.compact,
                      tooltip: 'რედაქტირება',
                      onPressed: onEdit,
                    ),
                    IconButton(
                      icon: const Icon(
                        LucideIcons.trash2,
                        size: 16,
                        color: Color(0xFF94A3B8),
                      ),
                      visualDensity: VisualDensity.compact,
                      tooltip: 'წაშლა',
                      onPressed: onDelete,
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Address line & city
                Text(
                  address.formattedAddress,
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 13.5,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF334155),
                  ),
                ),

                // Map coordinates indicator
                if (address.latitude != null && address.longitude != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.mapPinCheck,
                        size: 13,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'ზუსტი GPS კოორდინატები მონიშნულია',
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ],

                // Optional courier note
                if (address.note != null && address.note!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.messageSquare,
                          size: 13,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            address.note!.trim(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.notoSansGeorgian(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Action hint if not default
                if (!isDefault) ...[
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: onSetDefault,
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.checkCircle2,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'ძირითად მისამართად არჩევა',
                            style: GoogleFonts.notoSansGeorgian(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
