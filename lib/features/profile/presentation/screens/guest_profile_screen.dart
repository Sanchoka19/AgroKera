import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/auth/auth_state_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_confirmation_bottom_sheet.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/auth_required_bottom_sheet.dart';
import '../../../farm_inventory/presentation/screens/farmer_inventory_screen.dart';
import '../../../marketplace/presentation/screens/favorites_screen.dart';
import '../../../marketplace/presentation/widgets/guest_promo_banner.dart';
import '../../../orders/presentation/screens/client_orders_screen.dart';
import '../../../orders/presentation/screens/incoming_orders_screen.dart';
import '../../../orders/presentation/screens/order_chats_list_screen.dart';
import '../widgets/avatar_picker_modal.dart';
import '../widgets/customer_profile_header.dart';
import '../widgets/edit_profile_bottom_sheet.dart';
import '../widgets/farmer_kpi_card.dart';
import '../widgets/farmer_profile_hero.dart';
import '../widgets/profile_row_item.dart';
import '../widgets/profile_settings_card.dart';
import '../providers/user_address_provider.dart';
import 'farm_address_screen.dart';
import 'my_addresses_screen.dart';
import '../../../marketplace/presentation/providers/marketplace_provider.dart';
import 'farmer_delivery_settings_screen.dart';
import 'help_center_screen.dart';
import '../../../notifications/presentation/screens/notification_settings_screen.dart';

class GuestProfileScreen extends ConsumerStatefulWidget {
  const GuestProfileScreen({super.key});

  @override
  ConsumerState<GuestProfileScreen> createState() => _GuestProfileScreenState();
}

class _GuestProfileScreenState extends ConsumerState<GuestProfileScreen> {
  late final ScrollController _scrollController;
  double _scrollOffset = 0.0;
  bool _notificationsEnabled = true;
  bool _darkThemeEnabled = false;
  String _selectedLanguage = 'KA'; // 'KA' or 'EN'

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()
      ..addListener(() {
        if (mounted) {
          setState(() {
            _scrollOffset =
                _scrollController.hasClients ? _scrollController.offset : 0.0;
          });
        }
      });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildFarmerActivitySection(AuthState authState) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          ProfileRowItem(
            icon: LucideIcons.shoppingBag,
            title: 'ჩემი პროდუქტები',
            subtitle: 'პროდუქტების სია და ფასები',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const FarmerInventoryScreen(),
                ),
              );
            },
          ),
          const ProfileRowDivider(),
          ProfileRowItem(
            icon: LucideIcons.clipboardCheck,
            title: 'შემოსული შეკვეთები',
            subtitle: 'შეკვეთების მართვა და სტატუსი',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const IncomingOrdersScreen(),
                ),
              );
            },
          ),
          const ProfileRowDivider(),
          ProfileRowItem(
            icon: LucideIcons.truck,
            title: 'მიწოდების პარამეტრები',
            subtitle: 'მიტანის ზონები, ტარიფები და გრაფიკი',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => FarmerDeliverySettingsScreen(
                    farmerId: authState.farmerId,
                  ),
                ),
              );
            },
          ),
          const ProfileRowDivider(),
          ProfileRowItem(
            icon: LucideIcons.tractor,
            title: 'ფერმის ლოკაცია და თვითგატანა',
            subtitle: () {
              final farmers = ref.watch(marketplaceProvider).farmers;
              final f = farmers.where((x) => x.id == authState.farmerId).firstOrNull;
              final loc = f?.location.isNotEmpty == true ? f!.location : 'თვითგატანის წერტილი';
              return 'საჯარო თვითგატანის წერტილი ($loc)';
            }(),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => FarmAddressScreen(
                    farmerId: authState.farmerId,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerOrdersSection({required bool isFarmer}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          ProfileRowItem(
            icon: LucideIcons.shoppingBag,
            title: 'ჩემი შეკვეთები',
            subtitle: 'შეკვეთების ისტორია და სტატუსი',
            onTap: () {
              if (isFarmer) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ClientOrdersScreen(),
                  ),
                );
              } else {
                requireAuth(
                  context,
                  ref: ref,
                  onAuthenticated: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ClientOrdersScreen(),
                      ),
                    );
                  },
                );
              }
            },
          ),
          const ProfileRowDivider(),
          ProfileRowItem(
            icon: LucideIcons.heart,
            title: 'ფავორიტები',
            subtitle: 'შენახული სასურველი პროდუქტები',
            onTap: () {
              if (isFarmer) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const FavoritesScreen(),
                  ),
                );
              } else {
                requireAuth(
                  context,
                  ref: ref,
                  onAuthenticated: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const FavoritesScreen(),
                      ),
                    );
                  },
                );
              }
            },
          ),
          const ProfileRowDivider(),
          ProfileRowItem(
            icon: LucideIcons.mapPin,
            title: isFarmer ? 'ჩემი პირადი მისამართი' : 'ჩემი მისამართი',
            subtitle: () {
              final addr = ref.watch(userAddressProvider);
              return addr.hasAddress
                  ? addr.activeAddress
                  : 'დაამატეთ მისამართი';
            }(),
            onTap: () {
              if (isFarmer) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const MyAddressesScreen(),
                  ),
                );
              } else {
                requireAuth(
                  context,
                  ref: ref,
                  onAuthenticated: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const MyAddressesScreen(),
                      ),
                    );
                  },
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection({required bool isGuest}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          ProfileRowItem(
            icon: LucideIcons.helpCircle,
            title: 'დახმარების ცენტრი',
            subtitle: 'ინსტრუქციები, FAQ და მხარდაჭერა',
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const HelpCenterScreen(),
                ),
              );
            },
          ),
          if (!isGuest) ...[
            const ProfileRowDivider(),
            ProfileRowItem(
              icon: LucideIcons.logOut,
              iconColor: const Color(0xFFEF4444),
              tileColor: const Color(0xFFFEF2F2),
              title: 'გამოსვლა',
              subtitle: 'ანგარიშიდან გამოსვლა',
              onTap: () async {
                HapticFeedback.lightImpact();
                final confirmed = await AppConfirmationBottomSheet.showLogout(
                  context: context,
                );
                if (confirmed) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(0);
                  }
                  ref.read(authStateProvider.notifier).logout();
                  if (mounted) {
                    AppToast.info(
                      context,
                      'თქვენ გამოხვედით ანგარიშიდან. სასიამოვნო შოპინგს გისურვებთ!',
                    );
                  }
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isFarmer = authState.role == UserRole.farmer;
    final isGuest = !authState.isAuthenticated;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        top: !isFarmer,
        child: Column(
          children: [
            if (!isFarmer)
              AppHeader(
                title: 'ჩემი პროფილი',
                showNotificationBell: true,
                showCart: false,
                actions: [
                  IconButton(
                    tooltip: 'შეკვეთის ჩათი',
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      requireAuth(
                        context,
                        ref: ref,
                        onAuthenticated: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const OrderChatsListScreen(),
                            ),
                          );
                        },
                      );
                    },
                    icon: const Icon(
                      LucideIcons.messageSquare,
                      size: 24,
                      color: AppColors.primary,
                    ),
                  ),
                ],
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              ),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: EdgeInsets.fromLTRB(
                  isFarmer ? 0 : 20,
                  isFarmer ? 0 : 4,
                  isFarmer ? 0 : 20,
                  36,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isGuest) ...[
                      const GuestPromoBanner(showCloseButton: false),
                      const SizedBox(height: 24),
                    ] else if (isFarmer) ...[
                      FarmerProfileHero(
                        authState: authState,
                        scrollOffset: _scrollOffset,
                      ),
                    ] else ...[
                      CustomerProfileHeader(
                        avatarUrl: authState.userAvatarUrl,
                        userName: authState.userName ?? 'საბა ევგენიძე',
                        userEmail: authState.userEmail ??
                            'sabaevgenidze0919@gmail.com',
                        onAvatarTap: () =>
                            AvatarPickerModal.show(context, ref),
                        onEditTap: () => EditProfileBottomSheet.show(context),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isFarmer ? 20 : 0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (isFarmer) ...[
                            const FarmerKpiCard(),
                            const SizedBox(height: 24),
                            const ProfileSectionHeader('საფერმო საქმიანობა'),
                            _buildFarmerActivitySection(authState),
                            const SizedBox(height: 24),
                            const ProfileSectionHeader('პირადი შესყიდვები'),
                            _buildCustomerOrdersSection(isFarmer: true),
                            const SizedBox(height: 24),
                          ] else ...[
                            const ProfileSectionHeader(
                                'ინსტრუმენტები და სერვისები'),
                            _buildCustomerOrdersSection(isFarmer: false),
                            const SizedBox(height: 24),
                          ],
                          const ProfileSectionHeader('პარამეტრები'),
                          ProfileSettingsCard(
                            darkThemeEnabled: _darkThemeEnabled,
                            notificationsEnabled: _notificationsEnabled,
                            selectedLanguage: _selectedLanguage,
                            onDarkThemeChanged: (val) =>
                                setState(() => _darkThemeEnabled = val),
                            onNotificationsChanged: (val) =>
                                setState(() => _notificationsEnabled = val),
                            onLanguageChanged: (lang) =>
                                setState(() => _selectedLanguage = lang),
                            onOpenNotificationSettings: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const NotificationSettingsScreen(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          const ProfileSectionHeader('დახმარება და მხარდაჭერა'),
                          _buildSupportSection(isGuest: isGuest),
                          const SizedBox(height: 32),
                          Center(
                            child: Text(
                              'აგროკერა • ვერსია 1.0.0',
                              style: GoogleFonts.notoSansGeorgian(
                                fontSize: 12,
                                color: const Color(0xFF94A3B8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
