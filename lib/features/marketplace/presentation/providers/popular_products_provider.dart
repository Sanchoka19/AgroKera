import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_categories.dart';
import '../../data/models/category_model.dart';
import '../../data/models/product_model.dart';
import '../../domain/services/popular_products_service.dart';
import 'marketplace_provider.dart';

/// Provider providing the complete ranked list of popular products
final popularProductsProvider = Provider<List<ProductModel>>((ref) {
  final buyerProducts = ref.watch(buyerProductsProvider);
  return PopularProductsService.rankPopularProducts(buyerProducts);
});

/// Provider for the home screen horizontal slider, returning top 8 popular products
final topPopularProductsProvider = Provider<List<ProductModel>>((ref) {
  final popularProducts = ref.watch(popularProductsProvider);
  return popularProducts.take(8).toList();
});

/// Provider returning the top 4 popular categories for HomeScreen
final topPopularCategoriesProvider = Provider<List<CategoryModel>>((ref) {
  final buyerProducts = ref.watch(buyerProductsProvider);
  return PopularProductsService.rankPopularCategories(
    buyerProducts,
    AppCategories.categories,
  ).take(4).toList();
});

