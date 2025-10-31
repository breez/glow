import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/services/config_service.dart';

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

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
