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
  final String? userName;
  final String? userPhone;
  final String? userEmail;
  final UserRole role;
  final KycStatus kycStatus;

  const AuthState({
    this.isAuthenticated = false,
    this.userId,
    this.farmerId,
    this.userName,
    this.userPhone,
    this.userEmail,
    this.role = UserRole.guest,
    this.kycStatus = KycStatus.verified,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? userId,
    String? farmerId,
    String? userName,
    String? userPhone,
    String? userEmail,
    UserRole? role,
    KycStatus? kycStatus,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userId: userId ?? this.userId,
      farmerId: farmerId ?? this.farmerId,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      userEmail: userEmail ?? this.userEmail,
      role: role ?? this.role,
      kycStatus: kycStatus ?? this.kycStatus,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    unawaited(Future.microtask(restoreSession));
    return const AuthState(isAuthenticated: false);
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
        state = AuthState(
          isAuthenticated: true,
          userId: saved['userId'] ?? (role == UserRole.farmer ? 'user_farmer_2' : 'user_client_1'),
          farmerId: saved['farmerId'] ?? (role == UserRole.farmer ? 'farmer_2' : null),
          userName: saved['name'] ?? 'გიორგი ბერიძე',
          userPhone: saved['phone'] ?? '+995 599 12 34 56',
          userEmail: saved['email'] ?? 'example@gmail.com',
          role: role,
          kycStatus: KycStatus.fromString(saved['kycStatus']),
        );
      }
    }
  }

  void login({
    String name = 'გიორგი ბერიძე',
    String phone = '+995 599 12 34 56',
    String email = 'example@gmail.com',
    UserRole role = UserRole.customer,
  }) {
    final defaultUserId = role == UserRole.farmer ? 'user_farmer_2' : 'user_client_1';
    final defaultFarmerId = role == UserRole.farmer ? 'farmer_2' : null;

    state = state.copyWith(
      isAuthenticated: true,
      userId: defaultUserId,
      farmerId: defaultFarmerId,
      userName: name,
      userPhone: phone,
      userEmail: email,
      role: role,
      kycStatus: KycStatus.verified,
    );

    // Immediately persist session so reopening the app never loses auth state
    unawaited(
      ref.read(secureStorageProvider).saveSession(
            token: 'ak_session_$defaultUserId',
            userId: defaultUserId,
            farmerId: defaultFarmerId,
            role: role.name,
            name: name,
            phone: phone,
            email: email,
            kycStatus: KycStatus.verified.apiValue,
          ),
    );

    unawaited(_syncLoginWithBackend(
      name: name,
      phone: phone,
      email: email,
      role: role,
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
    String phone = '+995 599 00 00 00',
    String email = 'example@gmail.com',
  }) {
    final defaultUserId = role == UserRole.farmer ? 'user_farmer_2' : 'user_client_1';
    final defaultFarmerId = role == UserRole.farmer ? 'farmer_2' : null;
    final initialKyc =
        role == UserRole.farmer ? KycStatus.pendingReview : KycStatus.verified;

    state = state.copyWith(
      isAuthenticated: true,
      userId: defaultUserId,
      farmerId: defaultFarmerId,
      userName: name,
      userPhone: phone,
      userEmail: email,
      role: role,
      kycStatus: initialKyc,
    );

    // Immediately persist session so reopening the app never loses auth state
    unawaited(
      ref.read(secureStorageProvider).saveSession(
            token: 'ak_session_$defaultUserId',
            userId: defaultUserId,
            farmerId: defaultFarmerId,
            role: role.name,
            name: name,
            phone: phone,
            email: email,
            kycStatus: initialKyc.apiValue,
          ),
    );

    unawaited(_syncRegisterWithBackend(
      name: name,
      phone: phone,
      email: email,
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
    required String phone,
    required String email,
    required UserRole role,
  }) async {
    try {
      final storage = ref.read(secureStorageProvider);
      final api = ref.read(apiClientProvider);
      final response = await api.post<Map<String, dynamic>>(
        '/api/auth/login',
        data: {
          'name': name,
          'phone': phone,
          'email': email,
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
        final kycStr = user?['verificationStatus'] as String?;

        state = state.copyWith(
          userId: userId,
          farmerId: farmerId,
          kycStatus: KycStatus.fromString(kycStr),
        );

        await storage.saveSession(
          token: token,
          userId: userId,
          farmerId: farmerId,
          role: role.name,
          name: state.userName ?? name,
          phone: state.userPhone ?? phone,
          email: state.userEmail ?? email,
          kycStatus: kycStr ?? 'VERIFIED',
        );
      }
    } catch (_) {
      // Save local session if offline
      await ref.read(secureStorageProvider).saveSession(
            token: 'local_token',
            userId: state.userId ?? 'user_local',
            farmerId: state.farmerId,
            role: role.name,
            name: name,
            phone: phone,
            email: email,
          );
    }
  }

  Future<void> _syncRegisterWithBackend({
    required String name,
    required String phone,
    required String email,
    required UserRole role,
  }) async {
    try {
      final storage = ref.read(secureStorageProvider);
      final api = ref.read(apiClientProvider);
      final response = await api.post<Map<String, dynamic>>(
        '/api/auth/register',
        data: {
          'fullName': name,
          'phoneNumber': phone,
          'email': email,
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
        final kycStr = user?['verificationStatus'] as String?;

        state = state.copyWith(
          userId: userId,
          farmerId: farmerId,
          kycStatus: KycStatus.fromString(kycStr),
        );

        await storage.saveSession(
          token: token,
          userId: userId,
          farmerId: farmerId,
          role: role.name,
          name: name,
          phone: phone,
          email: email,
          kycStatus: kycStr ?? 'PENDING_REVIEW',
        );
      }
    } catch (_) {
      await ref.read(secureStorageProvider).saveSession(
            token: 'local_token',
            userId: state.userId ?? 'user_local',
            farmerId: state.farmerId,
            role: role.name,
            name: name,
            phone: phone,
            email: email,
          );
    }
  }
}

final authStateProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
