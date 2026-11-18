import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Reusable Section Header for Order Chat grouping
class OrderChatSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;
  final Color iconColor;
  final Color badgeBg;
  final Color badgeTextColor;

  const OrderChatSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.count,
    this.iconColor = const Color(0xFF0F172A),
    this.badgeBg = const Color(0xFFF1F5F9),
    this.badgeTextColor = const Color(0xFF64748B),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.notoSansGeorgian(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF334155),
                letterSpacing: 0.1,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.notoSansGeorgian(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: badgeTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

