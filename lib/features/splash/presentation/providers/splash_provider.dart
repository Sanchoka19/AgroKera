import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_state_provider.dart';
import '../../domain/splash_destination.dart';

/// Provider for determining the destination after splash animation completes.
/// Decouples authentication check logic from presentation widgets.
final splashDestinationProvider = Provider<SplashDestination>((ref) {
  final authState = ref.watch(authStateProvider);
  if (authState.isAuthenticated) {
    return SplashDestination.mainNav;
  }
  return SplashDestination.authWelcome;
});

