import 'package:flutter/material.dart';

/// Enumera las tags tematicas y funcionales usadas para clasificar contenido.
enum EntityTag {
  debuff,
  buff,
  quemadura,
  intoxicacion,
  contagio,
  ciclo,
  vida,
  ataque,
  barrera,
  resonancia,
  desafio,
  economia,
  muralla,
  arma,
  accesorio;
}

/// Expone el texto visible y el color base de cada tag.
extension EntityTagPresentation on EntityTag {
  /// Devuelve la etiqueta legible usada por pills, filtros y detalles.
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
      case EntityTag.contagio:
        return 'Contagio';
      case EntityTag.ciclo:
        return 'Ciclo';
      case EntityTag.vida:
        return 'Vida';
      case EntityTag.ataque:
        return 'Ataque';
      case EntityTag.barrera:
        return 'Barrera';
      case EntityTag.resonancia:
        return 'Resonancia';
      case EntityTag.desafio:
        return 'Desafio';
      case EntityTag.economia:
        return 'Economia';
      case EntityTag.muralla:
        return 'Muralla';
      case EntityTag.arma:
        return 'Arma';
      case EntityTag.accesorio:
        return 'Accesorio';
    }
  }

  /// Devuelve el color semantico base para UI y resaltado de efectos.
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
      case EntityTag.contagio:
        return const Color(0xFFB56DFF);
      case EntityTag.ciclo:
        return const Color(0xFFC0C0C0);
      case EntityTag.vida:
        return const Color(0xFFFF8BA7);
      case EntityTag.ataque:
        return const Color(0xFFF3D35C);
      case EntityTag.barrera:
        return const Color(0xFF59B7FF);
      case EntityTag.resonancia:
        return const Color(0xFFD0D5DE);
      case EntityTag.desafio:
        return const Color(0xFF55D6C2);
      case EntityTag.economia:
        return const Color(0xFFEBCB5A);
      case EntityTag.muralla:
        return const Color(0xFFB8C0CC);
      case EntityTag.arma:
        return const Color(0xFFF3D35C);
      case EntityTag.accesorio:
        return const Color(0xFF9EA7B3);
    }
  }
}
