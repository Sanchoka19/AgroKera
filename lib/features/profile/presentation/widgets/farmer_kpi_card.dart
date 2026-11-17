import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Emerald Gradient KPI Hero Card showing farm performance metrics (Revenue, Orders, Rating)
class FarmerKpiCard extends StatelessWidget {
  final String revenue;
  final String orderCount;
  final String rating;

  const FarmerKpiCard({
    super.key,
    this.revenue = '5000₾',
    this.orderCount = '100',
    this.rating = '4.5',
  });

  Widget _buildMetricCol({required String value, required String label}) {
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const RadialGradient(
          center: Alignment(-0.85, -0.75),
          radius: 1.35,
          colors: [
            Color(0xFF059669), // Vibrant Radiant Emerald around trophy
            Color(0xFF0D7A68), // Rich Teal
            Color(0xFF044E46), // Deep Forest Teal at bottom-right
          ],
          stops: [0.0, 0.45, 1.0],
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
                'საფერმო მაჩვენებლები და KPI',
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
                child: _buildMetricCol(
                  value: revenue,
                  label: 'ჯამური შემოსავალი',
                ),
              ),
              Container(
                width: 1,
                height: 38,
                color: Colors.white.withValues(alpha: 0.22),
              ),
              Expanded(
                child: _buildMetricCol(
                  value: orderCount,
                  label: 'შეკვეთების რაოდენობა',
                ),
              ),
              Container(
                width: 1,
                height: 38,
                color: Colors.white.withValues(alpha: 0.22),
              ),
              Expanded(
                child: _buildMetricCol(
                  value: rating,
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

