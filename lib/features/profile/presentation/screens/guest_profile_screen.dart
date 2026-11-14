import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:agrokera/core/auth/auth_state_provider.dart';
import 'package:agrokera/core/widgets/auth_required_bottom_sheet.dart';
import 'package:agrokera/features/marketplace/presentation/screens/favorites_screen.dart';
import 'package:agrokera/features/marketplace/presentation/widgets/guest_promo_banner.dart';
import 'help_center_screen.dart';

class GuestProfileScreen extends ConsumerStatefulWidget {
  const GuestProfileScreen({super.key});

  @override
  ConsumerState<GuestProfileScreen> createState() => _GuestProfileScreenState();
}

class _GuestProfileScreenState extends ConsumerState<GuestProfileScreen> {
  bool _notificationsEnabled = true;
  bool _darkThemeEnabled = false;
  String _selectedLanguage = 'KA'; // 'KA' or 'EN'

  void _showImagePickerNotice() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('პროფილის ფოტოს განახლების ფუნქცია მალე დაემატება!'),
        behavior: SnackBarBehavior.floating,
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
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ==========================================
              // GUEST: Official Previous Version Illustration Promo Banner
              // AUTHENTICATED: Modern Hero Avatar + Gradient KPI Card
              // ==========================================
              if (isGuest) ...[
                const GuestPromoBanner(showCloseButton: false),
                const SizedBox(height: 24),
              ] else ...[
                // Top utility row for authenticated user
                Align(
                  alignment: Alignment.centerRight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: const Icon(
                          LucideIcons.bell,
                          color: Color(0xFF0F172A),
                          size: 24,
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('ახალი შეტყობინებები არ არის.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Hero Identity (Centered Avatar with Camera Badge, Name, Subtitle)
                Center(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: isFarmer
                                  ? Image.network(
                                      'https://images.unsplash.com/photo-1595273670150-bd0c3c392e46?w=400&auto=format&fit=crop&q=80',
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => _buildPlaceholderAvatar(),
                                    )
                                  : Image.network(
                                      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&auto=format&fit=crop&q=80',
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => _buildPlaceholderAvatar(),
                                    ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _showImagePickerNotice,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F766E),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  LucideIcons.camera,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isFarmer
                            ? (authState.userName ?? 'რევაზ ბერიძე')
                            : (authState.userName ?? 'საბა ევგენიძე'),
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isFarmer
                            ? 'ფერმერი • ID 3031223'
                            : (authState.userEmail ?? 'sabaevgenidze0919@gmail.com'),
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 13.5,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Emerald Gradient KPI Hero Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF00A86B), // Vibrant Emerald
                        Color(0xFF044E46), // Deep rich Teal
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF044E46).withValues(alpha: 0.28),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.trophy,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isFarmer
                                ? 'საფერმო მაჩვენებლები და KPI'
                                : 'თვიური რეიტინგი და KPI',
                            style: GoogleFonts.notoSansGeorgian(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildGradientMetricCol(
                              value: isFarmer ? '5000₾' : '6',
                              label: isFarmer
                                  ? 'ჯამური შემოსავალი'
                                  : 'შესრულებული',
                            ),
                          ),
                          Container(width: 1, height: 38, color: Colors.white.withValues(alpha: 0.22)),
                          Expanded(
                            child: _buildGradientMetricCol(
                              value: isFarmer ? '100' : '100%',
                              label: isFarmer
                                  ? 'შეკვეთების რაოდენობა'
                                  : 'ხარისხის ქულა',
                            ),
                          ),
                          Container(width: 1, height: 38, color: Colors.white.withValues(alpha: 0.22)),
                          Expanded(
                            child: _buildGradientMetricCol(
                              value: isFarmer ? '4.5' : '3%',
                              label: isFarmer
                                  ? 'საშუალო შეფასება'
                                  : 'გეგმის შესრულება',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Farmer Status Pill (if Farmer)
                if (isFarmer) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.shieldCheck, color: Color(0xFF10B981), size: 20),
                        const SizedBox(width: 10),
                        Text(
                          'თქვენი სტატუსი',
                          style: GoogleFonts.notoSansGeorgian(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.check, size: 14, color: Color(0xFF10B981)),
                              const SizedBox(width: 4),
                              Text(
                                'ვერიფიცირებული',
                                style: GoogleFonts.notoSansGeorgian(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],

              // ==========================================
              // 4. GROUPED SECTION 1: ინსტრუმენტები და სერვისები / ანგარიშის მართვა
              // (Clean White Card, NO Harsh Black Borders!)
              // ==========================================
              _buildSectionHeader(
                isFarmer
                    ? 'საფერმო საქმიანობა'
                    : 'ინსტრუმენტები და სერვისები',
              ),
              Container(
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
                  children: isFarmer
                      ? [
                          _buildProfileRowItem(
                            icon: LucideIcons.shoppingBag,
                            title: 'ჩემი პროდუქტები',
                            subtitle: 'პროდუქტების სია და ფასები',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('გადადით კაბინეტში პროდუქტების სამართავად'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                          _buildRowDivider(),
                          _buildProfileRowItem(
                            icon: LucideIcons.clipboardCheck,
                            title: 'შემოსული შეკვეთები',
                            subtitle: 'შეკვეთების მართვა და სტატუსი',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('შემოსული შეკვეთების სია აქტიურია კაბინეტში'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                          _buildRowDivider(),
                          _buildProfileRowItem(
                            icon: LucideIcons.creditCard,
                            title: 'ანგარიშსწორება',
                            subtitle: 'საბანკო რეკვიზიტები და გადარიცხვები',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('ანგარიშსწორების გვერდი მზადდება.'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                          _buildRowDivider(),
                          _buildProfileRowItem(
                            icon: LucideIcons.mapPin,
                            title: 'ჩემი მისამართი',
                            subtitle: 'ფერმის ლოკაცია და რუკა',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('ფერმის ლოკაცია მონიშნულია რუკაზე.'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                        ]
                      : [
                          _buildProfileRowItem(
                            icon: LucideIcons.shoppingBag,
                            title: 'ჩემი შეკვეთები',
                            subtitle: 'შეკვეთების ისტორია და სტატუსი',
                            onTap: () {
                              requireAuth(
                                context,
                                ref: ref,
                                onAuthenticated: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('შეკვეთების ისტორია ცარიელია.'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                          _buildRowDivider(),
                          _buildProfileRowItem(
                            icon: LucideIcons.heart,
                            title: 'ფავორიტები',
                            subtitle: 'შენახული სასურველი პროდუქტები',
                            onTap: () {
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
                            },
                          ),
                          _buildRowDivider(),
                          _buildProfileRowItem(
                            icon: LucideIcons.mapPin,
                            title: 'ჩემი მისამართი',
                            subtitle: 'მიტანის მისამართები',
                            onTap: () {
                              requireAuth(
                                context,
                                ref: ref,
                                onAuthenticated: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('ჭავჭავაძე - თბილისი'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                          _buildRowDivider(),
                          _buildProfileRowItem(
                            icon: LucideIcons.creditCard,
                            title: 'საბანკო ანგარიშები',
                            subtitle: 'ბარათები და ანგარიშსწორება',
                            onTap: () {
                              requireAuth(
                                context,
                                ref: ref,
                                onAuthenticated: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('საბანკო ბარათები & ანგარიშები.'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                ),
              ),
              const SizedBox(height: 24),

              // ==========================================
              // 5. GROUPED SECTION 2: პარამეტრები
              // (Dark Theme Switch, Language Segmented Toggle, Notifications)
              // ==========================================
              _buildSectionHeader('პარამეტრები'),
              Container(
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
                    // Dark theme toggle switch
                    _buildProfileRowItem(
                      icon: LucideIcons.sun,
                      title: 'მუქი თემა',
                      subtitle: 'ღამის რეჟიმის ჩართვა/გამორთვა',
                      trailing: Switch.adaptive(
                        value: _darkThemeEnabled,
                        activeTrackColor: const Color(0xFF0F766E),
                        onChanged: (val) {
                          HapticFeedback.lightImpact();
                          setState(() => _darkThemeEnabled = val);
                        },
                      ),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _darkThemeEnabled = !_darkThemeEnabled);
                      },
                    ),
                    _buildRowDivider(),

                    // Language Segmented Pill Toggle: [ KA | EN ]
                    _buildProfileRowItem(
                      icon: LucideIcons.globe,
                      title: 'აპლიკაციის ენა',
                      subtitle: 'ინტერფეისის ენის არჩევა',
                      trailing: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildLanguagePill('KA', _selectedLanguage == 'KA'),
                            _buildLanguagePill('EN', _selectedLanguage == 'EN'),
                          ],
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          _selectedLanguage = _selectedLanguage == 'KA' ? 'EN' : 'KA';
                        });
                      },
                    ),
                    _buildRowDivider(),

                    // Notifications switch
                    _buildProfileRowItem(
                      icon: LucideIcons.bell,
                      title: 'შეტყობინებები',
                      subtitle: 'შეტყობინებების მიღება და სიახლეები',
                      trailing: Switch.adaptive(
                        value: _notificationsEnabled,
                        activeTrackColor: const Color(0xFF0F766E),
                        onChanged: (val) {
                          HapticFeedback.lightImpact();
                          setState(() => _notificationsEnabled = val);
                        },
                      ),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _notificationsEnabled = !_notificationsEnabled);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ==========================================
              // 6. GROUPED SECTION 3: დახმარება და მხარდაჭერა / Logout
              // ==========================================
              _buildSectionHeader('დახმარება და მხარდაჭერა'),
              Container(
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
                    _buildProfileRowItem(
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
                      _buildRowDivider(),
                      _buildProfileRowItem(
                        icon: LucideIcons.logOut,
                        iconColor: const Color(0xFFEF4444),
                        tileColor: const Color(0xFFFEF2F2),
                        title: 'გამოსვლა',
                        subtitle: 'ანგარიშიდან გამოსვლა',
                        onTap: () {
                          HapticFeedback.lightImpact();
                          ref.read(authStateProvider.notifier).logout();
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // App Version Footer
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
      ),
    );
  }

  // Section Header Text
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.notoSansGeorgian(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF64748B),
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  // Row Item with Squircle Tile
  Widget _buildProfileRowItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Color iconColor = const Color(0xFF0F766E),
    Color tileColor = const Color(0xFFE8F5E9),
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Pastel Squircle Icon Tile
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: tileColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 14),

              // Title and Descriptive Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              // Trailing action or subtle chevron
              trailing ??
                  const Icon(
                    LucideIcons.chevronRight,
                    color: Color(0xFF94A3B8),
                    size: 18,
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRowDivider() {
    return const Divider(
      height: 1,
      indent: 68,
      endIndent: 16,
      color: Color(0xFFF1F5F9),
    );
  }

  // Metric column inside the emerald gradient KPI card
  Widget _buildGradientMetricCol({required String value, required String label}) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.notoSansGeorgian(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.notoSansGeorgian(
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.85),
            height: 1.25,
          ),
        ),
      ],
    );
  }

  Widget _buildLanguagePill(String text, bool isSelected) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedLanguage = text);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F766E) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderAvatar() {
    return Container(
      color: const Color(0xFFE8F5E9),
      alignment: Alignment.center,
      child: const Icon(
        LucideIcons.user,
        size: 42,
        color: Color(0xFF0F766E),
      ),
    );
  }
}
