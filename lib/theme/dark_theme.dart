import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glow/theme/colors.dart';

ThemeData buildDarkTheme() {
  return ThemeData(
    useMaterial3: false,
    fontFamily: 'IBMPlexSans',
    brightness: Brightness.dark,

    scaffoldBackgroundColor: BreezColors.darkBackground,
    canvasColor: BreezColors.darkBackground,

    primaryColor: BreezColors.primary,
    primaryColorDark: BreezColors.darkBackground,
    primaryColorLight: BreezColors.primaryLight,

    colorScheme: const ColorScheme.dark(
      primary: Colors.white,
      onPrimary: Colors.white,
      secondary: Colors.white,
      onSecondary: Colors.white,
      surface: BreezColors.darkBackground,
      onSurface: Colors.white,
      error: BreezColors.warningDark,
      onError: Colors.black,
    ),

    appBarTheme: const AppBarTheme(
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
    ),

    bottomAppBarTheme: const BottomAppBarThemeData(height: 60, elevation: 0, color: BreezColors.primary),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: BreezColors.primary,
      foregroundColor: Colors.white,
      sizeConstraints: BoxConstraints(minHeight: 64, minWidth: 64),
    ),

    dialogTheme: const DialogThemeData(
      backgroundColor: BreezColors.darkSurface,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20.5,
        letterSpacing: 0.25,
        fontWeight: FontWeight.w500,
      ),
      contentTextStyle: TextStyle(color: Colors.white70, fontSize: 16.0, height: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
    ),

    cardTheme: const CardThemeData(
      color: BreezColors.darkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
    ),

    cardColor: const Color(0xFF121212),

    highlightColor: BreezColors.primary,
    dividerColor: const Color(0x337aa5eb),

    textSelectionTheme: TextSelectionThemeData(
      selectionColor: Colors.white.withValues(alpha: .5),
      selectionHandleColor: BreezColors.primary,
    ),

    chipTheme: const ChipThemeData(backgroundColor: BreezColors.primary),

    primaryIconTheme: const IconThemeData(color: Colors.white),

    datePickerTheme: _buildDarkDatePickerTheme(),

    drawerTheme: _buildDarkDrawerTheme(),
  );
}

DrawerThemeData _buildDarkDrawerTheme() {
  return const DrawerThemeData(backgroundColor: BreezColors.darkSurface, scrimColor: Colors.black54);
}

DatePickerThemeData _buildDarkDatePickerTheme() {
  return DatePickerThemeData(
    backgroundColor: BreezColors.darkSurface,
    headerBackgroundColor: BreezColors.primary,
    headerForegroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
    dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return BreezColors.primary;
      }
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
}
