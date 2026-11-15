import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_state_provider.dart';
import '../../../../core/network/api_client.dart';
import '../../../cart_checkout/data/models/cart_item_model.dart';
import '../../../marketplace/presentation/providers/marketplace_provider.dart';
import '../../domain/models/farmer_order_model.dart';

/// State of the farmer & client orders screen
class FarmerOrdersState {
  final List<FarmerOrder> orders;
  final OrderStatus? selectedFilter; // null = 'ყველა'

  const FarmerOrdersState({
    required this.orders,
    this.selectedFilter,
  });

  /// Filtered list based on active tab
  List<FarmerOrder> get filteredOrders {
    if (selectedFilter == null) return orders;
    return orders.where((o) => o.status == selectedFilter).toList();
  }

  /// Counts for filter badges
  int countForStatus(OrderStatus? status) {
    if (status == null) return orders.length;
    return orders.where((o) => o.status == status).length;
  }

  FarmerOrdersState copyWith({
    List<FarmerOrder>? orders,
    OrderStatus? Function()? selectedFilter,
  }) {
    return FarmerOrdersState(
      orders: orders ?? this.orders,
      selectedFilter:
          selectedFilter != null ? selectedFilter() : this.selectedFilter,
    );
  }
}

/// Notifier managing farmer & client orders lifecycle with Neon Backend sync
class FarmerOrdersNotifier extends Notifier<FarmerOrdersState> {
  @override
  FarmerOrdersState build() {
    final now = DateTime.now();

    final sampleOrders = [
      // 1. დასრულებული შეკვეთა (Completed)
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

      // 2. მიმდინარე შეკვეთა აქტიური ტაიმერით (In Progress with direct cancel timer)
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

      // 3. მიმდინარე შეკვეთა გასული ტაიმერით (In Progress with expired timer -> Request cancellation)
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

      // 4. გაუქმებული შეკვეთა (Cancelled with reason)
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

      // 5. მომლოდინე ახალი შეკვეთა (Pending / New)
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

    ref.listen(authStateProvider, (prev, next) {
      if (prev?.userId != next.userId ||
          prev?.farmerId != next.farmerId ||
          prev?.role != next.role) {
        unawaited(refreshFromBackend());
      }
    });
    unawaited(Future.microtask(refreshFromBackend));
    return FarmerOrdersState(orders: sampleOrders);
  }

  /// Fetches live orders from Neon PostgreSQL backend with strict Farmer/Customer isolation
  Future<void> refreshFromBackend() async {
    try {
      final auth = ref.read(authStateProvider);
      final api = ref.read(apiClientProvider);

      final queryParams = <String, dynamic>{};
      if (auth.isAuthenticated) {
        if (auth.role == UserRole.farmer && auth.farmerId != null) {
          queryParams['farmerId'] = auth.farmerId;
        } else if (auth.role == UserRole.customer && auth.userId != null) {
          queryParams['clientId'] = auth.userId;
        }
      }

      final response = await api.get<List<dynamic>>(
        '/api/orders',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      final rawOrders = response.data;
      if (rawOrders != null) {
        final fetched = rawOrders
            .whereType<Map<String, dynamic>>()
            .map(FarmerOrder.fromJson)
            .toList();

        final fetchedIds = fetched.map((o) => o.id).toSet();
        final localPending = state.orders
            .where((o) => !fetchedIds.contains(o.id))
            .toList();
        state = state.copyWith(orders: [...localPending, ...fetched]);
        checkAutoConfirmation();
      }
    } catch (_) {
      // Gracefully keep local state when offline or in widget tests
    }
  }

  void setFilter(OrderStatus? filter) {
    state = state.copyWith(selectedFilter: () => filter);
  }

  void acceptOrder(String id) {
    final now = DateTime.now();
    state = state.copyWith(
      orders: state.orders.map((o) {
        if (o.id == id) {
          return o.copyWith(
            status: OrderStatus.inProgress,
            cancellationDeadline: now.add(const Duration(minutes: 30)),
          );
        }
        return o;
      }).toList(),
    );

    unawaited(_syncOrderStatus(id, status: OrderStatus.inProgress));
  }

  void completeOrder(String id) {
    state = state.copyWith(
      orders: state.orders.map((o) {
        if (o.id == id) {
          return o.copyWith(status: OrderStatus.completed);
        }
        return o;
      }).toList(),
    );

    unawaited(_syncOrderStatus(id, status: OrderStatus.completed));
  }

  void cancelOrder(String id, {String reason = 'მარაგის არ არსებობის გამო'}) {
    state = state.copyWith(
      orders: state.orders.map((o) {
        if (o.id == id) {
          return o.copyWith(
            status: OrderStatus.cancelled,
            cancellationReason: reason,
          );
        }
        return o;
      }).toList(),
    );

    unawaited(
      _syncOrderStatus(id, status: OrderStatus.cancelled, reason: reason),
    );
  }

  /// Places a new order from the Cart & Checkout screen and syncs with Neon DB
  Future<FarmerOrder> createOrderFromCart({
    required List<CartItemModel> cartItems,
    required String deliveryAddress,
    required String deliveryTimeWindow,
    String? customerName,
    String? contactPhone,
    String paymentMethod = 'ESCROW',
  }) async {
    final auth = ref.read(authStateProvider);
    final effectiveName =
        (customerName != null && customerName.trim().isNotEmpty)
            ? customerName.trim()
            : (auth.userName ?? 'საბა ევგენიძე');
    final effectivePhone =
        (contactPhone != null && contactPhone.trim().isNotEmpty)
            ? contactPhone.trim()
            : (auth.userPhone ?? '+995 599 12 34 56');

    final now = DateTime.now();
    final generatedId = '${38100 + Random().nextInt(899)}';

    final orderItems = cartItems
        .map(
          (ci) => FarmerOrderItem(
            name: ci.title,
            quantityText: '${ci.quantity}${ci.unit}',
            price: ci.totalPrice,
          ),
        )
        .toList();

    final newOrder = FarmerOrder(
      id: generatedId,
      clientId: auth.userId ?? 'user_client_1',
      farmerId: 'farmer_2',
      createdAt: now,
      status: OrderStatus.pending,
      customerName: effectiveName,
      contactPerson: effectiveName,
      contactPhone: effectivePhone,
      deliveryAddress: deliveryAddress,
      deliveryTimeWindow: deliveryTimeWindow,
      cancellationDeadline: now.add(const Duration(minutes: 30)),
      trackingNumber: 'AK-$generatedId',
      items: orderItems,
      paymentMethod: paymentMethod,
    );

    state = state.copyWith(orders: [newOrder, ...state.orders]);
    await ref
        .read(marketplaceProvider.notifier)
        .deductStockForCartItems(cartItems);

    unawaited(() async {
      try {
        final api = ref.read(apiClientProvider);
        final response = await api.post<Map<String, dynamic>>(
          '/api/orders',
          data: {
            'clientId': auth.userId ?? 'user_client_1',
            'clientEmail': ?auth.userEmail,
            'contactPerson': effectiveName,
            'contactPhone': effectivePhone,
            'deliveryAddress': deliveryAddress,
            'deliveryTimeWindow': deliveryTimeWindow,
            'paymentMethod': paymentMethod,
            'items': cartItems
                .map(
                  (ci) => {
                    'productId': ci.id,
                    'quantity': ci.quantity,
                    'pricePerUnit': ci.pricePerUnit,
                  },
                )
                .toList(),
          },
        );
        if (response.data != null) {
          final serverOrder = FarmerOrder.fromJson(response.data!);
          state = state.copyWith(
            orders: state.orders
                .map((o) => o.id == generatedId ? serverOrder : o)
                .toList(),
          );
        }
      } catch (_) {
        // Offline resilient fallback
      }
    }());

    return newOrder;
  }

  /// Checks and automatically confirms pending orders whose 30-minute review window has elapsed
  void checkAutoConfirmation() {
    final now = DateTime.now();
    bool hasChanges = false;
    final updated = state.orders.map((o) {
      if (o.status == OrderStatus.pending &&
          o.cancellationDeadline != null &&
          now.isAfter(o.cancellationDeadline!)) {
        hasChanges = true;
        return o.copyWith(status: OrderStatus.inProgress);
      }
      return o;
    }).toList();

    if (hasChanges) {
      state = state.copyWith(orders: updated);
    }
  }

  Future<void> _syncOrderStatus(
    String id, {
    required OrderStatus status,
    String? reason,
  }) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.patch(
        '/api/orders/$id/status',
        data: {
          'status': status.apiValue,
          'cancellationReason': ?reason,
        },
      );
      if (status == OrderStatus.cancelled) {
        await ref.read(marketplaceProvider.notifier).refreshFromBackend();
      }
    } catch (_) {}
  }
}

/// Provider of farmer & client orders
final farmerOrdersProvider =
    NotifierProvider<FarmerOrdersNotifier, FarmerOrdersState>(
  FarmerOrdersNotifier.new,
);
