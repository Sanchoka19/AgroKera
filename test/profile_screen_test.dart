import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agrokera/core/auth/auth_state_provider.dart';
import 'package:agrokera/core/widgets/draggable_floating_cart.dart';
import 'package:agrokera/features/marketplace/data/models/farmer_model.dart';
import 'package:agrokera/features/marketplace/presentation/screens/farmer_profile_screen.dart';
import 'package:agrokera/features/profile/presentation/screens/farmer_delivery_settings_screen.dart';
import 'package:agrokera/features/profile/presentation/screens/farm_address_screen.dart';
import 'package:agrokera/features/profile/presentation/screens/guest_profile_screen.dart';
import 'package:agrokera/features/profile/presentation/screens/my_addresses_screen.dart';
import 'package:agrokera/features/profile/presentation/widgets/customer_profile_header.dart';
import 'package:agrokera/features/profile/presentation/widgets/farmer_profile_hero.dart';
import 'package:agrokera/features/profile/domain/models/user_address_model.dart';
import 'test_helper.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = TestHttpOverrides();
  });

  Widget wrapWithScaffold(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        home: child,
      ),
    );
  }

  testWidgets('GuestProfileScreen renders grouped sections and headers', (WidgetTester tester) async {
    await tester.pumpWidget(wrapWithScaffold(const GuestProfileScreen()));
    await tester.pumpAndSettle();

    // Guest Mode: Official illustration banner from previous version
    expect(find.text('არ გაქვს ანგარიში?'), findsOneWidget);
    expect(find.text('ავტორიზაცია'), findsOneWidget);
    expect(find.text('რეგისტრაცია'), findsOneWidget);
    expect(find.text('პროფილის გვერდი'), findsNothing);

    // Section 1 Header & Items (matching mockup)
    expect(find.text('ინსტრუმენტები და სერვისები'), findsOneWidget);
    expect(find.text('ჩემი შეკვეთები'), findsOneWidget);
    expect(find.text('ჩემი მისამართი'), findsOneWidget);
    expect(find.text('საბანკო ანგარიშები'), findsNothing);

    // Section 2: პარამეტრები
    expect(find.text('პარამეტრები'), findsOneWidget);
    expect(find.text('აპლიკაციის ენა'), findsOneWidget);
    expect(find.text('შეტყობინებები'), findsOneWidget);

    // Section 3: დახმარება და მხარდაჭერა
    expect(find.text('დახმარება და მხარდაჭერა'), findsOneWidget);
    expect(find.text('დახმარების ცენტრი'), findsOneWidget);

    // Footer Version
    expect(find.text('აგროკერა • ვერსია 1.0.0'), findsOneWidget);
  });

  testWidgets('Authenticated Customer Profile renders Hero Avatar, NO KPI card, and logout', (WidgetTester tester) async {
    final container = ProviderContainer();
    container.read(authStateProvider.notifier).login(
          name: 'გიორგი ბერიძე',
          email: 'user@example.ge',
          role: UserRole.customer,
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: GuestProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Authenticated Hero Identity
    expect(find.text('გიორგი ბერიძე'), findsOneWidget);
    expect(find.text('user@example.ge'), findsOneWidget);
    // Regular customer does NOT need KPI card
    expect(find.text('თვიური რეიტინგი და KPI'), findsNothing);
    expect(find.text('საფერმო მაჩვენებლები და KPI'), findsNothing);
    expect(find.text('გამოსვლა'), findsOneWidget);
  });

  testWidgets('Authenticated Farmer Profile renders Hero Avatar, KPI card, and verified badge', (WidgetTester tester) async {
    final container = ProviderContainer();
    container.read(authStateProvider.notifier).login(
          name: 'რევაზ ბერიძე',
          email: 'revaz@farm.ge',
          role: UserRole.farmer,
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: GuestProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Farmer Profile
    expect(find.text('რევაზ ბერიძე'), findsOneWidget);
    expect(find.text('საფერმო მაჩვენებლები და KPI'), findsOneWidget);
    expect(find.byTooltip('ვერიფიცირებული ფერმერი'), findsOneWidget);
    expect(find.text('მიწოდების პარამეტრები'), findsOneWidget);
    expect(find.text('პირადი შესყიდვები'), findsOneWidget);
    expect(find.text('ჩემი შეკვეთები'), findsOneWidget);
    expect(find.text('ფავორიტები'), findsOneWidget);
    expect(find.text('გამოსვლა'), findsOneWidget);
  });

  testWidgets('FarmerDeliverySettingsScreen renders delivery options and saves changes', (WidgetTester tester) async {
    final container = ProviderContainer();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: FarmerDeliverySettingsScreen(farmerId: 'farmer_2'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('მიწოდების პარამეტრები'), findsOneWidget);
    expect(find.text('საკურიერო მიტანა'), findsOneWidget);
    expect(find.text('დაფარვის ზონები'), findsOneWidget);
    expect(find.text('მიტანის დღეები'), findsOneWidget);
    expect(find.text('თვითგატანა მეურნეობიდან'), findsOneWidget);
    expect(find.text('ცვლილებების შენახვა'), findsOneWidget);

    // Initial regions for farmer_2
    expect(find.text('თბილისი'), findsOneWidget);
    expect(find.text('რუსთავი'), findsOneWidget);

    // Save changes
    final saveBtn = find.text('ცვლილებების შენახვა');
    await tester.ensureVisible(saveBtn);
    await tester.tap(saveBtn);
    await tester.pumpAndSettle();
  });

  testWidgets('FarmerProfileScreen renders delivery info card in About tab and opens details modal', (WidgetTester tester) async {
    const testFarmer = FarmerModel(
      id: 'f_test',
      farmName: 'გიორგის ფერმა',
      farmerName: 'გიორგი ბერიძე',
      location: 'თელავი, კახეთი',
      rating: 4.9,
      reviewCount: 80,
      avatarUrl: '',
      coverUrl: '',
      about: 'საგვარეულო მეურნეობა თელავში.',
      phone: '+995 599 11 22 33',
      isDeliveryEnabled: true,
      deliveryCity: 'თბილისი',
      deliveryFee: 7.0,
      regionalDeliveryFees: {'თბილისი': 7.0, 'რუსთავი': 10.0},
      deliveryDays: ['შაბათი', 'კვირა'],
    );

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: FarmerProfileScreen(farmer: testFarmer),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('გიორგის ფერმა'), findsOneWidget);
    expect(find.byType(DraggableFloatingCart), findsOneWidget);

    // Switch to "ფერმის შესახებ" tab
    await tester.tap(find.text('ფერმის შესახებ'));
    await tester.pumpAndSettle();

    // In About tab, floating cart must not be visible
    expect(find.byType(DraggableFloatingCart), findsNothing);

    // Check history, location, and delivery info
    expect(find.text('ფერმის ისტორია'), findsOneWidget);
    expect(find.text('მდებარეობა'), findsOneWidget);
    expect(find.text('მიწოდების პირობები'), findsOneWidget);
    expect(find.text('მიწოდება და თვითგატანა'), findsOneWidget);
    expect(find.text('დეტალები'), findsOneWidget);

    // Open delivery details modal bottom sheet
    final detailsBtn = find.text('დეტალები');
    await tester.ensureVisible(detailsBtn);
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, 100));
    await tester.pumpAndSettle();
    await tester.tap(detailsBtn);
    await tester.pumpAndSettle();

    expect(find.text('თბილისი • 7 ₾'), findsOneWidget);
    expect(find.text('რუსთავი • 10 ₾'), findsOneWidget);
    expect(find.textContaining('შაბათი, კვირა'), findsOneWidget);
    expect(find.text('გასაგებია'), findsOneWidget);

    await tester.tap(find.text('გასაგებია'));
    await tester.pumpAndSettle();
  });

  test('UserAddress model formats address and handles details correctly', () {
    final addr1 = UserAddress(
      id: '1',
      title: 'სახლი',
      city: 'თბილისი',
      addressLine: 'ი. ჭავჭავაძის გამზ. 24',
      details: 'სად. 2, ბ. 15',
      isDefault: true,
      createdAt: DateTime.now(),
    );
    expect(addr1.formattedAddress, 'თბილისი, ი. ჭავჭავაძის გამზ. 24, სად. 2, ბ. 15');

    final addr2 = UserAddress(
      id: '2',
      title: 'ფერმა',
      city: 'გორი',
      addressLine: 'გორი, სოფ. შინდისი',
      isDefault: false,
      createdAt: DateTime.now(),
    );
    expect(addr2.formattedAddress, 'გორი, სოფ. შინდისი');
  });

  testWidgets('MyAddressesScreen renders header and address list', (WidgetTester tester) async {
    await tester.pumpWidget(wrapWithScaffold(const MyAddressesScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('ჩემი მისამართები'), findsOneWidget);
  });

  testWidgets('FarmAddressScreen renders farm info card and save CTA', (WidgetTester tester) async {
    await tester.pumpWidget(wrapWithScaffold(const FarmAddressScreen(farmerId: 'farmer_1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('ფერმის მისამართი'), findsOneWidget);
    expect(find.text('ფერმის მისამართის შენახვა'), findsOneWidget);
    expect(find.text('თვითგატანის წერტილი (საჯარო)'), findsOneWidget);
  });

  testWidgets('Customer Profile allows editing user name via EditProfileBottomSheet', (WidgetTester tester) async {
    final container = ProviderContainer();
    container.read(authStateProvider.notifier).login(
          name: 'გიორგი ბერიძე',
          email: 'user@example.ge',
          role: UserRole.customer,
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: GuestProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap on the name or pencil icon to open sheet
    expect(find.text('გიორგი ბერიძე'), findsOneWidget);
    await tester.tap(find.text('გიორგი ბერიძე'));
    await tester.pumpAndSettle();

    // Bottom sheet is shown
    expect(find.text('პროფილის რედაქტირება'), findsOneWidget);
    expect(find.text('პირადი სახელი და გვარი'), findsOneWidget);
    expect(find.text('მეურნეობის / ფერმის დასახელება'), findsNothing); // Not a farmer

    // Enter new name
    final nameField = find.widgetWithText(TextFormField, 'გიორგი ბერიძე');
    await tester.enterText(nameField, 'გიორგი მაისურაძე');
    await tester.pump();

    // Tap Save
    await tester.tap(find.text('შენახვა'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Verify updated name in state and UI
    expect(container.read(authStateProvider).userName, 'გიორგი მაისურაძე');
    expect(find.descendant(of: find.byType(CustomerProfileHeader), matching: find.text('გიორგი მაისურაძე')), findsOneWidget);
  });

  testWidgets('Farmer Profile allows editing personal name and farm name via EditProfileBottomSheet', (WidgetTester tester) async {
    final container = ProviderContainer();
    container.read(authStateProvider.notifier).login(
          name: 'რევაზ ბერიძე',
          email: 'revaz@farm.ge',
          role: UserRole.farmer,
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: GuestProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap on the edit pencil button
    final editButton = find.byTooltip('პროფილის რედაქტირება');
    expect(editButton, findsOneWidget);
    await tester.tap(editButton);
    await tester.pumpAndSettle();

    // Bottom sheet is shown with both fields
    expect(find.text('პროფილის რედაქტირება'), findsOneWidget);
    expect(find.text('პირადი სახელი და გვარი'), findsOneWidget);
    expect(find.text('მეურნეობის / ფერმის დასახელება'), findsOneWidget);

    // Edit personal name
    final nameField = find.widgetWithText(TextFormField, 'რევაზ ბერიძე');
    await tester.enterText(nameField, 'რევაზ კობახიძე');
    await tester.pump();

    // Edit farm name
    final farmField = find.byType(TextFormField).at(1);
    await tester.enterText(farmField, 'ახალი ალაზანი');
    await tester.pump();

    // Tap Save
    await tester.tap(find.text('შენახვა'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Verify updated names in auth state and UI
    final auth = container.read(authStateProvider);
    expect(auth.userName, 'რევაზ კობახიძე');
    expect(auth.farmName, 'ახალი ალაზანი');
    expect(find.descendant(of: find.byType(FarmerProfileHero), matching: find.text('რევაზ კობახიძე')), findsOneWidget);
    expect(find.descendant(of: find.byType(FarmerProfileHero), matching: find.text('ახალი ალაზანი')), findsOneWidget);
  });

  testWidgets('EditProfileBottomSheet displays photo pickers for Customer and Farmer and updates avatar/cover state', (WidgetTester tester) async {
    final container = ProviderContainer();
    container.read(authStateProvider.notifier).login(
          name: 'რევაზ ბერიძე',
          email: 'revaz@farm.ge',
          role: UserRole.farmer,
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: GuestProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open EditProfileBottomSheet
    await tester.tap(find.byTooltip('პროფილის რედაქტირება'));
    await tester.pumpAndSettle();

    expect(find.text('პროფილის ფოტო'), findsOneWidget);
    expect(find.text('ფერმის გარეკანის ფოტო'), findsOneWidget);

    // Update avatar and cover via AuthNotifier
    await container.read(authStateProvider.notifier).updateUserAvatarUrl(
          'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
          syncBackend: false,
        );
    await container.read(authStateProvider.notifier).updateFarmCoverUrl(
          'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
          syncBackend: false,
        );
    await tester.pump();

    expect(
      container.read(authStateProvider).userAvatarUrl,
      startsWith('data:image/png;base64,'),
    );
    expect(
      container.read(authStateProvider).farmCoverUrl,
      startsWith('data:image/png;base64,'),
    );
  });
}

