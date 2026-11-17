import 'package:flutter/material.dart';
import '../../../marketplace/data/models/product_model.dart';
import '../screens/add_edit_product_screen.dart';

/// Legacy adapter for product creation/editing.
///
/// Forwards to [AddEditProductScreen], preserving backward compatibility
/// for any callers using `ProductFormSheet` or `ProductFormSheet.show()`.
class ProductFormSheet extends StatelessWidget {
  final ProductModel? existing;

  const ProductFormSheet({
    super.key,
    this.existing,
  });

  static Future<void> show(BuildContext context, {ProductModel? existing}) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEditProductScreen(existing: existing),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AddEditProductScreen(existing: existing);
  }
}
