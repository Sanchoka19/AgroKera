import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:agrokera/core/theme/app_colors.dart';
import 'package:agrokera/core/widgets/app_toast.dart';
import 'package:agrokera/core/widgets/auth_required_bottom_sheet.dart';
import 'package:agrokera/features/marketplace/data/models/product_model.dart';
import 'package:agrokera/features/marketplace/presentation/providers/favorites_provider.dart';

/// Pinned SliverAppBar containing product photo carousel, pagination dots,
/// Back button, Share button, and Favorite toggle.
class ProductImageGallery extends ConsumerStatefulWidget {
  final ProductModel product;

  const ProductImageGallery({super.key, required this.product});

  @override
  ConsumerState<ProductImageGallery> createState() =>
      _ProductImageGalleryState();
}

class _ProductImageGalleryState extends ConsumerState<ProductImageGallery> {
  int _currentPhotoIndex = 0;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final gallery = product.galleryImages;

    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: AppColors.surface,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: AppColors.surface.withValues(alpha: 0.9),
          child: IconButton(
            icon: const Icon(
              LucideIcons.chevronLeft,
              color: AppColors.textPrimary,
              size: 20,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: CircleAvatar(
            backgroundColor: AppColors.surface.withValues(alpha: 0.9),
            child: IconButton(
              icon: const Icon(
                LucideIcons.share2,
                color: AppColors.textPrimary,
                size: 19,
              ),
              onPressed: () {
                AppToast.info(context, 'პროდუქტის ლინკი დაკოპირებულია!');
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: AppColors.surface.withValues(alpha: 0.9),
            child: Consumer(
              builder: (context, ref, child) {
                final isFav =
                    ref.watch(favoritesProvider).contains(product.id);
                return IconButton(
                  icon: Icon(
                    isFav ? Icons.favorite : LucideIcons.heart,
                    color: isFav
                        ? AppColors.accentWarm
                        : AppColors.textPrimary,
                    size: 20,
                  ),
                  onPressed: () {
                    requireAuth(
                      context,
                      ref: ref,
                      onAuthenticated: () {
                        ref.read(favoritesProvider.notifier).toggle(product.id);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              itemCount: gallery.length,
              onPageChanged: (idx) {
                setState(() => _currentPhotoIndex = idx);
              },
              itemBuilder: (context, idx) {
                final imgUrl = gallery[idx];
                return imgUrl.startsWith('assets/')
                    ? Image.asset(
                        imgUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
                              color: AppColors.surfaceInput,
                              alignment: Alignment.center,
                              child: const Icon(
                                LucideIcons.image,
                                color: AppColors.textSecondary,
                                size: 48,
                              ),
                            ),
                      )
                    : Image.network(
                        imgUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
                              color: AppColors.surfaceInput,
                              alignment: Alignment.center,
                              child: const Icon(
                                LucideIcons.image,
                                color: AppColors.textSecondary,
                                size: 48,
                              ),
                            ),
                      );
              },
            ),
            if (gallery.length > 1)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(gallery.length, (i) {
                    final active = i == _currentPhotoIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: active ? 20 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.primary
                            : Colors.white.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
