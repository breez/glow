import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glow/core/theme/colors.dart';

ThemeData buildDarkTheme() {
  return ThemeData(
    useMaterial3: false,
    brightness: Brightness.dark,
    fontFamily: 'IBMPlexSans',
    colorScheme: _darkColorScheme,

    // Base colors
    scaffoldBackgroundColor: BreezColors.darkBackground,
    canvasColor: BreezColors.darkBackground,
    primaryColor: BreezColors.primary,
    primaryColorDark: BreezColors.darkBackground,
    primaryColorLight: BreezColors.primaryLight,
    cardColor: const Color(0xFF121212),
    highlightColor: BreezColors.primary,
    dividerColor: const Color(0x337aa5eb),

    // Components
    appBarTheme: _darkAppBarTheme,
    bottomAppBarTheme: _darkBottomAppBarTheme,
    filledButtonTheme: _darkFilledButtonTheme,
    floatingActionButtonTheme: _darkFabTheme,
    dialogTheme: _darkDialogTheme,
    cardTheme: _darkCardTheme,
    chipTheme: const ChipThemeData(backgroundColor: BreezColors.primary),
    drawerTheme: _darkDrawerTheme,
    datePickerTheme: _darkDatePickerTheme,

    // Text / icons
    primaryIconTheme: const IconThemeData(color: Colors.white),
    textSelectionTheme: TextSelectionThemeData(
      selectionColor: Colors.white.withValues(alpha: .5),
      selectionHandleColor: BreezColors.primary,
    ),
  );
}

const _darkColorScheme = ColorScheme.dark(
  primary: Colors.white,
  onPrimary: Colors.white,
  secondary: Colors.white,
  onSecondary: Colors.white,
  surface: BreezColors.darkBackground,
  onSurface: Colors.white,
  error: BreezColors.warningDark,
  onError: Colors.black,
);

const _darkAppBarTheme = AppBarTheme(
  centerTitle: false,
  elevation: 0,
  scrolledUnderElevation: 0,
  backgroundColor: BreezColors.darkBackground,
  foregroundColor: Colors.white,
  iconTheme: IconThemeData(color: Colors.white),
  systemOverlayStyle: SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: BreezColors.darkBackground,
    systemStatusBarContrastEnforced: false,
  ),
);

const _darkBottomAppBarTheme = BottomAppBarThemeData(
  height: 60,
  elevation: 0,
  color: BreezColors.primaryLight,
);

final _darkFilledButtonTheme = FilledButtonThemeData(
  style: FilledButton.styleFrom(
    backgroundColor: BreezColors.primaryLight,
    foregroundColor: Colors.white,
    minimumSize: const Size.fromHeight(48),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ),
);

const _darkFabTheme = FloatingActionButtonThemeData(
  backgroundColor: BreezColors.primaryLight,
  foregroundColor: Colors.white,
  sizeConstraints: BoxConstraints(minHeight: 64, minWidth: 64),
);

const _darkDialogTheme = DialogThemeData(
  backgroundColor: BreezColors.darkSurface,
  titleTextStyle: TextStyle(
    color: Colors.white,
    fontSize: 20.5,
    letterSpacing: 0.25,
    fontWeight: FontWeight.w500,
  ),
  contentTextStyle: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
);

const _darkCardTheme = CardThemeData(
  color: BreezColors.darkSurface,
  elevation: 0,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
);

const _darkDrawerTheme = DrawerThemeData(
  backgroundColor: BreezColors.darkSurface,
  scrimColor: Colors.black54,
);

final _darkDatePickerTheme = DatePickerThemeData(
  backgroundColor: BreezColors.darkSurface,
  headerBackgroundColor: BreezColors.primary,
  headerForegroundColor: Colors.white,
  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
  dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.selected)) return BreezColors.primary;
    return Colors.transparent;
  }),
  dayForegroundColor: WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.selected)) return Colors.white;
    if (states.contains(WidgetState.disabled)) return Colors.white38;
    return Colors.white;
  }),
  todayBorder: const BorderSide(color: BreezColors.primary),
  todayForegroundColor: WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.selected)) return Colors.white;
    return BreezColors.primary;
  }),
);
