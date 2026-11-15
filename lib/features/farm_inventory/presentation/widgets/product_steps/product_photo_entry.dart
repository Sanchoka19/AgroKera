import 'dart:typed_data';

class ProductPhotoEntry {
  final String url;
  final Uint8List? bytes;

  const ProductPhotoEntry({
    required this.url,
    this.bytes,
  });
}

