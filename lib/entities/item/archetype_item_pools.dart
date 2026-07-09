import '_imports.dart';

/// Objetos neutros que cualquier arquetipo puede encontrar en tiendas.
final List<Item> generalItemPool = _itemsWithAffinity(
  ItemArchetypeAffinity.general,
);

/// Objetos de Intoxicacion, debuffs y defensas ligeras para builds rapidas.
final List<Item> crepitansItemPool = _itemsWithAffinity(
  ItemArchetypeAffinity.crepitans,
);

/// Objetos centrados en curacion, barrera y buffs defensivos.
final List<Item> diabolicusItemPool = _itemsWithAffinity(
  ItemArchetypeAffinity.diabolicus,
);

/// Objetos con identidad ofensiva, Quemadura, Calentando o Desafio.
final List<Item> herculesItemPool = _itemsWithAffinity(
  ItemArchetypeAffinity.hercules,
);

/// Objetos economicos, curativos y defensivos ligados al Sacer.
final List<Item> sacerItemPool = _itemsWithAffinity(
  ItemArchetypeAffinity.sacer,
);

/// Relaciona cada arquetipo jugable con su pool de objetos especifica.
final Map<ArchetypeId, List<Item>> archetypeSpecificItemPools =
    Map<ArchetypeId, List<Item>>.unmodifiable({
  ArchetypeId.crepitans: crepitansItemPool,
  ArchetypeId.diabolicus: diabolicusItemPool,
  ArchetypeId.hercules: herculesItemPool,
  ArchetypeId.sacer: sacerItemPool,
});

/// Devuelve la pool de tienda combinando items generales y del arquetipo.
///
/// El Sacer ignora el filtro y puede comprar cualquier objeto del juego.
List<Item> itemPoolForArchetype(ArchetypeId? archetypeId) {
  if (archetypeId == ArchetypeId.sacer) {
    return List<Item>.unmodifiable(itemPresets);
  }

  return _deduplicateByCatalogKey([
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

/// Elimina duplicados conservando la primera aparicion de cada clave catalogo.
///
/// Esto permite mezclar el pool general con el pool de arquetipo sin repetir
/// items que hayan sido etiquetados como generalistas y especificos a la vez.
List<Item> _deduplicateByCatalogKey(Iterable<Item> items) {
  final seen = <String>{};
  final result = <Item>[];

  for (final item in items) {
    if (!seen.add(item.catalogKey)) continue;
    result.add(item);
  }

  return List<Item>.unmodifiable(result);
}
