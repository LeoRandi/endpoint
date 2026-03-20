import '_imports.dart';

class BattleSkillsDialog extends StatelessWidget {
  final List<String> skills;

  const BattleSkillsDialog({
    super.key,
    this.skills = const [],
  });

  @override
  Widget build(BuildContext context) {
    return BattleFloatingMenu(
      title: 'Habilidades',
      subtitle: 'Tecnicas del battler',
      emptyText: 'No tienes ninguna habilidad',
      entries: skills,
      entryTooltips: const {
        'Defender': 'Consumir turno sin atacar',
      },
      closeTooltip: 'Cerrar habilidades',
    );
  }
}
