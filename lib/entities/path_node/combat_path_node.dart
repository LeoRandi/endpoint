import '../_imports.dart';

/// Separa los encuentros por escalon para reutilizar rareza, color y factor de recompensa.
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

/// Nodo de ruta que abre un combate concreto contra un enemigo prefijado.
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
}
