import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:agrokera/core/auth/auth_repository.dart';
import 'package:agrokera/core/theme/app_colors.dart';
import 'package:agrokera/core/widgets/app_toast.dart';
import '../../models/farmer_onboarding_state.dart';
import '../../providers/farmer_onboarding_provider.dart';
import '../farmer_map_widget.dart';
import '../onboarding_shared_widgets.dart';

class Step1FarmInfoWidget extends ConsumerStatefulWidget {
  final TextEditingController farmNameController;

  const Step1FarmInfoWidget({
    super.key,
    required this.farmNameController,
  });

  @override
  ConsumerState<Step1FarmInfoWidget> createState() => _Step1FarmInfoWidgetState();
}

class _Step1FarmInfoWidgetState extends ConsumerState<Step1FarmInfoWidget> {
  final _imagePicker = ImagePicker();
  late final TextEditingController _addressController;
  late final TextEditingController _landmarkController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(farmerOnboardingProvider);
    _addressController = TextEditingController(text: state.dynamicAddress);
    _landmarkController = TextEditingController(text: state.landmark);
  }

  @override
  void dispose() {
    _addressController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  Future<void> _handlePickedFarmPhoto(XFile file) async {
    final notifier = ref.read(farmerOnboardingProvider.notifier);
    final authRepo = ref.read(authRepositoryProvider);
    String previewPath = file.path;
    try {
      final bytes = await file.readAsBytes();
      if (bytes.isNotEmpty) {
        previewPath = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      }
    } catch (_) {}
    notifier.setFarmPhoto(path: previewPath, name: file.name);
    if (mounted) {
      AppToast.info(context, 'ფერმის ფოტო იტვირთება...');
    }
    try {
      final remoteUrl = await authRepo.uploadImage(file, folder: 'covers');
      if (remoteUrl != null && remoteUrl.isNotEmpty) {
        notifier.setFarmPhoto(path: remoteUrl, name: file.name);
      }
    } catch (_) {}
    if (mounted) {
      AppToast.success(context, 'ფერმის ფოტო წარმატებით აიტვირთა!');
    }
  }

  Future<void> _pickFarmPhoto() async {
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
                  'ფერმის გარეკანის ფოტო',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'ეს ფოტო გამოჩნდება მთავარ გვერდზე თქვენი ფერმის ბარათზე',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(LucideIcons.camera, color: AppColors.primary),
                  title: Text(
                    'კამერით გადაღება',
                    style: GoogleFonts.notoSansGeorgian(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('გადაუღე ფერმას ან მეურნეობას'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    try {
                      final XFile? file = await _imagePicker.pickImage(
                        source: ImageSource.camera,
                        maxWidth: 1600,
                        maxHeight: 1000,
                        imageQuality: 85,
                      );
                      if (file != null) {
                        await _handlePickedFarmPhoto(file);
                      }
                    } catch (_) {
                      if (!mounted) return;
                      AppToast.error(context, 'კამერის გახსნა ვერ მოხერხდა');
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(LucideIcons.image, color: AppColors.primary),
                  title: Text(
                    'გალერეიდან არჩევა',
                    style: GoogleFonts.notoSansGeorgian(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('ატვირთე ლანდშაფტური სურათი'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    try {
                      final XFile? file = await _imagePicker.pickImage(
                        source: ImageSource.gallery,
                        maxWidth: 1600,
                        maxHeight: 1000,
                        imageQuality: 85,
                      );
                      if (file != null) {
                        await _handlePickedFarmPhoto(file);
                      }
                    } catch (_) {
                      if (!mounted) return;
                      AppToast.error(context, 'ფოტოს არჩევა ვერ მოხერხდა');
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(LucideIcons.image, color: AppColors.primary),
                  title: Text(
                    'სანიმუშო აგრო-გარეკანის არჩევა',
                    style: GoogleFonts.notoSansGeorgian(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('მზა თემატური ფოტოები (ვენახი, ბაღი, სათბური)'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showPresetCoverPicker();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPresetCoverPicker() {
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
                    itemBuilder: (context, index) {
                      final preset = FarmerOnboardingState.presetFarmCovers[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          ref.read(farmerOnboardingProvider.notifier).setFarmPhoto(
                                path: preset['url']!,
                                name: preset['title']!,
                              );
                          AppToast.success(context, 'გარეკანი არჩეულია: ${preset["title"]}');
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

  Future<void> _detectGps() async {
    HapticFeedback.lightImpact();
    try {
      final resolved =
          await ref.read(farmerOnboardingProvider.notifier).detectGpsLocation();
      if (!mounted) return;
      setState(() {
        _addressController.text = resolved;
      });
      AppToast.success(context, 'მისამართი დადგენილია: $resolved');
    } catch (e) {
      if (!mounted) return;
      AppToast.error(
        context,
        e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void _openFullScreenMap(FarmerOnboardingState state) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => FarmerMapWidget(
          isFullScreen: true,
          locationText: state.dynamicAddress.isNotEmpty
              ? state.dynamicAddress
              : '${state.selectedRegion}, ${state.selectedCity}',
          initialLocation: state.selectedLocation,
          onLocationChanged: (point) {
            ref.read(farmerOnboardingProvider.notifier).setLocation(point);
          },
          onAddressResolved: (point, address) {
            ref.read(farmerOnboardingProvider.notifier).setLocation(
                  point,
                  address: address,
                );
            setState(() {
              _addressController.text = address;
            });
          },
          onToggleFullScreen: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(farmerOnboardingProvider);
    final availableCities =
        FarmerOnboardingState.citiesByRegion[state.selectedRegion] ?? ['თელავი'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Card 1: ფერმის ინფორმაცია
        OnboardingSectionCard(
          title: 'ფერმის ინფორმაცია',
          icon: LucideIcons.sprout,
          children: [
            const OnboardingFieldLabel('ფერმის/მეურნეობის დასახელება*'),
            const SizedBox(height: 8),
            TextField(
              controller: widget.farmNameController,
              onChanged: (val) =>
                  ref.read(farmerOnboardingProvider.notifier).setFarmName(val),
              style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
              decoration: onboardingInputDecoration(hint: 'მწვანე ველი'),
            ),
            const SizedBox(height: 18),
            const OnboardingFieldLabel('ფერმის ბანერი *'),
            const SizedBox(height: 4),
            Text(
              'გამოჩნდება თქვენი ფერმის ბარათზე',
              style: GoogleFonts.notoSansGeorgian(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            if (state.hasFarmPhoto && state.farmPhotoPath != null)
              Container(
                height: 145,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    buildCoverPreviewImage(state.farmPhotoPath!),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.75),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.badgeCheck,
                          color: AppColors.primary,
                          size: 16,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _pickFarmPhoto,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.4),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  LucideIcons.camera,
                                  color: Colors.white,
                                  size: 13,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'შეცვლა',
                                  style: GoogleFonts.notoSansGeorgian(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      left: 12,
                      right: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.farmNameController.text.trim().isNotEmpty
                                ? widget.farmNameController.text.trim()
                                : 'ფერმის დასახელება',
                            style: GoogleFonts.notoSansGeorgian(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${state.selectedCity}, ${state.selectedRegion}',
                            style: GoogleFonts.notoSansGeorgian(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              InkWell(
                onTap: _pickFarmPhoto,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFCBD5E1),
                      width: 1.2,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            LucideIcons.plus,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ბანერის ატვირთვა',
                          style: GoogleFonts.notoSansGeorgian(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),

        // Card 2: მისამართი
        OnboardingSectionCard(
          title: 'მისამართი',
          icon: LucideIcons.mapPin,
          children: [
            const OnboardingFieldLabel('რეგიონი *'),
            const SizedBox(height: 8),
            OnboardingDropdown(
              title: 'აირჩიეთ რეგიონი',
              value: state.selectedRegion,
              items: FarmerOnboardingState.regions,
              onChanged: (val) {
                ref.read(farmerOnboardingProvider.notifier).setRegion(val);
                final updatedState = ref.read(farmerOnboardingProvider);
                _addressController.text = updatedState.dynamicAddress;
              },
            ),
            const SizedBox(height: 16),
            const OnboardingFieldLabel('ქალაქი/რაიონი *'),
            const SizedBox(height: 8),
            OnboardingDropdown(
              title: 'აირჩიეთ ქალაქი/რაიონი',
              value: state.selectedCity,
              items: availableCities,
              onChanged: (val) {
                ref.read(farmerOnboardingProvider.notifier).setCity(val);
                final updatedState = ref.read(farmerOnboardingProvider);
                _addressController.text = updatedState.dynamicAddress;
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: _detectGps,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(LucideIcons.locateFixed, size: 17),
                label: const Text(
                  'ჩემი მდებარეობის დადგენა (GPS)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            FarmerMapWidget(
              locationText: state.dynamicAddress.isNotEmpty
                  ? state.dynamicAddress
                  : '${state.selectedRegion}, ${state.selectedCity}',
              initialLocation: state.selectedLocation,
              onLocationChanged: (point) {
                ref.read(farmerOnboardingProvider.notifier).setLocation(point);
              },
              onAddressResolved: (point, address) {
                ref.read(farmerOnboardingProvider.notifier).setLocation(
                      point,
                      address: address,
                    );
                setState(() {
                  _addressController.text = address;
                });
              },
              onToggleFullScreen: () => _openFullScreenMap(state),
            ),
            const SizedBox(height: 16),

            // 1. Exact Address Line Input
            const OnboardingFieldLabel('მეურნეობის ზუსტი მისამართი (სოფელი, ქუჩა, ნომერი) *'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _addressController,
              onChanged: (val) {
                ref.read(farmerOnboardingProvider.notifier).setDynamicAddress(val);
              },
              style: GoogleFonts.notoSansGeorgian(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'მაგ: კახეთი, გურჯაანი, სოფ. ვაზისუბანი',
                hintStyle: GoogleFonts.notoSansGeorgian(
                  fontSize: 13,
                  color: const Color(0xFF94A3B8),
                ),
                prefixIcon: const Icon(
                  LucideIcons.mapPin,
                  size: 18,
                  color: AppColors.primary,
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
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
              ),
            ),
            const SizedBox(height: 16),

            // 2. Optional Landmark Input
            const OnboardingFieldLabel('ორიენტირი / როგორ მოვიდეთ (არასავალდებულო)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _landmarkController,
              onChanged: (val) {
                ref.read(farmerOnboardingProvider.notifier).setLandmark(val);
              },
              maxLines: 2,
              style: GoogleFonts.notoSansGeorgian(fontSize: 13.5),
              decoration: InputDecoration(
                hintText: 'მაგ: სოფლის ცენტრთან, წითელი ჭიშკარი, მეურნეობა #3',
                hintStyle: GoogleFonts.notoSansGeorgian(
                  fontSize: 12.5,
                  color: const Color(0xFF94A3B8),
                ),
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 24),
                  child: Icon(
                    LucideIcons.signpost,
                    size: 18,
                    color: Color(0xFF64748B),
                  ),
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
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
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
