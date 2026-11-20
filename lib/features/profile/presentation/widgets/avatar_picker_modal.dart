import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/profile_media_controller.dart';

/// Pure UI bottom sheet for selecting an avatar source (Camera or Gallery).
///
/// Business logic is completely delegated to [ProfileMediaController].
class AvatarPickerModal extends StatelessWidget {
  const AvatarPickerModal({super.key});

  /// Opens the modal bottom sheet and delegates selection to [ProfileMediaController].
  static Future<void> show(BuildContext context, WidgetRef ref) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const AvatarPickerModal(),
    );

    if (source != null && context.mounted) {
      await ref
          .read(profileMediaControllerProvider.notifier)
          .pickAndUploadAvatar(source, context: context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
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
                'გადაიღე ახალი ფოტო სელფით',
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),
              onTap: () => Navigator.pop(context, ImageSource.camera),
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
                'აირჩიე სურათი ტელეფონის მეხსიერებიდან',
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }
}
