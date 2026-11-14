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

  const FarmerModel({
    required this.id,
    required this.farmName,
    required this.farmerName,
    required this.location,
    required this.rating,
    required this.reviewCount,
    this.totalRatings = 120,
    this.isVerified = true,
    this.isVatPayer = true,
    required this.avatarUrl,
    required this.coverUrl,
    required this.about,
    this.phone = '+995 599 12 34 56',
  });

  factory FarmerModel.fromJson(Map<String, dynamic> json) {
    return FarmerModel(
      id: json['id'] as String,
      farmName: json['farmName'] as String? ?? '',
      farmerName: json['farmerName'] as String? ?? '',
      location: json['location'] as String? ?? 'კახეთი',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.9,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      totalRatings: (json['totalRatings'] as num?)?.toInt() ?? 0,
      isVerified: json['isVerified'] as bool? ?? true,
      isVatPayer: json['isVatPayer'] as bool? ?? false,
      avatarUrl: json['avatarUrl'] as String? ??
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&auto=format&fit=crop&q=80',
      coverUrl: json['coverUrl'] as String? ??
          'https://images.unsplash.com/photo-1500937386664-56d1dfef3854?w=1000&auto=format&fit=crop&q=80',
      about: json['about'] as String? ?? '',
      phone: json['phone'] as String? ?? '+995 599 11 22 33',
    );
  }
}
