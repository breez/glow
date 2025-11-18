import 'package:flutter/material.dart';

enum ProfileAnimal {
  bat,
  bear,
  boar,
  cat,
  chick,
  cow,
  deer,
  dog,
  eagle,
  elephant,
  fox,
  frog,
  hippo,
  hummingbird,
  koala,
  lion,
  monkey,
  mouse,
  owl,
  ox,
  panda,
  pig,
  rabbit,
  seagull,
  sheep,
  snake,
}

extension ProfileAnimalExtension on ProfileAnimal {
  String get displayName {
    switch (this) {
      case ProfileAnimal.bat:
        return 'Bat';
      case ProfileAnimal.bear:
        return 'Bear';
      case ProfileAnimal.boar:
        return 'Boar';
      case ProfileAnimal.cat:
        return 'Cat';
      case ProfileAnimal.chick:
        return 'Chick';
      case ProfileAnimal.cow:
        return 'Cow';
      case ProfileAnimal.deer:
        return 'Deer';
      case ProfileAnimal.dog:
        return 'Dog';
      case ProfileAnimal.eagle:
        return 'Eagle';
      case ProfileAnimal.elephant:
        return 'Elephant';
      case ProfileAnimal.fox:
        return 'Fox';
      case ProfileAnimal.frog:
        return 'Frog';
      case ProfileAnimal.hippo:
        return 'Hippo';
      case ProfileAnimal.hummingbird:
        return 'Hummingbird';
      case ProfileAnimal.koala:
        return 'Koala';
      case ProfileAnimal.lion:
        return 'Lion';
      case ProfileAnimal.monkey:
        return 'Monkey';
      case ProfileAnimal.mouse:
        return 'Mouse';
      case ProfileAnimal.owl:
        return 'Owl';
      case ProfileAnimal.ox:
        return 'Ox';
      case ProfileAnimal.panda:
        return 'Panda';
      case ProfileAnimal.pig:
        return 'Pig';
      case ProfileAnimal.rabbit:
        return 'Rabbit';
      case ProfileAnimal.seagull:
        return 'Seagull';
      case ProfileAnimal.sheep:
        return 'Sheep';
      case ProfileAnimal.snake:
        return 'Snake';
    }
  }

  IconData get iconData {
    switch (this) {
      case ProfileAnimal.bat:
        return const IconData(0xe900, fontFamily: 'animals');
      case ProfileAnimal.bear:
        return const IconData(0xe901, fontFamily: 'animals');
      case ProfileAnimal.boar:
        return const IconData(0xe902, fontFamily: 'animals');
      case ProfileAnimal.cat:
        return const IconData(0xe903, fontFamily: 'animals');
      case ProfileAnimal.chick:
        return const IconData(0xe904, fontFamily: 'animals');
      case ProfileAnimal.cow:
        return const IconData(0xe905, fontFamily: 'animals');
      case ProfileAnimal.deer:
        return const IconData(0xe906, fontFamily: 'animals');
      case ProfileAnimal.dog:
        return const IconData(0xe907, fontFamily: 'animals');
      case ProfileAnimal.eagle:
        return const IconData(0xe908, fontFamily: 'animals');
      case ProfileAnimal.elephant:
        return const IconData(0xe909, fontFamily: 'animals');
      case ProfileAnimal.fox:
        return const IconData(0xe90a, fontFamily: 'animals');
      case ProfileAnimal.frog:
        return const IconData(0xe90b, fontFamily: 'animals');
      case ProfileAnimal.hippo:
        return const IconData(0xe90c, fontFamily: 'animals');
      case ProfileAnimal.hummingbird:
        return const IconData(0xe90d, fontFamily: 'animals');
      case ProfileAnimal.koala:
        return const IconData(0xe90e, fontFamily: 'animals');
      case ProfileAnimal.lion:
        return const IconData(0xe90f, fontFamily: 'animals');
      case ProfileAnimal.monkey:
        return const IconData(0xe910, fontFamily: 'animals');
      case ProfileAnimal.mouse:
        return const IconData(0xe911, fontFamily: 'animals');
      case ProfileAnimal.owl:
        return const IconData(0xe912, fontFamily: 'animals');
      case ProfileAnimal.ox:
        return const IconData(0xe913, fontFamily: 'animals');
      case ProfileAnimal.panda:
        return const IconData(0xe914, fontFamily: 'animals');
      case ProfileAnimal.pig:
        return const IconData(0xe915, fontFamily: 'animals');
      case ProfileAnimal.rabbit:
        return const IconData(0xe916, fontFamily: 'animals');
      case ProfileAnimal.seagull:
        return const IconData(0xe917, fontFamily: 'animals');
      case ProfileAnimal.sheep:
        return const IconData(0xe918, fontFamily: 'animals');
      case ProfileAnimal.snake:
        return const IconData(0xe919, fontFamily: 'animals');
    }
  }
}
