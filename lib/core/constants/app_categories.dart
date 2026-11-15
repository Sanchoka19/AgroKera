import 'package:flutter/material.dart';
import '../constants/app_assets.dart';
import '../../features/marketplace/data/models/category_model.dart';

/// Clean System-wide AgroKera Product Categories catalog
abstract final class AppCategories {
  static const List<CategoryModel> categories = [
    CategoryModel(
      id: 'cat_fruit',
      name: 'ხილი',
      productCount: 0,
      imageUrl: AppAssets.categoryFruit,
      backgroundColor: Color(0xFF7CB342),
    ),
    CategoryModel(
      id: 'cat_citrus',
      name: 'ციტრუსი',
      productCount: 0,
      imageUrl: AppAssets.categoryCitrus,
      backgroundColor: Color(0xFFE5A93C),
    ),
    CategoryModel(
      id: 'cat_berry',
      name: 'კენკრა',
      productCount: 0,
      imageUrl: AppAssets.categoryBerry,
      backgroundColor: Color(0xFF8B263E),
    ),
    CategoryModel(
      id: 'cat_veg',
      name: 'ბოსტნეული',
      productCount: 0,
      imageUrl: AppAssets.categoryVegetable,
      backgroundColor: Color(0xFF1E7B54),
    ),
    CategoryModel(
      id: 'cat_dairy',
      name: 'ცხოველური პროდუქტები',
      productCount: 0,
      imageUrl: AppAssets.categoryMilk,
      backgroundColor: Color(0xFFDE8D1D),
    ),
    CategoryModel(
      id: 'cat_grain',
      name: 'მარცვლეული და პარკოსანი',
      productCount: 0,
      imageUrl: AppAssets.categoryBean,
      backgroundColor: Color(0xFFC78F52),
    ),
    CategoryModel(
      id: 'cat_honey',
      name: 'თაფლი და მეფუტკრეობა',
      productCount: 0,
      imageUrl: AppAssets.categoryHoney,
      backgroundColor: Color(0xFFD97706),
    ),
    CategoryModel(
      id: 'cat_wine',
      name: 'მეღვინეობა და სასმელები',
      productCount: 0,
      imageUrl: AppAssets.categoryWine,
      backgroundColor: Color(0xFF9D174D),
    ),
  ];
}
