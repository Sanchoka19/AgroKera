import 'package:flutter/material.dart';
import '../../../../core/widgets/app_filter_tab.dart';

/// Reusable quick tags selector using universal [AppFilterTab] without emojis.
class ReviewQuickTagsSelector extends StatelessWidget {
  final List<String> selectedTags;
  final ValueChanged<List<String>> onTagsChanged;

  const ReviewQuickTagsSelector({
    super.key,
    required this.selectedTags,
    required this.onTagsChanged,
  });

  static const List<String> availableTags = [
    'ახალი პროდუქცია',
    'დროული მიტანა',
    'სასიამოვნო კომუნიკაცია',
    'კარგი შეფუთვა',
    'საუკეთესო ხარისხი',
  ];

  void _toggleTag(String tag) {
    final updated = List<String>.from(selectedTags);
    if (updated.contains(tag)) {
      updated.remove(tag);
    } else {
      updated.add(tag);
    }
    onTagsChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: availableTags.map((tag) {
        final isSelected = selectedTags.contains(tag);
        return AppFilterTab(
          label: tag,
          isSelected: isSelected,
          onTap: () => _toggleTag(tag),
        );
      }).toList(),
    );
  }
}

