import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:agrokera/core/theme/app_colors.dart';
import 'package:agrokera/features/profile/domain/models/user_address_model.dart';

/// Tag style definition for address category visual distinction.
class _AddressTagStyle {
  final IconData icon;
  final Color foreground;
  final Color background;

  const _AddressTagStyle({
    required this.icon,
    required this.foreground,
    required this.background,
  });
}

/// Card widget presenting a single saved user address with modern actions and visual hierarchy.
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

  _AddressTagStyle _tagStyleForTitle(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('სახლ')) {
      return const _AddressTagStyle(
        icon: LucideIcons.home,
        foreground: AppColors.primary,
        background: AppColors.primaryLight,
      );
    }
    if (lower.contains('სამსახურ') || lower.contains('ოფის')) {
      return const _AddressTagStyle(
        icon: LucideIcons.briefcase,
        foreground: Color(0xFF2563EB),
        background: Color(0xFFEFF6FF),
      );
    }
    if (lower.contains('ფერმ') || lower.contains('მეურნეობ')) {
      return const _AddressTagStyle(
        icon: LucideIcons.tractor,
        foreground: Color(0xFF16A34A),
        background: Color(0xFFDCFCE7),
      );
    }
    if (lower.contains('აგარაკ')) {
      return const _AddressTagStyle(
        icon: LucideIcons.trees,
        foreground: Color(0xFFD97706),
        background: Color(0xFFFEF3C7),
      );
    }
    return const _AddressTagStyle(
      icon: LucideIcons.mapPin,
      foreground: Color(0xFF475569),
      background: Color(0xFFF1F5F9),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDefault = address.isDefault;
    final tagStyle = _tagStyleForTitle(address.title);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDefault ? 0.05 : 0.03),
            blurRadius: isDefault ? 14 : 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: isDefault ? null : onSetDefault,
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Left accent indicator for the default address
              if (isDefault)
                Positioned(
                  left: 0,
                  top: 16,
                  bottom: 16,
                  child: Container(
                    width: 4.5,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(4),
                        bottomRight: Radius.circular(4),
                      ),
                    ),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Category Icon, Title, Default Badge & Menu
                    Row(
                      children: [
                        // Tag Category Icon Container
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: tagStyle.background,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            tagStyle.icon,
                            size: 20,
                            color: tagStyle.foreground,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Title & Default Badge
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      address.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.notoSansGeorgian(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                  if (isDefault) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
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
                              if (address.city.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  address.city,
                                  style: GoogleFonts.notoSansGeorgian(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Action Context Menu
                        PopupMenuButton<String>(
                          icon: const Icon(
                            LucideIcons.ellipsisVertical,
                            size: 18,
                            color: Color(0xFF64748B),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          onSelected: (val) {
                            if (val == 'edit') {
                              onEdit();
                            } else if (val == 'default') {
                              onSetDefault();
                            } else if (val == 'delete') {
                              onDelete();
                            }
                          },
                          itemBuilder: (ctx) => [
                            if (!isDefault)
                              PopupMenuItem(
                                value: 'default',
                                child: Row(
                                  children: [
                                    const Icon(
                                      LucideIcons.checkCircle2,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'ძირითადად დაყენება',
                                      style: GoogleFonts.notoSansGeorgian(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  const Icon(
                                    LucideIcons.pencil,
                                    size: 16,
                                    color: Color(0xFF475569),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'რედაქტირება',
                                    style: GoogleFonts.notoSansGeorgian(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  const Icon(
                                    LucideIcons.trash2,
                                    size: 16,
                                    color: Color(0xFFEF4444),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'წაშლა',
                                    style: GoogleFonts.notoSansGeorgian(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFEF4444),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Formatted Address Line
                    Text(
                      address.formattedAddress,
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 13.5,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF334155),
                      ),
                    ),

                    // Map coordinates indicator
                    if (address.latitude != null && address.longitude != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.mapPinCheck,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'ზუსტი GPS კოორდინატები მონიშნულია',
                            style: GoogleFonts.notoSansGeorgian(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Optional courier note
                    if (address.note != null && address.note!.trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              LucideIcons.messageSquare,
                              size: 13,
                              color: Color(0xFF64748B),
                            ),
                            const SizedBox(width: 7),
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
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                LucideIcons.checkCircle2,
                                size: 15,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'ძირითად მისამართად არჩევა',
                                style: GoogleFonts.notoSansGeorgian(
                                  fontSize: 12.5,
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
            ],
          ),
        ),
      ),
    );
  }
}


