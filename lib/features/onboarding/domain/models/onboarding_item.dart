import '../../../../core/constants/app_assets.dart';

/// Domain model representing a single onboarding slide.
class OnboardingItem {
  final String title;
  final String subtitle;
  final String description;
  final String illustrationAsset;

  const OnboardingItem({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.illustrationAsset,
  });
}

/// Default onboarding slides showcasing AgroKera's core value propositions.
const List<OnboardingItem> defaultOnboardingItems = [
  OnboardingItem(
    title: 'აღმოაჩინე ნატურალური პროდუქტი',
    subtitle: 'მრავალფეროვანი აგრომარკეტი',
    description:
        'შეარჩიე უახლესი ბოსტნეული, ხილი და რძის ნაწარმი პირდაპირ ადგილობრივი ბაზრიდან.',
    illustrationAsset: AppAssets.onboarding1,
  ),
  OnboardingItem(
    title: 'პირდაპირ ფერმერებისგან',
    subtitle: 'ვერიფიცირებული მეურნეობები',
    description:
        'დაუკავშირდი ადგილობრივ ფერმერებს და მიიღე უმაღლესი ხარისხის მოსავალი შუამავლების გარეშე.',
    illustrationAsset: AppAssets.onboarding2,
  ),
  OnboardingItem(
    title: 'სწრაფი და საიმედო მიტანა',
    subtitle: 'პირდაპირ თქვენს კარამდე',
    description:
        'მოქნილი მიტანის სერვისი და შეკვეთის თვალყურის დევნება რეალურ დროში.',
    illustrationAsset: AppAssets.onboarding3,
  ),
];

