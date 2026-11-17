/// Core authentication domain models: roles, KYC status and session state.
library;

enum UserRole {
  guest,
  customer,
  farmer;

  String get displayName {
    switch (this) {
      case UserRole.farmer:
        return 'ფერმერი';
      case UserRole.customer:
        return 'მომხმარებელი';
      case UserRole.guest:
        return 'სტუმარი';
    }
  }

  /// Parses the role name persisted in secure storage (`farmer` / `customer`).
  static UserRole fromStorage(String? raw) {
    switch (raw) {
      case 'farmer':
        return UserRole.farmer;
      case 'customer':
        return UserRole.customer;
      default:
        return UserRole.guest;
    }
  }

  /// Role value expected by the backend API.
  String get apiValue => this == UserRole.farmer ? 'FARMER' : 'CLIENT';
}

enum KycStatus {
  unverified,
  pendingReview,
  verified,
  rejected;

  String get label {
    switch (this) {
      case KycStatus.unverified:
        return 'არავერიფიცირებული';
      case KycStatus.pendingReview:
        return 'მოწმდება';
      case KycStatus.verified:
        return 'ვერიფიცირებული';
      case KycStatus.rejected:
        return 'უარყოფილია';
    }
  }

  static KycStatus fromString(String? raw) {
    switch (raw?.toUpperCase()) {
      case 'PENDING_REVIEW':
        return KycStatus.pendingReview;
      case 'UNVERIFIED':
        return KycStatus.unverified;
      case 'REJECTED':
        return KycStatus.rejected;
      case 'VERIFIED':
      default:
        return KycStatus.verified;
    }
  }

  String get apiValue {
    switch (this) {
      case KycStatus.unverified:
        return 'UNVERIFIED';
      case KycStatus.pendingReview:
        return 'PENDING_REVIEW';
      case KycStatus.verified:
        return 'VERIFIED';
      case KycStatus.rejected:
        return 'REJECTED';
    }
  }
}

class AuthState {
  final bool isAuthenticated;
  final String? userId;
  final String? farmerId;
  final String? farmName;
  final String? userName;
  final String? userPhone;
  final String? userEmail;
  final String? userAvatarUrl;
  final String? farmCoverUrl;
  final UserRole role;
  final KycStatus kycStatus;

  const AuthState({
    this.isAuthenticated = false,
    this.userId,
    this.farmerId,
    this.farmName,
    this.userName,
    this.userPhone,
    this.userEmail,
    this.userAvatarUrl,
    this.farmCoverUrl,
    this.role = UserRole.guest,
    this.kycStatus = KycStatus.verified,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? userId,
    String? farmerId,
    String? farmName,
    String? userName,
    String? userPhone,
    String? userEmail,
    String? userAvatarUrl,
    String? farmCoverUrl,
    UserRole? role,
    KycStatus? kycStatus,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userId: userId ?? this.userId,
      farmerId: farmerId ?? this.farmerId,
      farmName: farmName ?? this.farmName,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      userEmail: userEmail ?? this.userEmail,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      farmCoverUrl: farmCoverUrl ?? this.farmCoverUrl,
      role: role ?? this.role,
      kycStatus: kycStatus ?? this.kycStatus,
    );
  }

  /// Checks if the authenticated user is the owner farmer matching any of
  /// the provided farmer ID, farm name, or farmer user name.
  bool isOwner({String? farmerId, String? farmName, String? farmerName}) {
    if (role != UserRole.farmer) return false;
    if (this.farmerId != null &&
        farmerId != null &&
        farmerId.isNotEmpty &&
        this.farmerId == farmerId) {
      return true;
    }
    if (this.farmName != null &&
        farmName != null &&
        farmName.isNotEmpty &&
        this.farmName == farmName) {
      return true;
    }
    if (this.farmName != null &&
        farmerName != null &&
        farmerName.isNotEmpty &&
        this.farmName == farmerName) {
      return true;
    }
    if (userName != null &&
        farmerName != null &&
        farmerName.isNotEmpty &&
        userName == farmerName) {
      return true;
    }
    return false;
  }
}

