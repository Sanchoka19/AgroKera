import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/custom_text_field.dart';
import '../../../../marketplace/data/mock_data.dart';
import '../../providers/farmer_inventory_provider.dart';
import 'agro_tag_item.dart';
import 'product_photo_entry.dart';

class ProductStep1Identity extends StatelessWidget {
  final List<ProductPhotoEntry> photos;
  final int mainPhotoIndex;
  final ValueChanged<int> onSetMainPhoto;
  final TextEditingController titleController;
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;
  final Set<String> selectedAgroTags;
  final ValueChanged<String> onToggleAgroTag;
  final VoidCallback onAddPhotoPressed;
  final ValueChanged<int> onRemovePhotoPressed;
  final bool isUploadingPhoto;

  const ProductStep1Identity({
    super.key,
    required this.photos,
    required this.mainPhotoIndex,
    required this.onSetMainPhoto,
    required this.titleController,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.selectedAgroTags,
    required this.onToggleAgroTag,
    required this.onAddPhotoPressed,
    required this.onRemovePhotoPressed,
    required this.isUploadingPhoto,
  });

  void _openCategorySelectionSheet(BuildContext context) {
    final categories = MockData.categories.map((c) => c.name).toList();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.82,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'აირჩიეთ კატეგორია',
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.of(ctx).pop(),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          LucideIcons.x,
                          size: 16,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Divider(color: Color(0xFFF1F5F9), height: 1),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  itemCount: categories.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final item = categories[index];
                    final isSelected = item == selectedCategory;
                    return InkWell(
                      onTap: () {
                        onCategoryChanged(item);
                        Navigator.of(ctx).pop();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFEBF7EF)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : const Color(0xFFE2E8F0),
                            width: isSelected ? 1.4 : 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item,
                                style: GoogleFonts.notoSansGeorgian(
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? AppColors.primaryDark
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                LucideIcons.check,
                                size: 18,
                                color: AppColors.primary,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'პროდუქტის იდენტობა და ფოტოები',
          style: GoogleFonts.notoSansGeorgian(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'ატვირთეთ პროდუქტის ხარისხიანი ფოტოები და მიუთითეთ დასახელება',
          style: GoogleFonts.notoSansGeorgian(
            fontSize: 13,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 20),

        // Photos Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'პროდუქტის ფოტოები *',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                if (photos.length > 1) ...[
                  const SizedBox(height: 2),
                  Text(
                    'დააკლიკეთ ფოტოს მის მთავარ ფოტოდ ასარჩევად',
                    style: GoogleFonts.notoSansGeorgian(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
            Text(
              '${photos.length}/${FarmerInventoryNotifier.maxProductPhotos}',
              style: GoogleFonts.notoSansGeorgian(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: photos.isNotEmpty
                    ? AppColors.primary
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Multi-Photo List
        SizedBox(
          height: 90,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (int i = 0; i < photos.length; i++) ...[
                GestureDetector(
                  onTap: () => onSetMainPhoto(i),
                  child: Container(
                    width: 90,
                    height: 90,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F7EE),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: i == mainPhotoIndex
                            ? AppColors.primary
                            : const Color(0xFFCBD5E1),
                        width: i == mainPhotoIndex ? 2.2 : 1.2,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (photos[i].bytes != null)
                          Image.memory(
                            photos[i].bytes!,
                            fit: BoxFit.cover,
                          )
                        else if (photos[i].url.startsWith('assets/'))
                          Image.asset(
                            photos[i].url,
                            fit: BoxFit.cover,
                          )
                        else
                          Image.network(
                            photos[i].url,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(
                              LucideIcons.image,
                              color: AppColors.primary,
                            ),
                          ),

                        // Main Photo Badge
                        if (i == mainPhotoIndex)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 2.5),
                              color: AppColors.primary.withValues(alpha: 0.94),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    LucideIcons.star,
                                    size: 10,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'მთავარი',
                                    style: GoogleFonts.notoSansGeorgian(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Positioned(
                            top: 4,
                            left: 4,
                            child: GestureDetector(
                              onTap: () => onSetMainPhoto(i),
                              child: Container(
                                padding: const EdgeInsets.all(3.5),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  LucideIcons.star,
                                  size: 11,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ),

                        // Delete button
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => onRemovePhotoPressed(i),
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                LucideIcons.x,
                                size: 13,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (photos.length < FarmerInventoryNotifier.maxProductPhotos)
                InkWell(
                  onTap: isUploadingPhoto ? null : onAddPhotoPressed,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFCBD5E1),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: isUploadingPhoto
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: AppColors.primary,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F7EE),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    LucideIcons.plus,
                                    color: AppColors.primary,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'დამატება',
                                  style: GoogleFonts.notoSansGeorgian(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Title Input
        CustomTextField(
          labelText: 'პროდუქტის დასახელება *',
          hintText: 'მაგ: ვარდისფერი პომიდორი',
          controller: titleController,
        ),
        const SizedBox(height: 16),

        // Category Selector
        Text(
          'კატეგორია *',
          style: GoogleFonts.notoSansGeorgian(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () => _openCategorySelectionSheet(context),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      LucideIcons.layoutGrid,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      selectedCategory,
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const Icon(
                  LucideIcons.chevronDown,
                  size: 18,
                  color: Color(0xFF64748B),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),

        // Agro Tags
        Text(
          'აგრო-ნიშნულები (სურვილისამებრ)',
          style: GoogleFonts.notoSansGeorgian(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'მონიშნეთ თვისებები, რომლებიც მყიდველს ხარისხში დაარწმუნებს',
          style: GoogleFonts.notoSansGeorgian(
            fontSize: 11.5,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AgroTagItem.all.map((tag) {
            final isSel = selectedAgroTags.contains(tag.label);
            return FilterChip(
              avatar: Icon(
                tag.icon,
                size: 15,
                color: isSel ? Colors.white : AppColors.primary,
              ),
              label: Text(tag.label),
              labelStyle: GoogleFonts.notoSansGeorgian(
                fontSize: 12.5,
                fontWeight: isSel ? FontWeight.w700 : FontWeight.w600,
                color: isSel ? Colors.white : const Color(0xFF334155),
              ),
              selected: isSel,
              selectedColor: AppColors.primary,
              backgroundColor: const Color(0xFFF1F5F9),
              showCheckmark: false,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSel ? AppColors.primary : const Color(0xFFE2E8F0),
                ),
              ),
              onSelected: (_) => onToggleAgroTag(tag.label),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
