import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../services/push_notification_service.dart';
import '../storage/secure_storage_service.dart';
import '../../features/marketplace/presentation/providers/marketplace_provider.dart';
import '../../features/profile/presentation/providers/user_address_provider.dart';
import 'auth_models.dart';
import 'auth_repository.dart';
import 'mock_account_resolver.dart';

export 'auth_models.dart';

/// Session/auth state manager.
///
/// Responsibilities are delegated to:
/// * [AuthRepository] — all HTTP calls (login, register, OTP, profile, upload, FCM)
/// * [MockAccountResolver] — optimistic/offline identity for demo & new accounts
/// * [SecureStorageService] — session persistence
class AuthNotifier extends Notifier<AuthState> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);
  SecureStorageService get _storage => ref.read(secureStorageProvider);

  @override
  AuthState build() {
    unawaited(Future.microtask(restoreSession));
    return const AuthState(isAuthenticated: false);
  }

  // ---------------------------------------------------------------------------
  // Session lifecycle
  // ---------------------------------------------------------------------------

  /// Restores persisted user session from FlutterSecureStorage
  Future<void> restoreSession() async {
    final saved = await _storage.readSession();
    if (!ref.mounted) return;
    final token = saved['token'];
    if (token == null || token.isEmpty) return;

    final role = UserRole.fromStorage(saved['role']);
    if (role == UserRole.guest) return;

    final savedEmail = saved['email'] ?? 'example@gmail.com';
    final savedAddress = await _storage.readActiveAddress();
    if (!ref.mounted) return;
    final fallback = MockAccountResolver.resolve(
      email: savedEmail,
      role: role,
      explicitName: saved['name'],
      explicitPhone: saved['phone'],
      explicitFarmName: saved['farmName'],
    );
    final rawSavedUserId = saved['userId'];
    final normalizedEmail = savedEmail.trim().toLowerCase();
    final isStaleSharedClientId = rawSavedUserId == 'user_client_1' &&
        normalizedEmail.isNotEmpty &&
        normalizedEmail != 'client@agrokera.ge' &&
        normalizedEmail != 'example@gmail.com';
    final effectiveUserId = (rawSavedUserId == null ||
            rawSavedUserId.isEmpty ||
            isStaleSharedClientId)
        ? fallback.userId
        : rawSavedUserId;

    state = AuthState(
      isAuthenticated: true,
      userId: effectiveUserId,
      farmerId: role == UserRole.farmer
          ? (saved['farmerId'] ?? fallback.farmerId)
          : null,
      farmName: role == UserRole.farmer
          ? (saved['farmName'] ?? fallback.farmName)
          : null,
      userName: isStaleSharedClientId
          ? fallback.name
          : (saved['name'] ?? fallback.name),
      userPhone: isStaleSharedClientId
          ? fallback.phone
          : (saved['phone'] ?? fallback.phone),
      userEmail: savedEmail,
      farmCoverUrl: role == UserRole.farmer
          ? (saved['farmCoverUrl'] ?? fallback.coverUrl)
          : null,
      userAvatarUrl: isStaleSharedClientId
          ? fallback.avatarUrl
          : (saved['userAvatarUrl'] ?? fallback.avatarUrl),
      userAddress: savedAddress,
      role: role,
      kycStatus: KycStatus.fromString(saved['kycStatus']),
    );
    if (isStaleSharedClientId) {
      unawaited(_resaveSession());
    }
    unawaited(syncFcmToken());
    unawaited(_syncProfileFromBackend());
  }

  Future<void> _syncProfileFromBackend() async {
    final uid = state.userId;
    if (uid == null || uid.isEmpty) return;
    try {
      final user = await _repo.getProfile(uid);
      if (!state.isAuthenticated) return;

      final currentEmail = state.userEmail?.trim().toLowerCase();
      final serverEmail = (user?['email'] as String?)?.trim().toLowerCase();

      // If stored userId does not exist or belongs to a different email on the server,
      // re-authenticate by email so strict per-account isolation is enforced.
      if (user == null ||
          (currentEmail != null &&
              currentEmail.isNotEmpty &&
              currentEmail != 'example@gmail.com' &&
              serverEmail != null &&
              serverEmail != currentEmail)) {
        if (currentEmail != null && currentEmail.isNotEmpty) {
          await _syncLoginWithBackend(
            name: state.userName ?? currentEmail.split('@').first,
            phone: state.userPhone,
            email: currentEmail,
            farmName: state.farmName,
            role: state.role,
          );
        }
        return;
      }

      final farmerProfile = user['farmerProfile'] as Map<String, dynamic>?;
      final serverFullName = user['fullName'] as String?;
      final serverFarmName = farmerProfile?['farmName'] as String?;
      final serverAvatarUrl = (farmerProfile?['avatarUrl'] as String?) ??
          (user['avatarUrl'] as String?);
      final serverCoverUrl = farmerProfile?['coverUrl'] as String?;

      final hasNewName =
          serverFullName != null && serverFullName.trim().isNotEmpty;
      final hasNewFarmName =
          serverFarmName != null && serverFarmName.trim().isNotEmpty;
      final hasNewAvatar =
          serverAvatarUrl != null && serverAvatarUrl.trim().isNotEmpty;
      final hasNewCover =
          serverCoverUrl != null && serverCoverUrl.trim().isNotEmpty;

      if (hasNewName || hasNewFarmName || hasNewAvatar || hasNewCover) {
        state = state.copyWith(
          userName: hasNewName ? serverFullName : state.userName,
          farmName: hasNewFarmName ? serverFarmName : state.farmName,
          userAvatarUrl: hasNewAvatar ? serverAvatarUrl : state.userAvatarUrl,
          farmCoverUrl: hasNewCover ? serverCoverUrl : state.farmCoverUrl,
        );
        if (state.isFarmer && (hasNewAvatar || hasNewCover)) {
          ref.read(marketplaceProvider.notifier).updateFarmerMedia(
                farmerId: state.farmerId,
                avatarUrl: hasNewAvatar ? serverAvatarUrl : null,
                coverUrl: hasNewCover ? serverCoverUrl : null,
              );
        }
        await _resaveSession();
      }
    } catch (_) {}
  }

  Future<void> syncFcmToken([String? token]) async {
    var effectiveToken = token ?? PushNotificationService().fcmToken;
    if (effectiveToken == null || effectiveToken.isEmpty) {
      effectiveToken = await PushNotificationService().refreshToken();
    }
    final uid = state.userId;
    if (uid == null || effectiveToken == null || effectiveToken.isEmpty) return;
    try {
      await _repo.syncFcmToken(userId: uid, fcmToken: effectiveToken);
    } catch (_) {}
  }

  void login({
    String? name,
    String? phone,
    String email = 'example@gmail.com',
    String? farmName,
    UserRole role = UserRole.customer,
  }) {
    final resolved = MockAccountResolver.resolve(
      email: email,
      role: role,
      explicitName: name,
      explicitPhone: phone,
      explicitFarmName: farmName,
    );

    final isSameAccount = state.userId == resolved.userId;
    state = AuthState(
      isAuthenticated: true,
      userId: resolved.userId,
      farmerId: role == UserRole.farmer ? resolved.farmerId : null,
      farmName: role == UserRole.farmer ? resolved.farmName : null,
      userName: resolved.name,
      userPhone: resolved.phone,
      userEmail: email,
      userAvatarUrl:
          resolved.avatarUrl ?? (isSameAccount ? state.userAvatarUrl : null),
      farmCoverUrl: role == UserRole.farmer
          ? (resolved.coverUrl ?? (isSameAccount ? state.farmCoverUrl : null))
          : null,
      userAddress: isSameAccount ? state.userAddress : null,
      role: role,
      kycStatus: KycStatus.verified,
    );

    if (!isSameAccount) {
      unawaited(
        Future.microtask(() {
          if (ref.mounted) ref.invalidate(userAddressProvider);
        }),
      );
    }

    // Immediately persist session so reopening the app never loses auth state
    unawaited(_saveOptimisticSession(
      resolved,
      role: role,
      email: email,
      kycStatus: KycStatus.verified,
    ));
    unawaited(syncFcmToken());

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
    final cleanFarmName =
        farmName.trim().isNotEmpty ? farmName.trim() : '$name-ის მეურნეობა';
    final resolved = MockAccountResolver.resolve(
      email: email,
      role: UserRole.farmer,
      explicitName: name,
      explicitPhone: state.userPhone,
      explicitFarmName: cleanFarmName,
    );

    state = AuthState(
      isAuthenticated: true,
      userId: resolved.userId,
      farmerId: resolved.farmerId,
      farmName: cleanFarmName,
      userName: resolved.name,
      userPhone: resolved.phone,
      userEmail: email,
      userAvatarUrl: state.userAvatarUrl ?? resolved.avatarUrl,
      farmCoverUrl: coverUrl ?? resolved.coverUrl,
      role: UserRole.farmer,
      kycStatus: KycStatus.verified,
    );

    unawaited(_saveOptimisticSession(
      resolved,
      role: UserRole.farmer,
      email: email,
      kycStatus: KycStatus.verified,
      farmNameOverride: cleanFarmName,
    ));

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
    unawaited(syncFcmToken());
  }

  /// Temporarily stores the user's name and email during the multi-step registration wizard
  /// without marking the user as authenticated until role selection & verification finish.
  void savePendingRegistrationDraft({
    required String name,
    required String email,
  }) {
    state = AuthState(
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
    final resolved = MockAccountResolver.resolve(
      email: email,
      role: role,
      explicitName: name,
      explicitPhone: phone,
      explicitFarmName: farmName,
    );
    final initialKyc =
        role == UserRole.farmer ? KycStatus.pendingReview : KycStatus.verified;

    // Ensure clients never inherit a leftover or default delivery address
    if (role == UserRole.customer) {
      unawaited(ref.read(userAddressProvider.notifier).clearAddresses());
    }

    state = AuthState(
      isAuthenticated: true,
      userId: resolved.userId,
      farmerId: role == UserRole.farmer ? resolved.farmerId : null,
      farmName: role == UserRole.farmer ? resolved.farmName : null,
      userName: resolved.name,
      userPhone: resolved.phone,
      userEmail: email,
      userAvatarUrl: resolved.avatarUrl,
      farmCoverUrl: role == UserRole.farmer ? resolved.coverUrl : null,
      role: role,
      kycStatus: initialKyc,
    );

    // Immediately persist session so reopening the app never loses auth state
    unawaited(_saveOptimisticSession(
      resolved,
      role: role,
      email: email,
      kycStatus: initialKyc,
    ));

    unawaited(_syncRegisterWithBackend(
      name: resolved.name,
      phone: phone,
      email: email,
      farmName: resolved.farmName,
      role: role,
    ));
    unawaited(syncFcmToken());
  }

  void logout() {
    final oldUid = state.userId;
    state = const AuthState(isAuthenticated: false);
    unawaited(_storage.clearSession());
    unawaited(ref.read(userAddressProvider.notifier).clearAddresses());
    if (oldUid != null && oldUid.isNotEmpty) {
      unawaited(_repo.syncFcmToken(userId: oldUid, fcmToken: ''));
    }
  }

  // ---------------------------------------------------------------------------
  // Email OTP
  // ---------------------------------------------------------------------------

  /// Sends a 5-digit OTP verification code to the specified Gmail/Email via backend SMTP
  Future<bool> sendEmailOtp(String email) async {
    try {
      await _repo.sendEmailOtp(email);
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
      await _repo.verifyEmailOtp(email: email, code: code);
      return null;
    } catch (_) {
      return 'შეყვანილი ვერიფიკაციის კოდი არასწორია ან ვადა გაუვიდა';
    }
  }

  // ---------------------------------------------------------------------------
  // KYC
  // ---------------------------------------------------------------------------

  Future<void> submitKycDocuments({
    required String idCardFrontUrl,
    required String idCardBackUrl,
    String? farmName,
    String? region,
    String? address,
  }) async {
    state = state.copyWith(kycStatus: KycStatus.pendingReview);
    await _storage.updateKycStatus(KycStatus.pendingReview.apiValue);

    await _patchProfileSilently({
      'verificationStatus': KycStatus.pendingReview.apiValue,
      'idCardFrontUrl': idCardFrontUrl,
      'idCardBackUrl': idCardBackUrl,
      'farmName': ?farmName,
      'region': ?region,
      'address': ?address,
    }, fallbackUserId: state.farmerId ?? 'user_farmer_2');
  }

  Future<void> updateKycStatus(KycStatus newStatus) async {
    state = state.copyWith(kycStatus: newStatus);
    await _storage.updateKycStatus(newStatus.apiValue);
    await _patchProfileSilently(
      {'verificationStatus': newStatus.apiValue},
      fallbackUserId: state.farmerId ?? 'user_farmer_2',
    );
  }

  // ---------------------------------------------------------------------------
  // Profile media & fields
  // ---------------------------------------------------------------------------

  Future<void> updateFarmCoverUrl(
    String coverUrl, {
    bool syncBackend = true,
  }) async {
    state = state.copyWith(farmCoverUrl: coverUrl);
    if (state.isFarmer) {
      ref.read(marketplaceProvider.notifier).updateFarmerMedia(
            farmerId: state.farmerId,
            coverUrl: coverUrl,
          );
    }
    await _resaveSession();
    if (syncBackend) {
      await _patchProfileSilently(
        {'coverUrl': coverUrl},
        fallbackUserId: state.farmerId ?? 'user_farmer_2',
      );
    }
  }

  Future<void> updateUserAvatarUrl(
    String avatarUrl, {
    bool syncBackend = true,
  }) async {
    state = state.copyWith(userAvatarUrl: avatarUrl);
    if (state.isFarmer) {
      ref.read(marketplaceProvider.notifier).updateFarmerMedia(
            farmerId: state.farmerId,
            avatarUrl: avatarUrl,
          );
    }
    await _resaveSession();
    if (syncBackend) {
      await _patchProfileSilently({'avatarUrl': avatarUrl});
    }
  }

  /// Uploads user avatar to cloud storage and persists to backend profile and local storage
  Future<bool> uploadAvatar(XFile file) => _uploadImage(
        file,
        folder: 'avatars',
        apply: updateUserAvatarUrl,
      );

  /// Uploads farm cover photo to cloud storage and persists to backend profile and local storage
  Future<bool> uploadFarmCover(XFile file) => _uploadImage(
        file,
        folder: 'covers',
        apply: updateFarmCoverUrl,
      );

  /// Updates current user email in auth state and persists to secure storage
  void updateEmail(String newEmail) {
    state = state.copyWith(userEmail: newEmail.trim());
    unawaited(_resaveSession());
  }

  /// Updates current user personal delivery address in auth state and persists to secure storage
  void updateUserAddress(String newAddress) {
    final clean = newAddress.trim();
    state = state.copyWith(userAddress: clean);
    unawaited(_storage.saveActiveAddress(clean));
    if (state.isAuthenticated && !state.isFarmer) {
      unawaited(_patchProfileSilently({'address': clean}));
    }
  }

  /// Updates public farm pickup location for the logged-in farmer in backend profile
  Future<void> updateFarmLocation(String newLocation) async {
    final clean = newLocation.trim();
    if (clean.isEmpty) return;
    await _patchProfileSilently(
      {'address': clean},
      fallbackUserId: state.farmerId,
    );
  }

  /// Updates user name and optionally farm name in state, secure storage and backend
  Future<void> updateProfileNames({
    String? userName,
    String? farmName,
  }) async {
    final cleanUserName = userName?.trim();
    final cleanFarmName = farmName?.trim();

    state = state.copyWith(
      userName: (cleanUserName != null && cleanUserName.isNotEmpty)
          ? cleanUserName
          : state.userName,
      farmName: (cleanFarmName != null && cleanFarmName.isNotEmpty)
          ? cleanFarmName
          : state.farmName,
    );

    await _resaveSession();

    final patchData = <String, dynamic>{};
    if (cleanUserName != null && cleanUserName.isNotEmpty) {
      patchData['name'] = cleanUserName;
    }
    if (cleanFarmName != null && cleanFarmName.isNotEmpty) {
      patchData['farmName'] = cleanFarmName;
    }

    if (patchData.isNotEmpty) {
      await _patchProfileSilently(
        patchData,
        fallbackUserId: state.farmerId ?? 'user_farmer_2',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Shows a local preview instantly, then uploads and swaps in the remote URL.
  /// Returns false when offline (local/data-url preview is kept).
  Future<bool> _uploadImage(
    XFile file, {
    required String folder,
    required Future<void> Function(String url, {bool syncBackend}) apply,
  }) async {
    String fallbackPreview = file.path;
    try {
      final bytes = await file.readAsBytes();
      if (bytes.isNotEmpty) {
        fallbackPreview = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      }
    } catch (_) {}
    await apply(fallbackPreview, syncBackend: false);
    try {
      final remoteUrl = await _repo.uploadImage(file, folder: folder);
      if (remoteUrl != null) {
        await apply(remoteUrl, syncBackend: true);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _patchProfileSilently(
    Map<String, dynamic> data, {
    String? fallbackUserId,
  }) async {
    final uid = state.userId ?? fallbackUserId;
    if (uid == null) return;
    try {
      final enriched = <String, dynamic>{
        'role': state.role.apiValue,
        if (state.userEmail != null && state.userEmail!.isNotEmpty)
          'email': state.userEmail,
        if (state.userName != null && state.userName!.isNotEmpty)
          'fullName': state.userName,
        if (state.farmName != null && state.farmName!.isNotEmpty)
          'farmName': state.farmName,
        ...data,
      };
      await _repo.patchProfile(uid, enriched);
    } catch (_) {
      // Offline resilient fallback
    }
  }

  /// Persists the optimistic (pre-backend) session right after login/register.
  Future<void> _saveOptimisticSession(
    ResolvedAccountIdentity resolved, {
    required UserRole role,
    required String email,
    required KycStatus kycStatus,
    String? farmNameOverride,
  }) {
    return _storage.saveSession(
      token: 'ak_session_${resolved.userId}',
      userId: resolved.userId,
      farmerId: resolved.farmerId,
      farmName: farmNameOverride ?? resolved.farmName,
      farmCoverUrl: state.farmCoverUrl ?? resolved.coverUrl,
      userAvatarUrl: state.userAvatarUrl ?? resolved.avatarUrl,
      role: role.name,
      name: resolved.name,
      phone: resolved.phone,
      email: email,
      kycStatus: kycStatus.apiValue,
    );
  }

  /// Re-saves the current session, keeping the stored token/ids and taking the
  /// latest profile fields (cover, avatar, email) from [state].
  Future<void> _resaveSession() async {
    final saved = await _storage.readSession();
    final userId = state.userId ?? saved['userId'];
    if (userId == null || userId.isEmpty) return;
    await _storage.saveSession(
      token: saved['token'] ?? 'ak_session_$userId',
      userId: userId,
      farmerId: state.farmerId ?? saved['farmerId'],
      farmName: state.farmName ?? saved['farmName'],
      farmCoverUrl: state.farmCoverUrl ?? saved['farmCoverUrl'],
      userAvatarUrl: state.userAvatarUrl ?? saved['userAvatarUrl'],
      role: state.role.name,
      name: state.userName ?? saved['name'] ?? '',
      phone: state.userPhone ?? saved['phone'] ?? '',
      email: state.userEmail ?? saved['email'],
      kycStatus: state.kycStatus.apiValue,
    );
  }

  Future<void> _syncLoginWithBackend({
    required String name,
    String? phone,
    required String email,
    String? farmName,
    required UserRole role,
  }) async {
    try {
      final data = await _repo.login(
        name: name,
        phone: phone,
        email: email,
        farmName: farmName,
        role: role,
      );
      await _applyServerAuthResponse(
        data,
        role: role,
        name: name,
        phone: phone,
        email: email,
        farmName: farmName,
        defaultPhone: '+995 599 11 22 33',
      );
    } catch (_) {
      await _saveOfflineSession(
        role: role,
        name: name,
        phone: phone,
        email: email,
        farmName: farmName,
        defaultPhone: '+995 599 11 22 33',
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
      final data = await _repo.register(
        name: name,
        phone: phone,
        email: email,
        farmName: farmName,
        region: region,
        city: city,
        address: address,
        coverUrl: coverUrl,
        role: role,
      );
      await _applyServerAuthResponse(
        data,
        role: role,
        name: name,
        phone: phone,
        email: email,
        farmName: farmName,
        coverUrl: coverUrl,
        defaultPhone: '+995 599 00 00 00',
      );
    } catch (_) {
      await _saveOfflineSession(
        role: role,
        name: name,
        phone: phone,
        email: email,
        farmName: farmName,
        defaultPhone: '+995 599 00 00 00',
      );
    }
  }

  /// Merges the authoritative `{ token, user: { ..., farmerProfile } }` payload
  /// returned by `/api/auth/login` and `/api/auth/register` into state & storage.
  Future<void> _applyServerAuthResponse(
    Map<String, dynamic>? data, {
    required UserRole role,
    required String name,
    String? phone,
    required String email,
    String? farmName,
    String? coverUrl,
    required String defaultPhone,
  }) async {
    if (data == null || !state.isAuthenticated) return;

    final user = data['user'] as Map<String, dynamic>?;
    final farmerProfile = user?['farmerProfile'] as Map<String, dynamic>?;
    final token = data['token'] as String? ?? 'ak_token';
    final userId = user?['id'] as String? ?? state.userId ?? 'user_1';
    final isSameUser = state.userId == userId;
    final farmerId = role == UserRole.farmer
        ? (farmerProfile?['id'] as String? ??
            (isSameUser ? state.farmerId : null))
        : null;
    final serverFarmName = role == UserRole.farmer
        ? (farmerProfile?['farmName'] as String? ??
            (isSameUser ? state.farmName : null) ??
            farmName)
        : null;
    final serverFullName =
        user?['fullName'] as String? ?? state.userName ?? name;
    final serverPhone = user?['phoneNumber'] as String? ??
        state.userPhone ??
        phone ??
        defaultPhone;
    final serverEmail = user?['email'] as String? ?? state.userEmail ?? email;
    final rawServerAvatar = (farmerProfile?['avatarUrl'] as String?) ??
        (user?['avatarUrl'] as String?);
    final serverAvatarUrl =
        (rawServerAvatar != null && rawServerAvatar.trim().isNotEmpty)
            ? rawServerAvatar
            : (isSameUser ? state.userAvatarUrl : null);
    final serverCoverUrl = role == UserRole.farmer
        ? (farmerProfile?['coverUrl'] as String? ??
            (isSameUser ? state.farmCoverUrl : null) ??
            coverUrl)
        : null;
    final kycStr = user?['verificationStatus'] as String?;

    state = AuthState(
      isAuthenticated: true,
      userId: userId,
      farmerId: farmerId,
      farmName: serverFarmName,
      userName: serverFullName,
      userPhone: serverPhone,
      userEmail: serverEmail,
      userAvatarUrl: serverAvatarUrl,
      farmCoverUrl: serverCoverUrl,
      userAddress: isSameUser ? state.userAddress : null,
      role: role,
      kycStatus: KycStatus.fromString(kycStr),
    );

    await _storage.saveSession(
      token: token,
      userId: userId,
      farmerId: farmerId,
      farmName: serverFarmName,
      farmCoverUrl: serverCoverUrl,
      userAvatarUrl: serverAvatarUrl,
      role: role.name,
      name: serverFullName,
      phone: serverPhone,
      email: serverEmail,
      kycStatus: kycStr ?? KycStatus.verified.apiValue,
    );
    unawaited(syncFcmToken());
  }

  /// Keeps a usable local session when the backend is unreachable.
  Future<void> _saveOfflineSession({
    required UserRole role,
    required String name,
    String? phone,
    required String email,
    String? farmName,
    required String defaultPhone,
  }) {
    return _storage.saveSession(
      token: 'local_token',
      userId: state.userId ?? 'user_local',
      farmerId: state.farmerId,
      farmName: state.farmName ?? farmName,
      farmCoverUrl: state.farmCoverUrl,
      userAvatarUrl: state.userAvatarUrl,
      role: role.name,
      name: state.userName ?? name,
      phone: state.userPhone ?? phone ?? defaultPhone,
      email: email,
    );
  }
}

final authStateProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
