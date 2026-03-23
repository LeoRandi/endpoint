import '_imports.dart';

class BattleSkillsDialog extends StatelessWidget {
  final List<BattlerAbility> skills;

  const BattleSkillsDialog({
    super.key,
    this.skills = const [],
  });

  @override
  Widget build(BuildContext context) {
    return BattleFloatingMenu<BattlerAbility>(
      title: 'Habilidades',
      subtitle: 'Tecnicas del battler',
      emptyText: 'No tienes ninguna habilidad',
      entries: skills
          .map(
            (ability) => BattleMenuEntry<BattlerAbility>(
              value: ability,
              label: ability.label,
              tooltip: ability.tooltip,
              isEnabled: ability.isImplemented,
            ),
          )
          .toList(growable: false),
      closeTooltip: 'Cerrar habilidades',
    );
  }
}
