import 'package:flutter/material.dart';

enum ProfileColor {
  salmon,
  blue,
  turquoise,
  orchid,
  purple,
  tomato,
  cyan,
  crimson,
  orange,
  lime,
  pink,
  green,
  red,
  yellow,
  azure,
  silver,
  magenta,
  olive,
  violet,
  rose,
  wine,
  mint,
  indigo,
  jade,
  coral,
}

extension ProfileColorExtension on ProfileColor {
  String get displayName {
    switch (this) {
      case ProfileColor.salmon:
        return 'Salmon';
      case ProfileColor.blue:
        return 'Blue';
      case ProfileColor.turquoise:
        return 'Turquoise';
      case ProfileColor.orchid:
        return 'Orchid';
      case ProfileColor.purple:
        return 'Purple';
      case ProfileColor.tomato:
        return 'Tomato';
      case ProfileColor.cyan:
        return 'Cyan';
      case ProfileColor.crimson:
        return 'Crimson';
      case ProfileColor.orange:
        return 'Orange';
      case ProfileColor.lime:
        return 'Lime';
      case ProfileColor.pink:
        return 'Pink';
      case ProfileColor.green:
        return 'Green';
      case ProfileColor.red:
        return 'Red';
      case ProfileColor.yellow:
        return 'Yellow';
      case ProfileColor.azure:
        return 'Azure';
      case ProfileColor.silver:
        return 'Silver';
      case ProfileColor.magenta:
        return 'Magenta';
      case ProfileColor.olive:
        return 'Olive';
      case ProfileColor.violet:
        return 'Violet';
      case ProfileColor.rose:
        return 'Rose';
      case ProfileColor.wine:
        return 'Wine';
      case ProfileColor.mint:
        return 'Mint';
      case ProfileColor.indigo:
        return 'Indigo';
      case ProfileColor.jade:
        return 'Jade';
      case ProfileColor.coral:
        return 'Coral';
    }
  }

  Color get color {
    switch (this) {
      case ProfileColor.salmon:
        return const Color(0xFFFA8072);
      case ProfileColor.blue:
        return const Color(0xFF4169E1);
      case ProfileColor.turquoise:
        return const Color(0xFF00CED1);
      case ProfileColor.orchid:
        return const Color(0xFF9932CC);
      case ProfileColor.purple:
        return const Color(0xFF800080);
      case ProfileColor.tomato:
        return const Color(0xFFFF6347);
      case ProfileColor.cyan:
        return const Color(0xFF008B8B);
      case ProfileColor.crimson:
        return const Color(0xFFDC143C);
      case ProfileColor.orange:
        return const Color(0xFFFFA500);
      case ProfileColor.lime:
        return const Color(0xFF32CD32);
      case ProfileColor.pink:
        return const Color(0xFFFF69B4);
      case ProfileColor.green:
        return const Color(0xFF00A644);
      case ProfileColor.red:
        return const Color(0xFFFF2727);
      case ProfileColor.yellow:
        return const Color(0xFFEECA0C);
      case ProfileColor.azure:
        return const Color(0xFF00C4FF);
      case ProfileColor.silver:
        return const Color(0xFF53687F);
      case ProfileColor.magenta:
        return const Color(0xFFFF00FF);
      case ProfileColor.olive:
        return const Color(0xFF808000);
      case ProfileColor.violet:
        return const Color(0xFF7F01FF);
      case ProfileColor.rose:
        return const Color(0xFFFF0080);
      case ProfileColor.wine:
        return const Color(0xFF950347);
      case ProfileColor.mint:
        return const Color(0xFF7ADEB8);
      case ProfileColor.indigo:
        return const Color(0xFF4B0082);
      case ProfileColor.jade:
        return const Color(0xFF00B27A);
      case ProfileColor.coral:
        return const Color(0xFFFF7F50);
    }
  }
}
