import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/auth/auth_state_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../marketplace/presentation/providers/marketplace_provider.dart';

/// Modal bottom sheet for picking an avatar from camera or gallery.
class AvatarPickerModal extends StatelessWidget {
  const AvatarPickerModal({super.key});

  static void show(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const AvatarPickerModal(),
    );
  }

  static Future<void> pickAndUploadAvatar(
    BuildContext context,
    WidgetRef ref,
    ImageSource source,
  ) async {
    final authNotifier = ref.read(authStateProvider.notifier);
    final marketplaceNotifier = ref.read(marketplaceProvider.notifier);

    try {
      final XFile? file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.front,
      );

      if (file == null) return;

      if (context.mounted) {
        AppToast.info(context, 'პროფილის ფოტო იტვირთება...');
      }

      final success = await authNotifier.uploadAvatar(file);
      if (success) {
        unawaited(marketplaceNotifier.refreshFromBackend());
      }

      if (context.mounted) {
        if (success) {
          AppToast.success(context, 'პროფილის ფოტო წარმატებით განახლდა!');
        } else {
          AppToast.success(context, 'პროფილის ფოტო შენახულია');
        }
      }
    } catch (_) {
      if (context.mounted) {
        AppToast.error(context, 'ფოტოს არჩევა ვერ მოხერხდა');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
                  'პროფილის ფოტოს შეცვლა',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'აირჩიეთ ფოტოს წყარო პროფილის განახლებისთვის',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(LucideIcons.camera, color: AppColors.primary, size: 22),
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
                    'გადაიღე ახალი ფოტო სელფით',
                    style: GoogleFonts.notoSansGeorgian(fontSize: 12, color: const Color(0xFF64748B)),
                  ),
                  onTap: () {
                    final navContext = Navigator.of(context).context;
                    Navigator.pop(context);
                    pickAndUploadAvatar(navContext, ref, ImageSource.camera);
                  },
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(LucideIcons.image, color: Color(0xFF475569), size: 22),
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
                    'აირჩიე სურათი ტელეფონის მეხსიერებიდან',
                    style: GoogleFonts.notoSansGeorgian(fontSize: 12, color: const Color(0xFF64748B)),
                  ),
                  onTap: () {
                    final navContext = Navigator.of(context).context;
                    Navigator.pop(context);
                    pickAndUploadAvatar(navContext, ref, ImageSource.gallery);
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

