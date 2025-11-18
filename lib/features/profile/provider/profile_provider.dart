import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/core/models/wallet_metadata.dart';
import 'package:glow/core/providers/wallet_provider.dart';
import 'package:glow/core/services/wallet_storage_service.dart';
import 'package:glow/features/profile/models/profile.dart';
import 'package:glow/features/profile/models/profile_animal.dart';
import 'package:glow/features/profile/models/profile_color.dart';
import 'package:glow/features/profile/services/profile_image_service.dart';

/// Generates a random profile with color and animal
Profile generateProfile() {
  final Random random = Random();
  final ProfileColor color = ProfileColor.values[random.nextInt(ProfileColor.values.length)];
  final ProfileAnimal animal = ProfileAnimal.values[random.nextInt(ProfileAnimal.values.length)];

  return Profile(color: color, animal: animal);
}

/// Provides the active wallet's profile
/// Returns null if no active wallet is set
final Provider<Profile?> profileProvider = Provider<Profile?>((Ref ref) {
  final WalletMetadata? activeWallet = ref.watch(activeWalletProvider).value;
  return activeWallet?.profile;
});

/// Provides the display name from the active wallet's profile
final Provider<String?> displayNameProvider = Provider<String?>((Ref ref) {
  final Profile? profile = ref.watch(profileProvider);
  return profile?.displayName;
});

/// Updates the active wallet's profile
/// Returns true on success, throws on error
class ProfileNotifier extends Notifier<void> {
  late final ProfileImageService _imageService;

  @override
  void build() {
    _imageService = ProfileImageService();
  }

  /// Update the profile for the active wallet
  ///
  /// If [inputName] matches the generated name (Color Animal), saves without customName
  /// If [inputName] is different, saves it as customName
  /// If [inputName] is empty, saves without customName
  Future<void> updateProfile({required Profile newProfile, required String inputName}) async {
    final WalletMetadata? wallet = ref.read(activeWalletProvider).value;

    if (wallet == null) {
      throw Exception('No active wallet');
    }

    // If the input text matches the generated name (Color Animal), don't set customName
    // Otherwise, use the input text as customName
    final String generatedName = newProfile.displayName;
    final String? customName = inputName.isEmpty || inputName == generatedName ? null : inputName;

    // Create updated profile
    final Profile updatedProfile = Profile(
      animal: newProfile.animal,
      color: newProfile.color,
      customName: customName,
      customImagePath: newProfile.customImagePath,
    );

    // Update wallet metadata
    final WalletMetadata updatedWallet = wallet.copyWith(profile: updatedProfile);
    await ref.read(walletStorageServiceProvider).updateWallet(updatedWallet);

    // Refresh wallet list - activeWalletProvider will update automatically via listener
    ref.invalidate(walletListProvider);
  }

  /// Pick an image from gallery, crop it, and update profile
  /// Returns the temporary image path for preview, or null if cancelled
  Future<String?> pickImageForPreview() async {
    return await _imageService.pickAndCropImage();
  }

  /// Save a temporary image to permanent storage (without updating profile)
  /// Returns the permanent file path
  Future<String> saveTempImage(String tempImagePath) async {
    final WalletMetadata? wallet = ref.read(activeWalletProvider).value;

    if (wallet == null) {
      throw Exception('No active wallet');
    }

    // Delete old image if exists
    final String? oldImagePath = wallet.profile.customImagePath;
    if (oldImagePath != null && oldImagePath.isNotEmpty) {
      await _imageService.deleteImage(oldImagePath);
    }

    // Save temp image to permanent storage
    return await _imageService.saveCroppedImage(tempImagePath);
  }

  /// Clean up a temporary image (when user cancels)
  Future<void> cleanupTempImage(String tempImagePath) async {
    await _imageService.deleteImage(tempImagePath);
  }

  /// Remove custom image from profile
  Future<void> removeProfileImage() async {
    final WalletMetadata? wallet = ref.read(activeWalletProvider).value;

    if (wallet == null) {
      throw Exception('No active wallet');
    }

    final String? imagePath = wallet.profile.customImagePath;
    if (imagePath == null || imagePath.isEmpty) {
      return;
    }

    // Delete the image file
    await _imageService.deleteImage(imagePath);

    // Create updated profile without image
    final Profile updatedProfile = wallet.profile.copyWith(customImagePath: '');

    // Update wallet metadata
    final WalletMetadata updatedWallet = wallet.copyWith(profile: updatedProfile);
    await ref.read(walletStorageServiceProvider).updateWallet(updatedWallet);

    // Refresh wallet list - activeWalletProvider will update automatically via listener
    ref.invalidate(walletListProvider);
  }
}

final NotifierProvider<ProfileNotifier, void> profileNotifierProvider =
    NotifierProvider<ProfileNotifier, void>(ProfileNotifier.new);
