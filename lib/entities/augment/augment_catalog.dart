import 'augment.dart';
import '../archetype_id.dart';
import '../entity_tag.dart';
import '../pattern/_exports.dart';
import '../rarity_tier.dart';

final List<Augment> augmentCatalog = List<Augment>.unmodifiable([
  Augment(
    id: 1,
    name: 'Augment M',
    description: 'Potencia ataques cuando el patron contiene una M.',
    tier: RarityTier.gray,
    assetPath: 'assets/sprites/unknown.png',
    affinity: AugmentAffinity.general,
    tags: const <EntityTag>[EntityTag.ataque],
    effects: AugmentEffects(
      patternEffects: {
        _points(const [(-1, 1), (0, 0), (1, 1)]):
            const AugmentEffect.patternAttackDamageBonus(
          value: 10,
          description: '+10 dano a cada ataque del patron.',
        ),
        _points(const [(-1, 0), (-1, 1), (0, 0), (1, 1), (1, 0)]):
            const AugmentEffect.patternAttackDamageBonus(
          value: 15,
          description: '+15 dano a cada ataque del patron.',
        ),
        _points(const [(-1, 0), (-1, 1), (0, 0), (1, 1), (1, 0)]):
            const AugmentEffect.patternAttackDamageBonus(
          value: 20,
          description: '+20 dano a cada ataque del patron.',
        ),
        _points(
          const [(-1, -1), (-1, 0), (-1, 1), (0, 0), (1, 1), (1, 0), (1, -1)],
        ): const AugmentEffect.patternAttackDamageBonus(
          value: 30,
          description: '+30 dano a cada ataque del patron.',
        ),
        _points(
          const [(-1, -1), (-1, 0), (-1, 1), (0, 0), (1, 1), (1, 0), (1, -1)],
        ): const AugmentEffect.patternAttackDamageBonus(
          value: 50,
          description: '+50 dano a cada ataque del patron.',
        ),
      },
    ),
  ),
  Augment(
    id: 2,
    name: 'Augment Columna',
    description: 'Convierte los trazos verticales en rutas de dano fiable.',
    tier: RarityTier.gray,
    assetPath: 'assets/sprites/unknown.png',
    affinity: AugmentAffinity.inamovible,
    tags: const <EntityTag>[EntityTag.ataque, EntityTag.barrera],
    effects: AugmentEffects(
      patternEffects: {
        _points(const [(0, -1), (0, 0), (0, 1)]):
            const AugmentEffect.patternAttackDamageBonus(
          value: 6,
          description: '+6 dano a cada ataque del patron.',
        ),
        _points(const [(-1, -1), (0, -1), (0, 0), (0, 1), (1, 1)]):
            const AugmentEffect.patternAttackDamageBonus(
          value: 10,
          description: '+10 dano a cada ataque del patron.',
        ),
        _points(const [(-1, -1), (0, -1), (0, 0), (0, 1), (1, 1)]):
            const AugmentEffect.patternAttackDamageBonus(
          value: 14,
          description: '+14 dano a cada ataque del patron.',
        ),
        _points(
          const [(-1, -1), (0, -1), (1, -1), (0, 0), (-1, 1), (0, 1), (1, 1)],
        ): const AugmentEffect.patternAttackDamageBonus(
          value: 22,
          description: '+22 dano a cada ataque del patron.',
        ),
        _points(
          const [(-1, -1), (0, -1), (1, -1), (0, 0), (-1, 1), (0, 1), (1, 1)],
        ): const AugmentEffect.patternAttackDamageBonus(
          value: 36,
          description: '+36 dano a cada ataque del patron.',
        ),
      },
    ),
  ),
  Augment(
    id: 3,
    name: 'Augment Zigzag',
    description: 'Premia giros agresivos y reposicionamiento constante.',
    tier: RarityTier.gray,
    assetPath: 'assets/sprites/unknown.png',
    affinity: AugmentAffinity.veloz,
    tags: const <EntityTag>[EntityTag.ataque],
    effects: AugmentEffects(
      patternEffects: {
        _points(const [(-1, 1), (0, 0), (1, 1)]):
            const AugmentEffect.patternAttackDamageBonus(
          value: 5,
          description: '+5 dano a cada ataque del patron.',
        ),
        _points(const [(-1, 1), (0, 0), (1, 1), (0, -1), (-1, 0)]):
            const AugmentEffect.patternAttackDamageBonus(
          value: 9,
          description: '+9 dano a cada ataque del patron.',
        ),
        _points(const [(-1, 1), (0, 0), (1, 1), (0, -1), (-1, 0)]):
            const AugmentEffect.patternAttackDamageBonus(
          value: 13,
          description: '+13 dano a cada ataque del patron.',
        ),
        _points(
          const [(-1, 1), (0, 0), (1, 1), (0, -1), (-1, 0), (0, 1), (1, 0)],
        ): const AugmentEffect.patternAttackDamageBonus(
          value: 21,
          description: '+21 dano a cada ataque del patron.',
        ),
        _points(
          const [(-1, 1), (0, 0), (1, 1), (0, -1), (-1, 0), (0, 1), (1, 0)],
        ): const AugmentEffect.patternAttackDamageBonus(
          value: 34,
          description: '+34 dano a cada ataque del patron.',
        ),
      },
    ),
  ),
  Augment(
    id: 4,
    name: 'Augment Gancho',
    description: 'Hace que los patrones que rodean al enemigo rematen mejor.',
    tier: RarityTier.gray,
    assetPath: 'assets/sprites/unknown.png',
    affinity: AugmentAffinity.imparable,
    tags: const <EntityTag>[EntityTag.ataque, EntityTag.desafio],
    effects: AugmentEffects(
      patternEffects: {
        _points(const [(-1, 0), (0, 0), (0, 1)]):
            const AugmentEffect.patternAttackDamageBonus(
          value: 7,
          description: '+7 dano a cada ataque del patron.',
        ),
        _points(const [(-1, -1), (-1, 0), (0, 0), (0, 1), (1, 1)]):
            const AugmentEffect.patternAttackDamageBonus(
          value: 11,
          description: '+11 dano a cada ataque del patron.',
        ),
        _points(const [(-1, -1), (-1, 0), (0, 0), (0, 1), (1, 1)]):
            const AugmentEffect.patternAttackDamageBonus(
          value: 16,
          description: '+16 dano a cada ataque del patron.',
        ),
        _points(
          const [(-1, -1), (-1, 0), (-1, 1), (0, 1), (1, 1), (1, 0), (0, 0)],
        ): const AugmentEffect.patternAttackDamageBonus(
          value: 24,
          description: '+24 dano a cada ataque del patron.',
        ),
        _points(
          const [(-1, -1), (-1, 0), (-1, 1), (0, 1), (1, 1), (1, 0), (0, 0)],
        ): const AugmentEffect.patternAttackDamageBonus(
          value: 40,
          description: '+40 dano a cada ataque del patron.',
        ),
      },
    ),
  ),
  Augment(
    id: 5,
    name: 'Augment Recursivo',
    description: 'Escala patrones que vuelven al centro para cerrar negocio.',
    tier: RarityTier.gray,
    assetPath: 'assets/sprites/unknown.png',
    affinity: AugmentAffinity.mercante,
    tags: const <EntityTag>[EntityTag.ataque, EntityTag.economia],
    effects: AugmentEffects(
      patternEffects: {
        _points(const [(-1, 0), (0, 0), (1, 0)]):
            const AugmentEffect.patternAttackDamageBonus(
          value: 4,
          description: '+4 dano a cada ataque del patron.',
        ),
        _points(const [(-1, 0), (0, 0), (1, 0), (0, 0), (0, 1)]):
            const AugmentEffect.patternAttackDamageBonus(
          value: 8,
          description: '+8 dano a cada ataque del patron.',
        ),
        _points(const [(-1, 0), (0, 0), (1, 0), (0, 0), (0, 1)]):
            const AugmentEffect.patternAttackDamageBonus(
          value: 12,
          description: '+12 dano a cada ataque del patron.',
        ),
        _points(
          const [(-1, 0), (0, 0), (1, 0), (0, 0), (0, 1), (0, 0), (0, -1)],
        ): const AugmentEffect.patternAttackDamageBonus(
          value: 20,
          description: '+20 dano a cada ataque del patron.',
        ),
        _points(
          const [(-1, 0), (0, 0), (1, 0), (0, 0), (0, 1), (0, 0), (0, -1)],
        ): const AugmentEffect.patternAttackDamageBonus(
          value: 32,
          description: '+32 dano a cada ataque del patron.',
        ),
      },
    ),
  ),
]);

final Map<int, Augment> augmentCatalogById = Map<int, Augment>.unmodifiable({
  for (final augment in augmentCatalog) augment.id: augment,
});

List<Augment> augmentCatalogForArchetype(ArchetypeId? archetypeId) {
  if (archetypeId == null) return augmentCatalog;

  final affinities = <AugmentAffinity>{
    AugmentAffinity.general,
    archetypeId.augmentAffinity,
  };
  return List<Augment>.unmodifiable(
    augmentCatalog.where((augment) => affinities.contains(augment.affinity)),
  );
}

List<OperativePatternPoint> _points(List<(int, int)> coordinates) {
  return List<OperativePatternPoint>.unmodifiable([
    for (final (x, y) in coordinates) OperativePatternPoint(x: x, y: y),
  ]);
}
