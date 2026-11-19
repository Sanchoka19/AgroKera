import '../../../marketplace/data/models/farmer_model.dart';
import '../../../marketplace/presentation/providers/marketplace_provider.dart';
import '../models/delivery_schedule_model.dart';

/// Business logic service for checkout operations, delivery slots,
/// farmer resolution, and regional coverage calculations.
class CheckoutService {
  const CheckoutService._();

  static const List<String> defaultDeliveryTimeSlots = [
    '10:00 - 13:00',
    '14:00 - 18:00',
  ];

  /// Resolves the farmer responsible for the items in the cart.
  static FarmerModel resolveFarmer(
    MarketplaceState marketplace,
    List<dynamic> cartItems,
  ) {
    if (cartItems.isNotEmpty) {
      final firstItem = cartItems.first;
      for (final p in marketplace.products) {
        if (p.id == firstItem.id) {
          for (final f in marketplace.farmers) {
            if (f.id == p.farmerId || f.farmerName == firstItem.farmerName) {
              return f;
            }
          }
        }
      }
      for (final f in marketplace.farmers) {
        if (f.farmerName == firstItem.farmerName) {
          return f;
        }
      }
    }
    if (marketplace.farmers.isNotEmpty) {
      return marketplace.farmers.first;
    }
    return const FarmerModel(
      id: 'default_farmer',
      farmName: 'აგრო ფერმა',
      farmerName: 'ფერმერი',
      location: 'საქართველო',
      rating: 0.0,
      reviewCount: 0,
      totalRatings: 0,
      isVerified: true,
      isVatPayer: false,
      avatarUrl: '',
      coverUrl: '',
      about: '',
      phone: '',
    );
  }

  /// Generates structured delivery date schedules and time slots.
  static List<DeliveryDateSchedule> generateDeliverySchedules(FarmerModel farmer) {
    if (!farmer.isDeliveryEnabled) {
      final now = DateTime.now();
      return [
        DeliveryDateSchedule(
          date: now,
          weekdayName: 'თვითგატანა',
          dayMonthFormatted:
              farmer.deliveryCity.isNotEmpty ? farmer.deliveryCity : 'მეურნეობა',
          timeSlots: const ['10:00 - 18:00'],
        ),
      ];
    }

    final rawDays = farmer.deliveryDays.isNotEmpty
        ? farmer.deliveryDays.map(FarmerModel.normalizeDay).toList()
        : ['შაბათი'];

    const geoWeekdayMap = {
      DateTime.monday: 'ორშაბათი',
      DateTime.tuesday: 'სამშაბათი',
      DateTime.wednesday: 'ოთხშაბათი',
      DateTime.thursday: 'ხუთშაბათი',
      DateTime.friday: 'პარასკევი',
      DateTime.saturday: 'შაბათი',
      DateTime.sunday: 'კვირა',
    };

    const shortMonthNames = [
      '',
      'იან',
      'თებ',
      'მარ',
      'აპრ',
      'მაი',
      'ივნ',
      'ივლ',
      'აგვ',
      'სექ',
      'ოქტ',
      'ნოე',
      'დეკ',
    ];

    final now = DateTime.now();
    final schedules = <DeliveryDateSchedule>[];

    // Scan up to 14 days ahead for matching delivery days (up to 4 upcoming dates)
    for (int i = 1; i <= 14; i++) {
      final date = now.add(Duration(days: i));
      final weekdayName = geoWeekdayMap[date.weekday];
      if (weekdayName != null && rawDays.contains(weekdayName)) {
        final monthName = shortMonthNames[date.month];
        schedules.add(
          DeliveryDateSchedule(
            date: date,
            weekdayName: weekdayName,
            dayMonthFormatted: '${date.day} $monthName',
            timeSlots: defaultDeliveryTimeSlots,
          ),
        );
        if (schedules.length >= 4) break;
      }
    }

    if (schedules.isEmpty) {
      final fallbackDate = now.add(const Duration(days: 1));
      final fallbackWeekday =
          geoWeekdayMap[fallbackDate.weekday] ?? rawDays.first;
      final monthName = shortMonthNames[fallbackDate.month];
      schedules.add(
        DeliveryDateSchedule(
          date: fallbackDate,
          weekdayName: fallbackWeekday,
          dayMonthFormatted: '${fallbackDate.day} $monthName',
          timeSlots: defaultDeliveryTimeSlots,
        ),
      );
    }

    return schedules;
  }

  /// Calculates available delivery time slots based on the farmer's delivery schedule.
  static List<String> generateDeliverySlots(FarmerModel farmer) {
    final schedules = generateDeliverySchedules(farmer);
    final slots = <String>[];
    for (final s in schedules) {
      for (final t in s.timeSlots) {
        slots.add(s.fullSlotString(t));
      }
    }
    return slots.isNotEmpty ? slots : ['შაბათი, 10:00 - 13:00'];
  }

  /// Matches the delivery address with the farmer's registered delivery zones and fees.
  static MapEntry<String, double>? findMatchedDeliveryZone(
    String address,
    FarmerModel farmer,
  ) {
    if (!farmer.isDeliveryEnabled) return null;
    final lowerAddr = address.toLowerCase();

    for (final entry in farmer.regionalDeliveryFees.entries) {
      if (lowerAddr.contains(entry.key.toLowerCase())) {
        return entry;
      }
    }

    if (lowerAddr.contains(farmer.deliveryCity.toLowerCase())) {
      return MapEntry(farmer.deliveryCity, farmer.deliveryFee);
    }

    return null;
  }
}

