import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:agrokera/core/theme/app_colors.dart';
import 'package:agrokera/core/widgets/app_toast.dart';
import '../../providers/farmer_inventory_provider.dart';

/// Modal bottom sheet allowing farmers to select photo source (Camera or Gallery)
/// for adding product photos.
class ProductPhotoPickerSheet extends StatelessWidget {
  final int currentPhotoCount;
  final int remainingPhotoSlots;
  final VoidCallback onPickCamera;
  final VoidCallback onPickGallery;

  const ProductPhotoPickerSheet({
    super.key,
    required this.currentPhotoCount,
    required this.remainingPhotoSlots,
    required this.onPickCamera,
    required this.onPickGallery,
  });

  static Future<void> show(
    BuildContext context, {
    required int currentPhotoCount,
    required int remainingPhotoSlots,
    required VoidCallback onPickCamera,
    required VoidCallback onPickGallery,
  }) async {
    if (remainingPhotoSlots <= 0) {
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
      builder: (ctx) => ProductPhotoPickerSheet(
        currentPhotoCount: currentPhotoCount,
        remainingPhotoSlots: remainingPhotoSlots,
        onPickCamera: () {
          Navigator.pop(ctx);
          onPickCamera();
        },
        onPickGallery: () {
          Navigator.pop(ctx);
          onPickGallery();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'პროდუქტის ფოტოს დამატება ($currentPhotoCount/${FarmerInventoryNotifier.maxProductPhotos})',
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
              onTap: onPickCamera,
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
                'აირჩიეთ 1 ან რამდენიმე ფოტო (დარჩენილია $remainingPhotoSlots ადგილი)',
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),
              onTap: onPickGallery,
            ),
          ],
        ),
      ),
    );
  }
}

