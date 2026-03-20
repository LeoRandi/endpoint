import '_imports.dart';

class BattleItemsDialog extends StatelessWidget {
  final List<String> items;
  final String subtitle;
  final String emptyText;
  final double bottomInset;

  const BattleItemsDialog({
    super.key,
    this.items = const [],
    this.subtitle = 'Inventario de combate',
    this.emptyText = 'No tienes ningun objeto',
    this.bottomInset = 164,
  });

  @override
  Widget build(BuildContext context) {
    return BattleFloatingMenu(
      title: 'Objetos',
      subtitle: subtitle,
      emptyText: emptyText,
      entries: items,
      closeTooltip: 'Cerrar inventario',
      bottomInset: bottomInset,
    );
  }
}
