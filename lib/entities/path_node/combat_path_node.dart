import '_imports.dart';

/// Separa los encuentros por escalon para reutilizar rareza, color y factor de recompensa.
///
/// El tier no es solo presentacion: tambien alimenta pools por dia, fuerza del
/// aura visual de boss y multiplicadores de recompensa.
enum CombatNodeTier {
  gray,
  green,
  blue,
  purple,
  yellow;

  /// Devuelve la rareza equivalente al escalon del combate.
  RarityTier get rarity {
    switch (this) {
      case CombatNodeTier.gray:
        return RarityTier.gray;
      case CombatNodeTier.green:
        return RarityTier.green;
      case CombatNodeTier.blue:
        return RarityTier.blue;
      case CombatNodeTier.purple:
        return RarityTier.purple;
      case CombatNodeTier.yellow:
        return RarityTier.yellow;
    }
  }

  /// Reexpone el color de la rareza para pintar el nodo.
  Color get accent => rarity.accent;

  /// Reexpone la etiqueta de rareza para el badge del nodo.
  String get badgeLabel => rarity.label;

  /// Reexpone el factor numerico del tier para economia y recompensas.
  int get factor => rarity.factor;
}

/// Centraliza como escalan los enemigos segun tier y dia de la run.
///
/// Mantener estas reglas fuera del preset permite que los pools de enemigos
/// sigan siendo canonicos y que cada nodo proyecte la dificultad al mostrarse.
abstract final class EnemyCombatScalingRules {
  /// Devuelve el nivel inicial de un enemigo para el tier indicado.
  static int baseLevelFor(CombatNodeTier tier) {
    return switch (tier) {
      CombatNodeTier.gray => 1,
      CombatNodeTier.green => 2,
      CombatNodeTier.blue => 3,
      CombatNodeTier.purple => 5,
      CombatNodeTier.yellow => 8,
    };
  }

  /// Devuelve el nivel maximo permitido para un tier de combate.
  static int maxLevelFor(CombatNodeTier tier) {
    return switch (tier) {
      CombatNodeTier.gray => 1,
      CombatNodeTier.green => 3,
      CombatNodeTier.blue => 5,
      CombatNodeTier.purple => 7,
      CombatNodeTier.yellow => 8,
    };
  }

  /// Calcula el nivel objetivo del enemigo para el dia actual.
  ///
  /// Los tiers altos empiezan a progresar mas tarde y cada tier queda limitado
  /// por su propio techo para no invadir el espacio de dificultad del siguiente.
  static int levelFor({
    required CombatNodeTier tier,
    required int dayNumber,
  }) {
    if (tier == CombatNodeTier.yellow) return 8;

    final baseLevel = baseLevelFor(tier);
    final progressionStartDay = switch (tier) {
      CombatNodeTier.gray => 99,
      CombatNodeTier.green => 3,
      CombatNodeTier.blue => 4,
      CombatNodeTier.purple => 4,
      CombatNodeTier.yellow => 99,
    };
    final levelBonus = max(0, dayNumber - progressionStartDay + 1);
    return min(maxLevelFor(tier), baseLevel + levelBonus);
  }

  /// Devuelve una copia del enemigo ajustada al tier y dia pedidos.
  ///
  /// Se escala desde las stats base del preset para que repetir el proceso no
  /// acumule incrementos sobre un enemigo ya escalado.
  static Battler scaleEnemy({
    required Battler enemy,
    required CombatNodeTier tier,
    required int dayNumber,
  }) {
    final level = levelFor(tier: tier, dayNumber: dayNumber);
    final baseLevel = baseLevelFor(tier);
    final levelBonus = max(0, level - baseLevel);
    final baseStats = Map<BattlerStat, int>.from(enemy.baseStats);
    var scaledHealth =
        (baseStats[BattlerStat.health] ?? enemy.health) + (levelBonus * 5);
    var scaledAttack =
        (baseStats[BattlerStat.attack] ?? enemy.baseAttack) + levelBonus;
    final scaledBarrier =
        (baseStats[BattlerStat.barrier] ?? enemy.baseBarrier) + levelBonus;
    if (tier == CombatNodeTier.blue ||
        tier == CombatNodeTier.purple ||
        tier == CombatNodeTier.yellow) {
      scaledHealth = max(1, (scaledHealth * 0.75).round());
      scaledAttack = max(1, (scaledAttack * 0.75).round());
    }

    baseStats[BattlerStat.health] = scaledHealth;
    baseStats[BattlerStat.attack] = tier == CombatNodeTier.yellow
        ? scaledAttack
        : max(1, (scaledAttack / 2).round());
    baseStats[BattlerStat.barrier] = scaledBarrier;

    return enemy.copyWith(
      level: level,
      health: scaledHealth,
      baseStats: Map<BattlerStat, int>.unmodifiable(baseStats),
    );
  }
}

/// Nodo de ruta que abre un combate concreto contra un enemigo prefijado.
///
/// Mantiene juntos el battler enemigo y su tier para que el coordinador pueda
/// construir `BattlePage` sin conocer pools ni presets.
class CombatPathNode extends PathNode {
  final Battler enemy;
  final CombatNodeTier tier;

  /// Crea un nodo de combate ya conectado a un enemigo y a su tier de recompensas.
  CombatPathNode({
    String? nodeId,
    required this.enemy,
    required this.tier,
    required String label,
    String? tooltip,
    String iconEmoji = '\u{1F47E}',
  }) : super.base(
          type: PathNodeType.encounter,
          nodeId: nodeId ?? 'encounter:$label',
          label: label,
          tooltip: tooltip ?? label,
          iconEmoji: iconEmoji,
          rarity: tier.rarity,
          accent: tier.accent,
          badgeLabel: tier.badgeLabel,
        );

  /// Devuelve el texto principal que se usa como titulo de la escena de combate.
  String get showTitle => label;

  /// Devuelve un nodo equivalente con el enemigo proyectado al dia indicado.
  CombatPathNode scaledForDay(int dayNumber) {
    return CombatPathNode(
      nodeId: nodeId,
      enemy: EnemyCombatScalingRules.scaleEnemy(
        enemy: enemy,
        tier: tier,
        dayNumber: dayNumber,
      ),
      tier: tier,
      label: label,
      tooltip: tooltip,
      iconEmoji: iconEmoji,
    );
  }
}
