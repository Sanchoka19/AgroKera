import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../domain/models/farmer_order_model.dart';

/// Repository responsible for remote API communication for orders
class OrdersRepository {
  final ApiClient _api;

  const OrdersRepository(this._api);

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

  Future<String?> syncOrderStatus(
    String id, {
    required OrderStatus status,
    String? reason,
    String? requesterId,
    String? requesterFarmerId,
  }) async {
    try {
      await _api.patch(
        '/api/orders/$id/status',
        data: {
          'status': status.apiValue,
          'cancellationReason': ?reason,
          'requesterId': requesterId,
          'requesterFarmerId': requesterFarmerId,
        },
      );
      return null;
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response!.data['error'] as String?)
          : null;
      return msg ?? 'სერვერის შეცდომა. სცადეთ თავიდან.';
    } catch (_) {
      return null;
    }
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
    } catch (_) {}
    return null;
  }
}

