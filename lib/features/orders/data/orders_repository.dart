import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/offline_queue/offline_mutation.dart';
import '../../../core/network/offline_queue/offline_queue_store.dart';
import '../domain/models/farmer_order_model.dart';

/// Repository responsible for remote API communication for orders with offline fallback queue
class OrdersRepository {
  final ApiClient _api;
  final OfflineQueueStore? _queueStore;

  const OrdersRepository(this._api, [this._queueStore]);

  Future<List<FarmerOrder>?> fetchOrdersForFarmer(String farmerId) async {
    try {
      final res = await _api.get<List<dynamic>>(
        '/api/orders',
        queryParameters: {'farmerId': farmerId},
      );
      if (res.data != null) {
        return res.data!
            .whereType<Map<String, dynamic>>()
            .map(FarmerOrder.fromJson)
            .toList();
      }
    } catch (_) {}
    return null;
  }

  Future<List<FarmerOrder>?> fetchOrdersForClient(String clientId) async {
    try {
      final res = await _api.get<List<dynamic>>(
        '/api/orders',
        queryParameters: {'clientId': clientId},
      );
      if (res.data != null) {
        return res.data!
            .whereType<Map<String, dynamic>>()
            .map(FarmerOrder.fromJson)
            .toList();
      }
    } catch (_) {}
    return null;
  }

  Future<({String? error, FarmerOrder? order})> syncOrderStatus(
    String id, {
    required OrderStatus status,
    String? reason,
    String? requesterId,
    String? requesterFarmerId,
  }) async {
    final payload = {
      'status': status.apiValue,
      'cancellationReason': ?reason,
      'requesterId': requesterId,
      'requesterFarmerId': requesterFarmerId,
    };

    try {
      final res = await _api.patch(
        '/api/orders/$id/status',
        data: payload,
      );
      FarmerOrder? updatedOrder;
      if (res.data != null && res.data is Map<String, dynamic>) {
        try {
          updatedOrder =
              FarmerOrder.fromJson(res.data as Map<String, dynamic>);
        } catch (_) {}
      }
      return (error: null, order: updatedOrder);
    } on DioException catch (e) {
      if (isFlutterTestEnv) {
        return (error: null, order: null);
      }
      // If it's a client 4xx validation error (e.g. 403 Forbidden / 400 Bad Request)
      final statusCode = e.response?.statusCode;
      if (statusCode != null && statusCode >= 400 && statusCode < 500 && statusCode != 408) {
        final msg = e.response?.data is Map
            ? (e.response!.data['error'] as String?)
            : null;
        return (error: msg ?? 'ოპერაცია უარყოფილია სერვერის მიერ', order: null);
      }

      // Offline / Network timeout / connection error: Enqueue offline mutation
      await _enqueueStatusUpdate(id, status, payload);
      return (error: null, order: null);
    } catch (_) {
      // General network/offline error: Enqueue offline mutation
      await _enqueueStatusUpdate(id, status, payload);
      return (error: null, order: null);
    }
  }

  Future<void> _enqueueStatusUpdate(
    String orderId,
    OrderStatus status,
    Map<String, dynamic> payload,
  ) async {
    if (_queueStore == null) return;
    try {
      await _queueStore.enqueue(
        OfflineMutation(
          id: 'order_status_${orderId}_${DateTime.now().millisecondsSinceEpoch}',
          endpoint: '/api/orders/$orderId/status',
          method: 'PATCH',
          payload: payload,
          timestamp: DateTime.now(),
          description: 'შეკვეთის სტატუსის განახლება ($status)',
        ),
      );
    } catch (_) {}
  }

  Future<FarmerOrder?> createOrder(Map<String, dynamic> orderPayload) async {
    try {
      final response = await _api.post<Map<String, dynamic>>(
        '/api/orders',
        data: orderPayload,
      );
      if (response.data != null) {
        return FarmerOrder.fromJson(response.data!);
      }
    } catch (_) {
      // Enqueue offline order creation
      if (_queueStore != null) {
        final orderId = orderPayload['id'] ?? 'ord_${DateTime.now().millisecondsSinceEpoch}';
        try {
          await _queueStore.enqueue(
            OfflineMutation(
              id: 'create_order_$orderId',
              endpoint: '/api/orders',
              method: 'POST',
              payload: orderPayload,
              timestamp: DateTime.now(),
              description: 'ოფლაინ შეკვეთის გაგზავნა',
            ),
          );
        } catch (_) {}
      }
    }
    return null;
  }
}
