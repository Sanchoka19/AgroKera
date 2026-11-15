import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_state_provider.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../cart_checkout/data/models/cart_item_model.dart';
import '../../../cart_checkout/presentation/providers/cart_provider.dart';
import '../../../marketplace/presentation/providers/marketplace_provider.dart';
import '../../domain/models/farmer_order_model.dart';

/// State of the farmer & client orders screen
class FarmerOrdersState {
  final List<FarmerOrder> orders;
  final List<FarmerOrder> incomingOrders;
  final List<FarmerOrder> clientOrders;
  final OrderStatus? selectedFilter; // null = 'ყველა'

  const FarmerOrdersState({
    required this.orders,
    this.incomingOrders = const [],
    this.clientOrders = const [],
    this.selectedFilter,
  });

  /// Filtered list of incoming orders based on active tab
  List<FarmerOrder> get filteredIncomingOrders {
    if (selectedFilter == null) return incomingOrders;
    return incomingOrders.where((o) => o.status == selectedFilter).toList();
  }

  /// Backward-compatible alias for filtered incoming orders
  List<FarmerOrder> get filteredOrders => filteredIncomingOrders;

  /// Counts for incoming orders filter badges
  int countForIncomingStatus(OrderStatus? status) {
    if (status == null) return incomingOrders.length;
    return incomingOrders.where((o) => o.status == status).length;
  }

  /// Backward-compatible alias for filter badge counts
  int countForStatus(OrderStatus? status) => countForIncomingStatus(status);

  /// Counts for client orders by status
  int countForClientStatus(OrderStatus? status) {
    if (status == null) return clientOrders.length;
    return clientOrders.where((o) => o.status == status).length;
  }

  FarmerOrdersState copyWith({
    List<FarmerOrder>? orders,
    List<FarmerOrder>? incomingOrders,
    List<FarmerOrder>? clientOrders,
    OrderStatus? Function()? selectedFilter,
  }) {
    return FarmerOrdersState(
      orders: orders ?? this.orders,
      incomingOrders: incomingOrders ?? this.incomingOrders,
      clientOrders: clientOrders ?? this.clientOrders,
      selectedFilter:
          selectedFilter != null ? selectedFilter() : this.selectedFilter,
    );
  }
}

/// Notifier managing farmer & client orders lifecycle with Neon Backend sync
class FarmerOrdersNotifier extends Notifier<FarmerOrdersState> {
  final Set<String> _reportedPaymentOrderIds = {};

  @override
  FarmerOrdersState build() {
    unawaited(_loadReportedPayments());
    ref.listen(authStateProvider, (prev, next) {
      if (prev?.userId != next.userId ||
          prev?.farmerId != next.farmerId ||
          prev?.role != next.role) {
        _partitionOrdersForAuth(next);
        unawaited(refreshFromBackend());
      }
    });
    unawaited(Future.microtask(refreshFromBackend));

    final auth = ref.read(authStateProvider);
    final initialList = isFlutterTestEnv ? _testOrders : const <FarmerOrder>[];
    final (initialIncoming, initialClient) =
        _initialPartition(initialList, auth);

    return FarmerOrdersState(
      orders: initialList,
      incomingOrders: initialIncoming,
      clientOrders: initialClient,
    );
  }

  (List<FarmerOrder>, List<FarmerOrder>) _initialPartition(
    List<FarmerOrder> list,
    AuthState auth,
  ) {
    if (auth.role == UserRole.farmer) {
      // In Farmer mode:
      // incomingOrders are orders received by this farm (where this user is the seller)
      final incoming = list.where((o) {
        if (auth.userId != null && o.clientId == auth.userId) return false;
        if (auth.farmerId != null && o.farmerId != null) {
          return o.farmerId == auth.farmerId;
        }
        return true;
      }).toList();

      // clientOrders are purchases made by this farmer from other farmers (where this user is the client)
      final client = list.where((o) {
        if (auth.farmerId != null && o.farmerId == auth.farmerId) return false;
        if (auth.userId != null && o.clientId != null) {
          return o.clientId == auth.userId;
        }
        return false;
      }).toList();

      return (incoming, client);
    } else if (auth.role == UserRole.customer) {
      // Regular customer: no incoming orders; client purchases are in clientOrders
      return (const <FarmerOrder>[], list);
    } else {
      // Guest or Test fallback: both receive sample list for isolated widget testing
      return (list, list);
    }
  }

  void _partitionOrdersForAuth(AuthState auth) {
    final allKnown = <String, FarmerOrder>{};
    for (final o in [
      ...state.orders,
      ...state.incomingOrders,
      ...state.clientOrders,
      if (isFlutterTestEnv) ..._testOrders,
    ]) {
      allKnown[o.id] = o;
    }
    final allList = allKnown.values.toList();
    final (incoming, client) = _initialPartition(allList, auth);

    state = state.copyWith(
      incomingOrders: incoming,
      clientOrders: client,
    );
  }

  Future<void> _loadReportedPayments() async {
    try {
      final storage = ref.read(secureStorageProvider);
      final saved = await storage.readReportedPaymentOrderIds();
      _reportedPaymentOrderIds.addAll(saved);
      if (_reportedPaymentOrderIds.isNotEmpty) {
        FarmerOrder flag(FarmerOrder o) {
          if (_reportedPaymentOrderIds.contains(o.id)) {
            return o.copyWith(hasClientReportedPayment: true);
          }
          return o;
        }

        state = state.copyWith(
          orders: state.orders.map(flag).toList(),
          incomingOrders: state.incomingOrders.map(flag).toList(),
          clientOrders: state.clientOrders.map(flag).toList(),
        );
      }
    } catch (_) {}
  }

  static List<FarmerOrder> get _testOrders {
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

  /// Fetches live orders from Neon PostgreSQL backend with strict Farmer/Customer isolation
  Future<void> refreshFromBackend() async {
    try {
      final auth = ref.read(authStateProvider);
      final api = ref.read(apiClientProvider);

      List<FarmerOrder>? fetchedIncoming;
      List<FarmerOrder>? fetchedClient;

      if (auth.isAuthenticated) {
        // 1. If farmer, fetch incoming orders received by this farm
        if (auth.role == UserRole.farmer && auth.farmerId != null) {
          try {
            final res = await api.get<List<dynamic>>(
              '/api/orders',
              queryParameters: {'farmerId': auth.farmerId},
            );
            if (res.data != null) {
              fetchedIncoming = res.data!
                  .whereType<Map<String, dynamic>>()
                  .map(FarmerOrder.fromJson)
                  .toList();
            }
          } catch (_) {}
        }

        // 2. Fetch personal client purchases placed by this user (farmer or customer)
        if (auth.userId != null) {
          try {
            final res = await api.get<List<dynamic>>(
              '/api/orders',
              queryParameters: {'clientId': auth.userId},
            );
            if (res.data != null) {
              fetchedClient = res.data!
                  .whereType<Map<String, dynamic>>()
                  .map(FarmerOrder.fromJson)
                  .toList();
            }
          } catch (_) {}
        }
      }

      var newIncoming = state.incomingOrders;
      var newClient = state.clientOrders;

      if (fetchedIncoming != null) {
        final fetchedIds = fetchedIncoming.map((o) => o.id).toSet();
        final localPending = state.incomingOrders
            .where((o) => !fetchedIds.contains(o.id))
            .toList();
        newIncoming = [...localPending, ...fetchedIncoming].map((o) {
          if (_reportedPaymentOrderIds.contains(o.id) ||
              o.hasClientReportedPayment) {
            return o.copyWith(hasClientReportedPayment: true);
          }
          return o;
        }).toList();
      }

      if (fetchedClient != null) {
        final fetchedIds = fetchedClient.map((o) => o.id).toSet();
        final localPending = state.clientOrders
            .where((o) => !fetchedIds.contains(o.id))
            .toList();
        newClient = [...localPending, ...fetchedClient].map((o) {
          if (_reportedPaymentOrderIds.contains(o.id) ||
              o.hasClientReportedPayment) {
            return o.copyWith(hasClientReportedPayment: true);
          }
          return o;
        }).toList();
      }

      final seenIds = <String>{};
      final combinedOrders = <FarmerOrder>[];
      for (final o in [...newClient, ...newIncoming, ...state.orders]) {
        if (seenIds.add(o.id)) {
          combinedOrders.add(o);
        }
      }

      state = state.copyWith(
        incomingOrders: newIncoming,
        clientOrders: newClient,
        orders: combinedOrders,
      );
      checkPendingOrderExpirations();
    } catch (_) {
      // Gracefully keep local state when offline or in widget tests
    }
  }

  void setFilter(OrderStatus? filter) {
    state = state.copyWith(selectedFilter: () => filter);
  }

  void acceptOrder(String id) {
    final now = DateTime.now();
    FarmerOrder update(FarmerOrder o) {
      if (o.id == id) {
        return o.copyWith(
          status: OrderStatus.inProgress,
          cancellationDeadline: now.add(const Duration(minutes: 30)),
        );
      }
      return o;
    }

    state = state.copyWith(
      orders: state.orders.map(update).toList(),
      incomingOrders: state.incomingOrders.map(update).toList(),
      clientOrders: state.clientOrders.map(update).toList(),
    );

    unawaited(_syncOrderStatus(id, status: OrderStatus.inProgress));
  }

  /// Called by the customer after completing wire transfer in their mobile bank
  void reportBankTransferSent(String id) {
    _reportedPaymentOrderIds.add(id);
    FarmerOrder update(FarmerOrder o) {
      if (o.id == id) {
        return o.copyWith(hasClientReportedPayment: true);
      }
      return o;
    }

    state = state.copyWith(
      orders: state.orders.map(update).toList(),
      incomingOrders: state.incomingOrders.map(update).toList(),
      clientOrders: state.clientOrders.map(update).toList(),
    );
    unawaited(
      ref
          .read(secureStorageProvider)
          .saveReportedPaymentOrderIds(_reportedPaymentOrderIds),
    );
  }

  /// Called by system / admin / bank webhook when wire transfer is verified in AgroKera Escrow
  void confirmEscrowPayment(String id) {
    FarmerOrder update(FarmerOrder o) {
      if (o.id == id) {
        return o.copyWith(isPaymentConfirmed: true);
      }
      return o;
    }

    state = state.copyWith(
      orders: state.orders.map(update).toList(),
      incomingOrders: state.incomingOrders.map(update).toList(),
      clientOrders: state.clientOrders.map(update).toList(),
    );
  }

  void completeOrder(String id) {
    FarmerOrder update(FarmerOrder o) {
      if (o.id == id) {
        return o.copyWith(status: OrderStatus.completed);
      }
      return o;
    }

    state = state.copyWith(
      orders: state.orders.map(update).toList(),
      incomingOrders: state.incomingOrders.map(update).toList(),
      clientOrders: state.clientOrders.map(update).toList(),
    );

    unawaited(_syncOrderStatus(id, status: OrderStatus.completed));
  }

  void cancelOrder(String id, {String reason = 'მარაგის არ არსებობის გამო'}) {
    final targetOrder = state.orders.where((o) => o.id == id).firstOrNull ??
        state.incomingOrders.where((o) => o.id == id).firstOrNull ??
        state.clientOrders.where((o) => o.id == id).firstOrNull;
    if (targetOrder != null && targetOrder.status != OrderStatus.cancelled) {
      unawaited(
        ref
            .read(marketplaceProvider.notifier)
            .restoreStockForOrderItems(targetOrder.items),
      );
    }

    FarmerOrder update(FarmerOrder o) {
      if (o.id == id) {
        return o.copyWith(
          status: OrderStatus.cancelled,
          cancellationReason: reason,
        );
      }
      return o;
    }

    state = state.copyWith(
      orders: state.orders.map(update).toList(),
      incomingOrders: state.incomingOrders.map(update).toList(),
      clientOrders: state.clientOrders.map(update).toList(),
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
    bool? hasVat,
    double deliveryFee = 0.0,
    double heavyFee = 0.0,
    double platformFee = 0.0,
    bool isPickup = false,
  }) async {
    final auth = ref.read(authStateProvider);
    if (auth.role == UserRole.farmer) {
      final isOwn = cartItems.any((ci) => auth.isOwnerOfCartItem(ci));
      if (isOwn) {
        throw StateError('ფერმერს არ შეუძლია საკუთარი პროდუქციის შეკვეთა');
      }
    }
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
            productId: ci.id,
            name: ci.title,
            quantityText: '${ci.quantity}${ci.unit}',
            price: ci.totalPrice,
            quantity: ci.quantity.toDouble(),
          ),
        )
        .toList();

    final targetFarmerId = (cartItems.isNotEmpty &&
            cartItems.first.farmerId != null &&
            cartItems.first.farmerId!.isNotEmpty)
        ? cartItems.first.farmerId!
        : 'farmer_2';

    final resolvedHasVat = hasVat ??
        () {
          final marketplace = ref.read(marketplaceProvider);
          final matchedFarmer = marketplace.farmers.where((f) =>
              (cartItems.isNotEmpty &&
                  cartItems.first.farmerId != null &&
                  f.id == cartItems.first.farmerId) ||
              (cartItems.isNotEmpty &&
                  (f.farmerName == cartItems.first.farmerName ||
                      f.farmName == cartItems.first.farmerName))).firstOrNull;
          return matchedFarmer?.isVatPayer ?? false;
        }();

    final newOrder = FarmerOrder(
      id: generatedId,
      clientId: auth.userId ?? 'user_client_1',
      farmerId: targetFarmerId,
      createdAt: now,
      status: OrderStatus.pending,
      customerName: effectiveName,
      contactPerson: effectiveName,
      contactPhone: effectivePhone,
      hasVat: resolvedHasVat,
      deliveryAddress: deliveryAddress,
      deliveryTimeWindow: deliveryTimeWindow,
      cancellationDeadline: now.add(const Duration(minutes: 30)),
      trackingNumber: 'AK-$generatedId',
      items: orderItems,
      paymentMethod: paymentMethod,
      deliveryFee: deliveryFee,
      heavyFee: heavyFee,
      platformFee: platformFee,
      isPickup: isPickup,
    );

    final updatedClient = [newOrder, ...state.clientOrders];
    final updatedIncoming = (auth.role == UserRole.farmer &&
            auth.farmerId != null &&
            targetFarmerId == auth.farmerId)
        ? [newOrder, ...state.incomingOrders]
        : state.incomingOrders;

    state = state.copyWith(
      orders: [newOrder, ...state.orders],
      clientOrders: updatedClient,
      incomingOrders: updatedIncoming,
    );
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
            'hasVat': resolvedHasVat,
            'deliveryFee': deliveryFee,
            'heavyFee': heavyFee,
            'platformFee': platformFee,
            'isPickup': isPickup,
            'totalAmount': newOrder.totalAmount,
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
          FarmerOrder replace(FarmerOrder o) =>
              o.id == generatedId ? serverOrder : o;
          state = state.copyWith(
            orders: state.orders.map(replace).toList(),
            clientOrders: state.clientOrders.map(replace).toList(),
            incomingOrders: state.incomingOrders.map(replace).toList(),
          );
        }
      } catch (_) {
        // Offline resilient fallback
      }
    }());

    return newOrder;
  }

  /// Automatically cancels and expires pending orders whose review window has elapsed
  /// without farmer confirmation, restoring reserved stock to inventory with zero refund friction.
  void checkPendingOrderExpirations() {
    final now = DateTime.now();
    bool hasChanges = false;
    FarmerOrder check(FarmerOrder o) {
      if (o.status == OrderStatus.pending &&
          o.cancellationDeadline != null &&
          now.isAfter(o.cancellationDeadline!)) {
        hasChanges = true;
        // Restore inventory stock because farmer didn't confirm
        unawaited(
          ref
              .read(marketplaceProvider.notifier)
              .restoreStockForOrderItems(o.items),
        );
        unawaited(
          _syncOrderStatus(
            o.id,
            status: OrderStatus.cancelled,
            reason:
                'ფერმერმა შეკვეთა დადგენილ დროში ვერ დაადასტურა (ვადა ამოიწურა)',
          ),
        );
        return o.copyWith(
          status: OrderStatus.cancelled,
          cancellationReason:
              'ფერმერმა შეკვეთა დადგენილ დროში ვერ დაადასტურა (ვადა ამოიწურა)',
        );
      }
      return o;
    }

    final updatedOrders = state.orders.map(check).toList();
    final updatedIncoming = state.incomingOrders.map(check).toList();
    final updatedClient = state.clientOrders.map(check).toList();

    if (hasChanges) {
      state = state.copyWith(
        orders: updatedOrders,
        incomingOrders: updatedIncoming,
        clientOrders: updatedClient,
      );
    }
  }

  /// Backward-compatible alias for expiring overdue pending orders
  void checkAutoConfirmation() => checkPendingOrderExpirations();

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
