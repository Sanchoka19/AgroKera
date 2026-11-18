import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/notification_settings_provider.dart';

/// Screen allowing the user to configure push and in-app notification preferences.
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 16),
      child: Text(
        title,
        style: GoogleFonts.notoSansGeorgian(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF64748B),
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: value,
            activeTrackColor: AppColors.primary,
            onChanged: (val) {
              HapticFeedback.lightImpact();
              onChanged(val);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(notificationSettingsProvider);
    final notifier = ref.read(notificationSettingsProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            LucideIcons.arrowLeft,
            color: Color(0xFF0F172A),
            size: 22,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'შეტყობინებების პარამეტრები',
          style: GoogleFonts.notoSansGeorgian(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _buildSectionHeader('შეკვეთები და კომუნიკაცია'),
          _buildSettingTile(
            icon: LucideIcons.truck,
            iconColor: const Color(0xFF0F766E),
            iconBg: const Color(0xFFCCFBF1),
            title: 'შეკვეთების შეტყობინებები',
            subtitle: 'სტატუსის ცვლილებები, დადასტურება და PIN კოდი',
            value: settings.ordersEnabled,
            onChanged: notifier.toggleOrders,
          ),
          const SizedBox(height: 10),
          _buildSettingTile(
            icon: LucideIcons.messageCircle,
            iconColor: const Color(0xFF0284C7),
            iconBg: const Color(0xFFE0F2FE),
            title: 'ჩათის შეტყობინებები',
            subtitle: 'შეტყობინებები ფერმერთან და კლიენტთან ჩათიდან',
            value: settings.chatEnabled,
            onChanged: notifier.toggleChat,
          ),

          _buildSectionHeader('სიახლეები და შეთავაზებები'),
          _buildSettingTile(
            icon: LucideIcons.tag,
            iconColor: const Color(0xFFD97706),
            iconBg: const Color(0xFFFEF3C7),
            title: 'ფასდაკლებები და აქციები',
            subtitle: 'სეზონური შეთავაზებები და სპეციალური ფასები',
            value: settings.promotionsEnabled,
            onChanged: notifier.togglePromotions,
          ),

          _buildSectionHeader('აპლიკაციის ინტერფეისი'),
          _buildSettingTile(
            icon: LucideIcons.bellRing,
            iconColor: AppColors.primary,
            iconBg: const Color(0xFFE6F4EA),
            title: 'In-App მცურავი ბანერი',
            subtitle: 'მცურავი შეტყობინების ჩვენება აპლიკაციაში მუშაობისას',
            value: settings.inAppToastEnabled,
            onChanged: notifier.toggleInAppToast,
          ),
        ],
      ),
    );
  }
}

