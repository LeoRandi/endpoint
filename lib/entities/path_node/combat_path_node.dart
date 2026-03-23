import '_imports.dart';

enum CombatNodeTier {
  gray(
    accent: Color(0xFF9EA7B3),
    badgeLabel: 'GRIS',
  ),
  green(
    accent: Color(0xFF5AF78E),
    badgeLabel: 'VERDE',
  ),
  blue(
    accent: Color(0xFF59B7FF),
    badgeLabel: 'AZUL',
  ),
  purple(
    accent: Color(0xFFBE7CFF),
    badgeLabel: 'MORADO',
  ),
  yellow(
    accent: Color(0xFFF3D35C),
    badgeLabel: 'AMARILLO',
  );

  final Color accent;
  final String badgeLabel;

  const CombatNodeTier({
    required this.accent,
    required this.badgeLabel,
  });
}

class CombatPathNode extends PathNode {
  final Battler enemy;
  final CombatNodeTier tier;

  CombatPathNode({
    required this.enemy,
    required this.tier,
    required String label,
    String? tooltip,
    String iconEmoji = '\u{1F47E}',
  }) : super.base(
          type: PathNodeType.encounter,
          label: label,
          tooltip: tooltip ?? label,
          iconEmoji: iconEmoji,
          accent: tier.accent,
          badgeLabel: tier.badgeLabel,
        );

  String get showTitle => label;
}
