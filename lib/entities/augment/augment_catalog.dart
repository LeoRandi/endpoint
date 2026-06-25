import '../archetype_id.dart';
import '../entity_tag.dart';
import '../pattern/_exports.dart';
import '../rarity_tier.dart';
import 'augment.dart';

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
          value: 30,
          description: '+30 dano a cada ataque del patron.',
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
          value: 50,
          description: '+50 dano a cada ataque del patron.',
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
