import '../domain/models/farmer_order_model.dart';

/// Test and mock sample orders for testing and fallback
abstract final class OrdersMockData {
  static const _sampleFarmerAvatar =
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&auto=format&fit=crop&q=80';
  static const _sampleCustomerAvatar =
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&auto=format&fit=crop&q=80';

  static List<FarmerOrder> get testOrders {
    final now = DateTime.now();
    return [
      FarmerOrder(
        id: '12345',
        farmerId: 'farmer_1',
        farmerName: 'გიორგის ფერმა',
        farmerAvatarUrl: _sampleFarmerAvatar,
        customerAvatarUrl: _sampleCustomerAvatar,
        createdAt: now.subtract(const Duration(hours: 4)),
        status: OrderStatus.completed,
        customerName: 'შპს "გემრიელი რესტორანი"',
        contactPerson: 'საბა ევგენიძე',
        contactPhone: '+995 599 12 34 56',
        hasVat: false,
        deliveryTimeWindow: 'ივლ 29, 10:00 - 13:00',
        deliveryAddress: '32 ჭავჭავაძე, ბათუმი',
        trackingNumber: 'AK-12345',
        items: const [
          FarmerOrderItem(
            name: 'ორგანული პომიდორი',
            quantityText: '5კგ',
            price: 10.00,
            imageUrl:
                'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?w=400&auto=format&fit=crop&q=80',
          ),
          FarmerOrderItem(
            name: 'ახალი კარტოფილი',
            quantityText: '15კგ',
            price: 15.00,
            imageUrl:
                'https://images.unsplash.com/photo-1518977676601-b53f82aba655?w=400&auto=format&fit=crop&q=80',
          ),
          FarmerOrderItem(
            name: 'მანგო',
            quantityText: '3კგ',
            price: 25.00,
            imageUrl:
                'https://images.unsplash.com/photo-1553279768-865429fa0078?w=400&auto=format&fit=crop&q=80',
          ),
        ],
      ),
      FarmerOrder(
        id: '12346',
        farmerId: 'farmer_1',
        farmerName: 'გიორგის ფერმა',
        farmerAvatarUrl: _sampleFarmerAvatar,
        customerAvatarUrl: _sampleCustomerAvatar,
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
            imageUrl:
                'https://images.unsplash.com/photo-1551462147-ff29053bfc14?w=400&auto=format&fit=crop&q=80',
          ),
          FarmerOrderItem(
            name: 'მწვანილი (ასორტი)',
            quantityText: '2კგ',
            price: 12.00,
            imageUrl:
                'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=400&auto=format&fit=crop&q=80',
          ),
        ],
      ),
      FarmerOrder(
        id: '12347',
        farmerId: 'farmer_1',
        farmerName: 'გიორგის ფერმა',
        farmerAvatarUrl: _sampleFarmerAvatar,
        customerAvatarUrl: _sampleCustomerAvatar,
        createdAt: now.subtract(const Duration(hours: 1, minutes: 15)),
        status: OrderStatus.inProgress,
        customerName: 'შპს "გემრიელი რესტორანი"',
        contactPerson: 'საბა ევგენიძე',
        contactPhone: '+995 599 12 34 56',
        hasVat: false,
        deliveryTimeWindow: 'ხვალ, 11:00 - 14:00',
        deliveryAddress: 'ჭავჭავაძის გამზ. 32, ბათუმი',
        cancellationDeadline: now.subtract(const Duration(minutes: 45)),
        trackingNumber: 'AK-12347',
        items: const [
          FarmerOrderItem(
            name: 'ორგანული პომიდორი',
            quantityText: '5კგ',
            price: 10.00,
            imageUrl:
                'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?w=400&auto=format&fit=crop&q=80',
          ),
          FarmerOrderItem(
            name: 'ახალი კარტოფილი',
            quantityText: '15კგ',
            price: 15.00,
            imageUrl:
                'https://images.unsplash.com/photo-1518977676601-b53f82aba655?w=400&auto=format&fit=crop&q=80',
          ),
          FarmerOrderItem(
            name: 'მანგო',
            quantityText: '3კგ',
            price: 25.00,
            imageUrl:
                'https://images.unsplash.com/photo-1553279768-865429fa0078?w=400&auto=format&fit=crop&q=80',
          ),
        ],
      ),
      FarmerOrder(
        id: '12348',
        farmerId: 'farmer_1',
        farmerName: 'გიორგის ფერმა',
        farmerAvatarUrl: _sampleFarmerAvatar,
        customerAvatarUrl: _sampleCustomerAvatar,
        createdAt: now.subtract(const Duration(days: 1)),
        status: OrderStatus.cancelled,
        customerName: 'შპს "გემრიელი რესტორანი"',
        contactPerson: 'საბა ევგენიძე',
        contactPhone: '+995 599 12 34 56',
        cancellationReason: 'მარაგის არ არსებობის გამო',
        hasVat: false,
        trackingNumber: 'AK-12348',
        items: const [
          FarmerOrderItem(
            name: 'ახალი კარტოფილი',
            quantityText: '40კგ',
            price: 40.00,
            imageUrl:
                'https://images.unsplash.com/photo-1518977676601-b53f82aba655?w=400&auto=format&fit=crop&q=80',
          ),
        ],
      ),
      FarmerOrder(
        id: '12349',
        farmerId: 'farmer_1',
        farmerName: 'გიორგის ფერმა',
        farmerAvatarUrl: _sampleFarmerAvatar,
        customerAvatarUrl: _sampleCustomerAvatar,
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
            imageUrl:
                'https://images.unsplash.com/photo-1587049352846-4a222e784d38?w=400&auto=format&fit=crop&q=80',
          ),
        ],
      ),
    ];
  }
}

