import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/core/providers/wallet_provider.dart';
import 'package:glow/core/services/config_service.dart';

// TODO: This will be used for theme management in the future
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final configService = ref.watch(configServiceProvider);
    return configService.getThemeMode();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final configService = ref.read(configServiceProvider);
    await configService.setThemeMode(mode);
    state = mode;
  }

  Future<void> reset() async {
    final configService = ref.read(configServiceProvider);
    await configService.resetThemeMode();
    state = configService.getThemeMode();
  }
}

final themeModeProvider = Provider<ThemeMode>((ref) {
  final hasWalletsAsync = ref.watch(hasWalletsProvider);
  if (hasWalletsAsync.value == true) {
    return ThemeMode.dark;
  }
  return ThemeMode.light;
});
