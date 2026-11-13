import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/auth/auth_state_provider.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';
import '../widgets/farmer_map_widget.dart';

enum LegalStatus {
  physical('ფიზიკური პირი', LucideIcons.user),
  entrepreneur('ინდ. მეწარმე', LucideIcons.briefcase),
  company('შპს', LucideIcons.building2);

  final String label;
  final IconData icon;
  const LegalStatus(this.label, this.icon);
}

/// 5-Step Farmer Onboarding & Verification Wizard
/// Strictly adhering to Figma screenshots:
/// - Step 1/5: ფერმის ინფორმაცია & მისამართი (Name, Photo, Region, City, Interactive Map)
/// - Step 2/5: აირჩიე თქვენი სტატუსი (ფიზიკური პირი / ინდ. მეწარმე / შპს)
/// - Step 3/5: იურიდიული დეტალები & საბანკო ანგარიში (ID, Documents Upload, Bank & IBAN)
/// - Step 4/5: დეტალები & წესები და პირობები (Summary review with "შეცვლა" + 2 Checkboxes)
/// - Step 5/5: SMS დადასტურება (5-digit OTP verification & complete onboarding)
class FarmerOnboardingScreen extends ConsumerStatefulWidget {
  const FarmerOnboardingScreen({super.key});

  @override
  ConsumerState<FarmerOnboardingScreen> createState() =>
      _FarmerOnboardingScreenState();
}

class _FarmerOnboardingScreenState extends ConsumerState<FarmerOnboardingScreen> {
  int _currentStep = 1; // 1 to 5

  // Step 1: Farm Information & Address
  final _farmNameController = TextEditingController(text: 'მწვანე ველი');
  bool _hasFarmPhoto = false;
  String _selectedRegion = 'კახეთი';
  String _selectedCity = 'გურჯაანი';

  final List<String> _regions = [
    'კახეთი',
    'იმერეთი',
    'შიდა ქართლი',
    'ქვემო ქართლი',
    'სამეგრელო',
    'გურია',
    'აჭარა',
    'მცხეთა-მთიანეთი',
  ];

  final Map<String, List<String>> _citiesByRegion = {
    'კახეთი': ['თელავი', 'გურჯაანი', 'ყვარელი', 'საგარეჯო', 'სიღნაღი', 'ახმეტა'],
    'იმერეთი': ['ქუთაისი', 'სამტრედია', 'ზესტაფონი', 'წყალტუბო'],
    'შიდა ქართლი': ['გორი', 'კასპი', 'ხაშური', 'ქარელი'],
    'ქვემო ქართლი': ['რუსთავი', 'მარნეული', 'ბოლნისი'],
    'სამეგრელო': ['ზუგდიდი', 'ფოთი', 'სენაკი'],
    'გურია': ['ოზურგეთი', 'ლანჩხუთი', 'ჩოხატაური'],
    'აჭარა': ['ბათუმი', 'ქობულეთი', 'ხელვაჩაური'],
    'მცხეთა-მთიანეთი': ['მცხეთა', 'დუშეთი', 'ყაზბეგი'],
  };

  // Step 2: Legal Status
  LegalStatus _selectedStatus = LegalStatus.physical;

  // Step 3: Legal Details & Bank
  final _idNumberController = TextEditingController(text: '61000000000');
  bool _uploadedSelfie = true;
  bool _uploadedIdFront = true;
  bool _uploadedIdBack = true;
  String _selectedBank = 'TBC';
  final List<String> _banks = ['TBC', 'BOG', 'Liberty Bank', 'BasisBank'];
  final _ibanController = TextEditingController(text: 'GE79TB7700000000000000');

  // Step 4: Terms & Conditions Checkboxes
  bool _agreeTerms = true;
  bool _agreeQuality = true;

  // Step 5: SMS OTP Verification
  static const int _pinLength = 5;
  final List<TextEditingController> _pinControllers =
      List.generate(_pinLength, (_) => TextEditingController());
  final List<FocusNode> _pinFocusNodes =
      List.generate(_pinLength, (_) => FocusNode());
  int _secondsRemaining = 540;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  String get _formattedTime {
    final minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$minutes.$seconds';
  }

  @override
  void dispose() {
    _farmNameController.dispose();
    _idNumberController.dispose();
    _ibanController.dispose();
    _timer?.cancel();
    for (final c in _pinControllers) {
      c.dispose();
    }
    for (final f in _pinFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onNext() {
    if (_currentStep < 5) {
      setState(() => _currentStep++);
    } else {
      _onCompleteOnboarding();
    }
  }

  void _onBack() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _onCompleteOnboarding() {
    ref.read(authStateProvider.notifier).login(
      role: UserRole.farmer,
      name: 'ლანა მახარაძე',
      phone: '+995 599 12 34 56',
      email: 'farmer@agrokera.ge',
    );

    Navigator.of(context).popUntil((route) => route.isFirst);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ფერმერის პროფილი წარმატებით შეიქმნა და ვერიფიცირდა!'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openFullScreenMap() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => FarmerMapWidget(
          isFullScreen: true,
          locationText: '$_selectedRegion, $_selectedCity',
          onToggleFullScreen: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: AppColors.textPrimary, size: 28),
          onPressed: _onBack,
        ),
        title: _buildProgressBar(),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: _buildCurrentStepContent(),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _currentStep / 5.0,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Text(
          '$_currentStep/5',
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
      ),
      child: PrimaryButton(
        text: _currentStep == 5 ? 'დადასტურება' : 'შემდეგი',
        height: 52,
        borderRadius: BorderRadius.circular(12),
        onPressed: _onNext,
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 1:
        return _buildStep1FarmInfo();
      case 2:
        return _buildStep2StatusSelection();
      case 3:
        return _buildStep3LegalAndBank();
      case 4:
        return _buildStep4ReviewAndTerms();
      case 5:
        return _buildStep5SmsVerification();
      default:
        return const SizedBox.shrink();
    }
  }

  // ==========================================
  // STEP 1: ფერმის ინფორმაცია & მისამართი
  // ==========================================
  Widget _buildStep1FarmInfo() {
    final availableCities = _citiesByRegion[_selectedRegion] ?? ['თელავი'];
    if (!availableCities.contains(_selectedCity)) {
      _selectedCity = availableCities.first;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Card 1: ფერმის ინფორმაცია
        _buildSectionCard(
          title: 'ფერმის ინფორმაცია',
          icon: LucideIcons.sprout,
          children: [
            _buildFieldLabel('ფერმის/მეურნეობის დასახელება*'),
            const SizedBox(height: 8),
            TextField(
              controller: _farmNameController,
              style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
              decoration: _buildInputDecoration(hint: 'მწვანე ველი'),
            ),
            const SizedBox(height: 18),
            _buildFieldLabel('ატვირთეთ თქვენი ან ფერმის ფოტო *'),
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                setState(() => _hasFarmPhoto = !_hasFarmPhoto);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_hasFarmPhoto ? 'ფოტო წარმატებით აიტვირთა!' : 'ფოტო წაიშალა'),
                    duration: const Duration(seconds: 1),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFCBD5E1),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _hasFarmPhoto ? LucideIcons.checkCircle2 : LucideIcons.camera,
                      size: 26,
                      color: _hasFarmPhoto ? AppColors.primary : const Color(0xFF334155),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _hasFarmPhoto ? 'ფოტო ატვირთულია' : 'ატვირთე',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _hasFarmPhoto ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Card 2: მისამართი
        _buildSectionCard(
          title: 'მისამართი',
          icon: LucideIcons.mapPin,
          children: [
            _buildFieldLabel('რეგიონი *'),
            const SizedBox(height: 8),
            _buildDropdown(
              value: _selectedRegion,
              items: _regions,
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedRegion = val;
                    _selectedCity = _citiesByRegion[val]?.first ?? 'თელავი';
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            _buildFieldLabel('ქალაქი/რაიონი *'),
            const SizedBox(height: 8),
            _buildDropdown(
              value: _selectedCity,
              items: availableCities,
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedCity = val);
                }
              },
            ),
            const SizedBox(height: 16),
            FarmerMapWidget(
              locationText: '$_selectedRegion, $_selectedCity',
              onToggleFullScreen: _openFullScreenMap,
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  // ==========================================
  // STEP 2: აირჩიე თქვენი სტატუსი
  // ==========================================
  Widget _buildStep2StatusSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Text(
          'აირჩიე\nთქვენი სტატუსი',
          style: AppTypography.h1.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            height: 1.3,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        ...LegalStatus.values.map((status) {
          final isSelected = _selectedStatus == status;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: InkWell(
              onTap: () {
                setState(() => _selectedStatus = status);
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : const Color(0xFFF1F5F9),
                    width: isSelected ? 2.0 : 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isSelected ? 0.06 : 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEBF7EF),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        status.icon,
                        size: 24,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 18),
                    Text(
                      status.label,
                      style: AppTypography.titleMedium.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ==========================================
  // STEP 3: იურიდიული დეტალები & საბანკო ანგარიში
  // ==========================================
  Widget _buildStep3LegalAndBank() {
    final String cardTitle;
    final IconData cardIcon;
    final String idLabel;

    switch (_selectedStatus) {
      case LegalStatus.physical:
        cardTitle = 'ფიზიკური პირის დეტალები';
        cardIcon = LucideIcons.user;
        idLabel = 'პირადი ნომერი *';
        break;
      case LegalStatus.entrepreneur:
        cardTitle = 'ინდ. მეწარმის დეტალები';
        cardIcon = LucideIcons.briefcase;
        idLabel = 'საიდენტიფიკაციო ნომერი *';
        break;
      case LegalStatus.company:
        cardTitle = 'შპს დეტალები';
        cardIcon = LucideIcons.building2;
        idLabel = 'საიდენტიფიკაციო ნომერი *';
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Card 1: Legal details & document upload
        _buildSectionCard(
          title: cardTitle,
          icon: cardIcon,
          children: [
            _buildFieldLabel(idLabel),
            const SizedBox(height: 8),
            TextField(
              controller: _idNumberController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
              decoration: _buildInputDecoration(hint: '61000000000'),
            ),
            const SizedBox(height: 18),

            // 3 Upload Boxes: სელფი, წინა მხარე, უკანა მხარე
            Row(
              children: [
                Expanded(
                  child: _buildUploadBox(
                    label: 'სელფი',
                    icon: LucideIcons.smile,
                    isDone: _uploadedSelfie,
                    onTap: () => setState(() => _uploadedSelfie = !_uploadedSelfie),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildUploadBox(
                    label: 'წინა მხარე',
                    icon: LucideIcons.contact,
                    isDone: _uploadedIdFront,
                    onTap: () => setState(() => _uploadedIdFront = !_uploadedIdFront),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildUploadBox(
                    label: 'უკანა მხარე',
                    icon: LucideIcons.creditCard,
                    isDone: _uploadedIdBack,
                    onTap: () => setState(() => _uploadedIdBack = !_uploadedIdBack),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'გთხოვთ, ატვირთოთ თქვენი პირადობის მოწმობის ორივე მხარე და სელფი, სადაც გიჭირავთ იგივე დოკუმენტი.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.primaryDark.withValues(alpha: 0.85),
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Card 2: საბანკო ანგარიში
        _buildSectionCard(
          title: 'საბანკო ანგარიში',
          icon: LucideIcons.creditCard,
          children: [
            _buildFieldLabel('ბენეფიციარი ბანკი *'),
            const SizedBox(height: 8),
            _buildDropdown(
              value: _selectedBank,
              items: _banks,
              onChanged: (val) {
                if (val != null) setState(() => _selectedBank = val);
              },
            ),
            const SizedBox(height: 16),
            _buildFieldLabel('ანგარიშის ნომერი (IBAN) *'),
            const SizedBox(height: 8),
            TextField(
              controller: _ibanController,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
              decoration: _buildInputDecoration(hint: 'GE**************'),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  // ==========================================
  // STEP 4: დეტალების გადახედვა & წესები
  // ==========================================
  Widget _buildStep4ReviewAndTerms() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Summary Details Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'დეტალები',
                    style: AppTypography.h1.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => setState(() => _currentStep = 1),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      minimumSize: Size.zero,
                    ),
                    child: const Text(
                      'შეცვლა',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildReviewRow('სრული სახელი:', 'ლანა მახარაძე'),
              _buildReviewRow('ფერმის სახელი:', _farmNameController.text.isNotEmpty ? _farmNameController.text : 'ოქროს ქვაფი'),
              _buildReviewRow('მისამართი:', '$_selectedRegion, $_selectedCity, 1 რაიონი'),
              _buildReviewRow('ბანკი:', _selectedBank),
              _buildReviewRow('IBAN:', _ibanController.text.length > 7 ? '****${_ibanController.text.substring(_ibanController.text.length - 7)}' : '****7ER9', isLast: true),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Terms and conditions Card
        _buildSectionCard(
          title: 'წესები და პირობები',
          icon: LucideIcons.building2,
          children: [
            // Checkbox 1
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _agreeTerms,
                    activeColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    onChanged: (val) => setState(() => _agreeTerms = val ?? false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      text: 'ვეთანხმები agrokera-ს ',
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: 13.5,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                      children: const [
                        TextSpan(
                          text: 'მომსახურების პირობებსა',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        TextSpan(text: ' და '),
                        TextSpan(
                          text: 'კონფიდენციალურობის პოლიტიკას',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Checkbox 2
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _agreeQuality,
                    activeColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    onChanged: (val) => setState(() => _agreeQuality = val ?? false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'ვაცნობიერებ სრულ პასუხისმგებლობას ჩემ მიერ განთავსებული პროდუქციის ხარისხზე, უსაფრთხოებასა და ბუნებრიობაზე.',
                    style: AppTypography.bodyMedium.copyWith(
                      fontSize: 13.5,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  // ==========================================
  // STEP 5: SMS დადასტურება
  // ==========================================
  Widget _buildStep5SmsVerification() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: SizedBox(
            height: 150,
            child: SvgPicture.asset(
              AppAssets.verification,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'შეიყვანეთ SMS კოდი',
          style: AppTypography.h1.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'კოდი გაიგზავნა example@gmail.com',
          style: AppTypography.bodyMedium.copyWith(
            fontSize: 14,
            color: const Color(0xFF64748B),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),

        // 5 OTP boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_pinLength, (index) {
            return SizedBox(
              width: 54,
              height: 58,
              child: TextField(
                controller: _pinControllers[index],
                focusNode: _pinFocusNodes[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '8',
                  hintStyle: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
                  ),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty && index < _pinLength - 1) {
                    _pinFocusNodes[index + 1].requestFocus();
                  } else if (value.isEmpty && index > 0) {
                    _pinFocusNodes[index - 1].requestFocus();
                  }
                },
              ),
            );
          }),
        ),
        const SizedBox(height: 24),

        // Resend
        Center(
          child: GestureDetector(
            onTap: () {
              setState(() => _secondsRemaining = 540);
              _startTimer();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('ახალი SMS კოდი გაიგზავნა.'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppColors.primary,
                ),
              );
            },
            child: RichText(
              text: TextSpan(
                text: 'არ მიგიღიათ კოდი? ',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                children: const [
                  TextSpan(
                    text: 'ახლიდან გაგზავნა',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Timer
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.clock, size: 18, color: Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(
              _formattedTime,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ==========================================
  // SHARED WIDGET HELPERS
  // ==========================================
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.textPrimary),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTypography.titleMedium.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: AppTypography.titleMedium.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  InputDecoration _buildInputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : items.first,
          isExpanded: true,
          icon: const Icon(LucideIcons.chevronDown, size: 20, color: AppColors.textPrimary),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildUploadBox({
    required String label,
    required IconData icon,
    required bool isDone,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 84,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDone ? const Color(0xFFEBF7EF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDone ? AppColors.primary : const Color(0xFFCBD5E1),
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isDone ? LucideIcons.checkCircle : icon,
              size: 22,
              color: isDone ? AppColors.primary : const Color(0xFF334155),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: isDone ? AppColors.primary : AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewRow(String title, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          if (!isLast) ...[
            const SizedBox(height: 8),
            const Divider(color: Color(0xFFF1F5F9), height: 1),
          ],
        ],
      ),
    );
  }
}
