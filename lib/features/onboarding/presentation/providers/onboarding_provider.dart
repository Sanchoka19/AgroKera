import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/models/onboarding_item.dart';

/// Immutable state for the onboarding experience.
class OnboardingState {
  final int currentIndex;
  final List<OnboardingItem> items;

  const OnboardingState({
    this.currentIndex = 0,
    required this.items,
  });

  bool get isLastPage => currentIndex == items.length - 1;
  bool get isFirstPage => currentIndex == 0;
  int get totalPages => items.length;

  OnboardingState copyWith({
    int? currentIndex,
    List<OnboardingItem>? items,
  }) {
    return OnboardingState(
      currentIndex: currentIndex ?? this.currentIndex,
      items: items ?? this.items,
    );
  }
}

/// Presentation logic notifier managing page transitions and completion.
/// Decoupled from UI widgets to prevent mixing business logic with rendering.
class OnboardingNotifier extends Notifier<OnboardingState> {
  SecureStorageService get _storage => ref.read(secureStorageProvider);

  @override
  OnboardingState build() {
    return const OnboardingState(items: defaultOnboardingItems);
  }

  void setPage(int index) {
    if (index >= 0 && index < state.items.length && index != state.currentIndex) {
      state = state.copyWith(currentIndex: index);
    }
  }

  void next() {
    if (!state.isLastPage) {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
    }
  }

  void previous() {
    if (!state.isFirstPage) {
      state = state.copyWith(currentIndex: state.currentIndex - 1);
    }
  }

  Future<void> completeOnboarding() async {
    await _storage.markOnboardingAsSeen();
  }
}

final onboardingProvider =
    NotifierProvider<OnboardingNotifier, OnboardingState>(OnboardingNotifier.new);
