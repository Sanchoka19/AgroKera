import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/custom_text_field.dart';
import 'agro_tag_item.dart';
import 'product_photo_entry.dart';

class ProductStep3Review extends StatelessWidget {
  final TextEditingController varietyController;
  final TextEditingController descriptionController;
  final List<ProductPhotoEntry> photos;
  final int mainPhotoIndex;
  final String title;
  final String selectedCategory;
  final String farmName;
  final String selectedUnit;
  final String stockText;
  final double effectivePrice;
  final double originalPrice;
  final bool isDiscountActive;
  final String discountPercentText;
  final bool isBulkDiscountActive;
  final String bulkMinQtyText;
  final String bulkDiscountPercentText;
  final double minOrder;
  final Set<String> selectedAgroTags;

  const ProductStep3Review({
    super.key,
    required this.varietyController,
    required this.descriptionController,
    required this.photos,
    this.mainPhotoIndex = 0,
    required this.title,
    required this.selectedCategory,
    required this.farmName,
    required this.selectedUnit,
    required this.stockText,
    required this.effectivePrice,
    required this.originalPrice,
    required this.isDiscountActive,
    required this.discountPercentText,
    required this.isBulkDiscountActive,
    required this.bulkMinQtyText,
    required this.bulkDiscountPercentText,
    required this.minOrder,
    required this.selectedAgroTags,
  });

  @override
  Widget build(BuildContext context) {
    final previewPhoto = (photos.isNotEmpty &&
            mainPhotoIndex >= 0 &&
            mainPhotoIndex < photos.length)
        ? photos[mainPhotoIndex]
        : (photos.isNotEmpty ? photos.first : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'აღწერა და გადახედვა',
          style: GoogleFonts.notoSansGeorgian(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'დაამატეთ მოკლე აღწერა და ნახეთ, როგორ გამოჩნდება პროდუქტი მყიდველისთვის',
          style: GoogleFonts.notoSansGeorgian(
            fontSize: 13,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 20),

        // Optional Variety Field
        CustomTextField(
          labelText: 'ჯიში / სახეობა (სურვილისამებრ)',
          hintText: 'მაგ: ვარდისფერი ქართული, ჩანდლერი...',
          controller: varietyController,
        ),
        const SizedBox(height: 14),

        // Description Input (Optional)
        CustomTextField(
          labelText: 'პროდუქტის აღწერა (სურვილისამებრ)',
          hintText: 'მოუყევით მყიდველებს თქვენი პროდუქტის გემოს, ხარისხის ან მოყვანის შესახებ...',
          controller: descriptionController,
          maxLines: 4,
          minLines: 3,
        ),
        const SizedBox(height: 24),

        // Section Title: Live Preview Card (Constrained with Expanded so it NEVER overflows!)
        Row(
          children: [
            const Icon(
              LucideIcons.eye,
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'პროდუქტის ბარათის გადახედვა',
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Marketplace Style Preview Card
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Header with Badges
              Stack(
                children: [
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F5F9),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: previewPhoto != null
                        ? (previewPhoto.bytes != null
                            ? Image.memory(
                                previewPhoto.bytes!,
                                fit: BoxFit.cover,
                              )
                            : (previewPhoto.url.startsWith('assets/')
                                ? Image.asset(
                                    previewPhoto.url,
                                    fit: BoxFit.cover,
                                  )
                                : Image.network(
                                    previewPhoto.url,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const Icon(
                                      LucideIcons.image,
                                      size: 40,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  )))
                        : const Center(
                            child: Icon(
                              LucideIcons.image,
                              size: 44,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                  ),

                  // Discount Badge
                  if (isDiscountActive &&
                      (int.tryParse(discountPercentText) ?? 0) > 0)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentWarm,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '-$discountPercentText%',
                          style: GoogleFonts.notoSansGeorgian(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                  // Stock Badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'მარაგშია: ${stockText.isEmpty ? "0" : stockText} $selectedUnit',
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Card Body Details
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          selectedCategory,
                          style: GoogleFonts.notoSansGeorgian(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('•', style: TextStyle(color: Color(0xFFCBD5E1))),
                        const SizedBox(width: 8),
                        Text(
                          farmName,
                          style: GoogleFonts.notoSansGeorgian(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title.isEmpty ? 'პროდუქტის დასახელება' : title,
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),

                    // Agro Tags in Preview with Lucide Icons
                    if (selectedAgroTags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: selectedAgroTags.map((tag) {
                          final icon = AgroTagItem.iconFor(tag);
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEBF7EF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(icon, size: 12, color: AppColors.primaryDark),
                                const SizedBox(width: 4),
                                Text(
                                  tag,
                                  style: GoogleFonts.notoSansGeorgian(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    const SizedBox(height: 12),
                    const Divider(color: Color(0xFFF1F5F9), height: 1),
                    const SizedBox(height: 12),

                    // Price Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ფასი 1 $selectedUnit-ზე',
                                style: GoogleFonts.notoSansGeorgian(
                                  fontSize: 11,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 2,
                                children: [
                                  Text(
                                    '₾${effectivePrice.toStringAsFixed(2)}',
                                    style: GoogleFonts.notoSansGeorgian(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  if (isDiscountActive &&
                                      originalPrice > effectivePrice) ...[
                                    Text(
                                      '₾${originalPrice.toStringAsFixed(2)}',
                                      style: GoogleFonts.notoSansGeorgian(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF94A3B8),
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Bulk Tag or Min Order Badge
                        if (isBulkDiscountActive &&
                            bulkMinQtyText.isNotEmpty &&
                            bulkDiscountPercentText.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F7EE),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'საბითუმო: $bulkMinQtyText $selectedUnit-დან',
                              style: GoogleFonts.notoSansGeorgian(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          )
                        else if (minOrder > 1)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'მინ. ${minOrder.toInt()} $selectedUnit',
                              style: GoogleFonts.notoSansGeorgian(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF475569),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
