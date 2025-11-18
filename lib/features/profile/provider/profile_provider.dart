import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/core/models/wallet_metadata.dart';
import 'package:glow/core/providers/wallet_provider.dart';
import 'package:glow/features/profile/models/profile.dart';
import 'package:glow/features/profile/models/profile_animal.dart';
import 'package:glow/features/profile/models/profile_color.dart';

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
