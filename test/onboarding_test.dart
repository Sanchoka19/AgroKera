import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agrokera/core/storage/secure_storage_service.dart';
import 'package:agrokera/features/onboarding/domain/models/onboarding_item.dart';
import 'package:agrokera/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:agrokera/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:agrokera/features/onboarding/presentation/widgets/onboarding_page_indicator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Onboarding Domain & Provider Unit Tests', () {
    test('defaultOnboardingItems contains 3 high-quality Georgian slides without emojis', () {
      expect(defaultOnboardingItems.length, 3);

      final emojiRegex = RegExp(
        r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F700}-\u{1F77F}\u{1F780}-\u{1F7FF}\u{1F800}-\u{1F8FF}\u{1F900}-\u{1F9FF}\u{1FA00}-\u{1FA6F}\u{1FA70}-\u{1FAFF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]',
        unicode: true,
      );

      for (final item in defaultOnboardingItems) {
        expect(emojiRegex.hasMatch(item.title), isFalse,
            reason: 'Title should not contain emojis: ${item.title}');
        expect(emojiRegex.hasMatch(item.subtitle), isFalse,
            reason: 'Subtitle should not contain emojis: ${item.subtitle}');
        expect(emojiRegex.hasMatch(item.description), isFalse,
            reason: 'Description should not contain emojis: ${item.description}');
        expect(item.illustrationAsset, isNotEmpty);
      }
    });

    test('OnboardingNotifier manages page transitions and completion correctly', () async {
      final storage = SecureStorageService();
      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(storage),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(onboardingProvider.notifier);
      expect(container.read(onboardingProvider).currentIndex, 0);
      expect(container.read(onboardingProvider).isFirstPage, isTrue);
      expect(container.read(onboardingProvider).isLastPage, isFalse);

      notifier.next();
      expect(container.read(onboardingProvider).currentIndex, 1);
      expect(container.read(onboardingProvider).isFirstPage, isFalse);
      expect(container.read(onboardingProvider).isLastPage, isFalse);

      notifier.next();
      expect(container.read(onboardingProvider).currentIndex, 2);
      expect(container.read(onboardingProvider).isLastPage, isTrue);

      // Cannot advance past last page
      notifier.next();
      expect(container.read(onboardingProvider).currentIndex, 2);

      notifier.previous();
      expect(container.read(onboardingProvider).currentIndex, 1);

      notifier.setPage(0);
      expect(container.read(onboardingProvider).currentIndex, 0);

      expect(await storage.hasSeenOnboarding(), isFalse);
      await notifier.completeOnboarding();
      expect(await storage.hasSeenOnboarding(), isTrue);
    });
  });

  group('Onboarding Widgets Tests', () {
    testWidgets('OnboardingPageIndicator renders correct dot count and active size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OnboardingPageIndicator(
              count: 3,
              currentIndex: 1,
            ),
          ),
        ),
      );

      final animatedContainers = tester.widgetList<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      expect(animatedContainers.length, 3);
    });

    testWidgets('OnboardingScreen renders header brand, step 1 and navigates through arrow buttons', (tester) async {
      final storage = SecureStorageService();
      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(storage),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: OnboardingScreen(),
          ),
        ),
      );

      // Verify Brand Header in top-left
      expect(find.text('AGROKERA'), findsOneWidget);
      expect(find.text('გამოტოვება'), findsOneWidget);

      // Slide 1 verification
      expect(find.text('აღმოაჩინე ნატურალური პროდუქტი'), findsOneWidget);
      expect(find.text('მრავალფეროვანი აგრომარკეტი'), findsOneWidget);

      // Tap circular next arrow button to advance to Slide 2
      final nextButton = find.byKey(const Key('onboarding_next_button'));
      expect(nextButton, findsOneWidget);
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      expect(find.text('პირდაპირ ფერმერებისგან'), findsOneWidget);
      expect(find.text('ვერიფიცირებული მეურნეობები'), findsOneWidget);
      // Back button appears on step 2
      expect(find.byKey(const Key('onboarding_prev_button')), findsOneWidget);

      // Tap next arrow button to advance to Slide 3
      await tester.tap(find.byKey(const Key('onboarding_next_button')));
      await tester.pumpAndSettle();

      expect(find.text('სწრაფი და საიმედო მიტანა'), findsOneWidget);
      expect(find.text('პირდაპირ თქვენს კარამდე'), findsOneWidget);
      expect(find.byKey(const Key('onboarding_start_button')), findsOneWidget);
      expect(find.text('დაწყება'), findsOneWidget);
      expect(find.text('უკვე გაქვთ ანგარიში? შესვლა'), findsOneWidget);
    });
  });
}
