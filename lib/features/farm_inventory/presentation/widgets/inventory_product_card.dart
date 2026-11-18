import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../marketplace/data/models/product_model.dart';

/// Pure UI widget for a single Product Card in Farmer Inventory
class InventoryProductCard extends StatelessWidget {
  final ProductModel product;
  final ValueChanged<bool> onToggleAvailability;
  final VoidCallback onEdit;
  final VoidCallback onRestock;
  final VoidCallback onDelete;

  const InventoryProductCard({
    super.key,
    required this.product,
    required this.onToggleAvailability,
    required this.onEdit,
    required this.onRestock,
    required this.onDelete,
  });

  Widget _buildProductImage(String url) {
    Widget fallback() => Container(
          width: 64,
          height: 64,
          color: const Color(0xFFF1F5F9),
          child: const Icon(
            LucideIcons.package,
            color: Color(0xFF94A3B8),
          ),
        );

    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback(),
      );
    }
    if (url.startsWith('data:image/')) {
      try {
        final base64Str = url.split(',').last;
        return Image.memory(
          base64Decode(base64Str),
          width: 64,
          height: 64,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => fallback(),
        );
      } catch (_) {}
    }
    if (!kIsWeb && File(url).existsSync()) {
      return Image.file(
        File(url),
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback(),
      );
    }
    return Image.network(
      url,
      width: 64,
      height: 64,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLow = product.stockQuantity > 0 && product.stockQuantity < 20;
    final isOut = product.stockQuantity <= 0 || !product.isAvailable;

    final statusColor = isOut
        ? const Color(0xFFDC2626)
        : isLow
            ? const Color(0xFFD97706)
            : const Color(0xFF16A34A);

    final statusBg = isOut
        ? const Color(0xFFFEE2E2)
        : isLow
            ? const Color(0xFFFEF3C7)
            : const Color(0xFFDCFCE7);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildProductImage(product.imageUrl),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isOut ? 'გათიშული / 0' : product.stockStatus,
                            style: GoogleFonts.notoSansGeorgian(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            product.category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.notoSansGeorgian(
                              fontSize: 11,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.title,
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₾${product.price.toStringAsFixed(2)} / ${product.unit}',
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: product.isAvailable && product.stockQuantity > 0,
                activeThumbColor: AppColors.primary,
                onChanged: onToggleAvailability,
              ),
            ],
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'მარაგი: ',
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        '${product.stockQuantity.toStringAsFixed(0)} ${product.unit}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    LucideIcons.trash2,
                    size: 16,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF334155),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(LucideIcons.pencil, size: 14),
                    label: Text(
                      'შეცვლა',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: onRestock,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(LucideIcons.packagePlus, size: 15),
                    label: Text(
                      'მარაგის შევსება',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
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

