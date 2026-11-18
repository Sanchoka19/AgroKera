import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../shimmer_loading.dart';

/// Skeleton placeholder mimicking ProductCard layout
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Image Placeholder
          const Expanded(
            child: ShimmerBox(
              width: double.infinity,
              height: double.infinity,
              borderRadius: BorderRadius.zero,
            ),
          ),

          // Details Section
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title line
                const ShimmerBox(
                  width: 110,
                  height: 14,
                ),
                const SizedBox(height: 6),

                // Farm line
                Row(
                  children: const [
                    ShimmerBox.circular(size: 11),
                    SizedBox(width: 4),
                    ShimmerBox(
                      width: 75,
                      height: 10,
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Rating line
                const ShimmerBox(
                  width: 55,
                  height: 10,
                ),
                const SizedBox(height: 10),

                // Price and Add button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: const [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ShimmerBox(
                          width: 45,
                          height: 9,
                        ),
                        SizedBox(height: 3),
                        ShimmerBox(
                          width: 60,
                          height: 14,
                        ),
                      ],
                    ),
                    ShimmerBox.circular(size: 32),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Responsive grid of ProductCardSkeleton items wrapped in ShimmerLoading
class ProductGridSkeleton extends StatelessWidget {
  final int itemCount;
  final EdgeInsetsGeometry padding;

  const ProductGridSkeleton({
    super.key,
    this.itemCount = 6,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: padding,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 210,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.70,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) => const ProductCardSkeleton(),
      ),
    );
  }
}
