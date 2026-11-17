import '../../../marketplace/data/models/farmer_model.dart';
import '../../../marketplace/presentation/providers/marketplace_provider.dart';

/// Business logic service for checkout operations, delivery slots,
/// farmer resolution, and regional coverage calculations.
class CheckoutService {
  const CheckoutService._();

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
      rating: 5.0,
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

  /// Calculates available delivery time slots based on the farmer's delivery schedule.
  static List<String> generateDeliverySlots(FarmerModel farmer) {
    if (!farmer.isDeliveryEnabled) {
      return ['თვითგატანა მეურნეობიდან (${farmer.deliveryCity})'];
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

    const monthNames = [
      '',
      'იანვარი',
      'თებერვალი',
      'მარტი',
      'აპრილი',
      'მაისი',
      'ივნისი',
      'ივლისი',
      'აგვისტო',
      'სექტემბერი',
      'ოქტომბერი',
      'ნოემბერი',
      'დეკემბერი',
    ];

    final now = DateTime.now();
    final matchingDates = <DateTime>[];

    for (int i = 1; i <= 14; i++) {
      final date = now.add(Duration(days: i));
      final weekdayName = geoWeekdayMap[date.weekday];
      if (rawDays.contains(weekdayName)) {
        matchingDates.add(date);
        if (matchingDates.length >= 2) break;
      }
    }

    if (matchingDates.isEmpty) {
      return [
        '${rawDays.first}, 10:00 - 13:00',
        '${rawDays.first}, 14:00 - 18:00',
      ];
    }

    final slots = <String>[];
    for (final d in matchingDates) {
      final weekdayName = geoWeekdayMap[d.weekday] ?? '';
      final monthName = monthNames[d.month];
      slots.add('$weekdayName, ${d.day} $monthName, 10:00-13:00');
      slots.add('$weekdayName, ${d.day} $monthName, 14:00-18:00');
    }

    return slots;
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
