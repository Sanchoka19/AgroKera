import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import '../storage/secure_storage_service.dart';

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

class _ResolvedAccountIdentity {
  final String userId;
  final String? farmerId;
  final String? farmName;
  final String name;
  final String phone;
  final String? avatarUrl;
  final String? coverUrl;

  const _ResolvedAccountIdentity({
    required this.userId,
    this.farmerId,
    this.farmName,
    required this.name,
    required this.phone,
    this.avatarUrl,
    this.coverUrl,
  });
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    unawaited(Future.microtask(restoreSession));
    return const AuthState(isAuthenticated: false);
  }

  _ResolvedAccountIdentity _resolveIdentity({
    required String email,
    required UserRole role,
    String? explicitName,
    String? explicitPhone,
    String? explicitFarmName,
  }) {
    final normalizedEmail = email.trim().toLowerCase();
    if (role == UserRole.farmer) {
      if (normalizedEmail.contains('lana')) {
        return _ResolvedAccountIdentity(
          userId: 'user_farmer_1',
          farmerId: 'farmer_1',
          farmName: explicitFarmName ?? 'მწვანე ველი',
          name: explicitName ?? 'ლანა მახარაძე',
          phone: explicitPhone ?? '+995 599 33 22 11',
          avatarUrl:
              'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400&auto=format&fit=crop&q=80',
          coverUrl:
              'https://images.unsplash.com/photo-1500382017468-9049fed747ef?w=1000&auto=format&fit=crop&q=80',
        );
      }
      if (normalizedEmail.contains('giorgi')) {
        return _ResolvedAccountIdentity(
          userId: 'user_farmer_2',
          farmerId: 'farmer_2',
          farmName: explicitFarmName ?? 'გიორგის ფერმა',
          name: explicitName ?? 'გიორგი ბერიძე',
          phone: explicitPhone ?? '+995 599 11 22 33',
          avatarUrl:
              'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&auto=format&fit=crop&q=80',
          coverUrl:
              'https://images.unsplash.com/photo-1500937386664-56d1dfef3854?w=1000&auto=format&fit=crop&q=80',
        );
      }
      if (normalizedEmail.contains('davit')) {
        return _ResolvedAccountIdentity(
          userId: 'user_farmer_3',
          farmerId: 'farmer_3',
          farmName: explicitFarmName ?? 'ალაზნის ბაღები',
          name: explicitName ?? 'დავით ნოზაძე',
          phone: explicitPhone ?? '+995 599 44 55 66',
          avatarUrl:
              'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&auto=format&fit=crop&q=80',
          coverUrl:
              'https://images.unsplash.com/photo-1464965911861-746a04b4bca6?w=1000&auto=format&fit=crop&q=80',
        );
      }
      if (normalizedEmail == 'example@gmail.com' || normalizedEmail.isEmpty) {
        final resolvedName = explicitName ?? 'გიორგი ბერიძე';
        return _ResolvedAccountIdentity(
          userId: 'user_farmer_2',
          farmerId: 'farmer_2',
          farmName: explicitFarmName ?? 'გიორგის ფერმა',
          name: resolvedName,
          phone: explicitPhone ?? '+995 599 11 22 33',
          avatarUrl:
              'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&auto=format&fit=crop&q=80',
          coverUrl:
              'https://images.unsplash.com/photo-1500937386664-56d1dfef3854?w=1000&auto=format&fit=crop&q=80',
        );
      }
      final slug = normalizedEmail.replaceAll(RegExp(r'[^a-z0-9]'), '_');
      final resolvedName = explicitName ?? normalizedEmail.split('@').first;
      return _ResolvedAccountIdentity(
        userId: 'user_farmer_$slug',
        farmerId: 'farmer_$slug',
        farmName: explicitFarmName ?? '$resolvedName-ის მეურნეობა',
        name: resolvedName,
        phone: explicitPhone ?? '+995 599 00 00 00',
      );
    }

    if (normalizedEmail.contains('client@agrokera.ge')) {
      return _ResolvedAccountIdentity(
        userId: 'user_client_1',
        name: explicitName ?? 'შპს "გემრიელი რესტორანი"',
        phone: explicitPhone ?? '+995 599 12 34 56',
      );
    }

    final slug = normalizedEmail.isEmpty || normalizedEmail == 'example@gmail.com'
        ? '1'
        : normalizedEmail.replaceAll(RegExp(r'[^a-z0-9]'), '_');
    return _ResolvedAccountIdentity(
      userId: 'user_client_$slug',
      name: explicitName ?? 'გიორგი ბერიძე',
      phone: explicitPhone ?? '+995 599 12 34 56',
    );
  }

  /// Restores persisted user session from FlutterSecureStorage
  Future<void> restoreSession() async {
    final storage = ref.read(secureStorageProvider);
    final saved = await storage.readSession();
    final token = saved['token'];
    if (token != null && token.isNotEmpty) {
      final roleStr = saved['role'];
      final role = roleStr == 'farmer'
          ? UserRole.farmer
          : roleStr == 'customer'
              ? UserRole.customer
              : UserRole.guest;
      if (role != UserRole.guest) {
        final savedEmail = saved['email'] ?? 'example@gmail.com';
        final fallback = _resolveIdentity(
          email: savedEmail,
          role: role,
          explicitName: saved['name'],
          explicitPhone: saved['phone'],
          explicitFarmName: saved['farmName'],
        );
        state = AuthState(
          isAuthenticated: true,
          userId: saved['userId'] ?? fallback.userId,
          farmerId: saved['farmerId'] ?? fallback.farmerId,
          farmName: saved['farmName'] ?? fallback.farmName,
          userName: saved['name'] ?? fallback.name,
          userPhone: saved['phone'] ?? fallback.phone,
          userEmail: savedEmail,
          farmCoverUrl: saved['farmCoverUrl'],
          userAvatarUrl: saved['userAvatarUrl'] ?? fallback.avatarUrl,
          role: role,
          kycStatus: KycStatus.fromString(saved['kycStatus']),
        );
      }
    }
  }

  void login({
    String? name,
    String? phone,
    String email = 'example@gmail.com',
    String? farmName,
    UserRole role = UserRole.customer,
  }) {
    final resolved = _resolveIdentity(
      email: email,
      role: role,
      explicitName: name,
      explicitPhone: phone,
      explicitFarmName: farmName,
    );

    state = state.copyWith(
      isAuthenticated: true,
      userId: resolved.userId,
      farmerId: resolved.farmerId,
      farmName: resolved.farmName,
      userName: resolved.name,
      userPhone: resolved.phone,
      userEmail: email,
      userAvatarUrl: resolved.avatarUrl,
      farmCoverUrl: resolved.coverUrl ?? state.farmCoverUrl,
      role: role,
      kycStatus: KycStatus.verified,
    );

    // Immediately persist session so reopening the app never loses auth state
    unawaited(
      ref.read(secureStorageProvider).saveSession(
            token: 'ak_session_${resolved.userId}',
            userId: resolved.userId,
            farmerId: resolved.farmerId,
            farmName: resolved.farmName,
            role: role.name,
            name: resolved.name,
            phone: resolved.phone,
            email: email,
            kycStatus: KycStatus.verified.apiValue,
          ),
    );

    unawaited(_syncLoginWithBackend(
      name: resolved.name,
      phone: phone,
      email: email,
      farmName: resolved.farmName,
      role: role,
    ));
  }

  /// Completes 5-step Farmer Onboarding and registers an isolated FarmerProfile
  void completeFarmerOnboarding({
    required String farmName,
    required String region,
    required String city,
    required String address,
    String? coverUrl,
  }) {
    final name = state.userName ?? 'ფერმერი';
    final email = state.userEmail ?? 'farmer@agrokera.ge';
    final cleanFarmName = farmName.trim().isNotEmpty
        ? farmName.trim()
        : '$name-ის მეურნეობა';
    final resolved = _resolveIdentity(
      email: email,
      role: UserRole.farmer,
      explicitName: name,
      explicitPhone: state.userPhone,
      explicitFarmName: cleanFarmName,
    );

    state = state.copyWith(
      isAuthenticated: true,
      userId: resolved.userId,
      farmerId: resolved.farmerId,
      farmName: cleanFarmName,
      userName: resolved.name,
      userPhone: resolved.phone,
      userEmail: email,
      farmCoverUrl: coverUrl,
      role: UserRole.farmer,
      kycStatus: KycStatus.verified,
    );

    unawaited(
      ref.read(secureStorageProvider).saveSession(
            token: 'ak_session_${resolved.userId}',
            userId: resolved.userId,
            farmerId: resolved.farmerId,
            farmName: cleanFarmName,
            role: UserRole.farmer.name,
            name: resolved.name,
            phone: resolved.phone,
            email: email,
            kycStatus: KycStatus.verified.apiValue,
          ),
    );

    unawaited(_syncRegisterWithBackend(
      name: resolved.name,
      phone: state.userPhone,
      email: email,
      farmName: cleanFarmName,
      region: region,
      city: city,
      address: address,
      coverUrl: coverUrl,
      role: UserRole.farmer,
    ));
  }

  /// Temporarily stores the user's name and email during the multi-step registration wizard
  /// without marking the user as authenticated until role selection & verification finish.
  void savePendingRegistrationDraft({
    required String name,
    required String email,
  }) {
    state = state.copyWith(
      isAuthenticated: false,
      role: UserRole.guest,
      userName: name,
      userEmail: email,
    );
  }

  void register({
    required UserRole role,
    String name = 'ახალი მომხმარებელი',
    String? phone,
    String email = 'example@gmail.com',
    String? farmName,
  }) {
    final resolved = _resolveIdentity(
      email: email,
      role: role,
      explicitName: name,
      explicitPhone: phone,
      explicitFarmName: farmName,
    );
    final initialKyc =
        role == UserRole.farmer ? KycStatus.pendingReview : KycStatus.verified;

    state = state.copyWith(
      isAuthenticated: true,
      userId: resolved.userId,
      farmerId: resolved.farmerId,
      farmName: resolved.farmName,
      userName: resolved.name,
      userPhone: resolved.phone,
      userEmail: email,
      role: role,
      kycStatus: initialKyc,
    );

    // Immediately persist session so reopening the app never loses auth state
    unawaited(
      ref.read(secureStorageProvider).saveSession(
            token: 'ak_session_${resolved.userId}',
            userId: resolved.userId,
            farmerId: resolved.farmerId,
            farmName: resolved.farmName,
            role: role.name,
            name: resolved.name,
            phone: resolved.phone,
            email: email,
            kycStatus: initialKyc.apiValue,
          ),
    );

    unawaited(_syncRegisterWithBackend(
      name: resolved.name,
      phone: phone,
      email: email,
      farmName: resolved.farmName,
      role: role,
    ));
  }

  Future<void> submitKycDocuments({
    required String idCardFrontUrl,
    required String idCardBackUrl,
    String? farmName,
    String? region,
    String? address,
  }) async {
    state = state.copyWith(kycStatus: KycStatus.pendingReview);
    final storage = ref.read(secureStorageProvider);
    await storage.updateKycStatus(KycStatus.pendingReview.apiValue);

    try {
      final api = ref.read(apiClientProvider);
      final uid = state.userId ?? 'user_farmer_2';
      await api.patch('/api/profile/$uid', data: {
        'verificationStatus': 'PENDING_REVIEW',
        'idCardFrontUrl': idCardFrontUrl,
        'idCardBackUrl': idCardBackUrl,
        'farmName': ?farmName,
        'region': ?region,
        'address': ?address,
      });
    } catch (_) {
      // Offline resilient fallback
    }
  }

  Future<void> updateKycStatus(KycStatus newStatus) async {
    state = state.copyWith(kycStatus: newStatus);
    final storage = ref.read(secureStorageProvider);
    await storage.updateKycStatus(newStatus.apiValue);

    try {
      final api = ref.read(apiClientProvider);
      final uid = state.userId ?? 'user_farmer_2';
      await api.patch('/api/profile/$uid', data: {
        'verificationStatus': newStatus.apiValue,
      });
    } catch (_) {}
  }

  Future<void> updateFarmCoverUrl(String coverUrl) async {
    state = state.copyWith(farmCoverUrl: coverUrl);
    final storage = ref.read(secureStorageProvider);
    final saved = await storage.readSession();
    if (saved['userId'] != null) {
      await storage.saveSession(
        token: saved['token'] ?? '',
        userId: saved['userId']!,
        farmerId: saved['farmerId'] ?? state.farmerId,
        farmName: saved['farmName'] ?? state.farmName,
        farmCoverUrl: coverUrl,
        role: saved['role'] ?? state.role.name,
        name: saved['name'] ?? state.userName ?? '',
        phone: saved['phone'] ?? state.userPhone ?? '',
        email: saved['email'] ?? state.userEmail,
        kycStatus: saved['kycStatus'] ?? state.kycStatus.apiValue,
      );
    }
    try {
      final api = ref.read(apiClientProvider);
      final uid = state.userId ?? 'user_farmer_2';
      await api.patch('/api/profile/$uid', data: {
        'coverUrl': coverUrl,
      });
    } catch (_) {}
  }

  Future<void> updateUserAvatarUrl(String avatarUrl) async {
    state = state.copyWith(userAvatarUrl: avatarUrl);
    final storage = ref.read(secureStorageProvider);
    final saved = await storage.readSession();
    if (saved['userId'] != null) {
      await storage.saveSession(
        token: saved['token'] ?? '',
        userId: saved['userId']!,
        farmerId: saved['farmerId'] ?? state.farmerId,
        farmName: saved['farmName'] ?? state.farmName,
        farmCoverUrl: saved['farmCoverUrl'] ?? state.farmCoverUrl,
        userAvatarUrl: avatarUrl,
        role: saved['role'] ?? state.role.name,
        name: saved['name'] ?? state.userName ?? '',
        phone: saved['phone'] ?? state.userPhone ?? '',
        email: saved['email'] ?? state.userEmail,
        kycStatus: saved['kycStatus'] ?? state.kycStatus.apiValue,
      );
    }
    try {
      final api = ref.read(apiClientProvider);
      final uid = state.userId;
      if (uid != null) {
        await api.patch('/api/profile/$uid', data: {
          'avatarUrl': avatarUrl,
        });
      }
    } catch (_) {}
  }

  /// Updates current user email in auth state and persists to secure storage
  void updateEmail(String newEmail) {
    final cleanEmail = newEmail.trim();
    state = state.copyWith(userEmail: cleanEmail);
    final storage = ref.read(secureStorageProvider);
    unawaited(storage.readSession().then((saved) {
      if (saved['userId'] != null) {
        storage.saveSession(
          token: saved['token'] ?? '',
          userId: saved['userId']!,
          farmerId: saved['farmerId'] ?? state.farmerId,
          farmName: saved['farmName'] ?? state.farmName,
          farmCoverUrl: state.farmCoverUrl,
          role: saved['role'] ?? state.role.name,
          name: saved['name'] ?? state.userName ?? '',
          phone: saved['phone'] ?? state.userPhone ?? '',
          email: cleanEmail,
          kycStatus: saved['kycStatus'] ?? state.kycStatus.apiValue,
        );
      }
    }));
  }

  void logout() {
    state = const AuthState(isAuthenticated: false);
    unawaited(ref.read(secureStorageProvider).clearSession());
  }

  /// Sends a 5-digit OTP verification code to the specified Gmail/Email via backend SMTP
  Future<bool> sendEmailOtp(String email) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.post('/api/auth/send-otp', data: {'email': email.trim()});
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Verifies the 5-digit OTP code entered by the user against backend
  Future<String?> verifyEmailOtp({
    required String email,
    required String code,
  }) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.post('/api/auth/verify-otp', data: {
        'email': email.trim(),
        'code': code.trim(),
      });
      return null;
    } catch (e) {
      return 'შეყვანილი ვერიფიკაციის კოდი არასწორია ან ვადა გაუვიდა';
    }
  }

  Future<void> _syncLoginWithBackend({
    required String name,
    String? phone,
    required String email,
    String? farmName,
    required UserRole role,
  }) async {
    try {
      final storage = ref.read(secureStorageProvider);
      final api = ref.read(apiClientProvider);
      final response = await api.post<Map<String, dynamic>>(
        '/api/auth/login',
        data: {
          'name': name,
          'phone': ?phone,
          'email': email,
          'farmName': ?farmName,
          'role': role == UserRole.farmer ? 'FARMER' : 'CLIENT',
        },
      );
      final data = response.data;
      if (data != null && state.isAuthenticated) {
        final user = data['user'] as Map<String, dynamic>?;
        final farmerProfile = user?['farmerProfile'] as Map<String, dynamic>?;
        final token = data['token'] as String? ?? 'ak_token';
        final userId = user?['id'] as String? ?? state.userId ?? 'user_1';
        final farmerId = farmerProfile?['id'] as String? ?? state.farmerId;
        final serverFarmName =
            farmerProfile?['farmName'] as String? ?? state.farmName ?? farmName;
        final serverFullName = user?['fullName'] as String? ?? state.userName ?? name;
        final serverPhone =
            user?['phoneNumber'] as String? ?? state.userPhone ?? phone ?? '+995 599 11 22 33';
        final serverEmail = user?['email'] as String? ?? state.userEmail ?? email;
        final serverAvatarUrl = farmerProfile?['avatarUrl'] as String?;
        final serverCoverUrl = farmerProfile?['coverUrl'] as String?;
        final kycStr = user?['verificationStatus'] as String?;

        state = state.copyWith(
          userId: userId,
          farmerId: farmerId,
          farmName: serverFarmName,
          userName: serverFullName,
          userPhone: serverPhone,
          userEmail: serverEmail,
          userAvatarUrl: serverAvatarUrl ?? state.userAvatarUrl,
          farmCoverUrl: serverCoverUrl ?? state.farmCoverUrl,
          kycStatus: KycStatus.fromString(kycStr),
        );

        await storage.saveSession(
          token: token,
          userId: userId,
          farmerId: farmerId,
          farmName: serverFarmName,
          role: role.name,
          name: serverFullName,
          phone: serverPhone,
          email: serverEmail,
          kycStatus: kycStr ?? 'VERIFIED',
        );
      }
    } catch (_) {
      // Save local session if offline
      await ref.read(secureStorageProvider).saveSession(
            token: 'local_token',
            userId: state.userId ?? 'user_local',
            farmerId: state.farmerId,
            farmName: state.farmName ?? farmName,
            role: role.name,
            name: state.userName ?? name,
            phone: state.userPhone ?? phone ?? '+995 599 11 22 33',
            email: email,
          );
    }
  }

  Future<void> _syncRegisterWithBackend({
    required String name,
    String? phone,
    required String email,
    String? farmName,
    String? region,
    String? city,
    String? address,
    String? coverUrl,
    required UserRole role,
  }) async {
    try {
      final storage = ref.read(secureStorageProvider);
      final api = ref.read(apiClientProvider);
      final response = await api.post<Map<String, dynamic>>(
        '/api/auth/register',
        data: {
          'fullName': name,
          'phoneNumber': ?phone,
          'email': email,
          'farmName': ?farmName,
          'region': ?region,
          'city': ?city,
          'address': ?address,
          'coverUrl': ?coverUrl,
          'role': role == UserRole.farmer ? 'FARMER' : 'CLIENT',
        },
      );
      final data = response.data;
      if (data != null && state.isAuthenticated) {
        final user = data['user'] as Map<String, dynamic>?;
        final farmerProfile = user?['farmerProfile'] as Map<String, dynamic>?;
        final token = data['token'] as String? ?? 'ak_token';
        final userId = user?['id'] as String? ?? state.userId ?? 'user_1';
        final farmerId = farmerProfile?['id'] as String? ?? state.farmerId;
        final serverFarmName =
            farmerProfile?['farmName'] as String? ?? state.farmName ?? farmName;
        final serverCoverUrl =
            farmerProfile?['coverUrl'] as String? ?? state.farmCoverUrl ?? coverUrl;
        final serverFullName = user?['fullName'] as String? ?? state.userName ?? name;
        final serverPhone =
            user?['phoneNumber'] as String? ?? state.userPhone ?? phone ?? '+995 599 00 00 00';
        final serverEmail = user?['email'] as String? ?? state.userEmail ?? email;
        final kycStr = user?['verificationStatus'] as String?;

        state = state.copyWith(
          userId: userId,
          farmerId: farmerId,
          farmName: serverFarmName,
          userName: serverFullName,
          userPhone: serverPhone,
          userEmail: serverEmail,
          farmCoverUrl: serverCoverUrl,
          kycStatus: KycStatus.fromString(kycStr),
        );

        await storage.saveSession(
          token: token,
          userId: userId,
          farmerId: farmerId,
          farmName: serverFarmName,
          role: role.name,
          name: serverFullName,
          phone: serverPhone,
          email: serverEmail,
          kycStatus: kycStr ?? 'VERIFIED',
        );
      }
    } catch (_) {
      await ref.read(secureStorageProvider).saveSession(
            token: 'local_token',
            userId: state.userId ?? 'user_local',
            farmerId: state.farmerId,
            farmName: state.farmName ?? farmName,
            role: role.name,
            name: state.userName ?? name,
            phone: state.userPhone ?? phone ?? '+995 599 00 00 00',
            email: email,
          );
    }
  }
}

final authStateProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
