import '../archetype_id.dart';
import '../entity_tag.dart';
import '../pattern/_exports.dart';
import '../rarity_tier.dart';
import 'augment.dart';

final List<Augment> augmentCatalog = List<Augment>.unmodifiable([
  Augment(
    id: 1,
    name: 'Augment M',
    description:
        'Mejora las armas del patron cuando el patron contiene una M.',
    tier: RarityTier.gray,
    assetPath: 'assets/sprites/unknown.png',
    affinity: AugmentAffinity.general,
    tags: const <EntityTag>[EntityTag.ataque],
    effects: AugmentEffects(
      patternEffects: {
        _points(const [(-1, 1), (0, 0), (1, 1)]):
            const AugmentEffect.patternAttackDamageBonus(
          value: 1,
          description: '+1 dano a las armas del patron durante el combate.',
        ),
        _points(const [(-1, 0), (-1, 1), (0, 0), (1, 1), (1, 0)]):
            const AugmentEffect.patternAttackDamageBonus(
          value: 2,
          description: '+2 dano a las armas del patron durante el combate.',
        ),
        _points(const [(-1, 0), (-1, 1), (0, 0), (1, 1), (1, 0)]):
            const AugmentEffect.patternAttackDamageBonus(
          value: 3,
          description: '+3 dano a las armas del patron durante el combate.',
        ),
        _points(
          const [
            (-1, -1),
            (-1, 0),
            (-1, 1),
            (0, 0),
            (1, 1),
            (1, 0),
            (1, -1),
          ],
        ): const AugmentEffect.patternAttackDamageBonus(
          value: 4,
          description: '+4 dano a las armas del patron durante el combate.',
        ),
        _points(
          const [
            (-1, -1),
            (-1, 0),
            (-1, 1),
            (0, 0),
            (1, 1),
            (1, 0),
            (1, -1),
          ],
        ): const AugmentEffect.patternAttackDamageBonus(
          value: 5,
          description: '+5 dano a las armas del patron durante el combate.',
        ),
      },
    ),
  ),
  Augment(
    id: 2,
    name: 'Spear Head Formation',
    description:
        'El arma en [-1, 1] gana dano permanente al completar la formacion.',
    tier: RarityTier.gray,
    assetPath: 'assets/sprites/unknown.png',
    affinity: AugmentAffinity.hercules,
    tags: const <EntityTag>[EntityTag.ataque, EntityTag.arma],
    effects: AugmentEffects(
      patternEffects: {
        _points(const [(-1, 0), (-1, 1), (0, 1)]):
            const AugmentEffect.patternTargetWeaponPermanentAttackDamageBonus(
          value: 1,
          description:
              '+1 dano permanente al arma en [-1, 1] si es parte del patron.',
          targetPoint: OperativePatternPoint(x: -1, y: 1),
        ),
        _points(const [(-1, 0), (-1, 1), (0, 1)]):
            const AugmentEffect.patternTargetWeaponPermanentAttackDamageBonus(
          value: 2,
          description:
              '+2 dano permanente al arma en [-1, 1] si es parte del patron.',
          targetPoint: OperativePatternPoint(x: -1, y: 1),
        ),
        _points(const [(0, -1), (-1, 0), (-1, 1), (0, 1), (1, 0)]):
            const AugmentEffect.patternTargetWeaponPermanentAttackDamageBonus(
          value: 3,
          description:
              '+3 dano permanente al arma en [-1, 1] si es parte del patron.',
          targetPoint: OperativePatternPoint(x: -1, y: 1),
        ),
        _points(const [(0, -1), (-1, 0), (-1, 1), (0, 1), (1, 0)]):
            const AugmentEffect.patternTargetWeaponPermanentAttackDamageBonus(
          value: 4,
          description:
              '+4 dano permanente al arma en [-1, 1] si es parte del patron.',
          targetPoint: OperativePatternPoint(x: -1, y: 1),
        ),
        _points(const [(0, -1), (-1, 0), (-1, 1), (0, 1), (1, 0)]):
            const AugmentEffect.patternTargetWeaponPermanentAttackDamageBonus(
          value: 5,
          description:
              '+5 dano permanente al arma en [-1, 1] si es parte del patron.',
          targetPoint: OperativePatternPoint(x: -1, y: 1),
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
