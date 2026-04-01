import 'package:flutter/material.dart';

/// Enumera las tags tematicas y funcionales usadas para clasificar contenido.
enum EntityTag {
  debuff,
  buff,
  quemadura,
  intoxicacion,
  vida,
  ataque,
  barrera,
  economia;
}

/// Expone el texto visible y el color base de cada tag.
extension EntityTagPresentation on EntityTag {
  String get label {
    switch (this) {
      case EntityTag.debuff:
        return 'Debuff';
      case EntityTag.buff:
        return 'Buff';
      case EntityTag.quemadura:
        return 'Quemadura';
      case EntityTag.intoxicacion:
        return 'Intoxicacion';
      case EntityTag.vida:
        return 'Vida';
      case EntityTag.ataque:
        return 'Ataque';
      case EntityTag.barrera:
        return 'Barrera';
      case EntityTag.economia:
        return 'Economia';
    }
  }

  Color get accent {
    switch (this) {
      case EntityTag.debuff:
        return const Color(0xFFFF6B6B);
      case EntityTag.buff:
        return const Color(0xFF5AF78E);
      case EntityTag.quemadura:
        return const Color(0xFFFF8C42);
      case EntityTag.intoxicacion:
        return const Color(0xFF74D66A);
      case EntityTag.vida:
        return const Color(0xFFFF8BA7);
      case EntityTag.ataque:
        return const Color(0xFFF3D35C);
      case EntityTag.barrera:
        return const Color(0xFF59B7FF);
      case EntityTag.economia:
        return const Color(0xFFEBCB5A);
    }
  }
}
