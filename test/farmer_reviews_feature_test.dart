import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agrokera/features/notifications/presentation/notification_navigator.dart';
import 'package:agrokera/features/reviews/domain/models/order_review_model.dart';
import 'package:agrokera/features/reviews/presentation/screens/farmer_my_reviews_screen.dart';
import 'package:agrokera/features/reviews/presentation/widgets/farmer_review_item_card.dart';

void main() {
  group('Reviews Feature Tests', () {
    final sampleReview = OrderReviewModel(
      id: 'rev_123',
      orderId: 'ord_987654',
      clientId: 'user_1',
      clientName: 'მარიამ ბერიძე',
      farmerId: 'farmer_1',
      rating: 5,
      tags: ['სუფთა და ნატურალური', 'სწრაფი მიწოდება'],
      comment: 'ძალიან გემრიელი და ხარისხიანი პროდუქცია იყო!',
      createdAt: DateTime(2024, 11, 19),
    );

    test('NotificationNavigator resolves review notifications correctly', () {
      expect(
        NotificationNavigator.resolveTarget(type: 'farmer_review_received'),
        NotificationTarget.review,
      );
      expect(
        NotificationNavigator.resolveTarget(type: 'review_received'),
        NotificationTarget.review,
      );
      expect(
        NotificationNavigator.resolveTarget(title: 'ახალი შეფასება • 5/5'),
        NotificationTarget.review,
      );
    });

    testWidgets('FarmerReviewItemCard renders tags, stars, comments and order badge',
        (tester) async {
      bool orderTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FarmerReviewItemCard(
              review: sampleReview,
              showOrderBadge: true,
              onOrderTap: () => orderTapped = true,
            ),
          ),
        ),
      );

      // Verify client info
      expect(find.text('მარიამ ბერიძე'), findsOneWidget);
      expect(find.text('19.11.2024'), findsOneWidget);

      // Verify tags
      expect(find.text('სუფთა და ნატურალური'), findsOneWidget);
      expect(find.text('სწრაფი მიწოდება'), findsOneWidget);

      // Verify comment
      expect(
        find.text('ძალიან გემრიელი და ხარისხიანი პროდუქცია იყო!'),
        findsOneWidget,
      );

      // Verify order badge and tap
      expect(find.text('#87654'), findsOneWidget);
      await tester.tap(find.text('#87654'));
      expect(orderTapped, isTrue);
    });

    testWidgets('FarmerMyReviewsScreen renders title and hero rating',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FarmerMyReviewsScreen(farmerId: 'farmer_test'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('ჩემი შეფასებები'), findsOneWidget);
      expect(find.text('/ 5.0'), findsOneWidget);
    });
  });
}

