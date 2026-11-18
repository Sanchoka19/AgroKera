import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/auth/auth_state_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../marketplace/presentation/providers/marketplace_provider.dart';

/// Bottom sheet modal to edit user's personal name and/or farm name.
class EditProfileBottomSheet extends ConsumerStatefulWidget {
  const EditProfileBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const EditProfileBottomSheet(),
    );
  }

  @override
  ConsumerState<EditProfileBottomSheet> createState() =>
      _EditProfileBottomSheetState();
}

class _EditProfileBottomSheetState extends ConsumerState<EditProfileBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _farmNameController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authStateProvider);
    _nameController = TextEditingController(
      text: auth.userName ?? (auth.isFarmer ? 'რევაზ ბერიძე' : 'საბა ევგენიძე'),
    );
    _farmNameController = TextEditingController(
      text: auth.farmName ?? (auth.isFarmer ? 'ჩემი მეურნეობა' : ''),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _farmNameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = ref.read(authStateProvider);
    final newName = _nameController.text.trim();
    final newFarmName = auth.isFarmer ? _farmNameController.text.trim() : null;

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      await ref.read(authStateProvider.notifier).updateProfileNames(
            userName: newName,
            farmName: newFarmName,
          );

      if (auth.isFarmer && newFarmName != null && newFarmName.isNotEmpty) {
        ref.read(marketplaceProvider.notifier).updateFarmerNames(
              farmerId: auth.farmerId,
              farmName: newFarmName,
              farmerName: newName,
            );
      }

      if (mounted) {
        Navigator.of(context).pop();
        AppToast.success(
          context,
          'პროფილის მონაცემები წარმატებით განახლდა',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppToast.error(
          context,
          'მონაცემების შენახვა ვერ მოხერხდა, სცადეთ თავიდან',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    final isFarmer = auth.isFarmer;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Header row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'პროფილის რედაქტირება',
                          style: GoogleFonts.notoSansGeorgian(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isFarmer
                              ? 'შეცვალეთ თქვენი პირადი და მეურნეობის სახელი'
                              : 'შეცვალეთ თქვენი პირადი სახელი და გვარი',
                          style: GoogleFonts.notoSansGeorgian(
                            fontSize: 12.5,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 20),
                      onPressed: () => Navigator.pop(context),
                      splashRadius: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 1. Personal Name Field
                Text(
                  'პირადი სახელი და გვარი',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  textInputAction:
                      isFarmer ? TextInputAction.next : TextInputAction.done,
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'გთხოვთ მიუთითოთ სახელი და გვარი';
                    }
                    if (v.trim().length < 2) {
                      return 'სახელი უნდა შედგებოდეს მინიმუმ 2 სიმბოლოსგან';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'მაგ: გიორგი ბერიძე',
                    hintStyle: GoogleFonts.notoSansGeorgian(
                      fontSize: 13.5,
                      color: const Color(0xFF94A3B8),
                    ),
                    prefixIcon: const Icon(
                      LucideIcons.user,
                      size: 18,
                      color: Color(0xFF64748B),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFEF4444)),
                    ),
                  ),
                ),

                // 2. Farm Name Field (Only for Farmer)
                if (isFarmer) ...[
                  const SizedBox(height: 18),
                  Text(
                    'მეურნეობის / ფერმის დასახელება',
                    style: GoogleFonts.notoSansGeorgian(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _farmNameController,
                    textInputAction: TextInputAction.done,
                    style: GoogleFonts.notoSansGeorgian(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'გთხოვთ მიუთითოთ მეურნეობის დასახელება';
                      }
                      if (v.trim().length < 2) {
                        return 'დასახელება უნდა შედგებოდეს მინიმუმ 2 სიმბოლოსგან';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: 'მაგ: მწვანე ველი',
                      hintStyle: GoogleFonts.notoSansGeorgian(
                        fontSize: 13.5,
                        color: const Color(0xFF94A3B8),
                      ),
                      prefixIcon: const Icon(
                        LucideIcons.sprout,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 13,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFEF4444)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          LucideIcons.info,
                          size: 15,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'ფერმის სახელი საჯაროა და გამოჩნდება პროდუქტების კატალოგში, ბაზარზე და შეკვეთების დეტალებში.',
                            style: GoogleFonts.notoSansGeorgian(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF166534),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Save button
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(LucideIcons.check, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'შენახვა',
                                style: GoogleFonts.notoSansGeorgian(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
