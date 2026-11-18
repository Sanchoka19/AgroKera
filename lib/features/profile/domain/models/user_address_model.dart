/// Domain models for user delivery and farm addresses
class UserAddress {
  final String id;
  final String title; // 'სახლი', 'სამსახური', 'მეურნეობა', 'აგარაკი', 'სხვა'
  final String city;
  final String addressLine;
  final String? details; // სადარბაზო, სართული, ბინა
  final String? note; // კომენტარი კურიერისთვის
  final bool isDefault;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;

  const UserAddress({
    required this.id,
    required this.title,
    required this.city,
    required this.addressLine,
    this.details,
    this.note,
    this.isDefault = false,
    this.latitude,
    this.longitude,
    required this.createdAt,
  });

  /// Human-friendly single-line formatted address
  String get formattedAddress {
    final cleanCity = city.trim();
    final cleanLine = addressLine.trim();
    final buffer = StringBuffer();

    if (cleanCity.isNotEmpty && !cleanLine.startsWith(cleanCity)) {
      buffer.write('$cleanCity, $cleanLine');
    } else {
      buffer.write(cleanLine.isNotEmpty ? cleanLine : cleanCity);
    }

    if (details != null && details!.trim().isNotEmpty) {
      buffer.write(', ${details!.trim()}');
    }
    return buffer.toString();
  }

  UserAddress copyWith({
    String? id,
    String? title,
    String? city,
    String? addressLine,
    String? details,
    String? note,
    bool? isDefault,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
  }) {
    return UserAddress(
      id: id ?? this.id,
      title: title ?? this.title,
      city: city ?? this.city,
      addressLine: addressLine ?? this.addressLine,
      details: details ?? this.details,
      note: note ?? this.note,
      isDefault: isDefault ?? this.isDefault,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'city': city,
      'addressLine': addressLine,
      'details': details,
      'note': note,
      'isDefault': isDefault,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserAddress.fromJson(Map<String, dynamic> json) {
    return UserAddress(
      id: json['id'] as String? ?? 'addr_${DateTime.now().millisecondsSinceEpoch}',
      title: json['title'] as String? ?? 'სახლი',
      city: json['city'] as String? ?? 'თბილისი',
      addressLine: json['addressLine'] as String? ?? '',
      details: json['details'] as String?,
      note: json['note'] as String?,
      isDefault: json['isDefault'] as bool? ?? false,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

/// State container for the address management feature
class UserAddressState {
  final List<UserAddress> addresses;
  final String activeAddress;
  final bool isLoading;
  final String? errorMessage;

  const UserAddressState({
    this.addresses = const [],
    this.activeAddress = '',
    this.isLoading = false,
    this.errorMessage,
  });

  /// Whether the user has configured at least one personal delivery address
  bool get hasAddress => addresses.isNotEmpty && activeAddress.trim().isNotEmpty;

  UserAddress? get defaultAddress {
    try {
      return addresses.firstWhere((a) => a.isDefault);
    } catch (_) {
      return addresses.isNotEmpty ? addresses.first : null;
    }
  }

  UserAddressState copyWith({
    List<UserAddress>? addresses,
    String? activeAddress,
    bool? isLoading,
    String? errorMessage,
  }) {
    return UserAddressState(
      addresses: addresses ?? this.addresses,
      activeAddress: activeAddress ?? this.activeAddress,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

