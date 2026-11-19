import '../../../../core/auth/auth_models.dart';

class FarmerModel {
  final String id;
  final String farmName;
  final String farmerName;
  final String location;
  final double rating;
  final int reviewCount;
  final int totalRatings;
  final bool isVerified;
  final bool isVatPayer;
  final String avatarUrl;
  final String coverUrl;
  final String about;
  final String phone;
  final bool isDeliveryEnabled;
  final String deliveryCity;
  final List<String> deliveryDays;
  final double deliveryFee;
  final Map<String, double> regionalDeliveryFees;
  final bool isPickupEnabled;

  static String normalizeDay(String d) {
    const map = {
      'ორშ': 'ორშაბათი',
      'სამ': 'სამშაბათი',
      'ოთხ': 'ოთხშაბათი',
      'ხუთ': 'ხუთშაბათი',
      'პარ': 'პარასკევი',
      'შაბ': 'შაბათი',
      'კვი': 'კვირა',
    };
    final trimmed = d.trim();
    return map[trimmed] ?? trimmed;
  }

  const FarmerModel({
    required this.id,
    required this.farmName,
    required this.farmerName,
    required this.location,
    required this.rating,
    required this.reviewCount,
    this.totalRatings = 0,
    this.isVerified = true,
    this.isVatPayer = true,
    required this.avatarUrl,
    required this.coverUrl,
    required this.about,
    this.phone = '+995 599 12 34 56',
    this.isDeliveryEnabled = true,
    this.deliveryCity = 'თბილისი',
    this.deliveryDays = const ['შაბათი'],
    this.deliveryFee = 7.0,
    this.regionalDeliveryFees = const {'თბილისი': 7.0},
    this.isPickupEnabled = true,
  });

  factory FarmerModel.fromJson(Map<String, dynamic> json) {
    return FarmerModel(
      id: json['id'] as String,
      farmName: json['farmName'] as String? ?? '',
      farmerName: json['farmerName'] as String? ?? '',
      location: json['location'] as String? ?? 'კახეთი',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      totalRatings: (json['totalRatings'] as num?)?.toInt() ??
          ((json['reviewCount'] as num?)?.toInt() ?? 0),
      isVerified: json['isVerified'] as bool? ?? true,
      isVatPayer: json['isVatPayer'] as bool? ?? false,
      avatarUrl: json['avatarUrl'] as String? ??
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&auto=format&fit=crop&q=80',
      coverUrl: json['coverUrl'] as String? ??
          'https://images.unsplash.com/photo-1500937386664-56d1dfef3854?w=1000&auto=format&fit=crop&q=80',
      about: json['about'] as String? ?? '',
      phone: json['phone'] as String? ?? '+995 599 11 22 33',
      isDeliveryEnabled: json['isDeliveryEnabled'] as bool? ?? true,
      deliveryCity: json['deliveryCity'] as String? ?? 'თბილისი',
      deliveryDays: (json['deliveryDays'] as List<dynamic>?)
              ?.map((e) => normalizeDay(e.toString()))
              .toSet()
              .toList() ??
          const ['შაბათი'],
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 7.0,
      regionalDeliveryFees:
          (json['regionalDeliveryFees'] as Map<String, dynamic>?)?.map(
                (k, v) => MapEntry(k, (v as num).toDouble()),
              ) ??
              const {'თბილისი': 7.0},
      isPickupEnabled: json['isPickupEnabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farmName': farmName,
      'farmerName': farmerName,
      'location': location,
      'rating': rating,
      'reviewCount': reviewCount,
      'totalRatings': totalRatings,
      'isVerified': isVerified,
      'isVatPayer': isVatPayer,
      'avatarUrl': avatarUrl,
      'coverUrl': coverUrl,
      'about': about,
      'phone': phone,
      'isDeliveryEnabled': isDeliveryEnabled,
      'deliveryCity': deliveryCity,
      'deliveryDays': deliveryDays,
      'deliveryFee': deliveryFee,
      'regionalDeliveryFees': regionalDeliveryFees,
      'isPickupEnabled': isPickupEnabled,
    };
  }

  FarmerModel copyWith({
    String? id,
    String? farmName,
    String? farmerName,
    String? location,
    double? rating,
    int? reviewCount,
    int? totalRatings,
    bool? isVerified,
    bool? isVatPayer,
    String? avatarUrl,
    String? coverUrl,
    String? about,
    String? phone,
    bool? isDeliveryEnabled,
    String? deliveryCity,
    List<String>? deliveryDays,
    double? deliveryFee,
    Map<String, double>? regionalDeliveryFees,
    bool? isPickupEnabled,
  }) {
    return FarmerModel(
      id: id ?? this.id,
      farmName: farmName ?? this.farmName,
      farmerName: farmerName ?? this.farmerName,
      location: location ?? this.location,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      totalRatings: totalRatings ?? this.totalRatings,
      isVerified: isVerified ?? this.isVerified,
      isVatPayer: isVatPayer ?? this.isVatPayer,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      about: about ?? this.about,
      phone: phone ?? this.phone,
      isDeliveryEnabled: isDeliveryEnabled ?? this.isDeliveryEnabled,
      deliveryCity: deliveryCity ?? this.deliveryCity,
      deliveryDays: deliveryDays ?? this.deliveryDays,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      regionalDeliveryFees: regionalDeliveryFees ?? this.regionalDeliveryFees,
      isPickupEnabled: isPickupEnabled ?? this.isPickupEnabled,
    );
  }

  /// Checks if this farm is owned by the provided authenticated user.
  bool isOwnedBy(AuthState auth) {
    return auth.isOwner(
      farmerId: id,
      farmName: farmName,
      farmerName: farmerName,
    );
  }
}
