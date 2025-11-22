import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/theme/dark_theme.dart';

/// Provides the app's theme data.
/// Since the app uses dark theme exclusively, this always returns the dark theme.
final Provider<ThemeData> appThemeProvider = Provider<ThemeData>((Ref ref) => buildDarkTheme());

/// Provides the theme mode. Since the app uses dark theme exclusively,
/// this always returns [ThemeMode.dark].
final Provider<ThemeMode> themeModeProvider = Provider<ThemeMode>((Ref ref) => ThemeMode.dark);
