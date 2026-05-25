import '../_imports.dart';
import '../../services/endpoint_preferences_models.dart';
import '../../services/operative_pattern_adjacency_service.dart';
import '../../services/operative_pattern_layout_service.dart';
import 'package:flutter/foundation.dart';

const _operativeTileExtent = 70.0;
const _operativeTileHeight = 84.0;
const _operativesPatternPanelHeight = 340.0;
const _operativesPatternBoardScale = 0.92;
const _operativesPatternDiamondRotation = pi / 4;
const _operativesPatternPointVisualSize = 38.0;
const _operativesPatternPointHitSize = 64.0;

class OperativesOverlay extends StatefulWidget {
  final Battler player;
  final List<Battler> companions;
  final ValueChanged<Battler>? onPlayerChanged;
  final EndpointGameMode gameMode;

  const OperativesOverlay({
    super.key,
    required this.player,
    this.companions = const [],
    this.onPlayerChanged,
    this.gameMode = EndpointGameMode.pattern,
  });

  @override
  State<OperativesOverlay> createState() => _OperativesOverlayState();
}

class _OperativesOverlayState extends State<OperativesOverlay> {
  late OperativesOverlayController _controller;
  final Map<Item, OperativePatternPoint> _patternAssignments =
      <Item, OperativePatternPoint>{};
  Map<String, String>? _scheduledPatternItemPointKeys;

  @override
  void initState() {
    super.initState();
    _controller = _buildController();
  }

  /// Reconstruye el controlador cuando cambia el jugador visible o la lista de acompanantes.
  @override
  void didUpdateWidget(covariant OperativesOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.player == widget.player &&
        listEquals(oldWidget.companions, widget.companions) &&
        oldWidget.onPlayerChanged == widget.onPlayerChanged &&
        oldWidget.gameMode == widget.gameMode) {
      return;
    }

    _controller.dispose();
    _controller = _buildController();
  }

  /// Crea el controlador que centraliza seleccion y equipo dentro del overlay.
  OperativesOverlayController _buildController() {
    return OperativesOverlayController(
      player: widget.player,
      companions: widget.companions,
      onPlayerChanged: widget.onPlayerChanged,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openItemDetails(Item item) async {
    final isPatternMode = widget.gameMode == EndpointGameMode.pattern;

    await showEndpointDialog<void>(
      context: context,
      barrierLabel: 'Detalle de objeto',
      barrierColor: EndpointPalette.overlayScrim,
      builder: (context) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return EndpointItemDetailsDialog(
              item: item,
              accent: item.rarity.accent,
              price: item.sellValue,
              priceLabel: 'VENTA',
              statusText: _controller.statusLabelFor(item),
              actionLabel:
                  isPatternMode ? null : _controller.actionLabelFor(item),
              onPrimaryAction:
                  !isPatternMode && _controller.isActionEnabled(item)
                      ? () {
                          _controller.handlePrimaryAction(item);
                        }
                      : null,
              secondaryActionLabel: _controller.sellActionLabelFor(item),
              secondaryActionIcon: Icons.sell_rounded,
              onSecondaryAction: () {
                final wasSold = _controller.sellInventoryItem(item);
                if (wasSold) Navigator.of(context).pop();
              },
              isSecondaryActionEnabled:
                  _controller.sellActionLabelFor(item) != null,
              enabledSecondaryActionTooltip:
                  'Vender objeto fuera de tienda por ${_controller.quickSellValueFor(item)} creditos',
              disabledSecondaryActionTooltip:
                  'El objeto ya no esta en tu inventario',
              isActionEnabled:
                  !isPatternMode && _controller.isActionEnabled(item),
              enabledActionTooltip: _controller.enabledActionTooltipFor(item),
              disabledActionTooltip: _controller.disabledActionTooltipFor(item),
            );
          },
        );
      },
    );
  }

  Future<void> _openEquippedItemDetails(
    Item item, {
    required Battler owner,
    required bool canUnequip,
  }) async {
    await showEndpointDialog<void>(
      context: context,
      barrierLabel: 'Detalle de objeto equipado',
      barrierColor: EndpointPalette.overlayScrim,
      builder: (context) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final detailBattler = canUnequip ? _controller.player : owner;

            return EndpointItemDetailsDialog(
              item: item,
              accent: item.rarity.accent,
              price: item.sellValue,
              priceLabel: 'VENTA',
              statusText: _controller.statusLabelForOwner(detailBattler, item),
              actionLabel: _controller.unequipActionLabelFor(
                detailBattler,
                item,
                canUnequip,
              ),
              onPrimaryAction: _controller.isUnequipEnabled(
                detailBattler,
                item,
                canUnequip,
              )
                  ? () {
                      _controller.handleUnequipItem(item);
                    }
                  : null,
              isActionEnabled: _controller.isUnequipEnabled(
                detailBattler,
                item,
                canUnequip,
              ),
              enabledActionTooltip: 'Quitar objeto del equipo activo',
              disabledActionTooltip: 'El objeto ya no esta equipado',
            );
          },
        );
      },
    );
  }

  void _syncPatternAssignments(
    Battler player, {
    bool persistPlayer = false,
  }) {
    final layout = OperativePatternLayoutService.resolveForPlayer(
      player: player,
    );
    final pointsByKey = <String, OperativePatternPoint>{
      for (final point in operativePatternPoints) point.key: point,
    };

    _patternAssignments.clear();
    for (final entry in layout.itemsByPointKey.entries) {
      final point = pointsByKey[entry.key];
      if (point == null) continue;
      _patternAssignments[entry.value] = point;
    }

    if (identical(layout.player, player)) return;
    if (persistPlayer) {
      _controller.replacePlayer(layout.player);
      return;
    }

    _queuePatternLayoutPersistence(layout.player.patternItemPointKeys);
  }

  void _queuePatternLayoutPersistence(
      Map<String, String> patternItemPointKeys) {
    if (mapEquals(_scheduledPatternItemPointKeys, patternItemPointKeys)) {
      return;
    }

    _scheduledPatternItemPointKeys = Map<String, String>.unmodifiable(
      patternItemPointKeys,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final scheduledPatternItemPointKeys = _scheduledPatternItemPointKeys;
      _scheduledPatternItemPointKeys = null;
      if (!mounted || scheduledPatternItemPointKeys == null) return;
      if (mapEquals(
        _controller.player.patternItemPointKeys,
        scheduledPatternItemPointKeys,
      )) {
        return;
      }

      _controller.replacePlayer(
        _controller.player.copyWith(
          patternItemPointKeys: scheduledPatternItemPointKeys,
        ),
      );
    });
  }

  bool _canPlaceItemOnPatternPoint(Item item, OperativePatternPoint point) {
    if (widget.gameMode != EndpointGameMode.pattern) return false;
    if (!_controller.isPlayerSelected) return false;
    if (!item.isEquippable) return false;

    final itemAtPoint = _itemAssignedToPatternPoint(point);
    if (itemAtPoint != null) return false;

    if (_controller.player.equippedItems.contains(item)) return true;
    return _controller.isActionEnabled(item);
  }

  Item? _itemAssignedToPatternPoint(OperativePatternPoint point) {
    for (final entry in _patternAssignments.entries) {
      if (entry.value == point) return entry.key;
    }
    return null;
  }

  void _placePatternItemOnPoint(Item item, OperativePatternPoint point) {
    if (!_canPlaceItemOnPatternPoint(item, point)) return;

    if (_controller.player.equippedItems.contains(item)) {
      setState(() {
        _patternAssignments[item] = point;
      });
      _controller.replacePlayer(
        OperativePatternLayoutService.rememberItemPoint(
          player: _controller.player,
          item: item,
          pointKey: point.key,
        ),
      );
      return;
    }

    final wasEquipped = _controller.equipInventoryItem(item);
    if (!wasEquipped) return;

    final updatedPlayer = OperativePatternLayoutService.rememberItemPoint(
      player: _controller.player,
      item: item,
      pointKey: point.key,
    );
    setState(() {
      _patternAssignments[item] = point;
    });
    _controller.replacePlayer(updatedPlayer);
  }

  bool _canUnequipPatternItem(Item item) {
    if (widget.gameMode != EndpointGameMode.pattern) return false;
    if (!_controller.isPlayerSelected) return false;
    return _controller.player.equippedItems.contains(item);
  }

  void _unequipPatternItemToInventory(Item item) {
    if (!_canUnequipPatternItem(item)) return;

    final wasUnequipped = _controller.unequipEquippedItem(item);
    if (!wasUnequipped) return;

    final updatedPlayer = OperativePatternLayoutService.forgetItem(
      player: _controller.player,
      item: item,
    );
    setState(() {
      _patternAssignments.remove(item);
    });
    _controller.replacePlayer(updatedPlayer);
  }

  Widget _buildInventoryItemTile(Item item) {
    final tile = EndpointInventoryItemTile(
      item: item,
      onPressed: () => _openItemDetails(item),
    );

    if (widget.gameMode != EndpointGameMode.pattern ||
        !_controller.isPlayerSelected ||
        !item.isEquippable) {
      return tile;
    }

    return Draggable<Item>(
      data: item,
      maxSimultaneousDrags: 1,
      rootOverlay: true,
      feedback: SizedBox(
        width: _operativeTileExtent,
        height: _operativeTileHeight,
        child: Material(
          color: Colors.transparent,
          child: EndpointInventoryItemTile(
            item: item,
            glowOpacity: 0.14,
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: tile,
      ),
      child: tile,
    );
  }

  Widget _buildInventoryArea(Battler player) {
    final content = player.inventoryItems.isEmpty
        ? Center(
            child: EndpointText(
              'No llevas ningun objeto.',
              textAlign: TextAlign.center,
              style: textSmallBold.copyWith(
                color: Colors.white.withValues(alpha: 0.72),
              ),
            ),
          )
        : LayoutBuilder(
            builder: (context, constraints) {
              return GridView.builder(
                itemCount: player.inventoryItems.length,
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: _operativeTileExtent,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  mainAxisExtent: _operativeTileHeight,
                ),
                itemBuilder: (context, index) {
                  final item = player.inventoryItems[index];
                  return _buildInventoryItemTile(item);
                },
              );
            },
          );

    if (widget.gameMode != EndpointGameMode.pattern ||
        !_controller.isPlayerSelected) {
      return content;
    }

    return DragTarget<Item>(
      onWillAcceptWithDetails: (details) {
        return _canUnequipPatternItem(details.data);
      },
      onAcceptWithDetails: (details) {
        _unequipPatternItemToInventory(details.data);
      },
      builder: (context, candidateItems, rejectedItems) {
        final isHighlighted = candidateItems.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isHighlighted
                ? Border.all(
                    color: EndpointPalette.patternAccent.withValues(
                      alpha: 0.72,
                    ),
                  )
                : null,
          ),
          child: content,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final operatives = _controller.operatives;
        final selectedOperative = _controller.selectedOperative;
        final player = _controller.player;
        final isPatternMode = widget.gameMode == EndpointGameMode.pattern;
        if (isPatternMode) {
          _syncPatternAssignments(player);
        }

        return SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 500,
                  maxHeight: min(size.height - 28, 620),
                ),
                child: Stack(
                  children: [
                    EndpointPanel(
                      accent: EndpointPalette.primaryAccent,
                      backgroundColor: EndpointPalette.panelBackgroundOpaque,
                      borderRadius: 18,
                      glowOpacity: 0.12,
                      blurRadius: 22,
                      spreadRadius: 2,
                      padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: EndpointText(
                                  'OPERATIVOS',
                                  style: textTitleMediumBold.copyWith(
                                    color: EndpointPalette.softForeground,
                                    letterSpacing: 1.8,
                                  ),
                                ),
                              ),
                              EndpointSceneCloseButton(
                                onPressed: () => Navigator.of(context).pop(),
                                tooltip: 'Cerrar operativos',
                              ),
                            ],
                          ),
                          if (!isPatternMode) ...[
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 60,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    for (int index = 0;
                                        index < operatives.length;
                                        index++) ...[
                                      if (index > 0) const SizedBox(width: 8),
                                      _OperativeIconCard(
                                        battler: operatives[index],
                                        isSelected:
                                            _controller.selectedIndex == index,
                                        isPlayer: index == 0,
                                        onPressed: () {
                                          _controller.selectOperative(index);
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                          ] else
                            const SizedBox(height: 8),
                          if (isPatternMode)
                            _PatternEquipmentPanel(
                              battler: player,
                              assignments: _patternAssignments,
                              onAcceptItem: _placePatternItemOnPoint,
                              canAcceptItem: _canPlaceItemOnPatternPoint,
                              onItemPressed: (item) => _openEquippedItemDetails(
                                item,
                                owner: player,
                                canUnequip: true,
                              ),
                            )
                          else
                            _EquipmentRow(
                              battler: selectedOperative,
                              isPlayer: _controller.isPlayerSelected,
                              onItemPressed: (item) => _openEquippedItemDetails(
                                item,
                                owner: selectedOperative,
                                canUnequip: _controller.isPlayerSelected,
                              ),
                            ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              EndpointText(
                                'OBJETOS DEL JUGADOR',
                                style: textSmallBold.copyWith(
                                  color: EndpointPalette.primaryAccent,
                                  letterSpacing: 1.4,
                                ),
                              ),
                              const Spacer(),
                              EndpointText(
                                '${player.inventoryItems.length}',
                                style: textSmallBold.copyWith(
                                  color: Colors.white.withValues(alpha: 0.76),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Expanded(child: _buildInventoryArea(player)),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 12,
                      bottom: 12,
                      child: _OperativesModeShortcuts(
                        gameMode: widget.gameMode,
                        onOpenPatternBoard: _openPatternBoard,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openPatternBoard() async {
    _syncPatternAssignments(_controller.player, persistPlayer: true);
    final equippedItemsByPointKey = <String, Item>{
      for (final entry in _patternAssignments.entries)
        entry.value.key: entry.key,
    };

    await showEndpointOverlay<void>(
      context: context,
      barrierLabel: 'Abrir patron de objetos',
      barrierColor: EndpointPalette.overlayScrimStrong,
      builder: (_) => OperativePatternOverlay(
        equippedItemsByPointKey: equippedItemsByPointKey,
        playerLevel: _controller.player.level,
      ),
    );
  }
}

class _PatternEquipmentPanel extends StatelessWidget {
  final Battler battler;
  final Map<Item, OperativePatternPoint> assignments;
  final bool Function(Item item, OperativePatternPoint point) canAcceptItem;
  final void Function(Item item, OperativePatternPoint point) onAcceptItem;
  final ValueChanged<Item>? onItemPressed;

  const _PatternEquipmentPanel({
    required this.battler,
    required this.assignments,
    required this.canAcceptItem,
    required this.onAcceptItem,
    this.onItemPressed,
  });

  @override
  Widget build(BuildContext context) {
    return EndpointPanel(
      backgroundColor: EndpointPalette.panelBackgroundSoft,
      borderRadius: 14,
      glowOpacity: 0.05,
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      child: SizedBox(
        height: _operativesPatternPanelHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: EndpointText(
                    'Equipamiento',
                    style: textSmallNumericBold.copyWith(
                      color: EndpointPalette.patternAccent,
                      fontSize: 11,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                EndpointEquipmentBudgetBadge(
                  usedCost: battler.equippedItemCost,
                  maxCost: battler.equipmentCapacity,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Expanded(
              child: _PatternEquipmentBoard(
                battler: battler,
                assignments: assignments,
                canAcceptItem: canAcceptItem,
                onAcceptItem: onAcceptItem,
                onItemPressed: onItemPressed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PatternEquipmentBoard extends StatelessWidget {
  final Battler battler;
  final Map<Item, OperativePatternPoint> assignments;
  final bool Function(Item item, OperativePatternPoint point) canAcceptItem;
  final void Function(Item item, OperativePatternPoint point) onAcceptItem;
  final ValueChanged<Item>? onItemPressed;

  const _PatternEquipmentBoard({
    required this.battler,
    required this.assignments,
    required this.canAcceptItem,
    required this.onAcceptItem,
    this.onItemPressed,
  });

  @override
  Widget build(BuildContext context) {
    final itemsByPoint = <OperativePatternPoint, Item>{
      for (final entry in assignments.entries) entry.value: entry.key,
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final outerSide = min(constraints.maxWidth, constraints.maxHeight);
        final boardSide = outerSide * _operativesPatternBoardScale;
        final adjacencyEvaluations = _adjacencyEvaluations(itemsByPoint);
        final adjacencyGuideSegments = _adjacencyGuideSegments(
          evaluations: adjacencyEvaluations,
          boardSide: boardSide,
        );
        final adjacencyTotals = OperativePatternAdjacencyService.totalsFor(
          adjacencyEvaluations,
        );

        return Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: Transform.rotate(
                angle: _operativesPatternDiamondRotation,
                child: SizedBox.square(
                  dimension: boardSide,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      if (adjacencyGuideSegments.isNotEmpty)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: OperativePatternAdjacencyGuidePainter(
                                segments: adjacencyGuideSegments,
                                endpointInset:
                                    _operativesPatternPointVisualSize * 0.62,
                              ),
                            ),
                          ),
                        ),
                      for (final point in operativePatternPoints)
                        _PatternEquipmentPointTarget(
                          point: point,
                          item: itemsByPoint[point],
                          center: _patternPointCenter(point, boardSide),
                          canAcceptItem: canAcceptItem,
                          onAcceptItem: onAcceptItem,
                          onItemPressed: onItemPressed,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _PatternEquipmentBoardPills(
                baseAttack: battler.attack,
                baseBarrier: battler.barrier,
                adjacencyAttack: adjacencyTotals.attack,
                adjacencyBarrier: adjacencyTotals.barrier,
              ),
            ),
          ],
        );
      },
    );
  }

  Offset _patternPointCenter(OperativePatternPoint point, double boardSide) {
    return operativePatternPointCenter(
      point: point,
      boardSide: boardSide,
    );
  }

  List<OperativePatternAdjacencyEvaluation> _adjacencyEvaluations(
    Map<OperativePatternPoint, Item> itemsByPoint,
  ) {
    return OperativePatternAdjacencyService.evaluate(
      itemsByPointKey: {
        for (final entry in itemsByPoint.entries) entry.key.key: entry.value,
      },
    );
  }

  List<OperativePatternAdjacencyGuideSegment> _adjacencyGuideSegments({
    required List<OperativePatternAdjacencyEvaluation> evaluations,
    required double boardSide,
  }) {
    return <OperativePatternAdjacencyGuideSegment>[
      for (final evaluation in evaluations)
        OperativePatternAdjacencyGuideSegment(
          start: _patternPointCenter(evaluation.sourcePoint, boardSide),
          end: _patternPointCenter(evaluation.targetPoint, boardSide),
          accent: evaluation.bonus.requiredTag.accent,
          isMatched: evaluation.isMatched,
        ),
    ];
  }
}

class _PatternEquipmentBoardPills extends StatefulWidget {
  final int baseAttack;
  final int baseBarrier;
  final int adjacencyAttack;
  final int adjacencyBarrier;

  const _PatternEquipmentBoardPills({
    required this.baseAttack,
    required this.baseBarrier,
    required this.adjacencyAttack,
    required this.adjacencyBarrier,
  });

  @override
  State<_PatternEquipmentBoardPills> createState() =>
      _PatternEquipmentBoardPillsState();
}

class _PatternEquipmentBoardPillsState
    extends State<_PatternEquipmentBoardPills> {
  bool _showBaseFullText = false;
  bool _showAdjacencyFullText = false;

  void _toggleBaseText() {
    setState(() {
      _showBaseFullText = !_showBaseFullText;
    });
  }

  void _toggleAdjacencyText() {
    setState(() {
      _showAdjacencyFullText = !_showAdjacencyFullText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: Align(
            alignment: Alignment.bottomLeft,
            child: _PatternEquipmentBoardPillGroup(
              onTap: _toggleBaseText,
              children: [
                _PatternEquipmentBoardPill(
                  compactLabel: '${max(0, widget.baseAttack)} BA',
                  fullLabel: '${max(0, widget.baseAttack)} BASE ATTACK',
                  isFullText: _showBaseFullText,
                  accent: EndpointPalette.dangerAccent,
                ),
                _PatternEquipmentBoardPill(
                  compactLabel: '${max(0, widget.baseBarrier)} BB',
                  fullLabel: '${max(0, widget.baseBarrier)} BASE BARRIER',
                  isFullText: _showBaseFullText,
                  accent: BattlerStat.barrier.accent,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Align(
            alignment: Alignment.bottomRight,
            child: _PatternEquipmentBoardPillGroup(
              onTap: _toggleAdjacencyText,
              children: [
                _PatternEquipmentBoardPill(
                  compactLabel: 'AA ${max(0, widget.adjacencyAttack)}',
                  fullLabel:
                      'ADJACENCY ATTACK ${max(0, widget.adjacencyAttack)}',
                  isFullText: _showAdjacencyFullText,
                  accent: EndpointPalette.dangerAccent,
                ),
                _PatternEquipmentBoardPill(
                  compactLabel: 'AB ${max(0, widget.adjacencyBarrier)}',
                  fullLabel:
                      'ADJACENCY BARRIER ${max(0, widget.adjacencyBarrier)}',
                  isFullText: _showAdjacencyFullText,
                  accent: BattlerStat.barrier.accent,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PatternEquipmentBoardPillGroup extends StatelessWidget {
  final VoidCallback onTap;
  final List<Widget> children;

  const _PatternEquipmentBoardPillGroup({
    required this.onTap,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < children.length; index++) ...[
            if (index > 0) const SizedBox(height: 4),
            children[index],
          ],
        ],
      ),
    );
  }
}

class _PatternEquipmentBoardPill extends StatelessWidget {
  final String compactLabel;
  final String fullLabel;
  final bool isFullText;
  final Color accent;

  const _PatternEquipmentBoardPill({
    required this.compactLabel,
    required this.fullLabel,
    required this.isFullText,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final label = isFullText ? fullLabel : compactLabel;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: EndpointPalette.panelBackgroundBattleOpaque.withValues(
          alpha: 0.9,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.58)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.12),
            blurRadius: 10,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          isFullText ? 7 : 6,
          4,
          isFullText ? 7 : 6,
          4,
        ),
        child: EndpointText(
          label,
          style: textSmallNumericBold.copyWith(
            color: accent,
            fontSize: isFullText ? 9.5 : 10,
            letterSpacing: 0.2,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _PatternEquipmentPointTarget extends StatelessWidget {
  final OperativePatternPoint point;
  final Item? item;
  final Offset center;
  final bool Function(Item item, OperativePatternPoint point) canAcceptItem;
  final void Function(Item item, OperativePatternPoint point) onAcceptItem;
  final ValueChanged<Item>? onItemPressed;

  const _PatternEquipmentPointTarget({
    required this.point,
    required this.item,
    required this.center,
    required this.canAcceptItem,
    required this.onAcceptItem,
    this.onItemPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: center.dx - (_operativesPatternPointHitSize / 2),
      top: center.dy - (_operativesPatternPointHitSize / 2),
      width: _operativesPatternPointHitSize,
      height: _operativesPatternPointHitSize,
      child: DragTarget<Item>(
        onWillAcceptWithDetails: (details) {
          return canAcceptItem(details.data, point);
        },
        onAcceptWithDetails: (details) {
          onAcceptItem(details.data, point);
        },
        builder: (context, candidateItems, rejectedItems) {
          final canDrop = candidateItems.isNotEmpty;
          final currentItem = item;

          return Center(
            child: Transform.rotate(
              angle: -_operativesPatternDiamondRotation,
              child: currentItem == null
                  ? _PatternEquipmentEmptyPoint(isHighlighted: canDrop)
                  : _PatternEquipmentDraggableItemPoint(
                      item: currentItem,
                      onPressed: onItemPressed == null
                          ? null
                          : () => onItemPressed!.call(currentItem),
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _PatternEquipmentDraggableItemPoint extends StatelessWidget {
  final Item item;
  final VoidCallback? onPressed;

  const _PatternEquipmentDraggableItemPoint({
    required this.item,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final point = _PatternEquipmentItemPoint(
      item: item,
      onPressed: onPressed,
    );

    return Draggable<Item>(
      data: item,
      maxSimultaneousDrags: 1,
      rootOverlay: true,
      feedback: Material(
        color: Colors.transparent,
        child: _PatternEquipmentItemPoint(item: item),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: point,
      ),
      child: point,
    );
  }
}

class _PatternEquipmentEmptyPoint extends StatelessWidget {
  final bool isHighlighted;

  const _PatternEquipmentEmptyPoint({
    required this.isHighlighted,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isHighlighted
        ? EndpointPalette.patternAccent
        : Colors.black.withValues(alpha: 0.88);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      width: _operativesPatternPointVisualSize,
      height: _operativesPatternPointVisualSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.72),
        border: Border.all(
          color: isHighlighted
              ? EndpointPalette.patternAccent.withValues(alpha: 0.96)
              : EndpointPalette.softForeground.withValues(alpha: 0.22),
          width: isHighlighted ? 2.2 : 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: isHighlighted ? 0.3 : 0.14),
            blurRadius: isHighlighted ? 16 : 8,
            spreadRadius: isHighlighted ? 2 : 0,
          ),
        ],
      ),
    );
  }
}

class _PatternEquipmentItemPoint extends StatelessWidget {
  final Item item;
  final VoidCallback? onPressed;

  const _PatternEquipmentItemPoint({
    required this.item,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final content = SizedBox.square(
      dimension: _operativesPatternPointHitSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: EndpointPalette.blend(
            EndpointPalette.panelBackground,
            item.rarity.accent,
            0.16,
          ),
          border: Border.all(
            color: item.rarity.accent.withValues(alpha: 0.9),
            width: 1.8,
          ),
          boxShadow: [
            BoxShadow(
              color: item.rarity.accent.withValues(alpha: 0.2),
              blurRadius: 14,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: EndpointText(
            item.iconEmoji,
            style: const TextStyle(
              fontSize: 20,
              height: 1,
            ),
          ),
        ),
      ),
    );

    return HoldTooltip(
      message: item.tooltipDescription,
      child: onPressed == null
          ? content
          : Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onPressed,
                child: content,
              ),
            ),
    );
  }
}

class _OperativesModeShortcuts extends StatelessWidget {
  final EndpointGameMode gameMode;
  final Future<void> Function() onOpenPatternBoard;

  const _OperativesModeShortcuts({
    required this.gameMode,
    required this.onOpenPatternBoard,
  });

  @override
  Widget build(BuildContext context) {
    switch (gameMode) {
      case EndpointGameMode.classic:
        return const SizedBox.shrink();
      case EndpointGameMode.pattern:
        return _OperativesShortcutButton(
          label: 'Patrón',
          icon: Icons.grid_view_rounded,
          tooltip: 'Abrir patron de objetos',
          accent: EndpointPalette.patternAccent,
          onPressed: () => unawaited(onOpenPatternBoard()),
        );
    }
  }
}

class _OperativeIconCard extends StatelessWidget {
  final Battler battler;
  final bool isSelected;
  final bool isPlayer;
  final VoidCallback onPressed;

  const _OperativeIconCard({
    required this.battler,
    required this.isSelected,
    required this.isPlayer,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isSelected
        ? EndpointPalette.primaryAccent
        : EndpointPalette.primaryAccent.withValues(alpha: 0.4);

    return HoldTooltip(
      message: battler.name,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            width: 54,
            padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
            decoration: BoxDecoration(
              color: EndpointPalette.blend(
                EndpointPalette.panelBackgroundSoft,
                EndpointPalette.primaryAccent,
                0.08,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: isSelected ? 0.12 : 0.04),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                EndpointEmojiSprite(
                  emoji: isPlayer ? battler.iconEmoji : '\u{1F464}',
                  accent: EndpointPalette.primaryAccent,
                  size: 28,
                ),
                const SizedBox(height: 2),
                EndpointText(
                  isPlayer ? 'TU' : 'OP',
                  style: textSmallBold.copyWith(
                    color: EndpointPalette.softForeground,
                    fontSize: 13,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EquipmentRow extends StatelessWidget {
  final Battler battler;
  final bool isPlayer;
  final ValueChanged<Item>? onItemPressed;

  const _EquipmentRow({
    required this.battler,
    required this.isPlayer,
    this.onItemPressed,
  });

  @override
  Widget build(BuildContext context) {
    return EndpointPanel(
      backgroundColor: EndpointPalette.panelBackgroundSoft,
      borderRadius: 14,
      glowOpacity: 0.05,
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: EndpointText(
                  isPlayer ? 'EQUIPO ACTIVO' : 'EQUIPO DEL OPERATIVO',
                  style: textSmallBold.copyWith(
                    color: EndpointPalette.primaryAccent,
                    fontSize: 15,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              EndpointEquipmentBudgetBadge(
                usedCost: battler.equippedItemCost,
                maxCost: battler.equipmentCapacity,
              ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: EndpointEquipmentSlotsStrip(
                battler: battler,
                layout: EndpointEquipmentLayout.standard,
                showBudgetBadge: false,
                onItemPressed: onItemPressed,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Boton flotante reutilizable para accesos secundarios del overlay.
class _OperativesShortcutButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final String tooltip;
  final Color accent;
  final VoidCallback onPressed;

  const _OperativesShortcutButton({
    required this.label,
    required this.icon,
    required this.tooltip,
    required this.accent,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return HoldTooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
            decoration: BoxDecoration(
              color: EndpointPalette.blend(
                EndpointPalette.panelBackground,
                accent,
                0.12,
              ),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: accent.withValues(alpha: 0.72),
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.14),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: accent,
                ),
                const SizedBox(width: 6),
                EndpointText(
                  label,
                  style: textSmallBold.copyWith(
                    color: EndpointPalette.softForeground,
                    letterSpacing: 0.9,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
