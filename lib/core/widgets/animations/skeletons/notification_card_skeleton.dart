import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../shimmer_loading.dart';

/// Skeleton placeholder mimicking NotificationCard layout
class NotificationCardSkeleton extends StatelessWidget {
  const NotificationCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon placeholder
          const ShimmerBox(
            width: 44,
            height: 44,
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          const SizedBox(width: 14),

          // Content placeholder
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerBox(width: 160, height: 14),
                SizedBox(height: 8),
                ShimmerBox(width: double.infinity, height: 11),
                SizedBox(height: 5),
                ShimmerBox(width: 120, height: 11),
                SizedBox(height: 8),
                ShimmerBox(width: 60, height: 9),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// List of NotificationCardSkeleton placeholders wrapped in ShimmerLoading
class NotificationListSkeleton extends StatelessWidget {
  final int itemCount;
  final EdgeInsetsGeometry padding;

  const NotificationListSkeleton({
    super.key,
    this.itemCount = 4,
    this.padding = const EdgeInsets.fromLTRB(20, 8, 20, 32),
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: padding,
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) => const NotificationCardSkeleton(),
      ),
    );
  }
}
