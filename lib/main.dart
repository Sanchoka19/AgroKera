import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_typography.dart';
import 'core/widgets/widgets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: AgroKeraApp()));
}

class AgroKeraApp extends StatelessWidget {
  const AgroKeraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgroKera',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      home: const FoundationPreviewScreen(),
    );
  }
}

/// Foundation showcase screen verifying Theme, Tokens and Core Widgets
class FoundationPreviewScreen extends StatelessWidget {
  const FoundationPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AgroKera 🌱')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('დიზაინ სისტემა & ჩონჩხი', style: AppTypography.h1),
              const SizedBox(height: 6),
              Text(
                'პირდაპირი კავშირი ფერმერსა და მყიდველს შორის — შუამავლების გარეშე.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Badges Section
              Text('სტატუსის ბეიჯები (StatusBadge):', style: AppTypography.h2),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatusBadge.verified(),
                  StatusBadge.success(
                    label: 'მარაგშია',
                    icon: const Icon(
                      LucideIcons.check,
                      size: 14,
                      color: AppColors.primary,
                    ),
                  ),
                  StatusBadge.pending(
                    label: 'ვერიფიკაციის მოლოდინში',
                    icon: const Icon(
                      LucideIcons.clock,
                      size: 14,
                      color: AppColors.rating,
                    ),
                  ),
                  StatusBadge.danger(
                    label: '-20% ფასდაკლება',
                    icon: const Icon(
                      LucideIcons.tag,
                      size: 14,
                      color: AppColors.accentWarm,
                    ),
                  ),
                  StatusBadge.neutral(
                    label: 'თვითგატანა (Self Pickup)',
                    icon: const Icon(
                      LucideIcons.mapPin,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Inputs Section
              Text(
                'საძიებო & ინფუთ ველები (CustomTextField):',
                style: AppTypography.h2,
              ),
              const SizedBox(height: 12),
              const CustomTextField(
                labelText: 'პროდუქტის ან ფერმის ძიება',
                hintText: 'მაგ. იმერული ყველი, კახური თაფლი...',
                prefixIcon: Icon(LucideIcons.search, size: 20),
              ),
              const SizedBox(height: 16),
              const CustomTextField(
                labelText: 'ფერმერის ტელეფონის ნომერი',
                hintText: '+995 599 00 00 00',
                prefixIcon: Icon(LucideIcons.phone, size: 20),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),

              // Buttons Section
              Text(
                'ღილაკები (PrimaryButton — 52px CTA):',
                style: AppTypography.h2,
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                text: 'შეკვეთის გაფორმება',
                icon: const Icon(
                  LucideIcons.shoppingBag,
                  size: 20,
                  color: AppColors.textOnPrimary,
                ),
                onPressed: () {},
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                text: 'მეურნეობის ლოკაცია რუკაზე',
                isOutlined: true,
                icon: const Icon(
                  LucideIcons.mapPin,
                  size: 20,
                  color: AppColors.primary,
                ),
                onPressed: () {},
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                text: 'იტვირთება...',
                isLoading: true,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
