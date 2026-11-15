import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/auth/auth_state_provider.dart';
import '../../../../core/constants/app_categories.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_confirmation_bottom_sheet.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../marketplace/data/models/product_model.dart';
import '../providers/farmer_inventory_provider.dart';
import '../providers/product_form_validator.dart';
import '../widgets/product_steps/product_photo_entry.dart';
import '../widgets/product_steps/product_step1_identity.dart';
import '../widgets/product_steps/product_step2_pricing.dart';
import '../widgets/product_steps/product_step3_review.dart';

/// Clean 3-Step Wizard Screen Orchestrator for Adding/Editing a Product.
/// Steps are cleanly decomposed into separate presentation widgets:
/// - [ProductStep1Identity] - Photos, Title, Category, Agro-Tags
/// - [ProductStep2Pricing] - Unit, Price, Stock, Min Order, Discounts
/// - [ProductStep3Review] - Variety, Description, Live Marketplace Preview
class AddEditProductScreen extends ConsumerStatefulWidget {
  final ProductModel? existing;

  const AddEditProductScreen({
    super.key,
    this.existing,
  });

  @override
  ConsumerState<AddEditProductScreen> createState() =>
      _AddEditProductScreenState();
}

class _AddEditProductScreenState extends ConsumerState<AddEditProductScreen> {
  int _currentStep = 1;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;

  // Step 1 State
  final List<ProductPhotoEntry> _selectedPhotos = [];
  int _mainPhotoIndex = 0;
  late final TextEditingController _titleCtrl;
  late String _selectedCategory;
  final Set<String> _selectedAgroTags = {};

  // Step 2 State
  late final TextEditingController _priceCtrl;
  late final TextEditingController _stockCtrl;
  late String _selectedUnit;
  late double _minOrder;
  late final TextEditingController _minOrderCtrl;
  bool _isDiscountActive = false;
  late final TextEditingController _discountCtrl;
  bool _isBulkDiscountActive = false;
  late final TextEditingController _bulkMinQtyCtrl;
  late final TextEditingController _bulkDiscountCtrl;

  // Step 3 State
  late final TextEditingController _descCtrl;
  late final TextEditingController _varietyCtrl;

  int get _remainingPhotoSlots =>
      FarmerInventoryNotifier.maxProductPhotos - _selectedPhotos.length;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;

    // Photos
    if (existing != null) {
      for (final img in existing.galleryImages.take(
        FarmerInventoryNotifier.maxProductPhotos,
      )) {
        if (img.trim().isNotEmpty) {
          _selectedPhotos.add(ProductPhotoEntry(url: img));
        }
      }
    }

    // Step 1
    _titleCtrl = TextEditingController(text: existing?.title ?? '');
    _selectedCategory = existing?.category ?? AppCategories.categories.first.name;

    // Step 2
    final initialBasePrice = existing?.originalPrice ?? existing?.price;
    _priceCtrl = TextEditingController(
      text: initialBasePrice != null
          ? (initialBasePrice % 1 == 0
              ? initialBasePrice.toInt().toString()
              : initialBasePrice.toStringAsFixed(2))
          : '',
    );
    _stockCtrl = TextEditingController(
      text: existing != null ? existing.stockQuantity.toStringAsFixed(0) : '50',
    );
    _selectedUnit = existing?.unit ?? 'კგ';
    _minOrder = existing?.minOrderQuantity ?? 1.0;
    _minOrderCtrl = TextEditingController(
      text: _minOrder.truncateToDouble() == _minOrder
          ? _minOrder.toInt().toString()
          : _minOrder.toString(),
    );

    _isDiscountActive =
        existing?.discountPercent != null && existing!.discountPercent! > 0;
    _discountCtrl = TextEditingController(
      text: _isDiscountActive ? existing!.discountPercent.toString() : '',
    );

    _isBulkDiscountActive = existing?.hasBulkDiscount ?? false;
    _bulkMinQtyCtrl = TextEditingController(
      text: _isBulkDiscountActive
          ? (existing!.bulkDiscountMinQty!.truncateToDouble() ==
                  existing.bulkDiscountMinQty!
              ? existing.bulkDiscountMinQty!.toInt().toString()
              : existing.bulkDiscountMinQty!.toString())
          : '',
    );
    _bulkDiscountCtrl = TextEditingController(
      text: _isBulkDiscountActive
          ? existing!.bulkDiscountPercent.toString()
          : '',
    );

    // Step 3
    _descCtrl = TextEditingController(text: existing?.description ?? '');
    _varietyCtrl = TextEditingController();

    // Listeners for live preview updates
    _priceCtrl.addListener(_onFieldChanged);
    _discountCtrl.addListener(_onFieldChanged);
    _bulkMinQtyCtrl.addListener(_onFieldChanged);
    _bulkDiscountCtrl.addListener(_onFieldChanged);
    _stockCtrl.addListener(_onFieldChanged);
    _titleCtrl.addListener(_onFieldChanged);
    _minOrderCtrl.addListener(_onMinOrderInputChanged);
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  void _onMinOrderInputChanged() {
    final parsed = double.tryParse(_minOrderCtrl.text.trim());
    if (parsed != null && parsed > 0 && parsed != _minOrder) {
      _minOrder = parsed;
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _priceCtrl.removeListener(_onFieldChanged);
    _discountCtrl.removeListener(_onFieldChanged);
    _bulkMinQtyCtrl.removeListener(_onFieldChanged);
    _bulkDiscountCtrl.removeListener(_onFieldChanged);
    _stockCtrl.removeListener(_onFieldChanged);
    _titleCtrl.removeListener(_onFieldChanged);
    _minOrderCtrl.removeListener(_onMinOrderInputChanged);

    _titleCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _minOrderCtrl.dispose();
    _discountCtrl.dispose();
    _bulkMinQtyCtrl.dispose();
    _bulkDiscountCtrl.dispose();
    _descCtrl.dispose();
    _varietyCtrl.dispose();
    super.dispose();
  }

  // --- Photo Picker Handling ---

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
      builder: (ctx) => SafeArea(
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
                  await _handlePickCamera();
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
                  await _handlePickGallery();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handlePickCamera() async {
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
        ProductPhotoEntry(url: result.url!, bytes: result.bytes),
      );
    });
    AppToast.success(context, 'ფოტო წარმატებით გადაღებულია და შეკუმშულია!');
  }

  Future<void> _handlePickGallery() async {
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
            ProductPhotoEntry(url: res.url!, bytes: res.bytes),
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

  // --- Step Navigation & Orchestration ---

  void _onBack() {
    HapticFeedback.lightImpact();
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    } else {
      _confirmExit();
    }
  }

  Future<void> _confirmExit() async {
    final hasChanges = _titleCtrl.text.isNotEmpty ||
        _priceCtrl.text.isNotEmpty ||
        _selectedPhotos.isNotEmpty;
    if (!hasChanges) {
      Navigator.of(context).pop();
      return;
    }

    final confirmed = await AppConfirmationBottomSheet.show(
      context: context,
      title: 'გასვლა ფორმიდან',
      message: 'შეყვანილი მონაცემები არ შეინახება. ნამდვილად გსურთ გასვლა?',
      confirmText: 'გასვლა',
      cancelText: 'დარჩენა',
      type: ConfirmationType.warning,
      icon: LucideIcons.alertTriangle,
    );
    if (confirmed && mounted) {
      Navigator.of(context).pop();
    }
  }

  void _onNext() {
    HapticFeedback.lightImpact();
    if (_currentStep == 1) {
      final error = ProductFormValidator.validateStep1(
        photoCount: _selectedPhotos.length,
        title: _titleCtrl.text,
        category: _selectedCategory,
      );
      if (error != null) {
        AppToast.error(context, error);
        return;
      }
      setState(() => _currentStep = 2);
    } else if (_currentStep == 2) {
      final error = ProductFormValidator.validateStep2(
        priceText: _priceCtrl.text,
        stockText: _stockCtrl.text,
        isDiscountActive: _isDiscountActive,
        discountText: _discountCtrl.text,
        isBulkDiscountActive: _isBulkDiscountActive,
        bulkMinQtyText: _bulkMinQtyCtrl.text,
        bulkDiscountText: _bulkDiscountCtrl.text,
      );
      if (error != null) {
        AppToast.error(context, error);
        return;
      }
      setState(() => _currentStep = 3);
    } else {
      _handleSave();
    }
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    final notifier = ref.read(farmerInventoryProvider.notifier);

    // Reorder images so selected main photo is guaranteed first
    final List<String> orderedImageUrls = [];
    if (_selectedPhotos.isNotEmpty) {
      final validMain = _mainPhotoIndex.clamp(0, _selectedPhotos.length - 1);
      orderedImageUrls.add(_selectedPhotos[validMain].url);
      for (int i = 0; i < _selectedPhotos.length; i++) {
        if (i != validMain) {
          orderedImageUrls.add(_selectedPhotos[i].url);
        }
      }
    }

    final title = _titleCtrl.text.trim();
    final price = double.parse(_priceCtrl.text.trim());
    final stock = double.parse(_stockCtrl.text.trim());
    final minOrder = _minOrder > 0 ? _minOrder : 1.0;

    final discount = _isDiscountActive
        ? int.tryParse(_discountCtrl.text.trim())
        : null;
    final bulkMinQty = _isBulkDiscountActive
        ? double.tryParse(_bulkMinQtyCtrl.text.trim())
        : null;
    final bulkDiscount = _isBulkDiscountActive
        ? int.tryParse(_bulkDiscountCtrl.text.trim())
        : null;

    final composedDescription = ProductFormValidator.composeDescription(
      variety: _varietyCtrl.text,
      agroTags: _selectedAgroTags,
      rawDescription: _descCtrl.text,
    );

    final hasActiveDiscount = discount != null && discount > 0;
    final effectiveSellingPrice = hasActiveDiscount
        ? (price * (1.0 - (discount / 100.0)))
        : price;
    final originalStrikethroughPrice = hasActiveDiscount ? price : null;

    try {
      await notifier.saveProduct(
        existing: widget.existing,
        title: title,
        category: _selectedCategory,
        price: effectiveSellingPrice,
        originalPrice: originalStrikethroughPrice,
        unit: _selectedUnit,
        stockQuantity: stock,
        description: composedDescription,
        imageUrl: orderedImageUrls.first,
        images: orderedImageUrls,
        minOrderQuantity: minOrder,
        discountPercent: hasActiveDiscount ? discount : null,
        bulkDiscountMinQty:
            (bulkMinQty != null && bulkMinQty > 0) ? bulkMinQty : null,
        bulkDiscountPercent:
            (bulkDiscount != null && bulkDiscount > 0) ? bulkDiscount : null,
      );

      if (!mounted) return;
      setState(() => _isSaving = false);
      Navigator.of(context).pop();
      AppToast.success(
        context,
        widget.existing == null
            ? 'პროდუქტი "$title" წარმატებით გამოქვეყნდა!'
            : 'პროდუქტი "$title" განახლდა!',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      AppToast.error(context, 'შენახვისას დაფიქსირდა შეცდომა');
    }
  }

  double get _currentPrice => double.tryParse(_priceCtrl.text.trim()) ?? 0.0;

  double get _discountedPrice => ProductFormValidator.calculateDiscountedPrice(
        basePrice: _currentPrice,
        isDiscountActive: _isDiscountActive,
        discountText: _discountCtrl.text,
      );

  double get _bulkUnitPrice => ProductFormValidator.calculateBulkUnitPrice(
        basePrice: _currentPrice,
        isBulkDiscountActive: _isBulkDiscountActive,
        bulkDiscountText: _bulkDiscountCtrl.text,
      );

  @override
  Widget build(BuildContext context) {
    final farmName = ref.watch(authStateProvider).farmName ?? 'ჩემი მეურნეობა';
    final effectivePrice = _isDiscountActive ? _discountedPrice : _currentPrice;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            LucideIcons.chevronLeft,
            color: AppColors.textPrimary,
            size: 28,
          ),
          onPressed: _onBack,
        ),
        title: _buildProgressBar(),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              LucideIcons.x,
              color: AppColors.textSecondary,
              size: 22,
            ),
            onPressed: _confirmExit,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              // Anchored to Alignment.topCenter so there is NO awkward top white space!
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                switchInCurve: Curves.easeInOutCubic,
                switchOutCurve: Curves.easeInOutCubic,
                layoutBuilder: (currentChild, previousChildren) {
                  return Stack(
                    alignment: Alignment.topCenter,
                    children: <Widget>[
                      ...previousChildren,
                      ?currentChild,
                    ],
                  );
                },
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.04, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey<int>(_currentStep),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: switch (_currentStep) {
                      1 => ProductStep1Identity(
                          photos: _selectedPhotos,
                          mainPhotoIndex: _mainPhotoIndex,
                          onSetMainPhoto: (idx) {
                            setState(() => _mainPhotoIndex = idx);
                            AppToast.info(context, 'მთავარი ფოტო არჩეულია');
                          },
                          titleController: _titleCtrl,
                          selectedCategory: _selectedCategory,
                          onCategoryChanged: (cat) =>
                              setState(() => _selectedCategory = cat),
                          selectedAgroTags: _selectedAgroTags,
                          onToggleAgroTag: (tag) {
                            setState(() {
                              if (_selectedAgroTags.contains(tag)) {
                                _selectedAgroTags.remove(tag);
                              } else {
                                _selectedAgroTags.add(tag);
                              }
                            });
                          },
                          onAddPhotoPressed: _openPhotoSourceSheet,
                          onRemovePhotoPressed: (idx) {
                            setState(() {
                              _selectedPhotos.removeAt(idx);
                              if (_mainPhotoIndex == idx) {
                                _mainPhotoIndex = 0;
                              } else if (_mainPhotoIndex > idx) {
                                _mainPhotoIndex--;
                              }
                            });
                          },
                          isUploadingPhoto: _isUploadingPhoto,
                        ),
                      2 => ProductStep2Pricing(
                          selectedUnit: _selectedUnit,
                          onUnitChanged: (u) => setState(() => _selectedUnit = u),
                          priceController: _priceCtrl,
                          stockController: _stockCtrl,
                          minOrderController: _minOrderCtrl,
                          onMinOrderIncrement: () {
                            setState(() {
                              _minOrder++;
                              _minOrderCtrl.text = _minOrder.toInt().toString();
                            });
                          },
                          onMinOrderDecrement: () {
                            if (_minOrder > 1) {
                              setState(() {
                                _minOrder--;
                                _minOrderCtrl.text =
                                    _minOrder.toInt().toString();
                              });
                            }
                          },
                          isDiscountActive: _isDiscountActive,
                          onToggleDiscount: () {
                            setState(() {
                              _isDiscountActive = !_isDiscountActive;
                              if (!_isDiscountActive) _discountCtrl.clear();
                            });
                          },
                          discountController: _discountCtrl,
                          isBulkDiscountActive: _isBulkDiscountActive,
                          onToggleBulkDiscount: () {
                            setState(() {
                              _isBulkDiscountActive = !_isBulkDiscountActive;
                              if (!_isBulkDiscountActive) {
                                _bulkMinQtyCtrl.clear();
                                _bulkDiscountCtrl.clear();
                              }
                            });
                          },
                          bulkMinQtyController: _bulkMinQtyCtrl,
                          bulkDiscountController: _bulkDiscountCtrl,
                          currentPrice: _currentPrice,
                          discountedPrice: _discountedPrice,
                          bulkUnitPrice: _bulkUnitPrice,
                        ),
                      3 => ProductStep3Review(
                          varietyController: _varietyCtrl,
                          descriptionController: _descCtrl,
                          photos: _selectedPhotos,
                          mainPhotoIndex: _mainPhotoIndex,
                          title: _titleCtrl.text,
                          selectedCategory: _selectedCategory,
                          farmName: farmName,
                          selectedUnit: _selectedUnit,
                          stockText: _stockCtrl.text,
                          effectivePrice: effectivePrice,
                          originalPrice: _currentPrice,
                          isDiscountActive: _isDiscountActive,
                          discountPercentText: _discountCtrl.text,
                          isBulkDiscountActive: _isBulkDiscountActive,
                          bulkMinQtyText: _bulkMinQtyCtrl.text,
                          bulkDiscountPercentText: _bulkDiscountCtrl.text,
                          minOrder: _minOrder,
                          selectedAgroTags: _selectedAgroTags,
                        ),
                      _ => const SizedBox.shrink(),
                    },
                  ),
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: List.generate(3, (index) {
              final isCompletedOrActive = index < _currentStep;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index < 2 ? 6.0 : 0.0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeInOutCubic,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isCompletedOrActive
                          ? AppColors.primary
                          : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              '$_currentStep/3',
              key: ValueKey<int>(_currentStep),
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
                height: 1.1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
      ),
      child: Row(
        children: [
          if (_currentStep > 1) ...[
            InkWell(
              onTap: _onBack,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                ),
                alignment: Alignment.center,
                child: Text(
                  'უკან',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF475569),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: PrimaryButton(
              text: _currentStep == 1
                  ? 'შემდეგი: ფასი და მარაგი'
                  : _currentStep == 2
                      ? 'შემდეგი: გადახედვა'
                      : (widget.existing == null
                          ? 'პროდუქტის გამოქვეყნება'
                          : 'ცვლილებების შენახვა'),
              icon: Icon(
                _currentStep == 3
                    ? (widget.existing == null
                        ? LucideIcons.send
                        : LucideIcons.check)
                    : LucideIcons.arrowRight,
                size: 18,
                color: Colors.white,
              ),
              height: 52,
              borderRadius: BorderRadius.circular(12),
              isLoading: _isSaving,
              onPressed: _isSaving ? null : _onNext,
            ),
          ),
        ],
      ),
    );
  }
}
