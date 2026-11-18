import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/auth/auth_state_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../farmer_onboarding/presentation/models/farmer_onboarding_state.dart';
import '../../../marketplace/presentation/providers/marketplace_provider.dart';

/// Modal bottom sheet for picking farm cover photo via camera, gallery or presets.
class CoverPhotoPickerModal extends StatelessWidget {
  const CoverPhotoPickerModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const CoverPhotoPickerModal(),
    );
  }

  static Future<void> pickAndUploadCover(
    BuildContext context,
    WidgetRef ref,
    ImageSource source,
  ) async {
    final authNotifier = ref.read(authStateProvider.notifier);
    final marketplaceNotifier = ref.read(marketplaceProvider.notifier);

    try {
      final XFile? file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1000,
        imageQuality: 85,
      );
      if (file == null) return;

      if (context.mounted) {
        AppToast.info(
          context,
          'გარეკანის ფოტო იტვირთება...',
        );
      }

      final success = await authNotifier.uploadFarmCover(file);
      if (success) {
        unawaited(marketplaceNotifier.refreshFromBackend());
      }

      if (context.mounted) {
        if (success) {
          AppToast.success(
            context,
            'გარეკანის ფოტო წარმატებით განახლდა!',
          );
        } else {
          AppToast.success(
            context,
            'გარეკანის ფოტო შენახულია',
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        AppToast.error(
          context,
          source == ImageSource.camera
              ? 'კამერის გახსნა ვერ მოხერხდა'
              : 'ფოტოს არჩევა ვერ მოხერხდა',
        );
      }
    }
  }

  static void showPresetPicker(BuildContext context, WidgetRef ref) {
    final authNotifier = ref.read(authStateProvider.notifier);
    final marketplaceNotifier = ref.read(marketplaceProvider.notifier);
    showModalBottomSheet(
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
                        onTap: () async {
                          Navigator.pop(ctx);
                          await authNotifier.updateFarmCoverUrl(preset['url']!);
                          unawaited(marketplaceNotifier.refreshFromBackend());
                          if (context.mounted) {
                            AppToast.success(
                              context,
                              'გარეკანი არჩეულია: ${preset["title"]}',
                            );
                          }
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
                              Image.network(
                                preset['url']!,
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
    return Consumer(
      builder: (context, ref, _) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const SizedBox(height: 12),
                ListTile(
                  leading:
                      const Icon(LucideIcons.camera, color: AppColors.primary),
                  title: Text(
                    'კამერით გადაღება',
                    style: GoogleFonts.notoSansGeorgian(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text('გადაუღე ფერმას ან მეურნეობას'),
                  onTap: () {
                    final navContext = Navigator.of(context).context;
                    Navigator.pop(context);
                    pickAndUploadCover(navContext, ref, ImageSource.camera);
                  },
                ),
                ListTile(
                  leading:
                      const Icon(LucideIcons.image, color: AppColors.primary),
                  title: Text(
                    'გალერეიდან არჩევა',
                    style: GoogleFonts.notoSansGeorgian(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text('ატვირთე ლანდშაფტური სურათი'),
                  onTap: () {
                    final navContext = Navigator.of(context).context;
                    Navigator.pop(context);
                    pickAndUploadCover(navContext, ref, ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(LucideIcons.image,
                      color: AppColors.primary),
                  title: Text(
                    'სანიმუშო აგრო-გარეკანის არჩევა',
                    style: GoogleFonts.notoSansGeorgian(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    'მზა თემატური ფოტოები (ვენახი, ბაღი, სათბური)',
                  ),
                  onTap: () {
                    final navContext = Navigator.of(context).context;
                    Navigator.pop(context);
                    showPresetPicker(navContext, ref);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

