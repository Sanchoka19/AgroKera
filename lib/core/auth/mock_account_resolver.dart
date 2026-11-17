import 'auth_models.dart';

/// Identity resolved for an email + role before (or without) backend confirmation.
class ResolvedAccountIdentity {
  final String userId;
  final String? farmerId;
  final String? farmName;
  final String name;
  final String phone;
  final String? avatarUrl;
  final String? coverUrl;

  const ResolvedAccountIdentity({
    required this.userId,
    this.farmerId,
    this.farmName,
    required this.name,
    required this.phone,
    this.avatarUrl,
    this.coverUrl,
  });
}

/// Maps demo/seed accounts (and arbitrary emails) to stable local identities.
///
/// Used for instant optimistic login and as an offline fallback until the
/// backend responds with the authoritative user profile.
abstract final class MockAccountResolver {
  static const _lanaAvatar =
      'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400&auto=format&fit=crop&q=80';
  static const _lanaCover =
      'https://images.unsplash.com/photo-1500382017468-9049fed747ef?w=1000&auto=format&fit=crop&q=80';
  static const _giorgiAvatar =
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&auto=format&fit=crop&q=80';
  static const _giorgiCover =
      'https://images.unsplash.com/photo-1500937386664-56d1dfef3854?w=1000&auto=format&fit=crop&q=80';
  static const _davitAvatar =
      'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&auto=format&fit=crop&q=80';
  static const _davitCover =
      'https://images.unsplash.com/photo-1464965911861-746a04b4bca6?w=1000&auto=format&fit=crop&q=80';

  static ResolvedAccountIdentity resolve({
    required String email,
    required UserRole role,
    String? explicitName,
    String? explicitPhone,
    String? explicitFarmName,
  }) {
    final normalizedEmail = email.trim().toLowerCase();
    if (role == UserRole.farmer) {
      return _resolveFarmer(
        normalizedEmail,
        explicitName: explicitName,
        explicitPhone: explicitPhone,
        explicitFarmName: explicitFarmName,
      );
    }
    return _resolveClient(
      normalizedEmail,
      explicitName: explicitName,
      explicitPhone: explicitPhone,
    );
  }

  static ResolvedAccountIdentity _resolveFarmer(
    String normalizedEmail, {
    String? explicitName,
    String? explicitPhone,
    String? explicitFarmName,
  }) {
    switch (normalizedEmail) {
      case 'lana@agrokera.ge':
        return ResolvedAccountIdentity(
          userId: 'user_farmer_1',
          farmerId: 'farmer_1',
          farmName: explicitFarmName ?? 'მწვანე ველი',
          name: explicitName ?? 'ლანა მახარაძე',
          phone: explicitPhone ?? '+995 599 33 22 11',
          avatarUrl: _lanaAvatar,
          coverUrl: _lanaCover,
        );
      case 'davit@agrokera.ge':
        return ResolvedAccountIdentity(
          userId: 'user_farmer_3',
          farmerId: 'farmer_3',
          farmName: explicitFarmName ?? 'ალაზნის ბაღები',
          name: explicitName ?? 'დავით ნოზაძე',
          phone: explicitPhone ?? '+995 599 44 55 66',
          avatarUrl: _davitAvatar,
          coverUrl: _davitCover,
        );
      // giorgi@agrokera.ge, the default demo email and an empty email all
      // map to the "Giorgi's farm" seed account.
      case 'giorgi@agrokera.ge':
      case 'example@gmail.com':
      case '':
        return ResolvedAccountIdentity(
          userId: 'user_farmer_2',
          farmerId: 'farmer_2',
          farmName: explicitFarmName ?? 'გიორგის ფერმა',
          name: explicitName ?? 'გიორგი ბერიძე',
          phone: explicitPhone ?? '+995 599 11 22 33',
          avatarUrl: _giorgiAvatar,
          coverUrl: _giorgiCover,
        );
    }

    final slug = normalizedEmail.replaceAll(RegExp(r'[^a-z0-9]'), '_');
    final resolvedName = explicitName ?? normalizedEmail.split('@').first;
    return ResolvedAccountIdentity(
      userId: 'user_farmer_$slug',
      farmerId: 'farmer_$slug',
      farmName: explicitFarmName ?? '$resolvedName-ის მეურნეობა',
      name: resolvedName,
      phone: explicitPhone ?? '+995 599 00 00 00',
    );
  }

  static ResolvedAccountIdentity _resolveClient(
    String normalizedEmail, {
    String? explicitName,
    String? explicitPhone,
  }) {
    if (normalizedEmail == 'client@agrokera.ge') {
      return ResolvedAccountIdentity(
        userId: 'user_client_1',
        name: explicitName ?? 'შპს "გემრიელი რესტორანი"',
        phone: explicitPhone ?? '+995 599 12 34 56',
      );
    }

    final slug =
        normalizedEmail.isEmpty || normalizedEmail == 'example@gmail.com'
            ? '1'
            : normalizedEmail.replaceAll(RegExp(r'[^a-z0-9]'), '_');
    return ResolvedAccountIdentity(
      userId: 'user_client_$slug',
      name: explicitName ?? 'გიორგი ბერიძე',
      phone: explicitPhone ?? '+995 599 12 34 56',
    );
  }
}

