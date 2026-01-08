import 'dart:io';

import 'package:flutter/material.dart';
import 'package:glow/features/profile/models/profile.dart';
import 'package:glow/features/profile/models/profile_animal.dart';
import 'package:glow/features/profile/models/profile_color.dart';
import 'package:glow/features/profile/services/profile_image_cache.dart';
import 'package:path/path.dart' as path;

enum AvatarSize {
  small(20),
  medium(24),
  large(36);

  final double radius;
  const AvatarSize(this.radius);
}

class ProfileAvatar extends StatelessWidget {
  final Profile profile;
  final AvatarSize avatarSize;
  final Color? backgroundColor;
  final bool isPreview;

  const ProfileAvatar({
    required this.profile,
    this.avatarSize = AvatarSize.small,
    this.backgroundColor,
    this.isPreview = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final String? imagePath = profile.customImagePath;
    final bool hasCustomImage = imagePath != null && imagePath.isNotEmpty;

    if (hasCustomImage) {
      return _FileImageAvatar(avatarSize.radius, imagePath, isPreview: isPreview);
    }

    return _buildIconAvatar();
  }

  Widget _buildIconAvatar() {
    return CircleAvatar(
      radius: avatarSize.radius,
      backgroundColor: Colors.white,
      child: Icon(
        profile.animal.iconData,
        size: avatarSize.radius * 2 * 0.75,
        color: profile.color.color,
      ),
    );
  }
}

class _FileImageAvatar extends StatelessWidget {
  final double radius;
  final String filePath;
  final bool isPreview;

  const _FileImageAvatar(this.radius, this.filePath, {this.isPreview = false});

  @override
  Widget build(BuildContext context) {
    File? imageFile;

    if (isPreview) {
      imageFile = File(filePath);
    } else {
      // Try sync cache first (precached images)
      imageFile = ProfileImageCache().getCachedFileSync(path.basename(filePath));
      // Fallback to direct file access if not cached
      imageFile ??= File(filePath);
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.file(
          imageFile,
          fit: BoxFit.cover,
          width: radius * 2,
          height: radius * 2,
          gaplessPlayback: true,
          errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
            // Return transparent on error - will show icon avatar from parent
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
