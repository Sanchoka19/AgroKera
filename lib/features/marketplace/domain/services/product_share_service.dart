import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/product_model.dart';

/// Single responsibility service dedicated to formatting product sharing content
/// and dispatching share intents to the underlying platform.
/// Strictly decoupled from UI presentation, free of emojis, and testable.
class ProductShareService {
  static const String defaultBaseUrl = 'https://agrokera.ge';
  final SharePlus _shareClient;

  ProductShareService({SharePlus? shareClient})
      : _shareClient = shareClient ?? SharePlus.instance;

  /// Builds a canonical product link
  String buildProductUrl(String productId, {String baseUrl = defaultBaseUrl}) {
    return '$baseUrl/products/$productId';
  }

  /// Formats clean, professional Georgian share text without emojis
  String formatShareText(ProductModel product, {String baseUrl = defaultBaseUrl}) {
    final buffer = StringBuffer();
    buffer.writeln(product.title);
    buffer.writeln('ფასი: ${product.price.toStringAsFixed(2)} ₾ / ${product.unit}');
    if (product.farmerName.trim().isNotEmpty) {
      buffer.writeln('ფერმერი: ${product.farmerName}');
    }
    buffer.writeln();
    buffer.writeln('იხილეთ AgroKera-ში:');
    buffer.write(buildProductUrl(product.id, baseUrl: baseUrl));
    return buffer.toString();
  }

  /// Builds subject line for platforms that support it (e.g. email)
  String formatShareSubject(ProductModel product) {
    return 'AgroKera: ${product.title}';
  }

  /// Dispatches the share sheet via the native platform
  Future<ShareResult> shareProduct(
    ProductModel product, {
    Rect? sharePositionOrigin,
    String baseUrl = defaultBaseUrl,
  }) async {
    final text = formatShareText(product, baseUrl: baseUrl);
    final subject = formatShareSubject(product);

    return await _shareClient.share(
      ShareParams(
        text: text,
        title: subject,
        subject: subject,
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }
}

/// Riverpod provider for ProductShareService allowing dependency injection and mocking
final productShareServiceProvider = Provider<ProductShareService>((ref) {
  return ProductShareService();
});
