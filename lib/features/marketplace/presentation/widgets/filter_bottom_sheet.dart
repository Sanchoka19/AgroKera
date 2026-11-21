import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/models/product_filter_criteria.dart';
import 'filter/price_range_filter_widget.dart';
import 'filter/quick_filter_toggles_widget.dart';
import 'filter/region_horizontal_scroll_widget.dart';
import 'filter/sort_options_widget.dart';

/// Clean, focused modular bottom sheet for marketplace product filtering.
/// Fully decoupled: delegates UI sections to dedicated widgets and uses pure domain criteria.
class FilterBottomSheet extends StatefulWidget {
  final ProductFilterCriteria? initialCriteria;
  final String? initialRegion;
  final String? initialCategory;
  final String? initialSort;
  final bool showCategoryFilter;
  final ValueChanged<ProductFilterCriteria>? onApplyCriteria;
  final Function(String? region, String? category)? onApply;

  const FilterBottomSheet({
    super.key,
    this.initialCriteria,
    this.initialRegion,
    this.initialCategory,
    this.initialSort,
    this.showCategoryFilter = true,
    this.onApplyCriteria,
    this.onApply,
  });

  static Future<ProductFilterCriteria?> show(
    BuildContext context, {
    ProductFilterCriteria? criteria,
    String? initialRegion,
    String? initialCategory,
    String? initialSort,
    bool showCategoryFilter = true,
    ValueChanged<ProductFilterCriteria>? onApplyCriteria,
    Function(String? region, String? category)? onApply,
  }) {
    return showModalBottomSheet<ProductFilterCriteria>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FilterBottomSheet(
        initialCriteria: criteria,
        initialRegion: initialRegion,
        initialCategory: initialCategory,
        initialSort: initialSort,
        showCategoryFilter: showCategoryFilter,
        onApplyCriteria: onApplyCriteria,
        onApply: onApply,
      ),
    );
  }

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late String _selectedRegion;
  late String _selectedSort;
  late RangeValues _priceRange;
  late bool _isBioOnly;
  late bool _inStockOnly;
  late bool _hasDiscountOnly;

  static const double _defaultMinPrice = 0.0;
  static const double _defaultMaxPrice = 100.0;

  @override
  void initState() {
    super.initState();
    final c = widget.initialCriteria;
    _selectedRegion = c?.region ?? widget.initialRegion ?? 'ყველა';
    _selectedSort = c?.sortBy ?? widget.initialSort ?? 'პოპულარული';
    _priceRange = RangeValues(
      c?.minPrice ?? _defaultMinPrice,
      c?.maxPrice ?? _defaultMaxPrice,
    );
    _isBioOnly = c?.isBioOnly ?? false;
    _inStockOnly = c?.inStockOnly ?? false;
    _hasDiscountOnly = c?.hasDiscountOnly ?? false;
  }

  void _resetAll() {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedRegion = 'ყველა';
      _selectedSort = 'პოპულარული';
      _priceRange = const RangeValues(_defaultMinPrice, _defaultMaxPrice);
      _isBioOnly = false;
      _inStockOnly = false;
      _hasDiscountOnly = false;
    });
  }

  void _applyFilter() {
    HapticFeedback.lightImpact();
    final appliedReg = _selectedRegion == 'ყველა' ? null : _selectedRegion;
    final appliedCat = widget.initialCategory ?? widget.initialCriteria?.category;

    final double? minPrice =
        _priceRange.start > _defaultMinPrice ? _priceRange.start : null;
    final double? maxPrice =
        _priceRange.end < _defaultMaxPrice ? _priceRange.end : null;

    final criteria = ProductFilterCriteria(
      region: appliedReg,
      category: appliedCat,
      sortBy: _selectedSort,
      minPrice: minPrice,
      maxPrice: maxPrice,
      isBioOnly: _isBioOnly,
      inStockOnly: _inStockOnly,
      hasDiscountOnly: _hasDiscountOnly,
    );

    widget.onApplyCriteria?.call(criteria);
    widget.onApply?.call(appliedReg, appliedCat);
    Navigator.of(context).pop(criteria);
  }

  @override
  Widget build(BuildContext context) {
    final maxSheetHeight = MediaQuery.of(context).size.height * 0.85;

    return Container(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ფილტრი', style: AppTypography.h2),
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceInput,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    LucideIcons.x,
                    size: 18,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Scrollable Filter Sections
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Quick Feature Toggles (Bio, In Stock, Discount)
                  QuickFilterTogglesWidget(
                    isBioOnly: _isBioOnly,
                    inStockOnly: _inStockOnly,
                    hasDiscountOnly: _hasDiscountOnly,
                    onBioChanged: (val) => setState(() => _isBioOnly = val),
                    onInStockChanged: (val) => setState(() => _inStockOnly = val),
                    onDiscountChanged: (val) =>
                        setState(() => _hasDiscountOnly = val),
                  ),
                  const SizedBox(height: 18),

                  // 2. Price Range Slider
                  PriceRangeFilterWidget(
                    minLimit: _defaultMinPrice,
                    maxLimit: _defaultMaxPrice,
                    currentRange: _priceRange,
                    onChanged: (vals) => setState(() => _priceRange = vals),
                  ),
                  const SizedBox(height: 18),

                  // 3. Region Single-row Horizontal Scroll
                  RegionHorizontalScrollWidget(
                    selectedRegion: _selectedRegion,
                    onRegionSelected: (reg) =>
                        setState(() => _selectedRegion = reg),
                  ),
                  const SizedBox(height: 18),

                  // 4. Sort Options
                  SortOptionsWidget(
                    selectedSort: _selectedSort,
                    onSortSelected: (opt) => setState(() => _selectedSort = opt),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Actions Row: "გასუფთავება" & "გაფილტვრა"
          Row(
            children: [
              Expanded(
                flex: 1,
                child: PrimaryButton(
                  text: 'გასუფთავება',
                  isOutlined: true,
                  onPressed: _resetAll,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: PrimaryButton(
                  text: 'გაფილტვრა',
                  onPressed: _applyFilter,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
