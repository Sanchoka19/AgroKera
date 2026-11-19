import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/auth/auth_repository.dart';
import '../../../../core/auth/auth_state_provider.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../marketplace/presentation/providers/marketplace_provider.dart';

class ProfileMediaState {
  final bool isAvatarUploading;
  final bool isCoverUploading;
  final String? errorMessage;

  const ProfileMediaState({
    this.isAvatarUploading = false,
    this.isCoverUploading = false,
    this.errorMessage,
  });

  ProfileMediaState copyWith({
    bool? isAvatarUploading,
    bool? isCoverUploading,
    String? errorMessage,
  }) {
    return ProfileMediaState(
      isAvatarUploading: isAvatarUploading ?? this.isAvatarUploading,
      isCoverUploading: isCoverUploading ?? this.isCoverUploading,
      errorMessage: errorMessage,
    );
  }
}

final profileMediaControllerProvider =
    NotifierProvider<ProfileMediaController, ProfileMediaState>(
  ProfileMediaController.new,
);

/// Dedicated business logic controller for Profile Avatar and Farm Cover media.
///
/// Encapsulates:
/// * Image picking from Camera/Gallery via ImagePicker
/// * Instant optimistic preview updates
/// * Remote cloud uploading via [AuthRepository]
/// * Profile persistence via [authStateProvider] & [marketplaceProvider]
/// * Clear user notifications
class ProfileMediaController extends Notifier<ProfileMediaState> {
  final ImagePicker _picker = ImagePicker();

  @override
  ProfileMediaState build() => const ProfileMediaState();

  AuthRepository get _authRepo => ref.read(authRepositoryProvider);
  AuthNotifier get _authNotifier => ref.read(authStateProvider.notifier);
  MarketplaceNotifier get _marketplaceNotifier =>
      ref.read(marketplaceProvider.notifier);

  /// Helper to derive the best optimistic preview path for an XFile
  Future<String> _getOptimisticPreviewPath(XFile file) async {
    if (!kIsWeb && file.path.isNotEmpty) {
      return file.path;
    }
    try {
      final bytes = await file.readAsBytes();
      if (bytes.isNotEmpty) {
        return 'data:image/jpeg;base64,${base64Encode(bytes)}';
      }
    } catch (_) {}
    return file.path;
  }

  /// Picks and uploads a new profile avatar from [source].
  Future<bool> pickAndUploadAvatar(
    ImageSource source, {
    BuildContext? context,
  }) async {
    XFile? file;
    try {
      file = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.front,
      );
    } catch (_) {
      if (context != null && context.mounted) {
        AppToast.error(
          context,
          source == ImageSource.camera
              ? 'კამერის გახსნა ვერ მოხერხდა'
              : 'გალერეიდან ფოტოს არჩევა ვერ მოხერხდა',
        );
      }
      return false;
    }

    if (file == null) return false;

    if (context != null && context.mounted) {
      AppToast.info(context, 'პროფილის ფოტო იტვირთება...');
    }

    // 1. Instant optimistic local preview
    final previewPath = await _getOptimisticPreviewPath(file);
    await _authNotifier.updateUserAvatarUrl(previewPath, syncBackend: false);

    state = state.copyWith(isAvatarUploading: true, errorMessage: null);

    try {
      // 2. Upload to remote Cloudflare R2 / Server storage
      final remoteUrl = await _authRepo.uploadImage(file, folder: 'avatars');

      if (remoteUrl != null && remoteUrl.isNotEmpty) {
        // 3. Persist authoritative URL to AuthState and Backend Profile
        await _authNotifier.updateUserAvatarUrl(remoteUrl, syncBackend: true);
        unawaited(_marketplaceNotifier.refreshFromBackend());

        if (context != null && context.mounted) {
          AppToast.success(context, 'პროფილის ფოტო წარმატებით განახლდა!');
        }
        return true;
      } else {
        // If offline or upload endpoint returned inline preview
        if (context != null && context.mounted) {
          AppToast.success(context, 'პროფილის ფოტო შენახულია');
        }
        return true;
      }
    } catch (_) {
      // Local preview is kept so user's choice is not lost
      if (context != null && context.mounted) {
        AppToast.success(context, 'პროფილის ფოტო შენახულია (ოფლაინ რეჟიმი)');
      }
      return false;
    } finally {
      state = state.copyWith(isAvatarUploading: false);
    }
  }

  /// Picks and uploads a new farm cover banner from [source].
  Future<bool> pickAndUploadFarmCover(
    ImageSource source, {
    BuildContext? context,
  }) async {
    XFile? file;
    try {
      file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1000,
        imageQuality: 85,
      );
    } catch (_) {
      if (context != null && context.mounted) {
        AppToast.error(
          context,
          source == ImageSource.camera
              ? 'კამერის გახსნა ვერ მოხერხდა'
              : 'გალერეიდან ფოტოს არჩევა ვერ მოხერხდა',
        );
      }
      return false;
    }

    if (file == null) return false;

    if (context != null && context.mounted) {
      AppToast.info(context, 'გარეკანის ფოტო იტვირთება...');
    }

    // 1. Instant optimistic local preview
    final previewPath = await _getOptimisticPreviewPath(file);
    await _authNotifier.updateFarmCoverUrl(previewPath, syncBackend: false);

    state = state.copyWith(isCoverUploading: true, errorMessage: null);

    try {
      // 2. Upload to remote Cloudflare R2 / Server storage
      final remoteUrl = await _authRepo.uploadImage(file, folder: 'covers');

      if (remoteUrl != null && remoteUrl.isNotEmpty) {
        // 3. Persist authoritative URL to AuthState and Backend Profile
        await _authNotifier.updateFarmCoverUrl(remoteUrl, syncBackend: true);
        unawaited(_marketplaceNotifier.refreshFromBackend());

        if (context != null && context.mounted) {
          AppToast.success(context, 'გარეკანის ფოტო წარმატებით განახლდა!');
        }
        return true;
      } else {
        if (context != null && context.mounted) {
          AppToast.success(context, 'გარეკანის ფოტო შენახულია');
        }
        return true;
      }
    } catch (_) {
      if (context != null && context.mounted) {
        AppToast.success(context, 'გარეკანის ფოტო შენახულია (ოფლაინ რეჟიმი)');
      }
      return false;
    } finally {
      state = state.copyWith(isCoverUploading: false);
    }
  }

  /// Applies one of the curated Agro-cover presets directly
  Future<bool> applyFarmCoverPreset(
    String presetUrl, {
    String? presetTitle,
    BuildContext? context,
  }) async {
    try {
      await _authNotifier.updateFarmCoverUrl(presetUrl, syncBackend: true);
      unawaited(_marketplaceNotifier.refreshFromBackend());

      if (context != null && context.mounted) {
        final title = (presetTitle != null && presetTitle.trim().isNotEmpty)
            ? ': $presetTitle'
            : '';
        AppToast.success(context, 'გარეკანი არჩეულია$title');
      }
      return true;
    } catch (_) {
      if (context != null && context.mounted) {
        AppToast.error(context, 'გარეკანის დაყენება ვერ მოხერხდა');
      }
      return false;
    }
  }
}
