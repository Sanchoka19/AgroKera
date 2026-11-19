import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../marketplace/presentation/providers/marketplace_provider.dart';
import '../../data/reviews_repository.dart';
import '../../domain/models/order_review_model.dart';

final reviewsRepositoryProvider = Provider<ReviewsRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return ReviewsRepository(api);
});

class ReviewsState {
  final Map<String, List<OrderReviewModel>> reviewsByFarmer;
  final Map<String, OrderReviewModel> reviewsByOrder;
  final bool isSubmitting;

  const ReviewsState({
    this.reviewsByFarmer = const {},
    this.reviewsByOrder = const {},
    this.isSubmitting = false,
  });

  ReviewsState copyWith({
    Map<String, List<OrderReviewModel>>? reviewsByFarmer,
    Map<String, OrderReviewModel>? reviewsByOrder,
    bool? isSubmitting,
  }) {
    return ReviewsState(
      reviewsByFarmer: reviewsByFarmer ?? this.reviewsByFarmer,
      reviewsByOrder: reviewsByOrder ?? this.reviewsByOrder,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class ReviewsNotifier extends Notifier<ReviewsState> {
  late final ReviewsRepository _repo;

  @override
  ReviewsState build() {
    _repo = ref.read(reviewsRepositoryProvider);
    return const ReviewsState();
  }

  /// Submits a review and seamlessly updates farmer rating across marketplace & profile
  Future<OrderReviewModel?> submitReview({
    required String orderId,
    required String clientId,
    required String farmerId,
    required String clientName,
    String? clientAvatarUrl,
    required int rating,
    List<String> tags = const [],
    String? comment,
  }) async {
    state = state.copyWith(isSubmitting: true);
    try {
      final result = await _repo.submitReview(
        orderId: orderId,
        clientId: clientId,
        farmerId: farmerId,
        clientName: clientName,
        clientAvatarUrl: clientAvatarUrl,
        rating: rating,
        tags: tags,
        comment: comment,
      );

      final review = result?.review ??
          OrderReviewModel(
            id: 'rev_local_${DateTime.now().millisecondsSinceEpoch}',
            orderId: orderId,
            clientId: clientId,
            clientName: clientName,
            clientAvatarUrl: clientAvatarUrl,
            farmerId: farmerId,
            rating: rating,
            tags: tags,
            comment: comment,
            createdAt: DateTime.now(),
          );

      final updatedOrdersMap = Map<String, OrderReviewModel>.from(state.reviewsByOrder);
      updatedOrdersMap[orderId] = review;

      final existingFarmerList =
          List<OrderReviewModel>.from(state.reviewsByFarmer[farmerId] ?? []);
      existingFarmerList.removeWhere((r) => r.orderId == orderId);
      existingFarmerList.insert(0, review);

      final updatedFarmerMap =
          Map<String, List<OrderReviewModel>>.from(state.reviewsByFarmer);
      updatedFarmerMap[farmerId] = existingFarmerList;

      state = state.copyWith(
        reviewsByOrder: updatedOrdersMap,
        reviewsByFarmer: updatedFarmerMap,
        isSubmitting: false,
      );

      // Dynamically update farmer rating in marketplaceProvider
      final farmerRating = result?.farmerRating ??
          (existingFarmerList.fold(0.0, (s, r) => s + r.rating) /
              existingFarmerList.length);
      final farmerReviewCount =
          result?.farmerReviewCount ?? existingFarmerList.length;

      ref.read(marketplaceProvider.notifier).updateFarmerRating(
            farmerId: farmerId,
            newRating: farmerRating,
            newReviewCount: farmerReviewCount,
          );

      return review;
    } catch (_) {
      state = state.copyWith(isSubmitting: false);
      return null;
    }
  }

  /// Loads reviews for a specific farmer from the server
  Future<void> loadReviewsForFarmer(String farmerId) async {
    final result = await _repo.fetchReviewsForFarmer(farmerId);
    final updatedFarmerMap =
        Map<String, List<OrderReviewModel>>.from(state.reviewsByFarmer);
    updatedFarmerMap[farmerId] = result.reviews;

    final updatedOrdersMap =
        Map<String, OrderReviewModel>.from(state.reviewsByOrder);
    for (final r in result.reviews) {
      updatedOrdersMap[r.orderId] = r;
    }

    state = state.copyWith(
      reviewsByFarmer: updatedFarmerMap,
      reviewsByOrder: updatedOrdersMap,
    );

    ref.read(marketplaceProvider.notifier).updateFarmerRating(
          farmerId: farmerId,
          newRating: result.averageRating,
          newReviewCount: result.reviewCount,
        );
  }

  /// Checks if an order has already been reviewed
  Future<OrderReviewModel?> checkOrderReview(String orderId) async {
    if (state.reviewsByOrder.containsKey(orderId)) {
      return state.reviewsByOrder[orderId];
    }
    final review = await _repo.fetchReviewForOrder(orderId);
    if (review != null) {
      final updatedOrdersMap =
          Map<String, OrderReviewModel>.from(state.reviewsByOrder);
      updatedOrdersMap[orderId] = review;
      state = state.copyWith(reviewsByOrder: updatedOrdersMap);
    }
    return review;
  }
}

final reviewsProvider =
    NotifierProvider<ReviewsNotifier, ReviewsState>(ReviewsNotifier.new);

