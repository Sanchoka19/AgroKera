import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agrokera/core/auth/auth_models.dart';
import 'package:agrokera/features/orders/data/orders_mock_data.dart';
import 'package:agrokera/features/orders/presentation/providers/order_chat_provider.dart';
import 'package:agrokera/features/orders/presentation/screens/order_chat_screen.dart';
import 'package:agrokera/features/orders/presentation/screens/order_chats_list_screen.dart';
import 'package:agrokera/features/orders/presentation/widgets/order_chat/order_chat_card_tile.dart';
import 'package:agrokera/features/profile/presentation/widgets/profile_image_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Order Chat Avatars Tests', () {
    final sampleOrder = OrdersMockData.testOrders.first.copyWith(
      farmerAvatarUrl: 'https://example.com/farmer_avatar.jpg',
      customerAvatarUrl: 'https://example.com/customer_avatar.jpg',
    );

    testWidgets('OrderChatCardTile renders avatar image in outer chat list',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OrderChatCardTile(
              order: sampleOrder,
              isFarmer: false, // Viewing as Customer -> should see Farmer avatar
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify ProfileImageView is present in the tile
      expect(find.byType(ProfileImageView), findsOneWidget);
    });

    testWidgets(
        'OrderChatScreen renders partner avatar in AppBar and beside incoming messages',
        (tester) async {
      final container = ProviderContainer();

      // Pre-seed a counterparty message
      container.read(orderChatProvider.notifier).loadMessages(sampleOrder.id);
      await container.read(orderChatProvider.notifier).sendMessage(
            orderId: sampleOrder.id,
            text: 'გამარჯობა, შეკვეთა მზად არის!',
            senderId: 'farmer_partner',
            senderRole: UserRole.farmer,
            senderName: 'გიორგის ფერმა',
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: OrderChatScreen(order: sampleOrder),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Top right AppBar has ProfileImageView
      final profileImageViews = find.byType(ProfileImageView);
      expect(profileImageViews, findsAtLeastNWidgets(2),
          reason:
              'AppBar and incoming message bubble should both render the partner avatar');

      container.dispose();
    });

    testWidgets('OrderChatsListScreen renders tiles with avatars',
        (tester) async {
      final container = ProviderContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: OrderChatsListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OrderChatCardTile), findsWidgets);
      expect(find.byType(ProfileImageView), findsWidgets);

      container.dispose();
    });
  });
}
