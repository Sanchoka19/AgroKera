import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/auth/auth_state_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_toast.dart';

/// Farmer KYC Verification & Status Management Screen
class KycVerificationScreen extends ConsumerStatefulWidget {
  const KycVerificationScreen({super.key});

  @override
  ConsumerState<KycVerificationScreen> createState() =>
      _KycVerificationScreenState();
}

class _KycVerificationScreenState extends ConsumerState<KycVerificationScreen> {
  final _imagePicker = ImagePicker();
  bool _frontUploaded = false;
  bool _backUploaded = false;
  String? _frontFileName;
  String? _backFileName;
  XFile? _frontFile;
  XFile? _backFile;
  bool _isSubmitting = false;

  Future<void> _pickKycPhoto({
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
            _frontUploaded = true;
            _frontFileName = file.name;
            _frontFile = file;
          } else {
            _backUploaded = true;
            _backFileName = file.name;
            _backFile = file;
          }
        });
        AppToast.success(
          context,
          isFront
              ? 'პირადობის წინა მხარე წარმატებით აიტვირთა'
              : 'პირადობის უკანა მხარე წარმატებით აიტვირთა',
        );
      }
    } catch (_) {
      if (!mounted) return;
      AppToast.error(
        context,
        'ფოტოს არჩევა ვერ მოხერხდა',
      );
    }
  }

  void _showDocumentSourceModal({required bool isFront}) {
    final label = isFront ? 'პირადობის წინა მხარე' : 'პირადობის უკანა მხარე';
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
                  label,
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'აირჩიეთ დოკუმენტის ატვირთვის მეთოდი',
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
                    'გადაუღე დოკუმენტს მკაფიო ფოტო',
                    style: GoogleFonts.notoSansGeorgian(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickKycPhoto(isFront: isFront, source: ImageSource.camera);
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
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickKycPhoto(isFront: isFront, source: ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitForReview() async {
    if (!_frontUploaded || !_backUploaded) {
      AppToast.error(
        context,
        'გთხოვთ ატვირთოთ პირადობის მოწმობის ორივე მხარე',
      );
      return;
    }
    setState(() => _isSubmitting = true);
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
    setState(() => _isSubmitting = false);
    AppToast.success(
      context,
      'დოკუმენტები გაიგზავნა გადამოწმებაზე!',
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final kycStatus = authState.kycStatus;

    final (
      Color badgeColor,
      Color badgeBg,
      IconData statusIcon,
      String statusTitle,
      String statusDescription
    ) = switch (kycStatus) {
      KycStatus.verified => (
          const Color(0xFF16A34A),
          const Color(0xFFDCFCE7),
          LucideIcons.shieldCheck,
          'თქვენი ფერმა ვერიფიცირებულია',
          'თქვენ გაქვთ სრული წვდომა პროდუქციის გამოქვეყნებასა და შეკვეთების მიღებაზე. მყიდველები ხედავენ ვერიფიკაციის ნიშანს თქვენს პროფილზე.'
        ),
      KycStatus.pendingReview => (
          const Color(0xFFD97706),
          const Color(0xFFFEF3C7),
          LucideIcons.clock,
          'დოკუმენტები მოწმდება',
          'ადმინისტრაცია ამოწმებს თქვენს პირადობის მოწმობას და მეურნეობის მონაცემებს. პროცესი საშუალოდ 2-4 საათს გრძელდება.'
        ),
      KycStatus.rejected => (
          const Color(0xFFDC2626),
          const Color(0xFFFEE2E2),
          LucideIcons.circleAlert,
          'ვერიფიკაცია უარყოფილია',
          'ატვირთული ფოტოები ბუნდოვანი იყო. გთხოვთ თავიდან გადაიღოთ პირადობის მოწმობის წინა და უკანა მხარე კარგი განათების პირობებში.'
        ),
      KycStatus.unverified => (
          const Color(0xFF475569),
          const Color(0xFFF1F5F9),
          LucideIcons.idCard,
          'გაიარეთ ფერმერის ვერიფიკაცია (KYC)',
          'პროდუქციის გასაყიდად და სანდოობის ბეიჯის მისაღებად აუცილებელია პირადობის დამადასტურებელი დოკუმენტის ატვირთვა.'
        ),
    };

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(
              title: 'ფერმერის ვერიფიკაცია (KYC)',
              showBack: true,
              showNotificationBell: false,
              showCart: false,
              padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Status Banner Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: badgeColor.withValues(alpha: 0.25)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: badgeBg,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  statusIcon,
                                  color: badgeColor,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: badgeBg,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        kycStatus.label,
                                        style: GoogleFonts.notoSansGeorgian(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: badgeColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      statusTitle,
                                      style: GoogleFonts.notoSansGeorgian(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            statusDescription,
                            style: GoogleFonts.notoSansGeorgian(
                              fontSize: 13,
                              height: 1.5,
                              color: const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      'პირადობის მოწმობის (ID) ფოტოები',
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'ფოტოები ინახება დაცულ Neon S3 საცავში მხოლოდ ვერიფიკაციის მიზნით.',
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 14),

                    _buildDocumentSlot(
                      title: 'პირადობის წინა მხარე (ID Front)',
                      subtitle: _frontUploaded
                          ? 'ფოტო ატვირთულია (${_frontFileName ?? "id_front.jpg"})'
                          : 'დააჭირეთ გადასაღებად ან ასატვირთად',
                      isUploaded: _frontUploaded,
                      onTap: () => _showDocumentSourceModal(isFront: true),
                    ),
                    const SizedBox(height: 12),
                    _buildDocumentSlot(
                      title: 'პირადობის უკანა მხარე (ID Back)',
                      subtitle: _backUploaded
                          ? 'ფოტო ატვირთულია (${_backFileName ?? "id_back.jpg"})'
                          : 'დააჭირეთ გადასაღებად ან ასატვირთად',
                      isUploaded: _backUploaded,
                      onTap: () => _showDocumentSourceModal(isFront: false),
                    ),

                    const SizedBox(height: 24),

                    if (kycStatus != KycStatus.verified)
                      SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _submitForReview,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(LucideIcons.upload, size: 18),
                          label: Text(
                            _isSubmitting
                                ? 'იგზავნება...'
                                : 'დოკუმენტების გაგზავნა გადამოწმებაზე',
                            style: GoogleFonts.notoSansGeorgian(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Quick Status Switcher for Testing KYC States with Neon Backend
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'სტატუსის სიმულაცია (Neon DB სინქრონიზაციით)',
                            style: GoogleFonts.notoSansGeorgian(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: KycStatus.values.map((st) {
                              final selected = st == kycStatus;
                              return ChoiceChip(
                                label: Text(
                                  st.label,
                                  style: GoogleFonts.notoSansGeorgian(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: selected
                                        ? Colors.white
                                        : const Color(0xFF334155),
                                  ),
                                ),
                                selected: selected,
                                selectedColor: AppColors.primary,
                                onSelected: (_) {
                                  ref
                                      .read(authStateProvider.notifier)
                                      .updateKycStatus(st);
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentSlot({
    required String title,
    required String subtitle,
    required bool isUploaded,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUploaded
                ? const Color(0xFF16A34A).withValues(alpha: 0.4)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isUploaded
                    ? const Color(0xFFDCFCE7)
                    : AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isUploaded ? LucideIcons.circleCheck : LucideIcons.idCard,
                color: isUploaded
                    ? const Color(0xFF16A34A)
                    : AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.notoSansGeorgian(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.notoSansGeorgian(
                      fontSize: 12,
                      color: isUploaded
                          ? const Color(0xFF16A34A)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isUploaded ? LucideIcons.refreshCw : LucideIcons.chevronRight,
              size: 18,
              color: isUploaded ? AppColors.primary : const Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }
}

