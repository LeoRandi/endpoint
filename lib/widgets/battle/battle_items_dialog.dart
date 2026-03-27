import '_imports.dart';

class BattleItemsDialog extends StatelessWidget {
  final Battler player;
  final List<Item> items;
  final String subtitle;
  final String emptyText;
  final double bottomInset;

  const BattleItemsDialog({
    super.key,
    required this.player,
    this.items = const [],
    this.subtitle = 'Inventario de combate',
    this.emptyText = EndpointStrings.noItems,
    this.bottomInset = 112,
  });

  @override
  Widget build(BuildContext context) {
    return EndpointInventoryOverlay(
      title: 'Objetos',
      subtitle: subtitle,
      emptyText: emptyText,
      closeTooltip: 'Cerrar inventario',
      items: items,
      bottomInset: bottomInset,
      detailStatusBuilder: (item) {
        if (player.equippedItems.contains(item)) {
          return 'Estado actual: equipado';
        }
        return 'Estado actual: en inventario';
      },
    );
  }
}
