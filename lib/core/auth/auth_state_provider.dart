import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthState {
  final bool isAuthenticated;
  final String? userName;
  final String? userPhone;

  const AuthState({
    this.isAuthenticated = false,
    this.userName,
    this.userPhone,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? userName,
    String? userPhone,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState(isAuthenticated: false);

  void login({
    String name = 'გიორგი ბერიძე',
    String phone = '+995 599 12 34 56',
  }) {
    state = state.copyWith(
      isAuthenticated: true,
      userName: name,
      userPhone: phone,
    );
  }

  void logout() {
    state = const AuthState(isAuthenticated: false);
  }
}

final authStateProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
