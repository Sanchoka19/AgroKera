import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_reason_bottom_sheet.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../orders/domain/models/farmer_order_model.dart';
import '../../../orders/presentation/providers/farmer_orders_provider.dart';
import '../../../orders/presentation/screens/incoming_orders_screen.dart';
import '../../../orders/presentation/screens/farmer_order_detail_screen.dart';
import 'farmer_inventory_screen.dart';

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
  void _onAcceptOrder(FarmerOrder order) {
    ref.read(farmerOrdersProvider.notifier).acceptOrder(order.id);
    AppToast.success(
      context,
      'შეკვეთა #${order.id} დადასტურებულია და გადავიდა პროცესში!',
    );
  }

  Future<void> _onCancelOrder(FarmerOrder order) async {
    final reason = await AppReasonBottomSheet.show(
      context: context,
      title: 'შეკვეთის გაუქმება',
      subtitle: 'შეკვეთა #${order.id} • გთხოვთ მიუთითოთ მიზეზი',
      confirmButtonText: 'დადასტურება',
      confirmButtonColor: const Color(0xFFDC2626),
      icon: LucideIcons.alertTriangle,
      reasons: AppReasonBottomSheet.defaultOrderCancellationReasons,
    );
    if (reason != null && mounted) {
      ref.read(farmerOrdersProvider.notifier).cancelOrder(order.id, reason: reason);
      AppToast.info(
        context,
        'შეკვეთა #${order.id} გაუქმებულია',
      );
    }
  }

  void _openAddProductSheet() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            const FarmerInventoryScreen(openAddOnStart: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeOrders = ref
        .watch(farmerOrdersProvider)
        .orders
        .where((o) =>
            o.status == OrderStatus.pending ||
            o.status == OrderStatus.inProgress)
        .toList();

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
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ==========================================
                    // SECTION 1: პროდუქტის მენეჯმენტი (Grouped Card like Profile)
                    // ==========================================
                    Padding(
                      padding: const EdgeInsets.only(left: 2, bottom: 10, top: 4),
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

                    // Unified Management Card (Clean Grouped Container with Dividers)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Item 1: დაამატე ახალი პროდუქტი
                          _buildManagementRowItem(
                            icon: LucideIcons.shoppingBag,
                            title: 'დაამატე ახალი პროდუქტი',
                            subtitle: 'ახალი სიის შექმნა',
                            onTap: _openAddProductSheet,
                            isFirst: true,
                          ),
                          _buildRowDivider(),

                          // Item 2: მარაგის მართვა
                          _buildManagementRowItem(
                            icon: LucideIcons.clipboardCheck,
                            title: 'მარაგის მართვა',
                            subtitle: 'განაახლეთ ხელმისაწვდომობა და ფასი',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const FarmerInventoryScreen(),
                                ),
                              );
                            },
                          ),
                          _buildRowDivider(),

                          // Item 3: შემოსული შეკვეთები
                          _buildManagementRowItem(
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
                            isLast: true,
                          ),
                        ],
                      ),
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

            // Order Cards List (Airy, container-less empty state directly on background)
            if (activeOrders.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
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
                      const SizedBox(height: 12),
                      Text(
                        'აქტიური შეკვეთები არ გაქვს',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'როდესაც მომხმარებელი შეიძენს შენს პროდუქტებს,\nახალი შეკვეთა აქ გამოჩნდება',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...activeOrders.map((order) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildOrderCard(order),
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

  /// Management Row Item (matching Profile style)
  Widget _buildManagementRowItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(20) : Radius.zero,
          bottom: isLast ? const Radius.circular(20) : Radius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              // Squircle icon tile matching profile page
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F7EE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 20,
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
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
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

  /// Subtle row divider matching profile page
  Widget _buildRowDivider() {
    return const Padding(
      padding: EdgeInsets.only(left: 68, right: 16),
      child: Divider(
        height: 1,
        thickness: 0.8,
        color: Color(0xFFF1F5F9),
      ),
    );
  }

  /// Single Order Card
  Widget _buildOrderCard(FarmerOrder order) {
    final isNew = order.status == OrderStatus.pending;

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
                '${order.productsSummary} • ₾${order.totalAmount.toStringAsFixed(2)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),

              // Row 3: Action Buttons (Only for New orders)
              if (isNew) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    // "გაუქმება" Button
                    Expanded(
                      child: InkWell(
                        onTap: () => _onCancelOrder(order),
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
                        onTap: () => _onAcceptOrder(order),
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
