import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../marketplace/presentation/screens/categories_screen.dart';
import '../../../orders/presentation/screens/incoming_orders_screen.dart';
import '../../../orders/presentation/screens/farmer_order_detail_screen.dart';

/// Model for a Farmer Cabinet Order
class _FarmerCabinetOrder {
  final String id;
  final String itemsText;
  final String priceText;
  String status; // 'new', 'inProgress', 'cancelled'
  final bool isAutoAccepted;

  _FarmerCabinetOrder({
    required this.id,
    required this.itemsText,
    required this.priceText,
    required this.status,
    this.isAutoAccepted = false,
  });
}

/// Farmer Dashboard Tab: "ჩემი ფერმა"
/// Rebuilt to match the clean, focused Figma design:
/// 1. Centered Header: "ჩემი ფერმა"
/// 2. "პროდუქტის მენეჯმენტი" (დაამატე ახალი პროდუქტი, მარაგის მართვა)
/// 3. "შეკვეთები" (ახალი შეკვეთები: გაუქმება / დათანხმება, პროცესში მყოფი შეკვეთები)
class FarmerDashboardScreen extends ConsumerStatefulWidget {
  const FarmerDashboardScreen({super.key});

  @override
  ConsumerState<FarmerDashboardScreen> createState() =>
      _FarmerDashboardScreenState();
}

class _FarmerDashboardScreenState extends ConsumerState<FarmerDashboardScreen> {
  // Live orders state
  late List<_FarmerCabinetOrder> _orders;

  @override
  void initState() {
    super.initState();
    _orders = [
      _FarmerCabinetOrder(
        id: '12345',
        itemsText: '3 პროდუქტი',
        priceText: '₾140',
        status: 'new',
      ),
      _FarmerCabinetOrder(
        id: '12346',
        itemsText: '3 პროდუქტი',
        priceText: '₾140',
        status: 'inProgress',
        isAutoAccepted: true,
      ),
      _FarmerCabinetOrder(
        id: '12347',
        itemsText: '4 პროდუქტი',
        priceText: '₾240',
        status: 'inProgress',
      ),
    ];
  }

  void _onAcceptOrder(int index) {
    final order = _orders[index];
    setState(() {
      order.status = 'inProgress';
    });
    AppToast.success(
      context,
      'შეკვეთა #${order.id} დადასტურებულია და გადავიდა პროცესში!',
    );
  }

  void _onCancelOrder(int index) {
    final order = _orders[index];
    setState(() {
      _orders.removeAt(index);
    });
    AppToast.info(
      context,
      'შეკვეთა #${order.id} გაუქმებულია',
    );
  }

  void _openAddProductSheet() {
    final titleController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'დაამატე ახალი პროდუქტი',
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'შეავსეთ პროდუქტის ძირითადი პარამეტრები',
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'პროდუქტის დასახელება',
                  hintText: 'მაგ: ნატურალური თაფლი',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'ფასი (₾)',
                        hintText: '25.00',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: stockController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'მარაგი (კგ/ც)',
                        hintText: '50',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  AppToast.success(
                    context,
                    'ახალი პროდუქტი წარმატებით დაემატა კატალოგში!',
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'პროდუქტის შენახვა',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Unified App Header (Title & Notifications Bell)
            const AppHeader(
              title: 'ჩემი ფერმა',
              showNotificationBell: true,
              showCart: false,
              padding: EdgeInsets.fromLTRB(20, 12, 20, 12),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ==========================================
                    // SECTION 1: პროდუქტის მენეჯმენტი
                    // ==========================================
                    Padding(
                      padding: const EdgeInsets.only(left: 2, bottom: 12, top: 4),
                      child: Text(
                'პროდუქტის მენეჯმენტი',
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E293B),
                  letterSpacing: -0.2,
                ),
              ),
            ),

            // Card 1: დაამატე ახალი პროდუქტი
            _buildManagementCard(
              icon: LucideIcons.shoppingBag,
              title: 'დაამატე ახალი პროდუქტი',
              subtitle: 'ახალი სიის შექმნა',
              onTap: _openAddProductSheet,
            ),
            const SizedBox(height: 12),

            // Card 2: მარაგის მართვა
            _buildManagementCard(
              icon: LucideIcons.clipboardCheck,
              title: 'მარაგის მართვა',
              subtitle: 'განაახლეთ ხელმისაწვდომობა და ფასი',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CategoriesScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // Card 3: შემოსული შეკვეთები
            _buildManagementCard(
              icon: LucideIcons.inbox,
              title: 'შემოსული შეკვეთები',
              subtitle: 'სტატუსები, დეტალები და ზედნადებები',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const IncomingOrdersScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // ==========================================
            // SECTION 2: შეკვეთები
            // ==========================================
            Padding(
              padding: const EdgeInsets.only(left: 2, right: 2, bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'შეკვეთები',
                    style: GoogleFonts.notoSansGeorgian(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E293B),
                      letterSpacing: -0.2,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const IncomingOrdersScreen(),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'ყველას ნახვა',
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Order Cards List
            if (_orders.isEmpty)
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F7EE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.packageCheck,
                        size: 28,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'შეკვეთები არ არის',
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...List.generate(_orders.length, (index) {
                final order = _orders[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildOrderCard(order, index),
                );
              }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Management Action Card (დაამატე ახალი პროდუქტი, მარაგის მართვა)
  Widget _buildManagementCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Mint circular icon badge
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F7EE),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),

              // Title and Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),

              // Right chevron arrow
              const Icon(
                LucideIcons.chevronRight,
                size: 20,
                color: Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Single Order Card
  Widget _buildOrderCard(_FarmerCabinetOrder order, int index) {
    final isNew = order.status == 'new';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => FarmerOrderDetailScreen(orderId: order.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Row 1: Order ID & Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'შეკვეთა #${order.id}',
                    style: GoogleFonts.notoSansGeorgian(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
              // Refined Status Badge with modern Dot Indicator & Organic palette
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                decoration: BoxDecoration(
                  color: isNew
                      ? const Color(0xFFFFFBEB)
                      : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isNew
                        ? const Color(0xFFFDE68A)
                        : const Color(0xFF99F6E4),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isNew
                            ? const Color(0xFFD97706)
                            : const Color(0xFF0F766E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isNew ? 'ახალი' : 'პროცესშია',
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: isNew
                            ? const Color(0xFFB45309)
                            : const Color(0xFF0F766E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Row 2: Subtitle
          Text(
            '${order.itemsText} - ${order.priceText}',
            style: GoogleFonts.notoSansGeorgian(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),

          // Extra auto-accepted notice (matching screenshot)
          if (order.isAutoAccepted) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  LucideIcons.sparkles,
                  size: 14,
                  color: Color(0xFF059669),
                ),
                const SizedBox(width: 5),
                Text(
                  'ავტომატურად მიღებული',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF059669),
                  ),
                ),
              ],
            ),
          ],

          // Row 3: Action Buttons (Only for New orders)
          if (isNew) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                // "გაუქმება" Button
                Expanded(
                  child: InkWell(
                    onTap: () => _onCancelOrder(index),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'გაუქმება',
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // "დათანხმება" Button
                Expanded(
                  child: InkWell(
                    onTap: () => _onAcceptOrder(index),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'დათანხმება',
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ),
  ),
);
  }
}
