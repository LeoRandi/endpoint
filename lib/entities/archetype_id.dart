/// Identifica de forma estable el arquetipo elegido para la run.
enum ArchetypeId {
  veloz,
  inamovible,
  imparable,
  mercante;
}

extension ArchetypeIdPresentation on ArchetypeId {
  /// Devuelve el nombre visible del arquetipo.
  String get label {
    switch (this) {
      case ArchetypeId.veloz:
        return 'Veloz';
      case ArchetypeId.inamovible:
        return 'Inamovible';
      case ArchetypeId.imparable:
        return 'Imparable';
      case ArchetypeId.mercante:
        return 'Mercante';
    }
  }
}
