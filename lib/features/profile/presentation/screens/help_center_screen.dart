import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import 'faq_details_screen.dart';

/// Help Center Screen adhering to Screenshot 8:
/// - "ხშირად დასმული კითხვები" (FAQ grid with 6 cards)
/// - "დაგვიკავშირდით" (Email and Phone contact cards)
class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, size: 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'დახმარების ცენტრი',
          style: AppTypography.h1.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // FAQ Section
              Text(
                'ხშირად დასმული კითხვები',
                style: AppTypography.titleMedium.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),

              // 2x3 Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _FaqTopicCard(
                    icon: LucideIcons.helpCircle,
                    title: 'ზოგადი',
                    subtitle: 'ხშირი კითხვები',
                    onTap: () => _openFaq(context, 'ზოგადი'),
                  ),
                  _FaqTopicCard(
                    icon: LucideIcons.truck,
                    title: 'მიტანა',
                    subtitle: 'მიტანის პოლიტიკა',
                    onTap: () => _openFaq(context, 'მიტანა'),
                  ),
                  _FaqTopicCard(
                    icon: LucideIcons.box,
                    title: 'დაბრუნება',
                    subtitle: 'დაბრუნების პოლიტიკა',
                    onTap: () => _openFaq(context, 'დაბრუნება'),
                  ),
                  _FaqTopicCard(
                    icon: LucideIcons.creditCard,
                    title: 'გადახდა',
                    subtitle: 'გადახდის მეთოდები',
                    onTap: () => _openFaq(context, 'გადახდა'),
                  ),
                  _FaqTopicCard(
                    icon: LucideIcons.user,
                    title: 'ანგარიში',
                    subtitle: 'ხშირი პარამეტრები',
                    onTap: () => _openFaq(context, 'ანგარიში'),
                  ),
                  _FaqTopicCard(
                    icon: LucideIcons.chevronDown,
                    title: 'ყველა',
                    subtitle: 'ყველა თემა',
                    onTap: () => _openFaq(context, 'ყველა თემა'),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Contact Section
              Text(
                'დაგვიკავშირდით',
                style: AppTypography.titleMedium.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),

              // Email Card
              _ContactCard(
                icon: LucideIcons.mail,
                title: 'ელ.ფოსტა',
                subtitle: 'agrokera@agro.com',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('გადამისამართება: agrokera@agro.com'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Phone Card
              _ContactCard(
                icon: LucideIcons.phone,
                title: 'დაგვიკავშირდით',
                subtitle: '+(995) 599 123 789',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ზარი: +995 599 123 789')),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _openFaq(BuildContext context, String topic) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => FaqDetailsScreen(topic: topic)),
    );
  }
}

class _FaqTopicCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FaqTopicCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 26, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTypography.titleMedium.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTypography.caption.copyWith(
                fontSize: 11,
                color: AppColors.textSecondary,
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

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ContactCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surfaceInput,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 22, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleMedium.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              LucideIcons.chevronRight,
              size: 20,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
