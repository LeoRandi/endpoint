import '_imports.dart';

class BattleItemsDialog extends StatelessWidget {
  final List<Item> items;
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
    return BattleFloatingMenu<Item>(
      title: 'Objetos',
      subtitle: subtitle,
      emptyText: emptyText,
      entries: items
          .map(
            (item) => BattleMenuEntry<Item>(
              value: item,
              label: item.name,
              tooltip: item.description,
              isEnabled: false,
            ),
          )
          .toList(growable: false),
      closeTooltip: 'Cerrar inventario',
      bottomInset: bottomInset,
    );
  }
}
