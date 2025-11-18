import 'package:flutter/material.dart';
import 'package:glow/features/profile/models/profile.dart';
import 'package:glow/features/profile/models/profile_animal.dart';
import 'package:glow/features/profile/models/profile_color.dart';

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

  const ProfileAvatar({
    required this.profile,
    this.avatarSize = AvatarSize.small,
    this.backgroundColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: avatarSize.radius,
      backgroundColor: Colors.white,
      child: Icon(profile.animal.iconData, size: avatarSize.radius * 2 * 0.75, color: profile.color.color),
    );
  }
}
