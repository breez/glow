import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glow/theme/colors.dart';

ThemeData buildLightTheme() {
  return ThemeData(
    useMaterial3: false,
    fontFamily: 'IBMPlexSans',
    brightness: Brightness.light,

    scaffoldBackgroundColor: BreezColors.lightBackground,
    canvasColor: BreezColors.lightBackground,

    primaryColor: BreezColors.primary,
    primaryColorDark: BreezColors.grey900,
    primaryColorLight: BreezColors.primaryLight,

    colorScheme: ColorScheme.light(
      primary: BreezColors.primary,
      onPrimary: Colors.white,
      secondary: Colors.white,
      onSecondary: BreezColors.primary,
      surface: Colors.white,
      onSurface: BreezColors.grey900,
      error: BreezColors.warning,
      onError: BreezColors.grey900,
    ),

    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: BreezColors.primaryLight,
      foregroundColor: Colors.white,
      iconTheme: IconThemeData(color: Colors.white),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: BreezColors.primaryLight,
        systemStatusBarContrastEnforced: false,
      ),
    ),

    bottomAppBarTheme: const BottomAppBarThemeData(height: 60, elevation: 0, color: BreezColors.primaryLight),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: BreezColors.primaryLight,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: BreezColors.primaryLight,
      foregroundColor: Colors.white,
      sizeConstraints: BoxConstraints(minHeight: 64, minWidth: 64),
    ),

    dialogTheme: const DialogThemeData(
      backgroundColor: Colors.white,
      titleTextStyle: TextStyle(
        color: BreezColors.grey600,
        fontSize: 20.5,
        letterSpacing: 0.25,
        fontWeight: FontWeight.w500,
      ),
      contentTextStyle: TextStyle(color: BreezColors.grey500, fontSize: 16.0, height: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
    ),

    cardTheme: const CardThemeData(
      color: BreezColors.primaryLight,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
    ),

    cardColor: BreezColors.primaryLight,

    highlightColor: const Color(0xFF4DA6F5),
    dividerColor: const Color(0x33ffffff),

    textSelectionTheme: TextSelectionThemeData(
      selectionColor: BreezColors.primaryLight.withValues(alpha: .25),
      selectionHandleColor: BreezColors.primaryLight,
    ),

    chipTheme: const ChipThemeData(backgroundColor: BreezColors.primaryLight),

    primaryIconTheme: const IconThemeData(color: BreezColors.grey500),

    datePickerTheme: _buildLightDatePickerTheme(),
  );
}

DatePickerThemeData _buildLightDatePickerTheme() {
  return DatePickerThemeData(
    backgroundColor: Colors.white,
    headerBackgroundColor: BreezColors.lightBackground,
    headerForegroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
    dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return BreezColors.lightBackground;
      }
      return Colors.transparent;
    }),
    dayForegroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return Colors.white;
      if (states.contains(WidgetState.disabled)) return Colors.black38;
      return Colors.black;
    }),
    todayBorder: const BorderSide(color: BreezColors.lightBackground),
    todayForegroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return Colors.white;
      return BreezColors.lightBackground;
    }),
  );
}
