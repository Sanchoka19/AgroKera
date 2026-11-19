import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agrokera/features/marketplace/data/models/farmer_model.dart';
import 'package:agrokera/features/orders/domain/models/farmer_order_model.dart';
import 'package:agrokera/features/reviews/domain/models/order_review_model.dart';
import 'package:agrokera/features/reviews/presentation/widgets/order_review_prompt_card.dart';
import 'package:agrokera/features/reviews/presentation/widgets/review_quick_tags_selector.dart';
import 'package:agrokera/features/reviews/presentation/widgets/star_rating_selector.dart';
import 'package:agrokera/features/reviews/presentation/widgets/farmer_reviews_section.dart';

void main() {
  group('OrderReviewModel serialization', () {
    test('serializes and deserializes cleanly', () {
      final now = DateTime(2026, 11, 19, 12, 0);
      final review = OrderReviewModel(
        id: 'rev_1',
        orderId: 'ord_1',
        clientId: 'usr_client',
        clientName: 'გიორგი ბ.',
        clientAvatarUrl: 'https://example.com/avatar.jpg',
        farmerId: 'farmer_1',
        rating: 5,
        tags: const ['ახალი და ნატურალური', 'სწრაფი მიტანა'],
        comment: 'ძალიან კმაყოფილი ვარ, მადლობა!',
        createdAt: now,
      );

      final json = review.toJson();
      expect(json['id'], 'rev_1');
      expect(json['orderId'], 'ord_1');
      expect(json['rating'], 5);
      expect(json['tags'], ['ახალი და ნატურალური', 'სწრაფი მიტანა']);
      expect(json['comment'], 'ძალიან კმაყოფილი ვარ, მადლობა!');

      final parsed = OrderReviewModel.fromJson(json);
      expect(parsed.id, review.id);
      expect(parsed.orderId, review.orderId);
      expect(parsed.clientName, review.clientName);
      expect(parsed.rating, 5);
      expect(parsed.tags.length, 2);
      expect(parsed.comment, review.comment);
    });
  });

  group('StarRatingSelector widget', () {
    testWidgets('renders 5 stars and changes label on selection', (tester) async {
      int selectedRating = 3;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return StarRatingSelector(
                  rating: selectedRating,
                  onRatingChanged: (val) {
                    setState(() => selectedRating = val);
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('საშუალო'), findsOneWidget);

      // Tap 5th star
      final stars = find.byType(GestureDetector);
      expect(stars, findsNWidgets(5));

      await tester.tap(stars.last);
      await tester.pumpAndSettle();

      expect(selectedRating, 5);
      expect(find.text('შესანიშნავი'), findsOneWidget);
    });
  });

  group('ReviewQuickTagsSelector widget', () {
    testWidgets('allows multi-selection of quick tags', (tester) async {
      List<String> currentTags = [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return ReviewQuickTagsSelector(
                  selectedTags: currentTags,
                  onTagsChanged: (tags) {
                    setState(() => currentTags = tags);
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('ახალი პროდუქცია'), findsOneWidget);
      expect(find.text('დროული მიტანა'), findsOneWidget);

      await tester.tap(find.text('ახალი პროდუქცია'));
      await tester.pumpAndSettle();

      expect(currentTags.contains('ახალი პროდუქცია'), isTrue);

      await tester.tap(find.text('დროული მიტანა'));
      await tester.pumpAndSettle();

      expect(currentTags.contains('ახალი პროდუქცია'), isTrue);
      expect(currentTags.contains('დროული მიტანა'), isTrue);
    });
  });

  group('OrderReviewPromptCard widget', () {
    testWidgets('shows review prompt when order is completed and unreviewed', (tester) async {
      final order = FarmerOrder(
        id: 'ord_100',
        customerName: 'ანა კ.',
        contactPerson: 'ანა კ.',
        contactPhone: '+995 555 111 222',
        createdAt: DateTime.now(),
        farmerId: 'farmer_1',
        farmerName: 'სამეგრელოს ბაღები',
        items: const [],
        status: OrderStatus.completed,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: OrderReviewPromptCard(order: order),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('შეკვეთა ჩაბარებულია!'), findsOneWidget);
      expect(find.text('შეაფასეთ შეკვეთა'), findsOneWidget);
    });
  });

  group('FarmerReviewsSection widget', () {
    testWidgets('displays rating summary and reviews or empty state', (tester) async {
      const farmer = FarmerModel(
        id: 'farmer_1',
        farmerName: 'დავით ბერიძე',
        farmName: 'ბერიძის მეურნეობა',
        location: 'კახეთი, ყვარელი',
        phone: '+995 555 123 456',
        avatarUrl: '',
        coverUrl: '',
        about: 'ნატურალური პროდუქტები',
        rating: 4.8,
        reviewCount: 12,
        totalRatings: 12,
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FarmerReviewsSection(farmer: farmer),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('მომხმარებელთა შეფასებები'), findsOneWidget);
      expect(find.text('4.8'), findsOneWidget);
      expect(find.text('12 შეფასება'), findsOneWidget);
    });
  });
}
