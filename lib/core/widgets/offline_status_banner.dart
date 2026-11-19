import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../network/connectivity/network_connectivity_service.dart';
import '../network/offline_queue/offline_sync_coordinator.dart';
import '../theme/app_colors.dart';

/// Non-intrusive, animated offline & sync status indicator.
///
/// Designed to be embedded into screens (e.g. Home, Inventory, Orders)
/// without blocking navigation or cluttering the UI.
class OfflineStatusBanner extends ConsumerWidget {
  const OfflineStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    final syncStatus = ref.watch(syncStatusProvider).value ?? SyncStatus.idle;

    if (isOnline && syncStatus == SyncStatus.idle) {
      return const SizedBox.shrink();
    }

    final isSyncing = syncStatus == SyncStatus.syncing;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSyncing
            ? AppColors.primaryLight
            : AppColors.accentWarm.withValues(alpha: 0.12),
        border: Border(
          bottom: BorderSide(
            color: isSyncing
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.accentWarm.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSyncing)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
            else
              const Icon(
                LucideIcons.wifiOff,
                size: 15,
                color: AppColors.accentWarm,
              ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                isSyncing
                    ? 'მიმდინარეობს მონაცემების სინქრონიზაცია...'
                    : 'ოფლაინ რეჟიმი • ცვლილებები შეინახება ლოკალურად',
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSyncing ? AppColors.primary : AppColors.accentWarm,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
