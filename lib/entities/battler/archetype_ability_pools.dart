import '_imports.dart';

/// Habilidades generales accesibles a cualquier arquetipo.
final List<BattlerAbility> generalAbilityPool = _abilitiesWithAffinity(
  BattlerAbilityArchetypeAffinity.general,
);

/// Habilidades exclusivas o preferentes del arquetipo Veloz.
final List<BattlerAbility> velozAbilityPool = _abilitiesWithAffinity(
  BattlerAbilityArchetypeAffinity.veloz,
);

/// Habilidades del arquetipo Inamovible.
final List<BattlerAbility> inamovibleAbilityPool = _abilitiesWithAffinity(
  BattlerAbilityArchetypeAffinity.inamovible,
);

/// Habilidades del arquetipo Imparable.
final List<BattlerAbility> imparableAbilityPool = _abilitiesWithAffinity(
  BattlerAbilityArchetypeAffinity.imparable,
);

/// Habilidades del arquetipo Mercante.
final List<BattlerAbility> mercanteAbilityPool = _abilitiesWithAffinity(
  BattlerAbilityArchetypeAffinity.mercante,
);

/// Relaciona cada arquetipo jugable con su pool de habilidades especifica.
final Map<ArchetypeId, List<BattlerAbility>> archetypeSpecificAbilityPools =
    Map<ArchetypeId, List<BattlerAbility>>.unmodifiable({
  ArchetypeId.veloz: velozAbilityPool,
  ArchetypeId.inamovible: inamovibleAbilityPool,
  ArchetypeId.imparable: imparableAbilityPool,
  ArchetypeId.mercante: mercanteAbilityPool,
});

/// Devuelve la pool de habilidades disponible para un arquetipo concreto.
List<BattlerAbility> abilityPoolForArchetype(ArchetypeId? archetypeId) {
  if (archetypeId == null) {
    return List<BattlerAbility>.unmodifiable(abilityPresets);
  }

  return _deduplicateByAbilityId([
    ...generalAbilityPool,
    ...?archetypeSpecificAbilityPools[archetypeId],
  ]);
}

/// Filtra los presets canonicos que declaran [affinity].
List<BattlerAbility> _abilitiesWithAffinity(
  BattlerAbilityArchetypeAffinity affinity,
) {
  return List<BattlerAbility>.unmodifiable([
    for (final ability in abilityPresets)
      if (ability.hasArchetypeAffinity(affinity)) ability,
  ]);
}

/// Elimina duplicados conservando la primera aparicion de cada habilidad.
///
/// Esto permite mezclar el pool general con el pool especifico sin repetir
/// habilidades compartidas entre arquetipos.
List<BattlerAbility> _deduplicateByAbilityId(
  Iterable<BattlerAbility> abilities,
) {
  final seen = <BattlerAbilityId>{};
  final result = <BattlerAbility>[];

  for (final ability in abilities) {
    if (!seen.add(ability.id)) continue;
    result.add(ability);
  }

  return List<BattlerAbility>.unmodifiable(result);
}
