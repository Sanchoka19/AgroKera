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
import '../screens/add_edit_product_screen.dart';

/// Modal Bottom Sheet for adding or editing a Farmer Product
class ProductFormSheet extends ConsumerStatefulWidget {
  final ProductModel? existing;

  const ProductFormSheet({
    super.key,
    this.existing,
  });

  static Future<void> show(BuildContext context, {ProductModel? existing}) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEditProductScreen(existing: existing),
      ),
    );
  }

  @override
  ConsumerState<ProductFormSheet> createState() => _ProductFormSheetState();
}

class _SelectedPhotoEntry {
  final String url;
  final Uint8List? bytes;

  const _SelectedPhotoEntry({
    required this.url,
    this.bytes,
  });
}

class _ProductFormSheetState extends ConsumerState<ProductFormSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _minOrderCtrl;
  late final TextEditingController _discountCtrl;
  late final TextEditingController _bulkMinQtyCtrl;
  late final TextEditingController _bulkDiscountCtrl;
  late String _selectedCategory;
  late String _selectedUnit;
  final List<_SelectedPhotoEntry> _selectedPhotos = [];
  bool _isUploadingPhoto = false;

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
    _minOrderCtrl = TextEditingController(
      text: existing != null
          ? (existing.minOrderQuantity.truncateToDouble() ==
                  existing.minOrderQuantity
              ? existing.minOrderQuantity.toInt().toString()
              : existing.minOrderQuantity.toString())
          : '1',
    );
    _discountCtrl = TextEditingController(
      text: (existing?.discountPercent != null &&
              existing!.discountPercent! > 0)
          ? existing.discountPercent.toString()
          : '',
    );
    _bulkMinQtyCtrl = TextEditingController(
      text: (existing?.bulkDiscountMinQty != null &&
              existing!.bulkDiscountMinQty! > 0)
          ? (existing.bulkDiscountMinQty!.truncateToDouble() ==
                  existing.bulkDiscountMinQty!
              ? existing.bulkDiscountMinQty!.toInt().toString()
              : existing.bulkDiscountMinQty!.toString())
          : '',
    );
    _bulkDiscountCtrl = TextEditingController(
      text: (existing?.bulkDiscountPercent != null &&
              existing!.bulkDiscountPercent! > 0)
          ? existing.bulkDiscountPercent.toString()
          : '',
    );
    _selectedCategory = existing?.category ?? MockData.categories.first.name;
    _selectedUnit = existing?.unit ?? 'კგ';
    if (existing != null) {
      for (final img in existing.galleryImages.take(
        FarmerInventoryNotifier.maxProductPhotos,
      )) {
        if (img.trim().isNotEmpty) {
          _selectedPhotos.add(_SelectedPhotoEntry(url: img));
        }
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _descCtrl.dispose();
    _minOrderCtrl.dispose();
    _discountCtrl.dispose();
    _bulkMinQtyCtrl.dispose();
    _bulkDiscountCtrl.dispose();
    super.dispose();
  }

  int get _remainingPhotoSlots =>
      FarmerInventoryNotifier.maxProductPhotos - _selectedPhotos.length;

  Future<void> _openPhotoSourceSheet() async {
    if (_remainingPhotoSlots <= 0) {
      AppToast.info(
        context,
        'მაქსიმუმ ${FarmerInventoryNotifier.maxProductPhotos} ფოტოს დამატებაა შესაძლებელი',
      );
      return;
    }

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
                  'პროდუქტის ფოტოს დამატება (${_selectedPhotos.length}/${FarmerInventoryNotifier.maxProductPhotos})',
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
                    await _handlePickCameraPhoto();
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
                    'აირჩიეთ 1 ან რამდენიმე ფოტო (დარჩენილია $_remainingPhotoSlots ადგილი)',
                    style: GoogleFonts.notoSansGeorgian(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _handlePickGalleryPhotos();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handlePickCameraPhoto() async {
    if (_remainingPhotoSlots <= 0) return;
    setState(() => _isUploadingPhoto = true);
    final result = await ref
        .read(farmerInventoryProvider.notifier)
        .pickPhoto(ImageSource.camera);
    if (!mounted) return;
    setState(() => _isUploadingPhoto = false);
    if (result == null) return;
    if (!result.isSuccess || result.url == null) {
      AppToast.error(
        context,
        result.errorMessage ?? 'ფოტოს გადაღება ვერ მოხერხდა',
      );
      return;
    }
    setState(() {
      _selectedPhotos.add(
        _SelectedPhotoEntry(url: result.url!, bytes: result.bytes),
      );
    });
    AppToast.success(context, 'ფოტო წარმატებით გადაღებულია და შეკუმშულია!');
  }

  Future<void> _handlePickGalleryPhotos() async {
    if (_remainingPhotoSlots <= 0) return;
    setState(() => _isUploadingPhoto = true);
    final results = await ref
        .read(farmerInventoryProvider.notifier)
        .pickGalleryPhotos(remainingSlots: _remainingPhotoSlots);
    if (!mounted) return;
    setState(() => _isUploadingPhoto = false);
    if (results.isEmpty) return;

    int addedCount = 0;
    String? firstError;
    setState(() {
      for (final res in results) {
        if (res.isSuccess &&
            res.url != null &&
            _selectedPhotos.length < FarmerInventoryNotifier.maxProductPhotos) {
          _selectedPhotos.add(
            _SelectedPhotoEntry(url: res.url!, bytes: res.bytes),
          );
          addedCount++;
        } else if (res.errorMessage != null) {
          firstError ??= res.errorMessage;
        }
      }
    });

    if (addedCount > 0) {
      AppToast.success(
        context,
        addedCount == 1
            ? 'ფოტო წარმატებით აიტვირთა!'
            : '$addedCount ფოტო წარმატებით აიტვირთა!',
      );
    } else if (firstError != null) {
      AppToast.error(context, firstError!);
    }
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
    final imageUrls = _selectedPhotos.map((p) => p.url).toList();
    final error = notifier.validateProductForm(
      imageUrl: imageUrls.firstOrNull,
      images: imageUrls,
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
    final minOrder = double.tryParse(_minOrderCtrl.text.trim()) ?? 1.0;
    final discount = int.tryParse(_discountCtrl.text.trim());
    final bulkMinQty = double.tryParse(_bulkMinQtyCtrl.text.trim());
    final bulkDiscount = int.tryParse(_bulkDiscountCtrl.text.trim());

    await notifier.saveProduct(
      existing: widget.existing,
      title: title,
      category: _selectedCategory,
      price: price,
      unit: _selectedUnit,
      stockQuantity: stock,
      description: _descCtrl.text.trim(),
      imageUrl: imageUrls.first,
      images: imageUrls,
      minOrderQuantity: minOrder > 0 ? minOrder : 1.0,
      discountPercent: (discount != null && discount > 0) ? discount : null,
      bulkDiscountMinQty:
          (bulkMinQty != null && bulkMinQty > 0) ? bulkMinQty : null,
      bulkDiscountPercent:
          (bulkDiscount != null && bulkDiscount > 0) ? bulkDiscount : null,
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

            // Multi-Photo Upload Section (Up to 5 Rounded Squares with + button)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'პროდუქტის ფოტოები',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  '${_selectedPhotos.length}/${FarmerInventoryNotifier.maxProductPhotos}',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: _selectedPhotos.isNotEmpty
                        ? AppColors.primary
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 84,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (int i = 0; i < _selectedPhotos.length; i++) ...[
                    Container(
                      width: 84,
                      height: 84,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F7EE),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: i == 0
                              ? AppColors.primary
                              : const Color(0xFFCBD5E1),
                          width: i == 0 ? 1.8 : 1.2,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (_selectedPhotos[i].bytes != null)
                            Image.memory(
                              _selectedPhotos[i].bytes!,
                              fit: BoxFit.cover,
                            )
                          else if (_selectedPhotos[i].url.startsWith('assets/'))
                            Image.asset(
                              _selectedPhotos[i].url,
                              fit: BoxFit.cover,
                            )
                          else
                            Image.network(
                              _selectedPhotos[i].url,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const Icon(
                                LucideIcons.image,
                                color: AppColors.primary,
                              ),
                            ),
                          if (i == 0)
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                color: AppColors.primary.withValues(alpha: 0.88),
                                alignment: Alignment.center,
                                child: Text(
                                  'მთავარი',
                                  style: GoogleFonts.notoSansGeorgian(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedPhotos.removeAt(i);
                                });
                              },
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
                  ],
                  if (_selectedPhotos.length <
                      FarmerInventoryNotifier.maxProductPhotos)
                    InkWell(
                      onTap: _isUploadingPhoto ? null : _openPhotoSourceSheet,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFCBD5E1),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: _isUploadingPhoto
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: AppColors.primary,
                                  ),
                                )
                              : Container(
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
                ],
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
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    labelText: 'მინ. შეკვეთა ($_selectedUnit)',
                    hintText: '1',
                    controller: _minOrderCtrl,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    labelText: 'ფასდაკლება (%)',
                    hintText: 'მაგ: 10',
                    controller: _discountCtrl,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.boxes,
                        size: 17,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'საბითუმო / მოცულობითი ფასდაკლება',
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'მიუთითეთ რაოდენობა, რის შემდეგაც მყიდველს დაუკლდება პროცენტი (არასავალდებულო)',
                    style: GoogleFonts.notoSansGeorgian(
                      fontSize: 11.5,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          labelText: 'ზღვარი ($_selectedUnit-დან)',
                          hintText: 'მაგ: 10',
                          controller: _bulkMinQtyCtrl,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          labelText: 'საბითუმო ფასდაკლება (%)',
                          hintText: 'მაგ: 15',
                          controller: _bulkDiscountCtrl,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
