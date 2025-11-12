import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glow/core/theme/colors.dart';

ThemeData buildLightTheme() {
  return ThemeData(
    useMaterial3: false,
    fontFamily: 'IBMPlexSans',
    brightness: Brightness.light,
    colorScheme: _lightColorScheme,

    // Base colors
    scaffoldBackgroundColor: BreezColors.lightBackground,
    canvasColor: BreezColors.lightBackground,
    primaryColor: BreezColors.primary,
    primaryColorDark: BreezColors.grey900,
    primaryColorLight: BreezColors.primaryLight,
    cardColor: BreezColors.primaryLight,
    highlightColor: const Color(0xFF4DA6F5),
    dividerColor: const Color(0x33ffffff),

    // Components
    appBarTheme: _lightAppBarTheme,
    bottomAppBarTheme: _lightBottomAppBarTheme,
    filledButtonTheme: filledButtonTheme,
    floatingActionButtonTheme: _lightFabTheme,
    dialogTheme: _lightDialogTheme,
    cardTheme: _lightCardTheme,
    chipTheme: _lightChipTheme,
    drawerTheme: _lightDrawerTheme,
    datePickerTheme: _lightDatePickerTheme,

    // Text / icons
    textTheme: ThemeData.dark().textTheme,
    inputDecorationTheme: ThemeData.dark().inputDecorationTheme,

    primaryTextTheme: ThemeData.dark().primaryTextTheme,

    primaryIconTheme: const IconThemeData(color: BreezColors.grey500),
    textSelectionTheme: TextSelectionThemeData(
      selectionColor: BreezColors.primaryLight.withValues(alpha: .25),
      selectionHandleColor: BreezColors.primaryLight,
    ),
  );
}

const AppBarTheme _lightAppBarTheme = AppBarTheme(
  centerTitle: false,
  elevation: 0,
  scrolledUnderElevation: 0,
  backgroundColor: BreezColors.primary,
  foregroundColor: Colors.white,
  iconTheme: IconThemeData(color: Colors.white),
  systemOverlayStyle: SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarBrightness: Brightness.dark,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: BreezColors.primary,
    systemStatusBarContrastEnforced: false,
  ),
);

const ColorScheme _lightColorScheme = ColorScheme.light(
  primary: BreezColors.primary,
  secondary: Colors.white,
  onSecondary: BreezColors.primary,
  onSurface: BreezColors.grey900,
  error: BreezColors.warning,
  onError: BreezColors.grey900,
);

const BottomAppBarThemeData _lightBottomAppBarTheme = BottomAppBarThemeData(
  height: 60,
  elevation: 0,
  color: BreezColors.primaryLight,
);
FilledButtonThemeData filledButtonTheme = FilledButtonThemeData(
  style: FilledButton.styleFrom(
    backgroundColor: Colors.white,
    foregroundColor: BreezColors.primaryLight,
    minimumSize: const Size.fromHeight(48),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ),
);
const FloatingActionButtonThemeData _lightFabTheme = FloatingActionButtonThemeData(
  backgroundColor: BreezColors.primaryLight,
  foregroundColor: Colors.white,
  sizeConstraints: BoxConstraints(minHeight: 64, minWidth: 64),
);
const DialogThemeData _lightDialogTheme = DialogThemeData(
  backgroundColor: Colors.white,
  titleTextStyle: TextStyle(
    color: BreezColors.grey600,
    fontSize: 20.5,
    letterSpacing: 0.25,
    fontWeight: FontWeight.w500,
  ),
  contentTextStyle: TextStyle(color: BreezColors.grey500, fontSize: 16.0, height: 1.5),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
);

const CardThemeData _lightCardTheme = CardThemeData(
  color: BreezColors.primaryLight,
  elevation: 0,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
);

const ChipThemeData _lightChipTheme = ChipThemeData(backgroundColor: BreezColors.primaryLight);

const DrawerThemeData _lightDrawerTheme = DrawerThemeData(
  backgroundColor: BreezColors.lightSurface,
  scrimColor: Colors.white54,
);

final DatePickerThemeData _lightDatePickerTheme = DatePickerThemeData(
  backgroundColor: Colors.white,
  headerBackgroundColor: BreezColors.lightBackground,
  headerForegroundColor: Colors.white,
  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
  dayBackgroundColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
    if (states.contains(WidgetState.selected)) {
      return BreezColors.lightBackground;
    }
    return Colors.transparent;
  }),
  dayForegroundColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
    if (states.contains(WidgetState.selected)) {
      return Colors.white;
    }
    if (states.contains(WidgetState.disabled)) {
      return Colors.black38;
    }
    return Colors.black;
  }),
  todayBorder: const BorderSide(color: BreezColors.lightBackground),
  todayForegroundColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
    if (states.contains(WidgetState.selected)) {
      return Colors.white;
    }
    return BreezColors.lightBackground;
  }),
);
