import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:agrokera/core/auth/auth_state_provider.dart';
import 'package:agrokera/features/marketplace/presentation/providers/marketplace_provider.dart';
import 'package:agrokera/features/profile/presentation/controllers/profile_media_controller.dart';
import 'package:agrokera/features/profile/presentation/widgets/avatar_picker_modal.dart';
import 'package:agrokera/features/profile/presentation/widgets/cover_photo_picker_modal.dart';
import 'package:agrokera/features/profile/presentation/widgets/profile_image_view.dart';
import 'package:agrokera/features/profile/presentation/widgets/farmer_profile_hero.dart';
import 'package:agrokera/features/profile/presentation/widgets/customer_profile_header.dart';
import 'test_helper.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = TestHttpOverrides();
  });

  Widget wrapWithScaffold(Widget child, [ProviderContainer? container]) {
    final scope = container != null
        ? UncontrolledProviderScope(container: container, child: child)
        : ProviderScope(child: child);
    return MaterialApp(home: Scaffold(body: scope));
  }

  group('ProfileImageView Widget Tests', () {
    testWidgets('renders placeholder icon when avatarUrl is null or empty',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileImageView.avatar(avatarUrl: null, size: 50),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ProfileImageView), findsOneWidget);
      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('renders network image when URL starts with https',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileImageView.avatar(
              avatarUrl: 'https://images.unsplash.com/photo-1544005313?w=400',
              size: 50,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('renders memory image when URL starts with data:image',
        (tester) async {
      const dataUri =
          'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileImageView.avatar(avatarUrl: dataUri, size: 50),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('renders fallback cover when coverUrl is null',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileImageView.cover(coverUrl: null),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ProfileImageView), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });
  });

  group('AvatarPickerModal Widget Tests', () {
    testWidgets('renders camera and gallery options and dismisses on tap',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  showModalBottomSheet<ImageSource>(
                    context: ctx,
                    isScrollControlled: true,
                    builder: (_) => const AvatarPickerModal(),
                  );
                },
                child: const Text('Open Avatar Modal'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Open Avatar Modal'));
      await tester.pumpAndSettle();

      expect(find.text('პროფილის ფოტოს შეცვლა'), findsOneWidget);
      expect(find.text('კამერით გადაღება'), findsOneWidget);
      expect(find.text('გალერეიდან არჩევა'), findsOneWidget);

      await tester.tap(find.text('კამერით გადაღება'));
      await tester.pumpAndSettle();

      expect(find.text('პროფილის ფოტოს შეცვლა'), findsNothing);
    });
  });

  group('CoverPhotoPickerModal Widget Tests', () {
    testWidgets('renders camera, gallery, and presets options without overflow',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  showModalBottomSheet<CoverPickerResult>(
                    context: ctx,
                    isScrollControlled: true,
                    builder: (_) => const CoverPhotoPickerModal(),
                  );
                },
                child: const Text('Open Cover Modal'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Open Cover Modal'));
      await tester.pumpAndSettle();

      expect(find.text('ფერმის გარეკანის შეცვლა'), findsOneWidget);
      expect(find.text('კამერით გადაღება'), findsOneWidget);
      expect(find.text('გალერეიდან არჩევა'), findsOneWidget);
      expect(find.text('სანიმუშო აგრო-გარეკანის არჩევა'), findsOneWidget);

      await tester.tap(find.text('გალერეიდან არჩევა'));
      await tester.pumpAndSettle();

      expect(find.text('ფერმის გარეკანის შეცვლა'), findsNothing);
    });

    testWidgets('opens preset picker and selects a preset', (tester) async {
      CoverPresetResult? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  selected = await CoverPhotoPickerModal.showPresetPicker(ctx);
                },
                child: const Text('Open Presets'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Open Presets'));
      await tester.pumpAndSettle();

      expect(find.text('აირჩიე სანიმუშო გარეკანი'), findsOneWidget);
      expect(find.text('სოფლის პეიზაჟი & სახლი'), findsOneWidget);

      await tester.tap(find.text('სოფლის პეიზაჟი & სახლი'));
      await tester.pumpAndSettle();

      expect(selected, isNotNull);
      expect(selected?.title, 'სოფლის პეიზაჟი & სახლი');
      expect(selected?.url, isNotEmpty);
    });
  });

  group('ProfileMediaController Unit Tests', () {
    test('applyFarmCoverPreset updates AuthState and MarketplaceProvider',
        () async {
      final container = ProviderContainer();
      container.read(authStateProvider.notifier).login(
            name: 'გიორგი ბერიძე',
            email: 'giorgi@agrokera.ge',
            role: UserRole.farmer,
          );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final controller =
          container.read(profileMediaControllerProvider.notifier);

      const newCover =
          'https://images.unsplash.com/photo-1500382017468-9049fed747ef';
      final success = await controller.applyFarmCoverPreset(
        newCover,
        presetTitle: 'ტესტ გარეკანი',
      );

      expect(success, isTrue);
      expect(container.read(authStateProvider).farmCoverUrl, newCover);

      // Verify farmer profile in marketplace is also updated
      final farmers = container.read(marketplaceProvider).farmers;
      final farmer = farmers.where((f) => f.id == 'farmer_2').firstOrNull;
      if (farmer != null) {
        expect(farmer.coverUrl, newCover);
      }
    });
  });

  group('FarmerProfileHero and CustomerProfileHeader Integration', () {
    testWidgets('FarmerProfileHero renders cover and avatar via ProfileImageView',
        (tester) async {
      final container = ProviderContainer();
      container.read(authStateProvider.notifier).login(
            name: 'რევაზ ბერიძე',
            email: 'revaz@farm.ge',
            role: UserRole.farmer,
          );

      await tester.pumpWidget(
        wrapWithScaffold(
          FarmerProfileHero(
            authState: container.read(authStateProvider),
            scrollOffset: 0.0,
          ),
          container,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('რევაზ ბერიძე'), findsOneWidget);
      expect(find.text('შეცვლა'), findsOneWidget);
      expect(find.byType(ProfileImageView), findsNWidgets(2)); // Cover & Avatar
    });

    testWidgets('CustomerProfileHeader renders avatar via ProfileImageView',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomerProfileHeader(
              avatarUrl: null,
              userName: 'მომხმარებელი',
              userEmail: 'user@agrokera.ge',
              onAvatarTap: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('მომხმარებელი'), findsOneWidget);
      expect(find.byType(ProfileImageView), findsOneWidget);
    });
  });
}
