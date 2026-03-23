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
    final entries = items.map((item) => item.name).toList();
    final entryTooltips = {
      for (final item in items) item.name: item.description,
    };

    return BattleFloatingMenu(
      title: 'Objetos',
      subtitle: subtitle,
      emptyText: emptyText,
      entries: entries,
      entryTooltips: entryTooltips,
      closeTooltip: 'Cerrar inventario',
      bottomInset: bottomInset,
    );
  }
}
