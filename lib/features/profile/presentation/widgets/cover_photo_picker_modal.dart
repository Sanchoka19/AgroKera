import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../farmer_onboarding/presentation/models/farmer_onboarding_state.dart';
import '../controllers/profile_media_controller.dart';
import 'profile_image_view.dart';

/// Selection result from the [CoverPhotoPickerModal].
sealed class CoverPickerResult {
  const CoverPickerResult();
}

class CoverSourceResult extends CoverPickerResult {
  final ImageSource source;
  const CoverSourceResult(this.source);
}

class CoverPresetResult extends CoverPickerResult {
  final String url;
  final String title;
  const CoverPresetResult({required this.url, required this.title});
}

/// Pure UI bottom sheet for picking farm cover photo via camera, gallery, or presets.
///
/// Business logic is completely delegated to [ProfileMediaController].
class CoverPhotoPickerModal extends StatelessWidget {
  const CoverPhotoPickerModal({super.key});

  /// Opens the modal bottom sheet and delegates selection to [ProfileMediaController].
  static Future<void> show(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<CoverPickerResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const CoverPhotoPickerModal(),
    );

    if (result == null || !context.mounted) return;

    final controller = ref.read(profileMediaControllerProvider.notifier);
    if (result is CoverSourceResult) {
      await controller.pickAndUploadFarmCover(result.source, context: context);
    } else if (result is CoverPresetResult) {
      await controller.applyFarmCoverPreset(
        result.url,
        presetTitle: result.title,
        context: context,
      );
    }
  }

  /// Opens curated presets modal and applies user choice via [ProfileMediaController].
  static Future<CoverPresetResult?> showPresetPicker(
    BuildContext context,
  ) async {
    return showModalBottomSheet<CoverPresetResult>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'აირჩიე სანიმუშო გარეკანი',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 160,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: FarmerOnboardingState.presetFarmCovers.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (itemCtx, index) {
                      final preset =
                          FarmerOnboardingState.presetFarmCovers[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(
                            ctx,
                            CoverPresetResult(
                              url: preset['url']!,
                              title: preset['title']!,
                            ),
                          );
                        },
                        child: Container(
                          width: 160,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ProfileImageView(
                                imageUrl: preset['url']!,
                                fit: BoxFit.cover,
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.70),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 8,
                                right: 8,
                                bottom: 8,
                                child: Text(
                                  preset['title']!,
                                  style: GoogleFonts.notoSansGeorgian(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'ფერმის გარეკანის შეცვლა',
              style: GoogleFonts.notoSansGeorgian(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'ეს ფოტო გამოჩნდება თქვენს პროფილზე და მთავარ გვერდზე',
              style: GoogleFonts.notoSansGeorgian(
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.camera,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              title: Text(
                'კამერით გადაღება',
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              subtitle: Text(
                'გადაუღე ფერმას ან მეურნეობას',
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),
              onTap: () => Navigator.pop(
                context,
                const CoverSourceResult(ImageSource.camera),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.image,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              title: Text(
                'გალერეიდან არჩევა',
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              subtitle: Text(
                'ატვირთე ლანდშაფტური სურათი',
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),
              onTap: () => Navigator.pop(
                context,
                const CoverSourceResult(ImageSource.gallery),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.galleryThumbnails,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              title: Text(
                'სანიმუშო აგრო-გარეკანის არჩევა',
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              subtitle: Text(
                'მზა თემატური ფოტოები (ვენახი, ბაღი, სათბური)',
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),
              onTap: () async {
                final presetResult = await showPresetPicker(context);
                if (presetResult != null && context.mounted) {
                  Navigator.pop(context, presetResult);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
