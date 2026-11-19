import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/auth/auth_state_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../orders/domain/models/farmer_order_model.dart';
import '../providers/reviews_provider.dart';
import 'review_quick_tags_selector.dart';
import 'star_rating_selector.dart';

/// Modal bottom sheet for submitting an order review and rating.
class OrderReviewBottomSheet extends ConsumerStatefulWidget {
  final FarmerOrder order;
  final VoidCallback? onReviewSubmitted;

  const OrderReviewBottomSheet({
    super.key,
    required this.order,
    this.onReviewSubmitted,
  });

  static Future<void> show({
    required BuildContext context,
    required FarmerOrder order,
    VoidCallback? onReviewSubmitted,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => OrderReviewBottomSheet(
        order: order,
        onReviewSubmitted: onReviewSubmitted,
      ),
    );
  }

  @override
  ConsumerState<OrderReviewBottomSheet> createState() =>
      _OrderReviewBottomSheetState();
}

class _OrderReviewBottomSheetState
    extends ConsumerState<OrderReviewBottomSheet> {
  int _rating = 5;
  List<String> _selectedTags = ['ახალი პროდუქცია'];
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final auth = ref.read(authStateProvider);
    final clientName = auth.userName ??
        (auth.userEmail != null && auth.userEmail!.contains('@')
            ? auth.userEmail!.split('@').first
            : 'მომხმარებელი');

    final effectiveFarmerId = widget.order.farmerId ?? 'farmer_2';

    final review = await ref.read(reviewsProvider.notifier).submitReview(
          orderId: widget.order.id,
          clientId: auth.userId ?? widget.order.clientId ?? 'user_client_1',
          farmerId: effectiveFarmerId,
          clientName: clientName,
          clientAvatarUrl: auth.userAvatarUrl,
          rating: _rating,
          tags: _selectedTags,
          comment: _commentController.text.trim(),
        );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (review != null) {
        AppToast.success(context, 'მადლობა შეფასებისთვის!');
        Navigator.pop(context);
        widget.onReviewSubmitted?.call();
      } else {
        AppToast.error(context, 'შეფასების გაგზავნა ვერ მოხერხდა');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final farmerName = widget.order.farmerName ?? 'ფერმერი';

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top drag handle
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      LucideIcons.star,
                      size: 20,
                      color: Color(0xFFD97706),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'შეაფასეთ შეკვეთა #${widget.order.id}',
                          style: GoogleFonts.notoSansGeorgian(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'ფერმერი: $farmerName',
                          style: GoogleFonts.notoSansGeorgian(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      LucideIcons.x,
                      size: 20,
                      color: Color(0xFF64748B),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Star Rating Selector
              StarRatingSelector(
                rating: _rating,
                onRatingChanged: (newRating) => setState(() => _rating = newRating),
              ),

              const SizedBox(height: 20),

              // Quick Tags
              Text(
                'რა მოგეწონათ ყველაზე მეტად?',
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 10),
              ReviewQuickTagsSelector(
                selectedTags: _selectedTags,
                onTagsChanged: (tags) => setState(() => _selectedTags = tags),
              ),

              const SizedBox(height: 18),

              // Comment Input Field
              Text(
                'კომენტარი (სურვილისამებრ)',
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _commentController,
                maxLines: 3,
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 13.5,
                  color: const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  hintText: 'გაგვიზიარეთ თქვენი შთაბეჭდილება...',
                  hintStyle: GoogleFonts.notoSansGeorgian(
                    fontSize: 13,
                    color: const Color(0xFF94A3B8),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // Submit Button
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _isSubmitting ? null : _submitReview,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(LucideIcons.checkCheck, size: 18),
                  label: Text(
                    _isSubmitting ? 'იგზავნება...' : 'შეფასების გაგზავნა',
                    style: GoogleFonts.notoSansGeorgian(
                      fontSize: 14.5,
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
}

