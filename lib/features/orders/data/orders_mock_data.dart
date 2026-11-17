import '../domain/models/farmer_order_model.dart';

/// Test and mock sample orders for testing and fallback
abstract final class OrdersMockData {
  static List<FarmerOrder> get testOrders {
    final now = DateTime.now();
    return [
      FarmerOrder(
        id: '12345',
        createdAt: now.subtract(const Duration(hours: 4)),
        status: OrderStatus.completed,
        customerName: 'შპს "გემრიელი რესტორანი"',
        contactPerson: 'საბა ევგენიძე',
        contactPhone: '+995 599 12 34 56',
        hasVat: true,
        deliveryTimeWindow: 'ივლ 29, 10:00 - 13:00',
        deliveryAddress: '32 ჭავჭავაძე, ბათუმი',
        trackingNumber: 'AK-12345',
        items: const [
          FarmerOrderItem(
            name: 'ორგანული პომიდორი',
            quantityText: '5კგ',
            price: 10.00,
          ),
          FarmerOrderItem(
            name: 'ახალი კარტოფილი',
            quantityText: '15კგ',
            price: 15.00,
          ),
          FarmerOrderItem(
            name: 'მანგო',
            quantityText: '3კგ',
            price: 25.00,
          ),
        ],
      ),
      FarmerOrder(
        id: '12346',
        createdAt: now.subtract(const Duration(minutes: 5)),
        status: OrderStatus.inProgress,
        customerName: 'შპს "მწვანე ბაღი"',
        contactPerson: 'გიორგი მაისურაძე',
        contactPhone: '+995 577 44 55 66',
        hasVat: false,
        deliveryTimeWindow: 'დღეს, 16:00 - 18:00',
        deliveryAddress: 'რუსთაველის გამზ. 14, თბილისი',
        cancellationDeadline: now.add(const Duration(minutes: 24, seconds: 59)),
        trackingNumber: 'AK-12346',
        items: const [
          FarmerOrderItem(
            name: 'ლობიო (წითელი)',
            quantityText: '10კგ',
            price: 45.00,
          ),
          FarmerOrderItem(
            name: 'მწვანილი (ასორტი)',
            quantityText: '2კგ',
            price: 12.00,
          ),
        ],
      ),
      FarmerOrder(
        id: '12347',
        createdAt: now.subtract(const Duration(hours: 1, minutes: 15)),
        status: OrderStatus.inProgress,
        customerName: 'შპს "გემრიელი რესტორანი"',
        contactPerson: 'საბა ევგენიძე',
        contactPhone: '+995 599 12 34 56',
        hasVat: true,
        deliveryTimeWindow: 'ხვალ, 11:00 - 14:00',
        deliveryAddress: 'ჭავჭავაძის გამზ. 32, ბათუმი',
        cancellationDeadline: now.subtract(const Duration(minutes: 45)),
        trackingNumber: 'AK-12347',
        items: const [
          FarmerOrderItem(
            name: 'ორგანული პომიდორი',
            quantityText: '5კგ',
            price: 10.00,
          ),
          FarmerOrderItem(
            name: 'ახალი კარტოფილი',
            quantityText: '15კგ',
            price: 15.00,
          ),
          FarmerOrderItem(
            name: 'მანგო',
            quantityText: '3კგ',
            price: 25.00,
          ),
        ],
      ),
      FarmerOrder(
        id: '12348',
        createdAt: now.subtract(const Duration(days: 1)),
        status: OrderStatus.cancelled,
        customerName: 'შპს "გემრიელი რესტორანი"',
        contactPerson: 'საბა ევგენიძე',
        contactPhone: '+995 599 12 34 56',
        cancellationReason: 'მარაგის არ არსებობის გამო',
        hasVat: true,
        trackingNumber: 'AK-12348',
        items: const [
          FarmerOrderItem(
            name: 'ახალი კარტოფილი',
            quantityText: '40კგ',
            price: 40.00,
          ),
        ],
      ),
      FarmerOrder(
        id: '12349',
        createdAt: now.subtract(const Duration(minutes: 2)),
        status: OrderStatus.pending,
        customerName: 'შპს "ორგანული ბაზარი"',
        contactPerson: 'ნინო დავითაშვილი',
        contactPhone: '+995 591 99 88 77',
        hasVat: false,
        deliveryTimeWindow: 'დღეს, 18:00 - 20:00',
        deliveryAddress: 'ვაჟა-ფშაველას გამზ. 45, თბილისი',
        cancellationDeadline: now.add(const Duration(minutes: 28)),
        trackingNumber: 'AK-12349',
        items: const [
          FarmerOrderItem(
            name: 'ნატურალური მაისის თაფლი',
            quantityText: '3 ქილა (3კგ)',
            price: 75.00,
          ),
        ],
      ),
    ];
  }
}

