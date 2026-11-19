import '../../../../core/network/api_client.dart';
import '../domain/models/order_review_model.dart';

/// Repository managing network interactions for order reviews and ratings.
class ReviewsRepository {
  final ApiClient _api;

  const ReviewsRepository(this._api);

  /// Submits a customer review for a completed order.
  Future<({OrderReviewModel review, double farmerRating, int farmerReviewCount})?>
      submitReview({
    required String orderId,
    required String clientId,
    required String farmerId,
    required String clientName,
    String? clientAvatarUrl,
    required int rating,
    List<String> tags = const [],
    String? comment,
  }) async {
    try {
      final res = await _api.post('/api/reviews', data: {
        'orderId': orderId,
        'clientId': clientId,
        'farmerId': farmerId,
        'clientName': clientName,
        'clientAvatarUrl': ?clientAvatarUrl,
        'rating': rating,
        'tags': tags,
        if (comment != null && comment.trim().isNotEmpty)
          'comment': comment.trim(),
      });

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = res.data as Map<String, dynamic>;
        final reviewJson = data['review'] as Map<String, dynamic>;
        final review = OrderReviewModel.fromJson(reviewJson);
        final farmerRating = (data['farmerRating'] as num?)?.toDouble() ?? 5.0;
        final farmerReviewCount = (data['farmerReviewCount'] as num?)?.toInt() ?? 1;

        return (
          review: review,
          farmerRating: farmerRating,
          farmerReviewCount: farmerReviewCount,
        );
      }
    } catch (_) {}
    return null;
  }

  /// Fetches reviews for a specific farmer.
  Future<({List<OrderReviewModel> reviews, double averageRating, int reviewCount})>
      fetchReviewsForFarmer(String farmerId) async {
    try {
      final res = await _api.get('/api/reviews/farmer/$farmerId');
      if (res.statusCode == 200 && res.data != null) {
        final data = res.data as Map<String, dynamic>;
        final list = (data['reviews'] as List<dynamic>?)
                ?.map((e) => OrderReviewModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];
        final averageRating = (data['averageRating'] as num?)?.toDouble() ?? 5.0;
        final reviewCount = (data['reviewCount'] as num?)?.toInt() ?? list.length;

        return (
          reviews: list,
          averageRating: averageRating,
          reviewCount: reviewCount,
        );
      }
    } catch (_) {}

    return (reviews: <OrderReviewModel>[], averageRating: 0.0, reviewCount: 0);
  }

  /// Checks if an order already has a submitted review.
  Future<OrderReviewModel?> fetchReviewForOrder(String orderId) async {
    try {
      final res = await _api.get('/api/reviews/order/$orderId');
      if (res.statusCode == 200 && res.data != null) {
        return OrderReviewModel.fromJson(res.data as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }
}
