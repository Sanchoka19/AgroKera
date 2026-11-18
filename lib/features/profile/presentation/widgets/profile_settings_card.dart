import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import 'profile_row_item.dart';

/// Card containing application settings (Dark mode, language, push notifications)
class ProfileSettingsCard extends StatelessWidget {
  final bool darkThemeEnabled;
  final bool notificationsEnabled;
  final String selectedLanguage;
  final ValueChanged<bool> onDarkThemeChanged;
  final ValueChanged<bool> onNotificationsChanged;
  final ValueChanged<String> onLanguageChanged;
  final VoidCallback? onOpenNotificationSettings;

  const ProfileSettingsCard({
    super.key,
    required this.darkThemeEnabled,
    required this.notificationsEnabled,
    required this.selectedLanguage,
    required this.onDarkThemeChanged,
    required this.onNotificationsChanged,
    required this.onLanguageChanged,
    this.onOpenNotificationSettings,
  });

  Widget _buildLanguagePill(String text, bool isSelected) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onLanguageChanged(text);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
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

  @override
  Widget build(BuildContext context) {
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
          // Dark theme toggle switch
          ProfileRowItem(
            icon: LucideIcons.sun,
            title: 'მუქი თემა',
            subtitle: 'ღამის რეჟიმის ჩართვა/გამორთვა',
            trailing: Switch.adaptive(
              value: darkThemeEnabled,
              activeTrackColor: AppColors.primary,
              onChanged: (val) {
                HapticFeedback.lightImpact();
                onDarkThemeChanged(val);
              },
            ),
            onTap: () {
              HapticFeedback.lightImpact();
              onDarkThemeChanged(!darkThemeEnabled);
            },
          ),
          const ProfileRowDivider(),

          // Language Segmented Pill Toggle: [ KA | EN ]
          ProfileRowItem(
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
                  _buildLanguagePill('KA', selectedLanguage == 'KA'),
                  _buildLanguagePill('EN', selectedLanguage == 'EN'),
                ],
              ),
            ),
            onTap: () {
              onLanguageChanged(selectedLanguage == 'KA' ? 'EN' : 'KA');
            },
          ),
          const ProfileRowDivider(),

          // Notifications switch
          ProfileRowItem(
            icon: LucideIcons.bell,
            title: 'შეტყობინებები',
            subtitle: 'შეტყობინებების მიღება და სიახლეები',
            trailing: Switch.adaptive(
              value: notificationsEnabled,
              activeTrackColor: AppColors.primary,
              onChanged: (val) {
                HapticFeedback.lightImpact();
                onNotificationsChanged(val);
              },
            ),
            onTap: onOpenNotificationSettings ??
                () {
                  HapticFeedback.lightImpact();
                  onNotificationsChanged(!notificationsEnabled);
                },
          ),
        ],
      ),
    );
  }
}

