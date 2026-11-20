import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/constants/app_categories.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/models/product_filter_criteria.dart';

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
  late String _selectedCategory;
  late String _selectedSort;

  final List<String> _regions = const [
    'ყველა',
    'კახეთი',
    'იმერეთი',
    'ქართლი',
    'სამეგრელო',
  ];

  List<String> get _categories => [
        'ყველა',
        ...AppCategories.categories.map((c) => c.name),
      ];

  final List<String> _sortOptions = const [
    'პოპულარული',
    'ჯერ იაფი',
    'ჯერ ძვირი',
    'მაღალი რეიტინგი',
  ];

  @override
  void initState() {
    super.initState();
    _selectedRegion = widget.initialCriteria?.region ??
        widget.initialRegion ??
        'ყველა';
    _selectedCategory = widget.initialCriteria?.category ??
        widget.initialCategory ??
        'ყველა';
    _selectedSort = widget.initialCriteria?.sortBy ??
        widget.initialSort ??
        'პოპულარული';
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
        18,
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

          // Scrollable filter options
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Region Section
                  Text(
                    'რეგიონი',
                    style: AppTypography.titleMedium.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _regions.map((reg) {
                      final isSelected = _selectedRegion == reg;
                      return ChoiceChip(
                        label: Text(reg),
                        selected: isSelected,
                        selectedColor: AppColors.primaryLight,
                        backgroundColor: AppColors.surfaceInput,
                        labelStyle: AppTypography.caption.copyWith(
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : Colors.transparent,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onSelected: (val) {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedRegion = reg);
                        },
                      );
                    }).toList(),
                  ),
                  if (widget.showCategoryFilter) ...[
                    const SizedBox(height: 18),
                    // Category Section
                    Text(
                      'კატეგორია',
                      style: AppTypography.titleMedium.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          selectedColor: AppColors.primaryLight,
                          backgroundColor: AppColors.surfaceInput,
                          labelStyle: AppTypography.caption.copyWith(
                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : Colors.transparent,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onSelected: (val) {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedCategory = cat);
                          },
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 18),

                  // Sort Section
                  Text(
                    'სორტირება',
                    style: AppTypography.titleMedium.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _sortOptions.map((opt) {
                      final isSelected = _selectedSort == opt;
                      return ChoiceChip(
                        label: Text(opt),
                        selected: isSelected,
                        selectedColor: AppColors.primaryLight,
                        backgroundColor: AppColors.surfaceInput,
                        labelStyle: AppTypography.caption.copyWith(
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : Colors.transparent,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onSelected: (val) {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedSort = opt);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
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
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _selectedRegion = 'ყველა';
                      _selectedCategory = widget.showCategoryFilter
                          ? 'ყველა'
                          : (widget.initialCategory ??
                              widget.initialCriteria?.category ??
                              'ყველა');
                      _selectedSort = 'პოპულარული';
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: PrimaryButton(
                  text: 'გაფილტვრა',
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    final appliedCat = widget.showCategoryFilter
                        ? (_selectedCategory == 'ყველა' ? null : _selectedCategory)
                        : (widget.initialCategory ?? widget.initialCriteria?.category);
                    final appliedReg =
                        _selectedRegion == 'ყველა' ? null : _selectedRegion;

                    final criteria = ProductFilterCriteria(
                      region: appliedReg,
                      category: appliedCat,
                      sortBy: _selectedSort,
                    );

                    widget.onApplyCriteria?.call(criteria);
                    widget.onApply?.call(appliedReg, appliedCat);
                    Navigator.of(context).pop(criteria);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
