import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../shimmer_loading.dart';

/// Skeleton placeholder mimicking ClientOrderCard layout
class OrderCardSkeleton extends StatelessWidget {
  const OrderCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Order ID & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 100, height: 16),
                  SizedBox(height: 5),
                  ShimmerBox(width: 130, height: 11),
                ],
              ),
              ShimmerBox(width: 80, height: 26, borderRadius: BorderRadius.all(Radius.circular(20))),
            ],
          ),
          const SizedBox(height: 14),

          // Divider
          Container(height: 1, color: AppColors.border),
          const SizedBox(height: 14),

          // Items preview line
          Row(
            children: const [
              ShimmerBox.circular(size: 28),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 140, height: 13),
                    SizedBox(height: 4),
                    ShimmerBox(width: 90, height: 10),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Total & Details CTA
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              ShimmerBox(width: 80, height: 16),
              ShimmerBox(width: 95, height: 32, borderRadius: BorderRadius.all(Radius.circular(10))),
            ],
          ),
        ],
      ),
    );
  }
}

/// List of OrderCardSkeleton placeholders wrapped in ShimmerLoading
class OrderListSkeleton extends StatelessWidget {
  final int itemCount;
  final EdgeInsetsGeometry padding;

  const OrderListSkeleton({
    super.key,
    this.itemCount = 3,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
        itemBuilder: (context, index) => const OrderCardSkeleton(),
      ),
    );
  }
}
