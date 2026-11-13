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
}
