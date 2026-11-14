import 'package:flutter/material.dart';
import '../../../../core/constants/app_assets.dart';
import 'models/category_model.dart';
import 'models/farmer_model.dart';
import 'models/product_model.dart';

abstract final class MockData {
  static const List<CategoryModel> categories = [
    CategoryModel(
      id: 'cat_fruit',
      name: 'ხილი',
      productCount: 5,
      imageUrl: AppAssets.categoryFruit,
      backgroundColor: Color(0xFF7CB342),
    ),
    CategoryModel(
      id: 'cat_citrus',
      name: 'ციტრუსი',
      productCount: 3,
      imageUrl: AppAssets.categoryCitrus,
      backgroundColor: Color(0xFFE5A93C),
    ),
    CategoryModel(
      id: 'cat_berry',
      name: 'კენკრა',
      productCount: 5,
      imageUrl: AppAssets.categoryBerry,
      backgroundColor: Color(0xFF8B263E),
    ),
    CategoryModel(
      id: 'cat_veg',
      name: 'ბოსტნეული',
      productCount: 5,
      imageUrl: AppAssets.categoryVegetable,
      backgroundColor: Color(0xFF1E7B54),
    ),
    CategoryModel(
      id: 'cat_dairy',
      name: 'ცხოველური პროდუქტები',
      productCount: 5,
      imageUrl: AppAssets.categoryMilk,
      backgroundColor: Color(0xFFDE8D1D),
    ),
    CategoryModel(
      id: 'cat_grain',
      name: 'მარცვლეული და პარკოსანი',
      productCount: 5,
      imageUrl: AppAssets.categoryBean,
      backgroundColor: Color(0xFFC78F52),
    ),
    CategoryModel(
      id: 'cat_honey',
      name: 'თაფლი და მეფუტკრეობა',
      productCount: 4,
      imageUrl: AppAssets.categoryHoney,
      backgroundColor: Color(0xFFD97706),
    ),
    CategoryModel(
      id: 'cat_wine',
      name: 'მეღვინეობა და სასმელები',
      productCount: 4,
      imageUrl: AppAssets.categoryWine,
      backgroundColor: Color(0xFF9D174D),
    ),
  ];

  static const List<FarmerModel> farmers = [
    FarmerModel(
      id: 'farmer_1',
      farmName: 'მწვანე ველი',
      farmerName: 'ლანა მახარაძე',
      location: 'გურჯაანი, კახეთი',
      rating: 4.9,
      reviewCount: 80,
      totalRatings: 120,
      isVerified: true,
      isVatPayer: true,
      avatarUrl:
          'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400&auto=format&fit=crop&q=80',
      coverUrl:
          'https://images.unsplash.com/photo-1500382017468-9049fed747ef?w=1000&auto=format&fit=crop&q=80',
      about:
          '„მწვანე ველი“ მდებარეობს კახეთში, გურჯაანის ნაყოფიერ მიწებზე. ჩვენ მოგვყავს ეკოლოგიურად სუფთა, ბიო-სერტიფიცირებული ბოსტნეული და ყურძენი ყოველგვარი ქიმიური დანამატების გარეშე.',
      phone: '+995 599 33 22 11',
    ),
    FarmerModel(
      id: 'farmer_2',
      farmName: 'გიორგის ფერმა',
      farmerName: 'გიორგი ბერიძე',
      location: 'თელავი, კახეთი',
      rating: 4.9,
      reviewCount: 80,
      totalRatings: 95,
      isVerified: true,
      isVatPayer: false,
      avatarUrl:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&auto=format&fit=crop&q=80',
      coverUrl:
          'https://images.unsplash.com/photo-1500937386664-56d1dfef3854?w=1000&auto=format&fit=crop&q=80',
      about:
          'საგვარეულო მეურნეობა თელავში. ვამარაგებთ რესტორნებსა და კერძო კლიენტებს ახალი ბოსტნეულითა და მწვანილეულით.',
      phone: '+995 599 11 22 33',
    ),
    FarmerModel(
      id: 'farmer_3',
      farmName: 'ალაზნის ბაღები',
      farmerName: 'დავით ნოზაძე',
      location: 'ყვარელი, კახეთი',
      rating: 4.8,
      reviewCount: 65,
      totalRatings: 110,
      isVerified: true,
      isVatPayer: true,
      avatarUrl:
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&auto=format&fit=crop&q=80',
      coverUrl:
          'https://images.unsplash.com/photo-1464965911861-746a04b4bca6?w=1000&auto=format&fit=crop&q=80',
      about:
          'ალაზნის ველზე გაშენებული მრავალწლიანი ხეხილისა და ციტრუსის ბაღები. 100% ნატურალური და მზით გამთბარი მოსავალი ყვარლიდან.',
      phone: '+995 599 44 55 66',
    ),
  ];

  static const List<ProductModel> products = [
    ProductModel(
      id: 'prod_1',
      title: 'მწვანილოვანი კომბოსტო',
      category: 'ბოსტნეული',
      farmerId: 'farmer_2',
      farmerName: 'გიორგის ფერმა',
      price: 15.0,
      discountPercent: 20,
      rating: 4.9,
      reviewCount: 80,
      stockStatus: 'მარაგშია',
      imageUrl:
          'https://images.unsplash.com/photo-1550142414-a81e12541000?w=600&auto=format&fit=crop&q=80',
      description:
          'ახალი, ხრაშუნა და ნატურალური მწვანილოვანი კომბოსტო პირდაპირ გიორგის ფერმიდან. იდეალურია სალათებისთვის და ჯანსაღი კერძებისთვის. მდიდარია C და K ვიტამინებით.',
    ),
    ProductModel(
      id: 'prod_2',
      title: 'ბულგარული წიწაკა',
      category: 'ბოსტნეული',
      farmerId: 'farmer_2',
      farmerName: 'გიორგის ფერმა',
      price: 15.0,
      discountPercent: 20,
      rating: 4.9,
      reviewCount: 80,
      stockStatus: 'მარაგშია',
      imageUrl:
          'https://images.unsplash.com/photo-1563565375-f3fdfdbefa83?w=600&auto=format&fit=crop&q=80',
      description:
          'ფერადი, წვნიანი და ტკბილი ბულგარული წიწაკა. დაკრეფილია დილით ადრე საუკეთესო არომატისა და სიახლის შესანარჩუნებლად.',
    ),
    ProductModel(
      id: 'prod_3',
      title: 'ხახვი',
      category: 'ბოსტნეული',
      farmerId: 'farmer_2',
      farmerName: 'გიორგის ფერმა',
      price: 15.0,
      rating: 4.9,
      reviewCount: 80,
      stockStatus: 'მარაგშია',
      imageUrl:
          'https://images.unsplash.com/photo-1618512496248-a07fe83aa8cb?w=600&auto=format&fit=crop&q=80',
      description:
          'მშრალი და მაღალი ხარისხის ადგილობრივი ხახვი. ინახება დიდხანს, გამოირჩევა მდიდარი პიკანტური გემოთი.',
    ),
    ProductModel(
      id: 'prod_4',
      title: 'პომიდორი',
      category: 'ბოსტნეული',
      farmerId: 'farmer_2',
      farmerName: 'გიორგის ფერმა',
      price: 15.0,
      discountPercent: 20,
      rating: 4.9,
      reviewCount: 80,
      stockStatus: 'იწურება',
      imageUrl:
          'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?w=600&auto=format&fit=crop&q=80',
      description:
          'არომატული ქართული ვარდისფერი პომიდორი. იზრდება ღია გრუნტზე, მზის სითბოში. გამორჩეული წვნიანობა და ნამდვილი ტომატის გემო.',
    ),
    ProductModel(
      id: 'prod_5',
      title: 'მწვანე ლობიო',
      category: 'ბოსტნეული',
      farmerId: 'farmer_1',
      farmerName: 'მწვანე ველი',
      price: 15.0,
      discountPercent: 20,
      rating: 4.9,
      reviewCount: 70,
      stockStatus: 'მარაგშია',
      imageUrl:
          'https://images.unsplash.com/photo-1567375698348-5d9d5ae99de0?w=600&auto=format&fit=crop&q=80',
      description:
          'ნაზი, უძარღვო მწვანე ლობიო კახეთის ბოსტნებიდან. სწრაფად იხარშება და ინარჩუნებს მკვეთრ ფერსა და სასარგებლო თვისებებს.',
    ),
    ProductModel(
      id: 'prod_6',
      title: 'კახური შავი ყურძენი',
      category: 'ხილი',
      farmerId: 'farmer_1',
      farmerName: 'მწვანე ველი',
      price: 25.0,
      rating: 5.0,
      reviewCount: 95,
      stockStatus: 'მარაგშია',
      imageUrl:
          'https://images.unsplash.com/photo-1537640538966-79f369143f8f?w=600&auto=format&fit=crop&q=80',
      description:
          'რჩეული საფერავის ჯიშის სუფრის ყურძენი გურჯაანის ვენახებიდან. ტკბილი, ხორციანი მარცვლებითა და საუკეთესო არომატით.',
    ),
    ProductModel(
      id: 'prod_honey_1',
      title: 'ალპური ყვავილების თაფლი',
      category: 'თაფლი და მეფუტკრეობა',
      farmerId: 'farmer_1',
      farmerName: 'მწვანე ველი',
      price: 28.0,
      discountPercent: 0,
      rating: 5.0,
      reviewCount: 42,
      stockStatus: 'მარაგშია',
      imageUrl:
          'https://images.unsplash.com/photo-1587049352846-4a222e784d38?w=600&auto=format&fit=crop&q=80',
      description:
          '100% ნატურალური, გაუცხელებელი ალპური ყვავილის თაფლი მაღალმთიანი რეგიონიდან.',
    ),
    ProductModel(
      id: 'prod_wine_1',
      title: 'საფერავი ქვევრის (ბიო)',
      category: 'მეღვინეობა და სასმელები',
      farmerId: 'farmer_3',
      farmerName: 'ალაზნის ბაღები',
      price: 35.0,
      discountPercent: 10,
      rating: 4.9,
      reviewCount: 56,
      stockStatus: 'მარაგშია',
      imageUrl:
          'https://images.unsplash.com/photo-1510812431401-41d2bd2722f3?w=600&auto=format&fit=crop&q=80',
      description:
          'ტრადიციული კახური წესით, ქვევრში 6 თვის განმავლობაში დავარგებული ბიო საფერავი.',
    ),
  ];
}
