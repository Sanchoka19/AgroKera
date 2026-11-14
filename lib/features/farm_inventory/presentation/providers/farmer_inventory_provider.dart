import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/auth/auth_state_provider.dart';
import '../../../../core/network/api_client.dart';
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
  static const int maxProductPhotos = 5;
  static const double compressedMaxDimension = 1280;
  static const int compressedQuality = 82;

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
    String? imageUrl,
    List<String>? images,
    required String title,
    required String priceText,
    required String stockText,
    required String description,
  }) {
    final hasAnyPhoto = (images != null &&
            images.any((u) => u.trim().isNotEmpty)) ||
        (imageUrl != null && imageUrl.trim().isNotEmpty);
    if (!hasAnyPhoto) {
      return 'გთხოვთ დაამატოთ მინიმუმ 1 პროდუქტის ფოტო';
    }
    if (images != null && images.length > maxProductPhotos) {
      return 'მაქსიმუმ $maxProductPhotos ფოტოს ატვირთვაა შესაძლებელი';
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

  Future<PickedProductPhoto> _uploadCompressedXFile(XFile file) async {
    final bytes = await file.readAsBytes();
    String uploadedUrl =
        'https://images.unsplash.com/photo-1542838132-92c53300491e?w=600&auto=format&fit=crop&q=80';
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.post<Map<String, dynamic>>(
        '/api/upload',
        data: {
          'fileName': file.name,
          'base64Data': base64Encode(bytes),
          'contentType': 'image/jpeg',
          'folder': 'products',
        },
      );
      final remoteUrl = response.data?['url'] as String?;
      if (remoteUrl != null && remoteUrl.isNotEmpty) {
        uploadedUrl = remoteUrl;
      }
    } catch (_) {
      if (file.path.startsWith('http') || file.path.startsWith('blob:')) {
        uploadedUrl = file.path;
      }
    }

    return PickedProductPhoto(
      url: uploadedUrl,
      name: file.name,
      bytes: bytes,
    );
  }

  /// Captures or selects a single product photo with smart HD compression (1280px, 82% quality)
  Future<PickedProductPhoto?> pickPhoto(ImageSource source) async {
    try {
      final XFile? file = await _imagePicker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: compressedMaxDimension,
        maxHeight: compressedMaxDimension,
        imageQuality: compressedQuality,
      );
      if (file == null) return null;
      return await _uploadCompressedXFile(file);
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

  /// Picks multiple photos from Gallery (up to [remainingSlots]) with smart HD compression
  Future<List<PickedProductPhoto>> pickGalleryPhotos({
    required int remainingSlots,
  }) async {
    if (remainingSlots <= 0) return const [];
    try {
      final List<XFile> files = await _imagePicker.pickMultiImage(
        maxWidth: compressedMaxDimension,
        maxHeight: compressedMaxDimension,
        imageQuality: compressedQuality,
        limit: remainingSlots > 1 ? remainingSlots : null,
      );
      if (files.isEmpty) return const [];
      final limited = files.take(remainingSlots).toList();
      final uploaded = <PickedProductPhoto>[];
      for (final file in limited) {
        uploaded.add(await _uploadCompressedXFile(file));
      }
      return uploaded;
    } catch (_) {
      final single = await pickPhoto(ImageSource.gallery);
      if (single == null) return const [];
      return [single];
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
    List<String>? images,
  }) async {
    final auth = ref.read(authStateProvider);
    final notifier = ref.read(marketplaceProvider.notifier);
    final normalizedImages = (images != null && images.isNotEmpty)
        ? images.take(maxProductPhotos).toList()
        : [imageUrl];

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
        imageUrl: normalizedImages.first,
        images: normalizedImages,
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
        imageUrl: normalizedImages.first,
        images: normalizedImages,
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

