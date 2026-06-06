/// Identifica de forma estable el arquetipo elegido para la run.
enum ArchetypeId {
  veloz,
  inamovible,
  imparable,
  mercante;
}

/// Traduce ids de arquetipo estables a copy visible.
///
/// Los ids se guardan en snapshots y pools; las pantallas deben depender de
/// esta presentacion en vez de formatear directamente el nombre del enum.
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
