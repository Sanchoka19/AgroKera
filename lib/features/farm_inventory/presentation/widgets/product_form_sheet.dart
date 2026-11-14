import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../marketplace/data/mock_data.dart';
import '../../../marketplace/data/models/product_model.dart';
import '../providers/farmer_inventory_provider.dart';

/// Modal Bottom Sheet for adding or editing a Farmer Product
class ProductFormSheet extends ConsumerStatefulWidget {
  final ProductModel? existing;

  const ProductFormSheet({
    super.key,
    this.existing,
  });

  static Future<void> show(BuildContext context, {ProductModel? existing}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProductFormSheet(existing: existing),
    );
  }

  @override
  ConsumerState<ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends ConsumerState<ProductFormSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _descCtrl;
  late String _selectedCategory;
  late String _selectedUnit;
  String? _selectedImageUrl;
  Uint8List? _selectedImageBytes;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleCtrl = TextEditingController(text: existing?.title ?? '');
    _priceCtrl = TextEditingController(
      text: existing != null ? existing.price.toStringAsFixed(1) : '',
    );
    _stockCtrl = TextEditingController(
      text: existing != null ? existing.stockQuantity.toStringAsFixed(0) : '50',
    );
    _descCtrl = TextEditingController(text: existing?.description ?? '');
    _selectedCategory = existing?.category ?? MockData.categories.first.name;
    _selectedUnit = existing?.unit ?? 'კგ';
    _selectedImageUrl = existing?.imageUrl;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _openPhotoSourceSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'პროდუქტის ფოტოს დამატება',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F7EE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.camera,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'კამერით გადაღება',
                    style: GoogleFonts.notoSansGeorgian(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    'გახსნის კამერას ფოტოს გადასაღებად',
                    style: GoogleFonts.notoSansGeorgian(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _handlePickPhoto(ImageSource.camera);
                  },
                ),
                const Divider(height: 12, color: Color(0xFFF1F5F9)),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F7EE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.image,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'გალერეიდან არჩევა',
                    style: GoogleFonts.notoSansGeorgian(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    'აირჩიეთ ფოტო მოწყობილობიდან',
                    style: GoogleFonts.notoSansGeorgian(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _handlePickPhoto(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handlePickPhoto(ImageSource source) async {
    final result =
        await ref.read(farmerInventoryProvider.notifier).pickPhoto(source);
    if (!mounted || result == null) return;
    if (!result.isSuccess) {
      AppToast.error(context, result.errorMessage ?? 'ფოტოს არჩევა ვერ მოხერხდა');
      return;
    }
    setState(() {
      _selectedImageUrl = result.url;
      _selectedImageBytes = result.bytes;
    });
    AppToast.success(
      context,
      source == ImageSource.camera
          ? 'ფოტო წარმატებით გადაღებულია!'
          : 'ფოტო წარმატებით აიტვირთა!',
    );
  }

  void _openCategorySelectionSheet() {
    final categories = MockData.categories.map((c) => c.name).toList();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.65,
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
              const SizedBox(height: 12),
              const Divider(color: Color(0xFFF1F5F9), height: 1),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: categories.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final item = categories[index];
                    final isSelected = item == _selectedCategory;
                    return InkWell(
                      onTap: () {
                        setState(() => _selectedCategory = item);
                        Navigator.of(ctx).pop();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
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

  Future<void> _handleSave() async {
    final notifier = ref.read(farmerInventoryProvider.notifier);
    final error = notifier.validateProductForm(
      imageUrl: _selectedImageUrl,
      title: _titleCtrl.text,
      priceText: _priceCtrl.text,
      stockText: _stockCtrl.text,
      description: _descCtrl.text,
    );
    if (error != null) {
      AppToast.error(context, error);
      return;
    }

    final title = _titleCtrl.text.trim();
    final price = double.parse(_priceCtrl.text.trim());
    final stock = double.parse(_stockCtrl.text.trim());

    await notifier.saveProduct(
      existing: widget.existing,
      title: title,
      category: _selectedCategory,
      price: price,
      unit: _selectedUnit,
      stockQuantity: stock,
      description: _descCtrl.text.trim(),
      imageUrl: _selectedImageUrl!,
    );

    if (!mounted) return;
    Navigator.of(context).pop();
    AppToast.success(
      context,
      widget.existing == null
          ? 'პროდუქტი "$title" დაემატა ბაზაში!'
          : 'პროდუქტი "$title" განახლდა!',
    );
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.existing;
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            const SizedBox(height: 16),
            Text(
              existing == null
                  ? 'ახალი პროდუქტის დამატება'
                  : 'პროდუქტის რედაქტირება',
              style: GoogleFonts.notoSansGeorgian(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 16),

            // Required Product Photo Upload Section (Rounded Square with + button)
            Text(
              'პროდუქტის ფოტო',
              style: GoogleFonts.notoSansGeorgian(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: _openPhotoSourceSheet,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: _selectedImageUrl != null
                        ? const Color(0xFFE8F7EE)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedImageUrl != null
                          ? AppColors.primary
                          : const Color(0xFFCBD5E1),
                      width: 1.5,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _selectedImageBytes != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.memory(
                              _selectedImageBytes!,
                              fit: BoxFit.cover,
                            ),
                            Container(
                              color: Colors.black.withValues(alpha: 0.25),
                              alignment: Alignment.center,
                              child: const Icon(
                                LucideIcons.camera,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ],
                        )
                      : _selectedImageUrl != null
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  _selectedImageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const Icon(
                                    LucideIcons.image,
                                    color: AppColors.primary,
                                  ),
                                ),
                                Container(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    LucideIcons.camera,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ],
                            )
                          : Center(
                              child: Container(
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
                            ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              labelText: 'პროდუქტის დასახელება',
              hintText: 'მაგ: ვარდისფერი პომიდორი',
              controller: _titleCtrl,
            ),
            const SizedBox(height: 12),
            Text(
              'კატეგორია',
              style: GoogleFonts.notoSansGeorgian(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: _openCategorySelectionSheet,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _selectedCategory,
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    labelText: 'ფასი (₾)',
                    hintText: 'მაგ: 4.50',
                    controller: _priceCtrl,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    labelText: 'მარაგი ($_selectedUnit)',
                    hintText: 'მაგ: 50',
                    controller: _stockCtrl,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: ['კგ', 'ცალი', 'ბოთლი', 'ყუთი'].map((u) {
                final isSel = _selectedUnit == u;
                return ChoiceChip(
                  label: Text(
                    u,
                    style: GoogleFonts.notoSansGeorgian(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSel ? Colors.white : const Color(0xFF334155),
                    ),
                  ),
                  selected: isSel,
                  selectedColor: AppColors.primary,
                  onSelected: (_) {
                    setState(() => _selectedUnit = u);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            CustomTextField(
              labelText: 'აღწერა',
              hintText: 'მოკლე ინფორმაცია პროდუქტის შესახებ...',
              controller: _descCtrl,
              maxLines: 4,
              minLines: 3,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  existing == null
                      ? 'პროდუქტის გამოქვეყნება'
                      : 'ცვლილებების შენახვა',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
