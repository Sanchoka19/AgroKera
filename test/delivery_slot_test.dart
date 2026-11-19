import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agrokera/core/widgets/app_filter_tab.dart';
import 'package:agrokera/features/cart_checkout/domain/models/delivery_schedule_model.dart';
import 'package:agrokera/features/cart_checkout/domain/services/checkout_service.dart';
import 'package:agrokera/features/cart_checkout/presentation/widgets/checkout/delivery_slot_bottom_sheet.dart';
import 'package:agrokera/features/marketplace/data/models/farmer_model.dart';

FarmerModel createTestFarmer({
  String id = 'farmer_test',
  List<String> deliveryDays = const ['შაბათი', 'ოთხშაბათი'],
  bool isDeliveryEnabled = true,
  String deliveryCity = 'თბილისი',
}) {
  return FarmerModel(
    id: id,
    farmName: 'სატესტო ფერმა',
    farmerName: 'სატესტო ფერმერი',
    location: 'კახეთი',
    rating: 5.0,
    reviewCount: 10,
    avatarUrl: '',
    coverUrl: '',
    about: '',
    deliveryDays: deliveryDays,
    isDeliveryEnabled: isDeliveryEnabled,
    deliveryCity: deliveryCity,
  );
}

void main() {
  group('CheckoutService Delivery Schedules Unit Tests', () {
    test('generateDeliverySchedules returns structured schedules for farmer days', () {
      final farmer = createTestFarmer();

      final schedules = CheckoutService.generateDeliverySchedules(farmer);
      expect(schedules, isNotEmpty);
      expect(schedules.length, inInclusiveRange(1, 4));

      for (final s in schedules) {
        expect(['შაბათი', 'ოთხშაბათი'], contains(s.weekdayName));
        expect(s.timeSlots, contains('10:00 - 13:00'));
        expect(s.timeSlots, contains('14:00 - 18:00'));
        expect(s.tabLabel, contains(s.weekdayName));
      }
    });

    test('generateDeliverySchedules handles disabled delivery as pickup schedule', () {
      final farmer = createTestFarmer(
        id: 'farmer_pickup',
        isDeliveryEnabled: false,
        deliveryCity: 'თელავი',
      );

      final schedules = CheckoutService.generateDeliverySchedules(farmer);
      expect(schedules.length, 1);
      expect(schedules.first.weekdayName, 'თვითგატანა');
      expect(schedules.first.dayMonthFormatted, 'თელავი');
    });
  });

  group('DeliverySlotBottomSheet Widget Tests', () {
    testWidgets('renders compact 2-tiered selector with universal AppFilterTabs', (
      WidgetTester tester,
    ) async {
      final now = DateTime.now();
      final schedules = [
        DeliveryDateSchedule(
          date: now.add(const Duration(days: 1)),
          weekdayName: 'შაბათი',
          dayMonthFormatted: '22 ნოემ',
          timeSlots: const ['10:00 - 13:00', '14:00 - 18:00'],
        ),
        DeliveryDateSchedule(
          date: now.add(const Duration(days: 5)),
          weekdayName: 'ოთხშაბათი',
          dayMonthFormatted: '26 ნოემ',
          timeSlots: const ['10:00 - 13:00', '14:00 - 18:00'],
        ),
      ];

      final farmer = createTestFarmer();

      String? selectedResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  DeliverySlotBottomSheet.show(
                    context: context,
                    farmer: farmer,
                    schedules: schedules,
                    activeSlot: 'შაბათი, 22 ნოემ, 10:00 - 13:00',
                    onSlotSelected: (val) => selectedResult = val,
                  );
                },
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Verify title and headers
      expect(find.text('მიტანის დროის არჩევა'), findsOneWidget);
      expect(find.text('მიტანის თარიღი'), findsOneWidget);
      expect(find.text('საათობრივი შუალედი'), findsOneWidget);

      // Verify universal AppFilterTab widgets are used for dates and times
      final filterTabs = find.byType(AppFilterTab);
      expect(filterTabs, findsWidgets);

      // Verify initial selected date & time
      expect(find.text('შაბათი, 22 ნოემ'), findsOneWidget);
      expect(find.text('ოთხშაბათი, 26 ნოემ'), findsOneWidget);
      expect(find.text('10:00 - 13:00'), findsOneWidget);
      expect(find.text('14:00 - 18:00'), findsOneWidget);

      // Select Wednesday
      await tester.tap(find.text('ოთხშაბათი, 26 ნოემ'));
      await tester.pumpAndSettle();

      // Select second time slot
      await tester.tap(find.text('14:00 - 18:00'));
      await tester.pumpAndSettle();

      // Tap confirm button
      final confirmBtn = find.textContaining('დადასტურება • ოთხშაბათი, 14:00 - 18:00');
      expect(confirmBtn, findsOneWidget);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Bottom sheet should be closed and callback delivered
      expect(find.text('მიტანის დროის არჩევა'), findsNothing);
      expect(selectedResult, 'ოთხშაბათი, 26 ნოემ, 14:00 - 18:00');
    });
  });
}
