import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agrokera/core/auth/auth_state_provider.dart';
import 'package:agrokera/features/splash/domain/splash_destination.dart';
import 'package:agrokera/features/splash/presentation/providers/splash_provider.dart';
import 'package:agrokera/features/splash/presentation/screens/splash_screen.dart';
import 'package:agrokera/features/splash/presentation/widgets/splash_auth_content.dart';
import 'package:agrokera/features/splash/presentation/widgets/splash_logo_badge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Splash Destination Provider Tests', () {
    test('resolves authWelcome when user is unauthenticated', () {
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(() => _MockAuthNotifier(false)),
        ],
      );
      addTearDown(container.dispose);

      final destination = container.read(splashDestinationProvider);
      expect(destination, SplashDestination.authWelcome);
    });

    test('resolves mainNav when user is authenticated', () {
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(() => _MockAuthNotifier(true)),
        ],
      );
      addTearDown(container.dispose);

      final destination = container.read(splashDestinationProvider);
      expect(destination, SplashDestination.mainNav);
    });
  });

  group('Splash Widgets Tests', () {
    testWidgets('SplashLogoBadge renders brand title and subtitle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SplashLogoBadge(
              iconSize: 48,
              fontSize: 18,
              showSubtitle: true,
            ),
          ),
        ),
      );

      expect(find.text('AGROKERA'), findsOneWidget);
      expect(find.text('ნატურალური & ქართული'), findsOneWidget);
    });

    testWidgets('SplashAuthContent renders all action buttons and triggers callbacks', (tester) async {
      bool googleTapped = false;
      bool signInTapped = false;
      bool signUpTapped = false;
      bool guestTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SplashAuthContent(
              onGoogleSignIn: () => googleTapped = true,
              onSignIn: () => signInTapped = true,
              onSignUp: () => signUpTapped = true,
              onContinueAsGuest: () => guestTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Google-ით შესვლა'), findsOneWidget);
      expect(find.text('შესვლა'), findsOneWidget);
      expect(find.text('რეგისტრაცია'), findsOneWidget);
      expect(find.text('სტუმრად დათვალიერება'), findsOneWidget);

      await tester.tap(find.text('Google-ით შესვლა'));
      expect(googleTapped, isTrue);

      await tester.tap(find.text('შესვლა'));
      expect(signInTapped, isTrue);

      await tester.tap(find.text('რეგისტრაცია'));
      expect(signUpTapped, isTrue);

      await tester.tap(find.text('სტუმრად დათვალიერება'));
      expect(guestTapped, isTrue);
    });

    testWidgets('SplashScreen mounts and plays animation timeline without errors', (tester) async {
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(() => _MockAuthNotifier(false)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SplashScreen(),
          ),
        ),
      );

      // Verify initial frame
      expect(find.byType(SplashScreen), findsOneWidget);

      // Advance through anticipation and circular explosion
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(SplashScreen), findsOneWidget);

      // Advance to full completion and navigation to MainNavScreen
      await tester.pump(const Duration(milliseconds: 1700));
      await tester.pumpAndSettle();

      expect(find.byType(SplashScreen), findsNothing);
    });
  });
}

class _MockAuthNotifier extends AuthNotifier {
  final bool _isAuth;

  _MockAuthNotifier(this._isAuth);

  @override
  AuthState build() {
    return AuthState(
      isAuthenticated: _isAuth,
      userId: _isAuth ? 'test-user-id' : null,
      userName: _isAuth ? 'Test User' : null,
      userEmail: _isAuth ? 'test@agrokera.ge' : null,
      role: _isAuth ? UserRole.customer : UserRole.guest,
    );
  }

  @override
  Future<void> restoreSession() async {}
}
