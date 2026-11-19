import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../network/connectivity/network_connectivity_service.dart';
import '../network/offline_queue/offline_sync_coordinator.dart';

/// Non-intrusive, floating capsule (pill) indicating offline & sync status.
///
/// Designed to float gracefully over screen content (Zero Layout Shift)
/// with smooth animations, notch/status-bar safe padding, and tap-for-details support.
class OfflineStatusBanner extends ConsumerStatefulWidget {
  const OfflineStatusBanner({super.key});

  @override
  ConsumerState<OfflineStatusBanner> createState() =>
      _OfflineStatusBannerState();
}

class _OfflineStatusBannerState extends ConsumerState<OfflineStatusBanner> {
  bool _showRestoredBanner = false;
  Timer? _restoredTimer;

  @override
  void dispose() {
    _restoredTimer?.cancel();
    super.dispose();
  }

  void _showOfflineInfoSheet(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.wifiOff,
                      size: 20,
                      color: Color(0xFFD97706),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ოფლაინ რეჟიმი',
                          style: GoogleFonts.notoSansGeorgian(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ლოკალური მეხსიერება აქტიურია',
                          style: GoogleFonts.notoSansGeorgian(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  'ინტერნეტთან კავშირი დროებით შეწყვეტილია. AgroKera აგრძელებს მუშაობას — თქვენი მოქმედებები, შეკვეთები და ცვლილებები უსაფრთხოდ ინახება ტელეფონში და ავტომატურად გაიგზავნება სერვერზე კავშირის აღდგენისთანავე.',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 13,
                    height: 1.5,
                    color: const Color(0xFF334155),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'გასაგებია',
                    style: GoogleFonts.notoSansGeorgian(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(isOnlineProvider, (previous, next) {
      if (previous == false && next == true) {
        _restoredTimer?.cancel();
        setState(() => _showRestoredBanner = true);
        _restoredTimer = Timer(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() => _showRestoredBanner = false);
          }
        });
      }
    });

    final isOnline = ref.watch(isOnlineProvider);
    final syncStatus = ref.watch(syncStatusProvider).value ?? SyncStatus.idle;

    final isSyncing = syncStatus == SyncStatus.syncing;
    final isOffline = !isOnline;

    final isVisible = isOffline || isSyncing || _showRestoredBanner;

    if (!isVisible) {
      return const SizedBox.shrink();
    }

    final Color bgColor;
    final Color borderColor;
    final Color textColor;
    final Widget iconWidget;
    final String label;

    if (_showRestoredBanner) {
      bgColor = const Color(0xFFECFDF5);
      borderColor = const Color(0xFFA7F3D0);
      textColor = const Color(0xFF065F46);
      iconWidget = const Icon(
        LucideIcons.check,
        size: 14,
        color: Color(0xFF059669),
      );
      label = 'კავშირი აღდგა';
    } else if (isSyncing) {
      bgColor = const Color(0xFFF0FDFA);
      borderColor = const Color(0xFF99F6E4);
      textColor = const Color(0xFF0F766E);
      iconWidget = const SizedBox(
        width: 13,
        height: 13,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0F766E)),
        ),
      );
      label = 'მიმდინარეობს მონაცემების სინქრონიზაცია...';
    } else {
      bgColor = const Color(0xFFFFFBEB);
      borderColor = const Color(0xFFFDE68A);
      textColor = const Color(0xFF92400E);
      iconWidget = const Icon(
        LucideIcons.wifiOff,
        size: 14,
        color: Color(0xFFD97706),
      );
      label = 'ოფლაინ რეჟიმი • ცვლილებები შეინახება ლოკალურად';
    }

    return SafeArea(
      bottom: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isOffline ? () => _showOfflineInfoSheet(context) : null,
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    iconWidget,
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        label,
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isOffline) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        LucideIcons.info,
                        size: 13,
                        color: Color(0xFFD97706),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
