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
    id: 3,
    name: 'Crackling Overload',
    description:
        'Aplica debuffs al enemigo al completar formaciones Crepitans.',
    tier: RarityTier.gray,
    assetPath: 'assets/sprites/unknown.png',
    affinity: AugmentAffinity.crepitans,
    tags: const <EntityTag>[
      EntityTag.debuff,
      EntityTag.quemadura,
      EntityTag.intoxicacion,
    ],
    effects: AugmentEffects(
      patternEffects: {
        _points(const [(-1, 1), (0, 1), (1, 1), (0, 0)]):
            const AugmentEffect.patternOpponentDebuffs(
          description: 'Aplica 2 Fragilidad al enemigo.',
          opponentDebuffs: <AugmentDebuffApplication>[
            AugmentDebuffApplication(
              type: AugmentDebuffType.fragilidad,
              value: 2,
            ),
          ],
        ),
        _points(const [(1, -1), (0, -1), (-1, -1), (0, 0)]):
            const AugmentEffect.patternOpponentDebuffs(
          description: 'Aplica 2 Conmocion al enemigo.',
          opponentDebuffs: <AugmentDebuffApplication>[
            AugmentDebuffApplication(
              type: AugmentDebuffType.conmocion,
              value: 2,
            ),
          ],
        ),
        _points(const [(0, 0), (-1, 1), (0, 1), (1, 1), (-1, -1)]):
            const AugmentEffect.patternOpponentDebuffs(
          description: 'Aplica 2 Fragilidad y 2 Intoxicacion al enemigo.',
          opponentDebuffs: <AugmentDebuffApplication>[
            AugmentDebuffApplication(
              type: AugmentDebuffType.fragilidad,
              value: 2,
            ),
            AugmentDebuffApplication(
              type: AugmentDebuffType.intoxicacion,
              value: 2,
            ),
          ],
        ),
        _points(const [(0, 0), (1, -1), (0, -1), (-1, -1), (1, 1)]):
            const AugmentEffect.patternOpponentDebuffs(
          description: 'Aplica 2 Conmocion y 4 Quemadura al enemigo.',
          opponentDebuffs: <AugmentDebuffApplication>[
            AugmentDebuffApplication(
              type: AugmentDebuffType.conmocion,
              value: 2,
            ),
            AugmentDebuffApplication(
              type: AugmentDebuffType.quemadura,
              value: 4,
            ),
          ],
        ),
        _points(
          const [
            (0, 0),
            (-1, 1),
            (0, 1),
            (1, 1),
            (-1, -1),
            (0, -1),
            (-1, -1),
            (0, 0),
          ],
        ): const AugmentEffect.patternOpponentDebuffs(
          description:
              'Aplica 2 Fragilidad, 2 Conmocion, 2 Intoxicacion y 4 Quemadura al enemigo.',
          opponentDebuffs: <AugmentDebuffApplication>[
            AugmentDebuffApplication(
              type: AugmentDebuffType.fragilidad,
              value: 2,
            ),
            AugmentDebuffApplication(
              type: AugmentDebuffType.conmocion,
              value: 2,
            ),
            AugmentDebuffApplication(
              type: AugmentDebuffType.intoxicacion,
              value: 2,
            ),
            AugmentDebuffApplication(
              type: AugmentDebuffType.quemadura,
              value: 4,
            ),
          ],
        ),
      },
    ),
  ),
  Augment(
    id: 4,
    name: 'Obsidian Fortress',
    description:
        'Gana Barrera antes de resolver la pila de acciones al completar la formacion.',
    tier: RarityTier.gray,
    assetPath: 'assets/sprites/unknown.png',
    affinity: AugmentAffinity.diabolicus,
    tags: const <EntityTag>[EntityTag.barrera],
    effects: AugmentEffects(
      patternEffects: {
        _points(const [(-1, -1), (0, 0), (1, 1)]):
            const AugmentEffect.patternOwnerBarrierBonus(
          value: 3,
          description: '+3 Barrera antes de resolver la pila de acciones.',
        ),
        _points(const [(-1, -1), (0, 0), (1, 1)]):
            const AugmentEffect.patternOwnerBarrierBonus(
          value: 7,
          description: '+7 Barrera antes de resolver la pila de acciones.',
        ),
        _points(const [(0, -1), (-1, -1), (0, 0), (1, 1), (0, 1)]):
            const AugmentEffect.patternOwnerBarrierBonus(
          value: 15,
          description: '+15 Barrera antes de resolver la pila de acciones.',
        ),
        _points(const [(0, -1), (-1, -1), (0, 0), (1, 1), (0, 1)]):
            const AugmentEffect.patternOwnerBarrierBonus(
          value: 27,
          description: '+27 Barrera antes de resolver la pila de acciones.',
        ),
        _points(const [(0, -1), (-1, -1), (0, 0), (1, 1), (0, 1)]):
            const AugmentEffect.patternOwnerBarrierBonus(
          value: 43,
          description: '+43 Barrera antes de resolver la pila de acciones.',
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
