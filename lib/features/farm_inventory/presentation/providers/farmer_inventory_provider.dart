import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/auth/auth_state_provider.dart';
import '../../../marketplace/data/models/product_model.dart';
import '../../../marketplace/presentation/providers/marketplace_provider.dart';

/// Filter tabs for the Farmer Inventory Screen
enum InventoryFilter {
  all,
  active,
  low,
  out,
}

/// Result of picking a product photo via Camera or Gallery
class PickedProductPhoto {
  final String? url;
  final String? name;
  final Uint8List? bytes;
  final String? errorMessage;

  const PickedProductPhoto({
    this.url,
    this.name,
    this.bytes,
    this.errorMessage,
  });

  bool get isSuccess => url != null && errorMessage == null;
}

/// Immutable state for Farmer Inventory business logic
class FarmerInventoryState {
  final InventoryFilter selectedFilter;
  final List<ProductModel> allProducts;

  const FarmerInventoryState({
    this.selectedFilter = InventoryFilter.all,
    this.allProducts = const [],
  });

  int get allCount => allProducts.length;

  int get activeCount =>
      allProducts.where((p) => p.isAvailable && p.stockQuantity >= 20).length;

  int get lowCount =>
      allProducts.where((p) => p.stockQuantity > 0 && p.stockQuantity < 20).length;

  int get outCount =>
      allProducts.where((p) => !p.isAvailable || p.stockQuantity <= 0).length;

  List<ProductModel> get filteredProducts {
    return allProducts.where((p) {
      return switch (selectedFilter) {
        InventoryFilter.active => p.isAvailable && p.stockQuantity >= 20,
        InventoryFilter.low => p.stockQuantity > 0 && p.stockQuantity < 20,
        InventoryFilter.out => !p.isAvailable || p.stockQuantity <= 0,
        InventoryFilter.all => true,
      };
    }).toList();
  }

  FarmerInventoryState copyWith({
    InventoryFilter? selectedFilter,
    List<ProductModel>? allProducts,
  }) {
    return FarmerInventoryState(
      selectedFilter: selectedFilter ?? this.selectedFilter,
      allProducts: allProducts ?? this.allProducts,
    );
  }
}

/// Business logic controller for Farmer Inventory & Product Management
class FarmerInventoryNotifier extends Notifier<FarmerInventoryState> {
  final ImagePicker _imagePicker = ImagePicker();

  @override
  FarmerInventoryState build() {
    final marketplace = ref.watch(marketplaceProvider);
    return FarmerInventoryState(
      allProducts: marketplace.products,
    );
  }

  void setFilter(InventoryFilter filter) {
    state = state.copyWith(selectedFilter: filter);
  }

  /// Validates product form fields and returns a Georgian error message if invalid, or `null` if valid.
  String? validateProductForm({
    required String? imageUrl,
    required String title,
    required String priceText,
    required String stockText,
    required String description,
  }) {
    if (imageUrl == null || imageUrl.trim().isEmpty) {
      return 'გთხოვთ დაამატოთ პროდუქტის ფოტო';
    }
    if (title.trim().isEmpty) {
      return 'გთხოვთ შეავსოთ პროდუქტის დასახელება';
    }
    final price = double.tryParse(priceText.trim()) ?? 0.0;
    if (price <= 0) {
      return 'გთხოვთ მიუთითოთ სწორი ფასი';
    }
    final stock = double.tryParse(stockText.trim()) ?? -1.0;
    if (stockText.trim().isEmpty || stock < 0) {
      return 'გთხოვთ მიუთითოთ მარაგის რაოდენობა';
    }
    if (description.trim().isEmpty) {
      return 'გთხოვთ შეავსოთ პროდუქტის აღწერა';
    }
    return null;
  }

  /// Captures or selects a product photo from Camera or Gallery
  Future<PickedProductPhoto?> pickPhoto(ImageSource source) async {
    try {
      final XFile? file = await _imagePicker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 85,
      );
      if (file == null) return null;
      final bytes = await file.readAsBytes();
      final url = file.path.startsWith('http') || file.path.startsWith('blob:')
          ? file.path
          : 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=600&auto=format&fit=crop&q=80';
      return PickedProductPhoto(
        url: url,
        name: file.name,
        bytes: bytes,
      );
    } on PlatformException catch (e) {
      return PickedProductPhoto(
        errorMessage: source == ImageSource.camera
            ? 'კამერაზე წვდომა ვერ მოხერხდა (${e.message ?? "შეამოწმეთ ნებართვა"})'
            : 'ფოტოს არჩევა ვერ მოხერხდა',
      );
    } catch (_) {
      return PickedProductPhoto(
        errorMessage: source == ImageSource.camera
            ? 'კამერის გახსნა ვერ მოხერხდა. შეამოწმეთ ნებართვა.'
            : 'ფოტოს არჩევა ვერ მოხერხდა',
      );
    }
  }

  /// Creates or updates a product in Marketplace & Neon DB
  Future<void> saveProduct({
    ProductModel? existing,
    required String title,
    required String category,
    required double price,
    required String unit,
    required double stockQuantity,
    required String description,
    required String imageUrl,
  }) async {
    final auth = ref.read(authStateProvider);
    final notifier = ref.read(marketplaceProvider.notifier);

    if (existing == null) {
      await notifier.addProduct(
        title: title.trim(),
        category: category,
        price: price,
        unit: unit,
        stockQuantity: stockQuantity,
        farmerId: auth.farmerId ?? 'farmer_2',
        farmerName: auth.userName != null
            ? '${auth.userName}-ის ფერმა'
            : 'გიორგის ფერმა',
        description: description.trim(),
        imageUrl: imageUrl,
      );
    } else {
      await notifier.updateProduct(
        existing.id,
        title: title.trim(),
        category: category,
        price: price,
        unit: unit,
        stockQuantity: stockQuantity,
        description: description.trim(),
        imageUrl: imageUrl,
      );
    }
  }

  /// Toggles product availability
  Future<void> toggleAvailability(ProductModel product, bool isAvailable) async {
    await ref.read(marketplaceProvider.notifier).updateProduct(
          product.id,
          isAvailable: isAvailable,
          stockQuantity:
              isAvailable && product.stockQuantity <= 0 ? 25.0 : null,
        );
  }

  /// Restocks a product and returns the new total stock quantity
  Future<double?> restockProduct(String productId, double addedQuantity) async {
    return ref
        .read(marketplaceProvider.notifier)
        .restockProduct(productId, addedQuantity);
  }

  /// Deletes a product from inventory
  Future<void> deleteProduct(String productId) async {
    await ref.read(marketplaceProvider.notifier).deleteProduct(productId);
  }
}

final farmerInventoryProvider =
    NotifierProvider<FarmerInventoryNotifier, FarmerInventoryState>(
  FarmerInventoryNotifier.new,
);

