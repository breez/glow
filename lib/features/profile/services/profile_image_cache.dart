import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

const String profileImagesDirName = 'profile_images';

class ProfileImageCache {
  final DefaultCacheManager _cacheManager = DefaultCacheManager();
  final Map<String, File> _memoryCache = <String, File>{};

  static final ProfileImageCache _instance = ProfileImageCache._internal();

  factory ProfileImageCache() {
    return _instance;
  }

  ProfileImageCache._internal();

  /// Synchronous cache lookup - returns immediately if in memory cache
  File? getCachedFileSync(String fileName) {
    return _memoryCache[fileName];
  }

  Future<File?> getProfileImageFile({required String fileName}) async {
    // Check memory cache first
    if (_memoryCache.containsKey(fileName)) {
      return _memoryCache[fileName];
    }

    // Use fileName as unique cache key
    final File? cachedFile = await _getCachedProfileImageFile(fileName);
    if (cachedFile != null) {
      _memoryCache[fileName] = cachedFile;
      return cachedFile;
    }

    final File? loadedFile = await _loadProfileImageFileFromDocuments(fileName);
    if (loadedFile != null) {
      _memoryCache[fileName] = loadedFile;
    }
    return loadedFile;
  }

  Future<File?> _getCachedProfileImageFile(String fileName) async {
    final FileInfo? cachedFileInfo = await _cacheManager.getFileFromCache(fileName);
    return cachedFileInfo?.file;
  }

  Future<File?> _loadProfileImageFileFromDocuments(String fileName) async {
    try {
      final Directory directory = await getApplicationDocumentsDirectory();
      final Directory profileImagesDir = Directory(path.join(directory.path, profileImagesDirName));
      final String profileImageFilePath = path.join(profileImagesDir.path, fileName);
      final File profileImageFile = File(profileImageFilePath);

      if (await profileImageFile.exists()) {
        final Uint8List bytes = await profileImageFile.readAsBytes();
        await cacheProfileImage(fileName, bytes);
        return profileImageFile;
      }
    } catch (e) {
      // Return null on error
    }

    return null;
  }

  Future<void> cacheProfileImage(String fileName, Uint8List bytes) async {
    try {
      await _cacheManager.putFile(fileName, bytes, eTag: fileName);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> clearCache(String fileName) async {
    try {
      _memoryCache.remove(fileName);
      await _cacheManager.removeFile(fileName);
    } catch (e) {
      // Ignore errors
    }
  }
}
