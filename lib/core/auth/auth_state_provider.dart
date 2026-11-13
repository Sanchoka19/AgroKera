import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class AuthState {
  final bool isAuthenticated;
  final String? userName;
  final String? userPhone;
  final String? userEmail;
  final UserRole role;

  const AuthState({
    this.isAuthenticated = false,
    this.userName,
    this.userPhone,
    this.userEmail,
    this.role = UserRole.guest,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? userName,
    String? userPhone,
    String? userEmail,
    UserRole? role,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      userEmail: userEmail ?? this.userEmail,
      role: role ?? this.role,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState(isAuthenticated: false);

  void login({
    String name = 'გიორგი ბერიძე',
    String phone = '+995 599 12 34 56',
    String email = 'example@gmail.com',
    UserRole role = UserRole.customer,
  }) {
    state = state.copyWith(
      isAuthenticated: true,
      userName: name,
      userPhone: phone,
      userEmail: email,
      role: role,
    );
  }

  void register({
    required UserRole role,
    String name = 'ახალი მომხმარებელი',
    String phone = '+995 599 00 00 00',
    String email = 'example@gmail.com',
  }) {
    state = state.copyWith(
      isAuthenticated: true,
      userName: name,
      userPhone: phone,
      userEmail: email,
      role: role,
    );
  }

  void logout() {
    state = const AuthState(isAuthenticated: false);
  }
}

final authStateProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
