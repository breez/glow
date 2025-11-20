import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'package:glow/features/profile/services/profile_image_cache.dart';

/// Service for picking and cropping profile images
class ProfileImageService {
  final ImagePicker _picker = ImagePicker();
  final ProfileImageCache _cache = ProfileImageCache();

  /// Pick an image from gallery and crop it
  /// Returns the cropped file path, or null if user cancelled
  Future<String?> pickAndCropImage() async {
    try {
      // Pick image from gallery
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        return null;
      }

      // Crop the image to a square
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 85,
        maxWidth: 512,
        maxHeight: 512,
        uiSettings: <PlatformUiSettings>[
          AndroidUiSettings(
            toolbarTitle: 'Crop Profile Image',
            toolbarColor: const Color(0xFF000000),
            toolbarWidgetColor: const Color(0xFFFFFFFF),
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            hideBottomControls: false,
          ),
          IOSUiSettings(
            title: 'Crop Profile Image',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            aspectRatioPickerButtonHidden: true,
          ),
        ],
      );

      if (croppedFile == null) {
        return null;
      }

      // Return the temporary cropped file path
      return croppedFile.path;
    } catch (e) {
      // Return null on any error
      return null;
    }
  }

  /// Save a temporary cropped image to permanent storage
  /// Returns the permanent file path
  Future<String> saveCroppedImage(String tempPath) async {
    final Uint8List bytes = await File(tempPath).readAsBytes();
    final String savedPath = await _saveProfileImage(bytes);

    // Clean up the temporary file
    try {
      await File(tempPath).delete();
    } catch (_) {
      // Ignore cleanup errors
    }

    return savedPath;
  }

  /// Save profile image bytes to app directory
  Future<String> _saveProfileImage(Uint8List bytes) async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final Directory profileImagesDir = Directory(path.join(appDir.path, 'profile_images'));
    await profileImagesDir.create(recursive: true);

    final String fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.png';
    final String filePath = path.join(profileImagesDir.path, fileName);

    await File(filePath).writeAsBytes(bytes, flush: true);

    // Cache the image for faster loading
    await _cache.cacheProfileImage(fileName, bytes);

    return filePath;
  }

  /// Delete a profile image file
  Future<void> deleteImage(String imagePath) async {
    try {
      final File file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
      // Clear cache when deleting
      await _cache.clearCache(path.basename(imagePath));
    } catch (_) {
      // Ignore deletion errors
    }
  }
}
