import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:agrokera/core/auth/auth_state_provider.dart';
import 'package:agrokera/core/theme/app_colors.dart';
import 'package:agrokera/features/marketplace/presentation/providers/marketplace_provider.dart';
import 'package:agrokera/features/orders/domain/models/farmer_order_model.dart';
import 'package:agrokera/features/orders/presentation/providers/farmer_orders_provider.dart';

/// Clean White Dashboard KPI Card showing farm performance metrics (Revenue, Orders, Rating)
/// dynamically calculated from real incoming orders and farmer profile data.
class FarmerKpiCard extends ConsumerWidget {
  final String? revenue;
  final String? orderCount;
  final String? rating;

  const FarmerKpiCard({
    super.key,
    this.revenue,
    this.orderCount,
    this.rating,
  });

  Widget _buildMetricCol({required String value, required String label}) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.notoSansGeorgian(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.notoSansGeorgian(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
            height: 1.25,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final ordersState = ref.watch(farmerOrdersProvider);
    final marketplace = ref.watch(marketplaceProvider);

    final incomingOrders = ordersState.incomingOrders;
    final nonCancelledOrders =
        incomingOrders.where((o) => o.status != OrderStatus.cancelled);
    final totalRevenue =
        nonCancelledOrders.fold(0.0, (sum, o) => sum + o.totalAmount);

    final displayRevenue = revenue ??
        (totalRevenue > 0 ? '${totalRevenue.toStringAsFixed(0)} ₾' : '0 ₾');

    final displayOrderCount = orderCount ?? '${incomingOrders.length}';

    final farmerId = authState.farmerId;
    final matchingFarmer = marketplace.farmers.where((f) =>
        (farmerId != null && f.id == farmerId) ||
        (authState.farmName != null && f.farmName == authState.farmName) ||
        (authState.userId != null && f.farmerName == authState.userName)
    ).firstOrNull;

    final displayRating = rating ??
        (matchingFarmer != null
            ? (matchingFarmer.reviewCount > 0
                ? matchingFarmer.rating.toStringAsFixed(1)
                : (matchingFarmer.rating > 0 ? matchingFarmer.rating.toStringAsFixed(1) : '—'))
            : '—');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F7EE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.trophy,
                  color: AppColors.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'საფერმო მაჩვენებლები და KPI',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCol(
                  value: displayRevenue,
                  label: 'ჯამური შემოსავალი',
                ),
              ),
              Container(
                width: 1,
                height: 38,
                color: const Color(0xFFF1F5F9),
              ),
              Expanded(
                child: _buildMetricCol(
                  value: displayOrderCount,
                  label: 'შეკვეთების რაოდენობა',
                ),
              ),
              Container(
                width: 1,
                height: 38,
                color: const Color(0xFFF1F5F9),
              ),
              Expanded(
                child: _buildMetricCol(
                  value: displayRating,
                  label: 'საშუალო შეფასება',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
