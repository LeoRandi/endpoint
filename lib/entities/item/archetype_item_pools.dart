import '../_imports.dart';

/// Objetos neutros que cualquier arquetipo puede encontrar en tiendas.
final List<Item> generalItemPool = _itemsWithAffinity(
  ItemArchetypeAffinity.general,
);

/// Objetos de Intoxicacion, debuffs y defensas ligeras para builds rapidas.
final List<Item> velozItemPool = _itemsWithAffinity(
  ItemArchetypeAffinity.veloz,
);

/// Objetos centrados en curacion, barrera y buffs defensivos.
final List<Item> inamovibleItemPool = _itemsWithAffinity(
  ItemArchetypeAffinity.inamovible,
);

/// Objetos con identidad ofensiva, Quemadura, Calentando o Desafio.
final List<Item> imparableItemPool = _itemsWithAffinity(
  ItemArchetypeAffinity.imparable,
);

/// Objetos economicos, curativos y defensivos ligados al Mercante.
final List<Item> mercanteItemPool = _itemsWithAffinity(
  ItemArchetypeAffinity.mercante,
);

/// Relaciona cada arquetipo jugable con su pool de objetos especifica.
final Map<ArchetypeId, List<Item>> archetypeSpecificItemPools =
    Map<ArchetypeId, List<Item>>.unmodifiable({
  ArchetypeId.veloz: velozItemPool,
  ArchetypeId.inamovible: inamovibleItemPool,
  ArchetypeId.imparable: imparableItemPool,
  ArchetypeId.mercante: mercanteItemPool,
});

/// Devuelve la pool de tienda combinando items generales y del arquetipo.
///
/// El Mercante ignora el filtro y puede comprar cualquier objeto del juego.
List<Item> itemPoolForArchetype(ArchetypeId? archetypeId) {
  if (archetypeId == ArchetypeId.mercante) {
    return List<Item>.unmodifiable(itemPresets);
  }

  return _deduplicateByItemId([
    ...generalItemPool,
    ...?archetypeSpecificItemPools[archetypeId],
  ]);
}

/// Filtra los presets canonicos que declaran [affinity].
List<Item> _itemsWithAffinity(ItemArchetypeAffinity affinity) {
  return List<Item>.unmodifiable([
    for (final item in itemPresets)
      if (item.hasArchetypeAffinity(affinity)) item,
  ]);
}

/// Elimina duplicados conservando la primera aparicion de cada [ItemId].
///
/// Esto permite mezclar el pool general con el pool de arquetipo sin repetir
/// items que hayan sido etiquetados como generalistas y especificos a la vez.
List<Item> _deduplicateByItemId(Iterable<Item> items) {
  final seen = <ItemId>{};
  final result = <Item>[];

  for (final item in items) {
    if (!seen.add(item.id)) continue;
    result.add(item);
  }

  return List<Item>.unmodifiable(result);
}
