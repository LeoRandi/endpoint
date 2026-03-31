import '../_imports.dart';

/// Mantiene compatibilidad con las llamadas existentes aunque ya no existan slots visibles.
enum EndpointEquipmentLayout {
  standard,
  generic,
}

/// Renderiza solo los objetos equipados como cards y muestra el presupuesto `x/y`.
class EndpointEquipmentSlotsStrip extends StatelessWidget {
  final Battler battler;
  final EndpointEquipmentLayout layout;
  final ValueChanged<Item>? onItemPressed;
  final double tileExtent;
  final double tileHeight;
  final double emojiSize;
  final double spacing;
  final Color borderColor;
  final Color backgroundColor;
  final Color textColor;

  const EndpointEquipmentSlotsStrip({
    super.key,
    required this.battler,
    this.layout = EndpointEquipmentLayout.standard,
    this.onItemPressed,
    this.tileExtent = 70,
    this.tileHeight = 84,
    this.emojiSize = 18,
    this.spacing = 8,
    this.borderColor = EndpointPalette.accentBorderSoft,
    this.backgroundColor = EndpointPalette.controlBackground,
    this.textColor = EndpointPalette.softForeground,
  });

  @override
  Widget build(BuildContext context) {
    final equippedItems = _buildVisibleItems();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        equippedItems.isEmpty ? _buildEmptyState() : _buildItemsRow(equippedItems),
        Positioned(
          top: -8,
          right: 0,
          child: _EndpointEquipmentBudgetBadge(
            usedCost: battler.equippedItemCost,
            maxCost: battler.equipmentCapacity,
          ),
        ),
      ],
    );
  }

  /// Devuelve solo los objetos equipados que deben verse, sin huecos vacios intermedios.
  List<Item> _buildVisibleItems() {
    switch (layout) {
      case EndpointEquipmentLayout.standard:
      case EndpointEquipmentLayout.generic:
        return battler.equippedItems;
    }
  }

  /// Construye la fila de cards reales para cada objeto actualmente equipado.
  Widget _buildItemsRow(List<Item> equippedItems) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int index = 0; index < equippedItems.length; index++) ...[
          if (index > 0) SizedBox(width: spacing),
          _buildItemTile(equippedItems[index]),
        ],
      ],
    );
  }

  /// Construye una card compacta para un unico objeto equipado.
  Widget _buildItemTile(Item item) {
    return SizedBox(
      width: tileExtent,
      height: tileHeight,
      child: _EndpointEquippedItemCard(
        item: item,
        emojiSize: emojiSize,
        borderColor: borderColor,
        backgroundColor: backgroundColor,
        textColor: textColor,
        onPressed: onItemPressed == null ? null : () => onItemPressed!.call(item),
      ),
    );
  }

  /// Construye un estado vacio minimo cuando todavia no hay objetos equipados.
  Widget _buildEmptyState() {
    return SizedBox(
      width: max(tileExtent * 1.6, 108),
      height: tileHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Center(
          child: EndpointText(
            'Sin equipo',
            textAlign: TextAlign.center,
            style: textSmallBold.copyWith(
              color: textColor.withOpacity(0.72),
              letterSpacing: 0.6,
            ),
          ),
        ),
      ),
    );
  }
}

/// Muestra el presupuesto de equipo consumido frente al maximo actual del battler.
class _EndpointEquipmentBudgetBadge extends StatelessWidget {
  final int usedCost;
  final int maxCost;

  const _EndpointEquipmentBudgetBadge({
    required this.usedCost,
    required this.maxCost,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: EndpointPalette.panelBackgroundGold,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: EndpointPalette.rewardAccent.withAlpha(168)),
        boxShadow: [
          BoxShadow(
            color: EndpointPalette.rewardAccent.withAlpha(46),
            blurRadius: 12,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 3, 8, 3),
        child: EndpointText(
          '$usedCost/$maxCost',
          style: textSmallNumericBold.copyWith(
            color: EndpointPalette.rewardAccent,
            fontSize: 11,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

/// Representa una card simple de objeto equipado sin iconografia de slot.
class _EndpointEquippedItemCard extends StatelessWidget {
  final Item item;
  final double emojiSize;
  final Color borderColor;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback? onPressed;

  const _EndpointEquippedItemCard({
    required this.item,
    required this.emojiSize,
    required this.borderColor,
    required this.backgroundColor,
    required this.textColor,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: borderColor),
      boxShadow: [
        BoxShadow(
          color: borderColor.withOpacity(0.12),
          blurRadius: 8,
        ),
      ],
    );
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: EndpointText(
                item.iconEmoji,
                style: TextStyle(
                  fontSize: emojiSize,
                  height: 1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          EndpointText(
            item.displayName,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: textSmallBold.copyWith(
              color: textColor,
              fontSize: 11,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );

    return HoldTooltip(
      message: item.tooltipDescription,
      child: onPressed == null
          ? DecoratedBox(
              decoration: decoration,
              child: content,
            )
          : Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPressed,
                borderRadius: BorderRadius.circular(12),
                child: Ink(
                  decoration: decoration,
                  child: content,
                ),
              ),
            ),
    );
  }
}
