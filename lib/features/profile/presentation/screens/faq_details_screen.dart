import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Support FAQ Details Screen matching Screenshots 9 & 10:
/// - Title "საფორთი"
/// - Subheaders: "რით შემიძლია დაგეხმაროთ?", "ჩვეულებრივი მომხმარებლისთვის"
/// - Expandable Accordion cards for AgroKera FAQ
class FaqDetailsScreen extends StatefulWidget {
  final String topic;

  const FaqDetailsScreen({super.key, this.topic = 'ზოგადი'});

  @override
  State<FaqDetailsScreen> createState() => _FaqDetailsScreenState();
}

class _FaqDetailsScreenState extends State<FaqDetailsScreen> {
  final List<bool> _isExpanded = [true, true, false];

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
          'საფორთი',
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
              Text(
                'რით შემიძლია დაგეხმაროთ?',
                style: AppTypography.h1.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'ჩვეულებრივი მომხმარებლისთვის',
                style: AppTypography.titleMedium.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              // Item 1: რა არის აგროკერა
              _FaqAccordionCard(
                title: 'რა არის აგროკერა',
                content:
                    'აგროკერა არის პროფესიონალური b2b პლატფორმა, რომელიც საქართველოს რესტორნებს, სასტუმროებსა და კაფეებს (horeca სექტორს) პირდაპირ აკავშირებს სანდო ქართველ ფერმერებთან. ჩვენი მიზანია, გავამარტივოთ, გავაიაფოთ და უფრო გამჭვირვალე გავხადოთ თქვენი ბიზნესის მომარაგების პროცესი.',
                isExpanded: _isExpanded[0],
                onTap: () {
                  setState(() => _isExpanded[0] = !_isExpanded[0]);
                },
              ),
              const SizedBox(height: 14),

              // Item 2: როგორ განვათავსო შეკვეთა?
              _FaqAccordionCard(
                title: 'როგორ განვათავსო შეკვეთა?',
                content:
                    '1. გაიარეთ რეგისტრაცია, როგორც "ბიზნეს-მომხმარებელმა".\n'
                    '2. იპოვეთ სასურველი ფერმერები და დაამატეთ მათი პროდუქტები კალათაში. შეგიძლიათ, ერთ კალათაში რამდენიმე სხვადასხვა ფერმერის პროდუქცია მოათავსოთ.\n'
                    '3. კალათის გვერდზე თქვენი შეკვეთა ავტომატურად დაიყოფა ფერმერების მიხედვით.\n'
                    '4. დააჭირეთ "შეკვეთის გაგზავნას". ამის შემდეგ, თითოეული ფერმერი მიიღებს მისთვის განკუთვნილ, დამოუკიდებელ შეკვეთას.',
                isExpanded: _isExpanded[1],
                onTap: () {
                  setState(() => _isExpanded[1] = !_isExpanded[1]);
                },
              ),
              const SizedBox(height: 14),

              // Item 3: როგორ ხდება ანგარიშსწორება?
              _FaqAccordionCard(
                title: 'როგორ ხდება ანგარიშსწორება?',
                content:
                    'ანგარიშსწორება ხდება უშუალოდ თქვენსა და ფერმერს შორის, პლატფორმის გარეთ. შეკვეთის დადასტურების შემდეგ, თქვენ უკავშირდებით ფერმერს მითითებულ საბანკო ანგარიშზე თანხის ჩასარიცხად ან ნაღდი ანგარიშსწორებით მიღებისას.',
                isExpanded: _isExpanded[2],
                onTap: () {
                  setState(() => _isExpanded[2] = !_isExpanded[2]);
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqAccordionCard extends StatelessWidget {
  final String title;
  final String content;
  final bool isExpanded;
  final VoidCallback onTap;

  const _FaqAccordionCard({
    required this.title,
    required this.content,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTypography.titleMedium.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? LucideIcons.chevronUp
                        : LucideIcons.chevronDown,
                    size: 20,
                    color: AppColors.textPrimary,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                content,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: 0.85),
                  height: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
