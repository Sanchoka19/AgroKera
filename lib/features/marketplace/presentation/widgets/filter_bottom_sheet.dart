import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/constants/app_categories.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';

class FilterBottomSheet extends StatefulWidget {
  final String? initialRegion;
  final String? initialCategory;
  final bool showCategoryFilter;
  final Function(String? region, String? category) onApply;

  const FilterBottomSheet({
    super.key,
    this.initialRegion,
    this.initialCategory,
    this.showCategoryFilter = true,
    required this.onApply,
  });

  static Future<void> show(
    BuildContext context, {
    String? initialRegion,
    String? initialCategory,
    bool showCategoryFilter = true,
    required Function(String? region, String? category) onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FilterBottomSheet(
        initialRegion: initialRegion,
        initialCategory: initialCategory,
        showCategoryFilter: showCategoryFilter,
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
  String _selectedSort = 'პოპულარული';

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
    _selectedRegion = widget.initialRegion ?? 'ყველა';
    _selectedCategory = widget.initialCategory ?? 'ყველა';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        18,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const SizedBox(height: 18),

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
                  setState(() => _selectedSort = opt);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Actions Row: "გასუფთავება" & "გაფილტვრა"
          Row(
            children: [
              Expanded(
                flex: 1,
                child: PrimaryButton(
                  text: 'გასუფთავება',
                  isOutlined: true,
                  onPressed: () {
                    setState(() {
                      _selectedRegion = 'ყველა';
                      _selectedCategory = widget.showCategoryFilter
                          ? 'ყველა'
                          : (widget.initialCategory ?? 'ყველა');
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
                    final appliedCat = widget.showCategoryFilter
                        ? (_selectedCategory == 'ყველა' ? null : _selectedCategory)
                        : widget.initialCategory;
                    widget.onApply(
                      _selectedRegion == 'ყველა' ? null : _selectedRegion,
                      appliedCat,
                    );
                    Navigator.of(context).pop();
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
