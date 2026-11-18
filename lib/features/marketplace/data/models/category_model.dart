import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String name;
  final int productCount;
  final String imageUrl;
  final String? svgUrl;
  final Color backgroundColor;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.productCount,
    required this.imageUrl,
    this.svgUrl,
    required this.backgroundColor,
  });
}
