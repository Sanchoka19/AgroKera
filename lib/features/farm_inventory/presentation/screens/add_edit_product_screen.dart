import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:agrokera/core/auth/auth_state_provider.dart';
import 'package:agrokera/core/constants/app_categories.dart';
import 'package:agrokera/core/theme/app_colors.dart';
import 'package:agrokera/core/widgets/app_confirmation_bottom_sheet.dart';
import 'package:agrokera/core/widgets/app_toast.dart';
import '../../../marketplace/data/models/product_model.dart';
import '../providers/farmer_inventory_provider.dart';
import '../providers/product_form_validator.dart';
import '../../domain/models/product_pricing_advisory.dart';
import '../widgets/product_publish_confirmation_sheet.dart';
import '../widgets/product_steps/product_photo_entry.dart';
import '../widgets/product_steps/product_photo_picker_sheet.dart';
import '../widgets/product_steps/product_step1_identity.dart';
import '../widgets/product_steps/product_step2_pricing.dart';
import '../widgets/product_steps/product_step3_review.dart';
import '../widgets/product_steps/product_wizard_bottom_bar.dart';
import '../widgets/product_steps/product_wizard_progress_bar.dart';

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
  late final TextEditingController _estimatedWeightCtrl;

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
    final initialEstimatedWeight =
        ProductPricingAdvisory.extractEstimatedWeightFromDescription(
            existing?.description);
    _estimatedWeightCtrl =
        TextEditingController(text: initialEstimatedWeight ?? '');

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
    _estimatedWeightCtrl.addListener(_onFieldChanged);
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
    _estimatedWeightCtrl.removeListener(_onFieldChanged);

    _titleCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _minOrderCtrl.dispose();
    _discountCtrl.dispose();
    _bulkMinQtyCtrl.dispose();
    _bulkDiscountCtrl.dispose();
    _estimatedWeightCtrl.dispose();
    _descCtrl.dispose();
    _varietyCtrl.dispose();
    super.dispose();
  }

  // --- Photo Picker Handling ---

  Future<void> _openPhotoSourceSheet() async {
    await ProductPhotoPickerSheet.show(
      context,
      currentPhotoCount: _selectedPhotos.length,
      remainingPhotoSlots: _remainingPhotoSlots,
      onPickCamera: _handlePickCamera,
      onPickGallery: _handlePickGallery,
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
        minOrder: _minOrder,
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
      _confirmAndSave();
    }
  }

  Future<void> _confirmAndSave() async {
    final title = _titleCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text.trim()) ?? 0.0;
    final stock = double.tryParse(_stockCtrl.text.trim()) ?? 0.0;
    final discount = _isDiscountActive ? int.tryParse(_discountCtrl.text.trim()) : null;

    final advisory = ProductPricingAdvisory.evaluate(
      title: title,
      category: _selectedCategory,
      unit: _selectedUnit,
      basePrice: price,
      discountPercent: discount,
      stock: stock,
      minOrder: _minOrder,
      estimatedPieceWeight:
          _selectedUnit == 'ცალი' ? _estimatedWeightCtrl.text.trim() : null,
      description: _descCtrl.text,
    );

    final confirmed = await ProductPublishConfirmationSheet.show(
      context,
      advisory: advisory,
      onEditWeightRequested: () {
        setState(() => _currentStep = 2);
      },
    );

    if (confirmed) {
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
      estimatedPieceWeight:
          _selectedUnit == 'ცალი' ? _estimatedWeightCtrl.text.trim() : null,
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
        title: ProductWizardProgressBar(currentStep: _currentStep),
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
              // Anchored to Alignment.topCenter so there is NO awkward top white space
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
                          estimatedWeightController: _estimatedWeightCtrl,
                          onQuickWeightPresetSelected: (preset) {
                            setState(() => _estimatedWeightCtrl.text = preset);
                          },
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
            ProductWizardBottomBar(
              currentStep: _currentStep,
              isExisting: widget.existing != null,
              isSaving: _isSaving,
              onBack: _onBack,
              onNext: _onNext,
            ),
          ],
        ),
      ),
    );
  }
}
