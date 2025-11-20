import 'package:glow/features/profile/models/profile.dart';
import 'package:glow/features/profile/models/profile_animal.dart';
import 'package:glow/features/profile/models/profile_color.dart';

/// Non-sensitive metadata for a wallet stored in secure storage.
///
/// SECURITY CRITICAL:
/// - Mnemonic is NEVER stored in this model
/// - Wallet ID is derived from mnemonic hash (first 8 chars of SHA-256)
/// - Mnemonic itself is stored separately in secure storage with key: 'wallet_mnemonic_{id}'
class WalletMetadata {
  final String id;
  final Profile profile;
  final bool isVerified;

  const WalletMetadata({required this.id, required this.profile, this.isVerified = false});

  /// Display name from profile (customName or "Color Animal")
  String get displayName => profile.displayName;

  WalletMetadata copyWith({String? id, Profile? profile, bool? isVerified}) => WalletMetadata(
    id: id ?? this.id,
    profile: profile ?? this.profile,
    isVerified: isVerified ?? this.isVerified,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'animal': profile.animal.name,
    'color': profile.color.name,
    'customName': profile.customName,
    'customImagePath': profile.customImagePath,
    'isVerified': isVerified,
  };

  factory WalletMetadata.fromJson(Map<String, dynamic> json) {
    final String id = json['id'] as String;
    final bool isVerified = json['isVerified'] as bool? ?? false;

    Profile profile;

    // Migration: Check if old format (name field) or new format (animal/color)
    if (json.containsKey('animal') && json.containsKey('color')) {
      // New format: has animal/color
      final ProfileAnimal animal = ProfileAnimal.values.byName(json['animal'] as String);
      final ProfileColor color = ProfileColor.values.byName(json['color'] as String);
      profile = Profile(
        animal: animal,
        color: color,
        customName: json['customName'] as String?,
        customImagePath: json['customImagePath'] as String?,
      );
    } else {
      // Old format: has name field - generate new profile and use name as customName
      final String? oldName = json['name'] as String?;
      profile = Profile(
        animal: ProfileAnimal.values[0], // Default animal
        color: ProfileColor.values[0], // Default color
        customName: oldName,
      );
    }

    return WalletMetadata(id: id, profile: profile, isVerified: isVerified);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalletMetadata &&
          other.id == id &&
          other.profile.animal == profile.animal &&
          other.profile.color == profile.color &&
          other.profile.customName == profile.customName &&
          other.profile.customImagePath == profile.customImagePath &&
          other.isVerified == isVerified;

  @override
  int get hashCode =>
      Object.hash(id, profile.animal, profile.color, profile.customName, profile.customImagePath, isVerified);

  @override
  String toString() => 'WalletMetadata(id: $id, profile: ${profile.displayName}, isVerified: $isVerified)';
}
