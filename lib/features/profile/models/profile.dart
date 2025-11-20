import 'package:glow/features/profile/models/profile_animal.dart';
import 'package:glow/features/profile/models/profile_color.dart';

class Profile {
  final ProfileAnimal animal;
  final ProfileColor color;
  final String? customName;
  final String? customImagePath;

  const Profile({required this.animal, required this.color, this.customName, this.customImagePath});

  /// Returns an anonymous profile with default values
  factory Profile.anonymous() {
    return const Profile(animal: ProfileAnimal.cat, color: ProfileColor.green);
  }

  /// Returns custom name if set, otherwise generates "Color Animal" format
  String get displayName => customName ?? '${color.displayName} ${animal.displayName}';

  Profile copyWith({
    ProfileAnimal? animal,
    ProfileColor? color,
    String? customName,
    String? customImagePath,
  }) {
    return Profile(
      animal: animal ?? this.animal,
      color: color ?? this.color,
      customName: customName ?? this.customName,
      customImagePath: customImagePath ?? this.customImagePath,
    );
  }
}
