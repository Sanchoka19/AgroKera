import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../auth/auth_state_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_toast.dart';
import 'primary_button.dart';

/// Centralized KYC Guard function.
/// If farmer is verified, executes [onVerified].
/// Otherwise, presents the [KycRequiredBottomSheet].
void requireKyc(
  BuildContext context, {
  required WidgetRef ref,
  required VoidCallback onVerified,
}) {
  final kycStatus = ref.read(authStateProvider).kycStatus;
  if (kycStatus == KycStatus.verified) {
    onVerified();
  } else {
    KycRequiredBottomSheet.show(context);
  }
}

/// In-place KYC Bottom Sheet modal prompt:
/// Enables farmers to inspect verification status or upload ID Front and Back directly
/// without navigating to a separate screen.
class KycRequiredBottomSheet extends ConsumerStatefulWidget {
  const KycRequiredBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: const KycRequiredBottomSheet(),
      ),
    );
  }

  @override
  ConsumerState<KycRequiredBottomSheet> createState() =>
      _KycRequiredBottomSheetState();
}

class _KycRequiredBottomSheetState
    extends ConsumerState<KycRequiredBottomSheet> {
  final _imagePicker = ImagePicker();
  String? _frontFileName;
  String? _backFileName;
  XFile? _frontFile;
  XFile? _backFile;
  bool _isSubmitting = false;

  Future<void> _pickDocument({
    required bool isFront,
    required ImageSource source,
  }) async {
    try {
      final XFile? file = await _imagePicker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 85,
      );
      if (!mounted) return;
      if (file != null) {
        setState(() {
          if (isFront) {
            _frontFileName = file.name;
            _frontFile = file;
          } else {
            _backFileName = file.name;
            _backFile = file;
          }
        });
        AppToast.success(
          context,
          isFront
              ? 'პირადობის წინა მხარე არჩეულია'
              : 'პირადობის უკანა მხარე არჩეულია',
        );
      }
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, 'ფოტოს არჩევა ვერ მოხერხდა');
    }
  }

  void _showSourceModal({required bool isFront}) {
    final title = isFront ? 'პირადობის წინა მხარე' : 'პირადობის უკანა მხარე';
    showModalBottomSheet<void>(
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
                  title,
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'აირჩიეთ დოკუმენტის ატვირთვის წყარო',
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
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'კამერით გადაღება',
                    style: GoogleFonts.notoSansGeorgian(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickDocument(isFront: isFront, source: ImageSource.camera);
                  },
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
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'გალერეიდან არჩევა',
                    style: GoogleFonts.notoSansGeorgian(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickDocument(isFront: isFront, source: ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleSubmit() async {
    if (_frontFileName == null || _backFileName == null) {
      AppToast.warning(
        context,
        'გთხოვთ ატვირთოთ პირადობის მოწმობის ორივე მხარე',
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      if (_frontFile != null && _backFile != null) {
        await ref.read(authStateProvider.notifier).uploadAndSubmitKyc(
              frontFile: _frontFile!,
              backFile: _backFile!,
            );
      } else {
        await ref.read(authStateProvider.notifier).submitKycDocuments(
              idCardFrontUrl: 's3://agrokera-assets/kyc/id_front.jpg',
              idCardBackUrl: 's3://agrokera-assets/kyc/id_back.jpg',
            );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      AppToast.success(context, 'დოკუმენტები გაიგზავნა გადამოწმებაზე');
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, 'დოკუმენტების გაგზავნა ვერ მოხერხდა');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final kycStatus = ref.watch(authStateProvider).kycStatus;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: kycStatus == KycStatus.pendingReview
          ? _buildPendingView()
          : _buildUploadView(isRejected: kycStatus == KycStatus.rejected),
    );
  }

  Widget _buildPendingView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    LucideIcons.clock,
                    size: 20,
                    color: Color(0xFFD97706),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'საბუთები მოწმდება',
                  style: AppTypography.h1.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.surfaceInput,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  LucideIcons.x,
                  size: 18,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'თქვენი პირადობის მოწმობა გადამოწმების პროცესშია ადმინისტრაციის მიერ. პროცესი საშუალოდ 2-4 საათს გრძელდება.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const Icon(
                LucideIcons.info,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'დადასტურებისთანავე შეძლებთ პროდუქციის გამოქვეყნებას და გაყიდვების დაწყებას.',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          text: 'გასაგებია',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildUploadView({required bool isRejected}) {
    final canSubmit = _frontFileName != null && _backFileName != null && !_isSubmitting;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isRejected
                        ? const Color(0xFFFEE2E2)
                        : AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isRejected ? LucideIcons.circleAlert : LucideIcons.idCard,
                    size: 20,
                    color: isRejected
                        ? const Color(0xFFDC2626)
                        : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'პირადობის ვერიფიკაცია',
                  style: AppTypography.h1.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.surfaceInput,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  LucideIcons.x,
                  size: 18,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          isRejected
              ? 'წინა ატვირთვა უარყოფილია ბუნდოვანი ფოტოს გამო. გთხოვთ ატვირთოთ მკაფიო ფოტოები.'
              : 'პროდუქციის განსათავსებლად და სანდოობის ბეიჯის მისაღებად ატვირთეთ პირადობის მოწმობის ორივე მხარე.',
          style: AppTypography.bodyMedium.copyWith(
            color: isRejected ? const Color(0xFFDC2626) : AppColors.textSecondary,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _buildDocCard(
                label: 'წინა მხარე',
                icon: LucideIcons.idCard,
                fileName: _frontFileName,
                onTap: () => _showSourceModal(isFront: true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDocCard(
                label: 'უკანა მხარე',
                icon: LucideIcons.creditCard,
                fileName: _backFileName,
                onTap: () => _showSourceModal(isFront: false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(
              LucideIcons.shieldCheck,
              size: 15,
              color: AppColors.primary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'თქვენი პერსონალური მონაცემები სრულად დაცულია',
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        PrimaryButton(
          text: _isSubmitting ? 'იგზავნება...' : 'გაგზავნა გადამოწმებაზე',
          onPressed: canSubmit ? _handleSubmit : null,
        ),
      ],
    );
  }

  Widget _buildDocCard({
    required String label,
    required IconData icon,
    required String? fileName,
    required VoidCallback onTap,
  }) {
    final isDone = fileName != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isDone ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDone ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isDone ? const Color(0xFFDCFCE7) : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDone ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Icon(
                isDone ? LucideIcons.check : icon,
                size: 20,
                color: isDone ? const Color(0xFF16A34A) : AppColors.primary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: GoogleFonts.notoSansGeorgian(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              isDone ? 'არჩეულია' : 'ატვირთვა',
              style: GoogleFonts.notoSansGeorgian(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDone ? const Color(0xFF16A34A) : AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
