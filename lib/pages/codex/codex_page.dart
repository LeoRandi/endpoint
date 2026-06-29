import '_imports.dart';

enum _CodexCategory {
  archetypes,
  items,
  augments,
  enemies,
  shops,
  events,
  buffs,
  debuffs,
}

extension _CodexCategoryPresentation on _CodexCategory {
  bool get supportsArchetypeSections {
    switch (this) {
      case _CodexCategory.archetypes:
      case _CodexCategory.items:
      case _CodexCategory.augments:
      case _CodexCategory.shops:
        return true;
      case _CodexCategory.enemies:
      case _CodexCategory.events:
      case _CodexCategory.buffs:
      case _CodexCategory.debuffs:
        return false;
    }
  }

  bool get supportsRarityOrdering {
    switch (this) {
      case _CodexCategory.archetypes:
      case _CodexCategory.items:
      case _CodexCategory.augments:
      case _CodexCategory.enemies:
      case _CodexCategory.shops:
      case _CodexCategory.events:
        return true;
      case _CodexCategory.buffs:
      case _CodexCategory.debuffs:
        return false;
    }
  }
}

enum _CodexOrderMode {
  nameAsc,
  nameDesc,
  rarityAsc,
  rarityDesc,
  indexedFirst,
  indexedLast,
}

extension _CodexOrderModePresentation on _CodexOrderMode {
  bool get isRarityOrdering {
    switch (this) {
      case _CodexOrderMode.rarityAsc:
      case _CodexOrderMode.rarityDesc:
        return true;
      case _CodexOrderMode.nameAsc:
      case _CodexOrderMode.nameDesc:
      case _CodexOrderMode.indexedFirst:
      case _CodexOrderMode.indexedLast:
        return false;
    }
  }

  String get label {
    switch (this) {
      case _CodexOrderMode.nameAsc:
        return 'Nombre A-Z';
      case _CodexOrderMode.nameDesc:
        return 'Nombre Z-A';
      case _CodexOrderMode.rarityAsc:
        return 'Rareza baja-alta';
      case _CodexOrderMode.rarityDesc:
        return 'Rareza alta-baja';
      case _CodexOrderMode.indexedFirst:
        return 'Indexados primero';
      case _CodexOrderMode.indexedLast:
        return 'Indexados ultimo';
    }
  }
}

class CodexPage extends StatefulWidget {
  const CodexPage({super.key});

  @override
  State<CodexPage> createState() => _CodexPageState();
}

class _CodexPageState extends State<CodexPage> {
  _CodexCategory _selectedCategory = _CodexCategory.archetypes;
  Set<String> _indexedKeys = <String>{};
  final Map<_CodexCategory, _CodexOrderMode> _orderModes = {
    for (final category in _CodexCategory.values)
      category: _CodexOrderMode.nameAsc,
  };

  static final List<ArchetypePathNode> _archetypes = List.unmodifiable([
    velozArchetypeNode,
    inamovibleArchetypeNode,
    imparableArchetypeNode,
    mercanteArchetypeNode,
  ]);

  static final List<CombatPathNode> _enemyNodes = List.unmodifiable([
    for (final node in combatPathNodeExamples) node,
  ]);

  static final List<ShopPathNode> _shopNodes = _deduplicateShopNodes([
    ...dayShopNodes,
    ...nightShopNodes,
  ]);

  static final List<EventPathNode> _eventNodes = _deduplicateEventNodes([
    ...dayEventNodes,
    ...nightEventNodes,
  ]);

  static const List<BattlerStatus> _statusPresets = [
    calentandoStatus,
    potenciaStatus,
    cicloEclipseStatus,
    puntoCiegoStatus,
    desafioStatus,
    desafioExcitanteStatus,
    ResonanciaStatus(),
    quemaduraStatus,
    intoxicacionStatus,
    contagioStatus,
    catalisisCruelStatus,
    fragilidadStatus,
    conmocionStatus,
    deudaStatus,
  ];

  @override
  void initState() {
    super.initState();
    unawaited(_loadIndexedKeys());
  }

  Future<void> _loadIndexedKeys() async {
    final indexedKeys = await CodexDiscoveryService.loadIndexedKeys();
    if (!mounted) return;

    setState(() {
      _indexedKeys = indexedKeys;
    });
  }

  List<_CodexEntry> get _selectedEntries {
    switch (_selectedCategory) {
      case _CodexCategory.archetypes:
        return [
          for (final archetype in _archetypes) _CodexEntry.archetype(archetype),
        ];
      case _CodexCategory.items:
        return [
          for (final item in itemPresets) _CodexEntry.item(item),
        ];
      case _CodexCategory.augments:
        return [
          for (final augment in augmentCatalog) _CodexEntry.augment(augment),
        ];
      case _CodexCategory.enemies:
        return [
          for (final node in _enemyNodes) _CodexEntry.enemy(node),
        ];
      case _CodexCategory.shops:
        return [
          for (final node in _shopNodes) _CodexEntry.shop(node),
        ];
      case _CodexCategory.events:
        return [
          for (final node in _eventNodes) _CodexEntry.event(node),
        ];
      case _CodexCategory.buffs:
        return [
          for (final status in _statusPresets)
            if (status.type == BattlerStatusType.buff)
              _CodexEntry.status(status),
        ];
      case _CodexCategory.debuffs:
        return [
          for (final status in _statusPresets)
            if (status.type == BattlerStatusType.debuff)
              _CodexEntry.status(status),
        ];
    }
  }

  _CodexOrderMode get _selectedOrderMode =>
      _orderModes[_selectedCategory] ?? _CodexOrderMode.nameAsc;

  List<_CodexSection> get _selectedSections {
    final entries = _sortedEntries(_selectedEntries, _selectedOrderMode);
    if (!_selectedCategory.supportsArchetypeSections) {
      return [
        _CodexSection(
          title: _CodexCategoryData.forCategory(_selectedCategory).title,
          accent: _CodexCategoryData.forCategory(_selectedCategory).accent,
          entries: entries,
        ),
      ];
    }

    final sectionEntries = <_CodexArchetypeSectionKey, List<_CodexEntry>>{
      for (final key in _CodexArchetypeSectionKey.values) key: <_CodexEntry>[],
    };

    for (final entry in entries) {
      sectionEntries[entry.sectionKey]!.add(entry);
    }

    return [
      for (final key in _CodexArchetypeSectionKey.values)
        if (sectionEntries[key]!.isNotEmpty)
          _CodexSection(
            title: key.label,
            accent: key.accent,
            entries: sectionEntries[key]!,
          ),
    ];
  }

  List<_CodexEntry> _sortedEntries(
    List<_CodexEntry> entries,
    _CodexOrderMode orderMode,
  ) {
    final sortedEntries = [...entries];
    sortedEntries.sort((a, b) {
      final comparison = switch (orderMode) {
        _CodexOrderMode.nameAsc ||
        _CodexOrderMode.nameDesc =>
          a.sortName.compareTo(b.sortName),
        _CodexOrderMode.rarityAsc ||
        _CodexOrderMode.rarityDesc =>
          a.raritySortIndex.compareTo(b.raritySortIndex),
        _CodexOrderMode.indexedFirst ||
        _CodexOrderMode.indexedLast =>
          (_isIndexed(a) ? 1 : 0).compareTo(_isIndexed(b) ? 1 : 0),
      };
      final resolvedComparison =
          comparison == 0 ? a.sortName.compareTo(b.sortName) : comparison;

      return switch (orderMode) {
        _CodexOrderMode.nameAsc ||
        _CodexOrderMode.rarityAsc =>
          resolvedComparison,
        _CodexOrderMode.nameDesc ||
        _CodexOrderMode.rarityDesc =>
          -resolvedComparison,
        _CodexOrderMode.indexedFirst => -resolvedComparison,
        _CodexOrderMode.indexedLast => resolvedComparison,
      };
    });

    return List<_CodexEntry>.unmodifiable(sortedEntries);
  }

  bool _isIndexed(_CodexEntry entry) => _indexedKeys.contains(entry.codexKey);

  @override
  Widget build(BuildContext context) {
    final category = _CodexCategoryData.forCategory(_selectedCategory);
    final entries = _selectedEntries;
    final sections = _selectedSections;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: EndpointGradients.menu),
        child: SafeArea(
          child: Stack(
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: _CodexSidebar(
                      selectedCategory: _selectedCategory,
                      selectedOrderMode: _selectedOrderMode,
                      showRarityOrderModes:
                          _selectedCategory.supportsRarityOrdering,
                      onCategorySelected: (category) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                      onOrderModeSelected: (orderMode) {
                        setState(() {
                          _orderModes[_selectedCategory] = orderMode;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: _CodexContentPanel(
                      title: category.title,
                      accent: category.accent,
                      entryCount: entries.length,
                      sections: sections,
                      indexedKeys: _indexedKeys,
                      onEntryPressed: _openEntryDetails,
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 10,
                right: 10,
                child: EndpointSceneCloseButton(
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Cerrar Codex',
                  accent: EndpointPalette.primaryAccent,
                  foregroundColor: EndpointPalette.softForeground,
                  backgroundColor: EndpointPalette.closeButtonBackground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openEntryDetails(_CodexEntry entry) async {
    switch (entry.kind) {
      case _CodexEntryKind.archetype:
        await showEndpointDialog<void>(
          context: context,
          barrierLabel: 'Detalle de arquetipo',
          barrierColor: EndpointPalette.overlayScrim,
          builder: (context) => _CodexArchetypeDetailsDialog(
            archetype: entry.archetype!,
          ),
        );
      case _CodexEntryKind.item:
        final item = entry.item!;
        await showEndpointDialog<void>(
          context: context,
          barrierLabel: 'Detalle de objeto',
          barrierColor: EndpointPalette.overlayScrim,
          builder: (context) => EndpointItemDetailsDialog(
            item: item,
            accent: item.rarity.accent,
            price: item.baseCost,
            priceLabel: 'COSTE BASE',
            statusText: 'DESBLOQUEADO',
          ),
        );
      case _CodexEntryKind.augment:
        await showEndpointDialog<void>(
          context: context,
          barrierLabel: 'Detalle de aumento',
          barrierColor: EndpointPalette.overlayScrim,
          builder: (context) => EndpointAugmentDetailsDialog(
            augment: entry.augment!,
            statusText: 'DESBLOQUEADO',
          ),
        );
      case _CodexEntryKind.enemy:
        await showEndpointDialog<void>(
          context: context,
          barrierLabel: 'Detalle de enemigo',
          barrierColor: EndpointPalette.overlayScrim,
          builder: (context) => _CodexEnemyDetailsDialog(
            enemy: entry.enemy!,
            tier: entry.enemyTier!,
          ),
        );
      case _CodexEntryKind.shop:
        await showEndpointDialog<void>(
          context: context,
          barrierLabel: 'Detalle de tienda',
          barrierColor: EndpointPalette.overlayScrim,
          builder: (context) => _CodexShopDetailsDialog(shop: entry.shop!),
        );
      case _CodexEntryKind.event:
        await showEndpointDialog<void>(
          context: context,
          barrierLabel: 'Detalle de evento',
          barrierColor: EndpointPalette.overlayScrim,
          builder: (context) => _CodexEventDetailsDialog(event: entry.event!),
        );
      case _CodexEntryKind.status:
        await showEndpointDialog<void>(
          context: context,
          barrierLabel: 'Detalle de estado',
          barrierColor: EndpointPalette.overlayScrim,
          builder: (context) => _CodexStatusDetailsDialog(
            status: entry.status!,
          ),
        );
    }
  }

  static List<ShopPathNode> _deduplicateShopNodes(
    Iterable<ShopPathNode> nodes,
  ) {
    final seen = <String>{};
    final result = <ShopPathNode>[];
    for (final node in nodes) {
      if (!seen.add(node.nodeId)) continue;
      result.add(node);
    }
    return List<ShopPathNode>.unmodifiable(result);
  }

  static List<EventPathNode> _deduplicateEventNodes(
    Iterable<EventPathNode> nodes,
  ) {
    final seen = <PathEventId>{};
    final result = <EventPathNode>[];
    for (final node in nodes) {
      if (!seen.add(node.id)) continue;
      result.add(node);
    }
    return List<EventPathNode>.unmodifiable(result);
  }
}

class _CodexSidebar extends StatelessWidget {
  final _CodexCategory selectedCategory;
  final _CodexOrderMode selectedOrderMode;
  final bool showRarityOrderModes;
  final ValueChanged<_CodexCategory> onCategorySelected;
  final ValueChanged<_CodexOrderMode> onOrderModeSelected;

  const _CodexSidebar({
    required this.selectedCategory,
    required this.selectedOrderMode,
    required this.showRarityOrderModes,
    required this.onCategorySelected,
    required this.onOrderModeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: EndpointPalette.panelBackgroundOpaque.withValues(alpha: 0.94),
        border: Border(
          right: BorderSide(
            color: EndpointPalette.primaryAccent.withValues(alpha: 0.34),
          ),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(6, 10, 6, 10),
              children: [
                for (final category in _CodexCategory.values) ...[
                  _CodexCategoryButton(
                    data: _CodexCategoryData.forCategory(category),
                    isSelected: selectedCategory == category,
                    onPressed: () => onCategorySelected(category),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 10),
            child: _CodexOrderButton(
              selectedOrderMode: selectedOrderMode,
              showRarityOrderModes: showRarityOrderModes,
              onOrderModeSelected: onOrderModeSelected,
            ),
          ),
        ],
      ),
    );
  }
}

class _CodexCategoryButton extends StatelessWidget {
  final _CodexCategoryData data;
  final bool isSelected;
  final VoidCallback onPressed;

  const _CodexCategoryButton({
    required this.data,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final accent = data.accent;
    final background = isSelected
        ? EndpointPalette.blend(EndpointPalette.panelBackground, accent, 0.26)
        : EndpointPalette.blend(EndpointPalette.panelBackground, accent, 0.08);

    return HoldTooltip(
      message: data.title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: accent.withValues(alpha: isSelected ? 0.92 : 0.48),
                width: isSelected ? 1.7 : 1.1,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: accent.withValues(alpha: 0.2),
                    blurRadius: 12,
                  ),
              ],
            ),
            child: Center(
              child: data.emojiIcon != null
                  ? EndpointText(
                      data.emojiIcon!,
                      style: const TextStyle(
                        fontSize: 23,
                        height: 1,
                        decoration: TextDecoration.none,
                      ),
                    )
                  : Icon(
                      data.icon,
                      color: EndpointPalette.soften(accent),
                      size: 25,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CodexOrderButton extends StatelessWidget {
  final _CodexOrderMode selectedOrderMode;
  final bool showRarityOrderModes;
  final ValueChanged<_CodexOrderMode> onOrderModeSelected;

  const _CodexOrderButton({
    required this.selectedOrderMode,
    required this.showRarityOrderModes,
    required this.onOrderModeSelected,
  });

  @override
  Widget build(BuildContext context) {
    const accent = EndpointPalette.infoAccent;

    return HoldTooltip(
      message: 'Ordenar Codex',
      child: PopupMenuButton<_CodexOrderMode>(
        tooltip: '',
        initialValue: selectedOrderMode,
        onSelected: onOrderModeSelected,
        color: EndpointPalette.panelBackgroundOpaque,
        position: PopupMenuPosition.over,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: accent.withValues(alpha: 0.62)),
        ),
        itemBuilder: (context) {
          final visibleOrderModes = _CodexOrderMode.values.where(
            (orderMode) => showRarityOrderModes || !orderMode.isRarityOrdering,
          );

          return [
            for (final orderMode in visibleOrderModes)
              PopupMenuItem<_CodexOrderMode>(
                value: orderMode,
                child: Row(
                  children: [
                    Icon(
                      selectedOrderMode == orderMode
                          ? Icons.check_rounded
                          : Icons.sort_rounded,
                      color: selectedOrderMode == orderMode
                          ? accent
                          : EndpointPalette.softForeground.withValues(
                              alpha: 0.7,
                            ),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    EndpointText(
                      orderMode.label,
                      style: textSmallBold.copyWith(
                        color: EndpointPalette.softForeground,
                        fontSize: 12,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ],
                ),
              ),
          ];
        },
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: EndpointPalette.blend(
              EndpointPalette.panelBackground,
              accent,
              0.12,
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: accent.withValues(alpha: 0.54),
              width: 1.1,
            ),
          ),
          child: Icon(
            Icons.sort_rounded,
            color: EndpointPalette.soften(accent),
            size: 25,
          ),
        ),
      ),
    );
  }
}

class _CodexContentPanel extends StatelessWidget {
  final String title;
  final Color accent;
  final int entryCount;
  final List<_CodexSection> sections;
  final Set<String> indexedKeys;
  final ValueChanged<_CodexEntry> onEntryPressed;

  const _CodexContentPanel({
    required this.title,
    required this.accent,
    required this.entryCount,
    required this.sections,
    required this.indexedKeys,
    required this.onEntryPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 54),
            child: Row(
              children: [
                Expanded(
                  child: EndpointText(
                    title.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textExtraLargeBold.copyWith(
                      color: EndpointPalette.soften(accent),
                      fontSize: 34,
                      letterSpacing: 2.2,
                      shadows: [
                        Shadow(
                          color: accent.withValues(alpha: 0.35),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                EndpointText(
                  '$entryCount',
                  style: textMediumNumericBold.copyWith(
                    color: accent,
                    fontSize: 18,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              children: [
                for (final section in sections) ...[
                  _CodexSectionList(
                    section: section,
                    indexedKeys: indexedKeys,
                    onEntryPressed: onEntryPressed,
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CodexSectionList extends StatelessWidget {
  final _CodexSection section;
  final Set<String> indexedKeys;
  final ValueChanged<_CodexEntry> onEntryPressed;

  const _CodexSectionList({
    required this.section,
    required this.indexedKeys,
    required this.onEntryPressed,
  });

  @override
  Widget build(BuildContext context) {
    final accent = section.accent;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: EndpointPalette.blend(
          EndpointPalette.panelBackgroundOpaque,
          accent,
          0.14,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          top: BorderSide(color: accent.withValues(alpha: 0.82), width: 1.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: EndpointText(
                    section.title.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textSmallBold.copyWith(
                      color: EndpointPalette.soften(accent),
                      fontSize: 12,
                      letterSpacing: 1.3,
                    ),
                  ),
                ),
                EndpointText(
                  '${section.entries.length}',
                  style: textSmallNumericBold.copyWith(
                    color: accent,
                    fontSize: 11,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GridView.builder(
              itemCount: section.entries.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 72,
                mainAxisExtent: 66,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                final entry = section.entries[index];

                return _CodexEntryTile(
                  entry: entry,
                  isIndexed: indexedKeys.contains(entry.codexKey),
                  onPressed: () => onEntryPressed(entry),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CodexEntryTile extends StatelessWidget {
  final _CodexEntry entry;
  final bool isIndexed;
  final VoidCallback onPressed;

  const _CodexEntryTile({
    required this.entry,
    required this.isIndexed,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final accent = entry.accent;

    return HoldTooltip(
      message: isIndexed ? entry.tooltip : '???',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isIndexed ? onPressed : null,
          borderRadius: BorderRadius.circular(8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isIndexed
                  ? EndpointPalette.blend(
                      EndpointPalette.panelBackgroundOpaque,
                      accent,
                      0.1,
                    )
                  : Colors.black.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isIndexed
                    ? accent.withValues(alpha: 0.54)
                    : EndpointPalette.neutralAccent.withValues(alpha: 0.3),
              ),
            ),
            child: Center(
              child: !isIndexed
                  ? Icon(
                      Icons.help_rounded,
                      color: EndpointPalette.neutralAccent.withValues(
                        alpha: 0.28,
                      ),
                      size: 30,
                    )
                  : entry.emojiIcon != null
                      ? entry.imageAsset != null
                          ? Padding(
                              padding: const EdgeInsets.all(7),
                              child: Image.asset(
                                entry.imageAsset!,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.none,
                              ),
                            )
                          : EndpointText(
                              entry.emojiIcon!,
                              style: const TextStyle(
                                fontSize: 25,
                                height: 1,
                                decoration: TextDecoration.none,
                              ),
                            )
                      : Icon(
                          entry.icon,
                          color: EndpointPalette.soften(accent),
                          size: 28,
                        ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CodexArchetypeDetailsDialog extends StatelessWidget {
  final ArchetypePathNode archetype;

  const _CodexArchetypeDetailsDialog({
    required this.archetype,
  });

  @override
  Widget build(BuildContext context) {
    final accent = archetype.accent;

    return EndpointDetailsDialogScaffold(
      accent: accent,
      backgroundColor: EndpointPalette.panelBackgroundOpaque,
      foregroundColor: EndpointPalette.soften(accent),
      closeBackgroundColor: EndpointPalette.closeButtonBackground,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EndpointEmojiSprite(
                emoji: archetype.playerIconEmoji,
                accent: accent,
                size: 72,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EndpointText(
                      archetype.label,
                      maxLines: null,
                      style: textLargeBold.copyWith(
                        color: EndpointPalette.soften(accent),
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 5),
                    EndpointText(
                      'ARQUETIPO',
                      style: textSmallBold.copyWith(
                        color: accent,
                        fontSize: 10,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          EndpointText(
            archetype.tooltip,
            maxLines: null,
            style: textMedium.copyWith(
              color: EndpointPalette.softForeground.withValues(alpha: 0.84),
              height: 1.24,
            ),
          ),
          const SizedBox(height: 12),
          EndpointText(
            _buildArchetypeSummary(archetype),
            maxLines: null,
            style: textSmallNumericBold.copyWith(
              color: accent,
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  String _buildArchetypeSummary(ArchetypePathNode archetype) {
    final parts = <String>[
      for (final entry in archetype.baseStatModifiers.entries)
        '${entry.value >= 0 ? '+' : ''}${entry.value} ${entry.key.shortLabel}',
      if (archetype.moneyModifier != 0)
        '${archetype.moneyModifier >= 0 ? '+' : ''}${archetype.moneyModifier}C',
      if (archetype.incomeModifier != 0)
        '${archetype.incomeModifier >= 0 ? '+' : ''}${archetype.incomeModifier} INCOME',
      '${archetype.startingAugments.length} AUMENTOS',
    ];

    return parts.join('   ');
  }
}

class _CodexEnemyDetailsDialog extends StatelessWidget {
  final Battler enemy;
  final CombatNodeTier tier;

  const _CodexEnemyDetailsDialog({
    required this.enemy,
    required this.tier,
  });

  @override
  Widget build(BuildContext context) {
    final accent = tier.accent;

    return EndpointDetailsDialogScaffold(
      accent: accent,
      backgroundColor: EndpointPalette.panelBackgroundOpaque,
      foregroundColor: EndpointPalette.soften(accent),
      closeBackgroundColor: EndpointPalette.closeButtonBackground,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EndpointEmojiSprite(
                emoji: enemy.iconEmoji,
                imageAsset: enemy.imageAsset,
                accent: accent,
                size: 72,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EndpointText(
                      enemy.name,
                      maxLines: null,
                      style: textLargeBold.copyWith(
                        color: EndpointPalette.soften(accent),
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 5),
                    EndpointText(
                      'ENEMIGO ${tier.badgeLabel}',
                      style: textSmallBold.copyWith(
                        color: accent,
                        fontSize: 10,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _CodexStatStrip(battler: enemy, accent: accent),
          if (enemy.augments.isNotEmpty) ...[
            const SizedBox(height: 12),
            EndpointText(
              'AUMENTOS',
              style: textSmallBold.copyWith(
                color: accent,
                fontSize: 10,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final augment in enemy.augments)
                  EndpointAugmentOrb(
                    augment: augment,
                    size: 42,
                    enableTooltipLongPress: true,
                    onPressed: () => _openAugmentDetails(context, augment),
                  ),
              ],
            ),
          ],
          if (enemy.equippedItems.isNotEmpty) ...[
            const SizedBox(height: 12),
            EndpointText(
              'OBJETOS',
              style: textSmallBold.copyWith(
                color: accent,
                fontSize: 10,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in enemy.equippedItems)
                  _CodexEnemyItemButton(
                    item: item,
                    onPressed: () => _openItemDetails(context, item),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openAugmentDetails(
    BuildContext context,
    Augment augment,
  ) async {
    await showEndpointDialog<void>(
      context: context,
      barrierLabel: 'Detalle de aumento',
      barrierColor: EndpointPalette.overlayScrim,
      builder: (context) => EndpointAugmentDetailsDialog(
        augment: augment,
        accent: augment.accent,
        statusText: 'DESBLOQUEADO',
      ),
    );
  }

  Future<void> _openItemDetails(BuildContext context, Item item) async {
    await showEndpointDialog<void>(
      context: context,
      barrierLabel: 'Detalle de objeto',
      barrierColor: EndpointPalette.overlayScrim,
      builder: (context) => EndpointItemDetailsDialog(
        item: item,
        accent: item.rarity.accent,
        price: item.baseCost,
        priceLabel: 'COSTE BASE',
        statusText: 'DESBLOQUEADO',
      ),
    );
  }
}

class _CodexEnemyItemButton extends StatelessWidget {
  final Item item;
  final VoidCallback onPressed;

  const _CodexEnemyItemButton({
    required this.item,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return HoldTooltip(
      message: item.displayName,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: EndpointEmojiSprite(
            emoji: item.iconEmoji,
            imageAsset: item.asset,
            accent: item.rarity.accent,
            size: 42,
          ),
        ),
      ),
    );
  }
}

class _CodexStatStrip extends StatelessWidget {
  final Battler battler;
  final Color accent;

  const _CodexStatStrip({
    required this.battler,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final entries = [
      ('HP', battler.maxHealth),
      ('ATK', battler.attack),
      ('BAR', battler.barrier),
      ('INC', battler.income),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final entry in entries)
          DecoratedBox(
            decoration: BoxDecoration(
              color: EndpointPalette.blend(
                EndpointPalette.panelBackground,
                accent,
                0.12,
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accent.withValues(alpha: 0.4)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              child: EndpointText(
                '${entry.$1} ${entry.$2}',
                style: textSmallNumericBold.copyWith(
                  color: EndpointPalette.softForeground,
                  fontSize: 11,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CodexShopDetailsDialog extends StatelessWidget {
  final ShopPathNode shop;

  const _CodexShopDetailsDialog({
    required this.shop,
  });

  @override
  Widget build(BuildContext context) {
    final accent = shop.accent;

    return EndpointDetailsDialogScaffold(
      accent: accent,
      backgroundColor: EndpointPalette.panelBackgroundOpaque,
      foregroundColor: EndpointPalette.soften(accent),
      closeBackgroundColor: EndpointPalette.closeButtonBackground,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EndpointEmojiSprite(
                emoji: shop.iconEmoji,
                accent: accent,
                size: 72,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EndpointText(
                      shop.shopTitle,
                      maxLines: null,
                      style: textLargeBold.copyWith(
                        color: EndpointPalette.soften(accent),
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 5),
                    EndpointText(
                      'TIENDA ${shop.rarity.label}',
                      style: textSmallBold.copyWith(
                        color: accent,
                        fontSize: 10,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          EndpointText(
            shop.tooltip,
            maxLines: null,
            style: textMedium.copyWith(
              color: EndpointPalette.softForeground.withValues(alpha: 0.84),
              height: 1.24,
            ),
          ),
          const SizedBox(height: 12),
          EndpointText(
            '${shop.stockCriterion.label}: ${shop.stockCriterion.description}',
            maxLines: null,
            style: textSmallBold.copyWith(
              color: accent,
              fontSize: 11,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _CodexEventDetailsDialog extends StatelessWidget {
  final EventPathNode event;

  const _CodexEventDetailsDialog({
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    final accent = event.accent;

    return EndpointDetailsDialogScaffold(
      accent: accent,
      backgroundColor: EndpointPalette.panelBackgroundOpaque,
      foregroundColor: EndpointPalette.soften(accent),
      closeBackgroundColor: EndpointPalette.closeButtonBackground,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EndpointEmojiSprite(
                emoji: event.iconEmoji,
                accent: accent,
                size: 72,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EndpointText(
                      event.eventTitle,
                      maxLines: null,
                      style: textLargeBold.copyWith(
                        color: EndpointPalette.soften(accent),
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 5),
                    EndpointText(
                      'EVENTO ${event.rarity.label}',
                      style: textSmallBold.copyWith(
                        color: accent,
                        fontSize: 10,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          EndpointText(
            event.description,
            maxLines: null,
            style: textMedium.copyWith(
              color: EndpointPalette.softForeground.withValues(alpha: 0.84),
              height: 1.24,
            ),
          ),
          const SizedBox(height: 12),
          EndpointText(
            event.outcomeText,
            maxLines: null,
            style: textSmallBold.copyWith(
              color: accent,
              fontSize: 11,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _CodexStatusDetailsDialog extends StatelessWidget {
  final BattlerStatus status;

  const _CodexStatusDetailsDialog({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final accent = status.hasTag(EntityTag.desafio)
        ? EntityTag.desafio.accent
        : status.type.accent;
    final foreground = status.hasTag(EntityTag.desafio)
        ? EndpointPalette.soften(accent)
        : status.type.foreground;
    final previewBattler = defaultPlayerBattler.copyWith(
      statuses: [status],
    );

    return EndpointDetailsDialogScaffold(
      accent: accent,
      backgroundColor: EndpointPalette.panelBackgroundOpaque,
      foregroundColor: foreground,
      closeBackgroundColor: EndpointPalette.closeButtonBackground,
      maxWidth: 420,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: EndpointPalette.panelBackground,
                  border: Border.all(color: accent),
                ),
                child: Icon(
                  status.icon,
                  size: 36,
                  color: foreground,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EndpointText(
                      status.name,
                      maxLines: null,
                      style: textLargeBold.copyWith(
                        color: foreground,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 5),
                    EndpointText(
                      status.type.label.toUpperCase(),
                      style: textSmallBold.copyWith(
                        color: accent,
                        fontSize: 10,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (status.hasTags) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: EndpointTagPillMarquee(
                tags: status.tags,
                accent: accent,
              ),
            ),
          ],
          const SizedBox(height: 12),
          EndpointHighlightedValueText(
            status.localizedDescriptionFor(previewBattler),
            tags: status.tags,
            maxLines: null,
            style: textMedium.copyWith(
              color: EndpointPalette.softForeground.withValues(alpha: 0.84),
              height: 1.24,
            ),
          ),
          const SizedBox(height: 12),
          EndpointText(
            'Duracion: ${status.remainingTurnsLabel}   Value: ${status.value}',
            maxLines: null,
            style: textSmallNumericBold.copyWith(
              color: accent,
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

enum _CodexEntryKind {
  archetype,
  item,
  augment,
  enemy,
  shop,
  event,
  status,
}

class _CodexEntry {
  final _CodexEntryKind kind;
  final ArchetypePathNode? archetype;
  final Item? item;
  final Augment? augment;
  final Battler? enemy;
  final String? enemyNodeId;
  final CombatNodeTier? enemyTier;
  final ShopPathNode? shop;
  final EventPathNode? event;
  final BattlerStatus? status;

  const _CodexEntry.archetype(ArchetypePathNode value)
      : kind = _CodexEntryKind.archetype,
        archetype = value,
        item = null,
        augment = null,
        enemy = null,
        enemyNodeId = null,
        enemyTier = null,
        shop = null,
        event = null,
        status = null;

  const _CodexEntry.item(Item value)
      : kind = _CodexEntryKind.item,
        archetype = null,
        item = value,
        augment = null,
        enemy = null,
        enemyNodeId = null,
        enemyTier = null,
        shop = null,
        event = null,
        status = null;

  const _CodexEntry.augment(Augment value)
      : kind = _CodexEntryKind.augment,
        archetype = null,
        item = null,
        augment = value,
        enemy = null,
        enemyNodeId = null,
        enemyTier = null,
        shop = null,
        event = null,
        status = null;

  _CodexEntry.enemy(CombatPathNode value)
      : kind = _CodexEntryKind.enemy,
        archetype = null,
        item = null,
        augment = null,
        enemy = value.enemy,
        enemyNodeId = value.nodeId,
        enemyTier = value.tier,
        shop = null,
        event = null,
        status = null;

  const _CodexEntry.shop(ShopPathNode value)
      : kind = _CodexEntryKind.shop,
        archetype = null,
        item = null,
        augment = null,
        enemy = null,
        enemyNodeId = null,
        enemyTier = null,
        shop = value,
        event = null,
        status = null;

  const _CodexEntry.event(EventPathNode value)
      : kind = _CodexEntryKind.event,
        archetype = null,
        item = null,
        augment = null,
        enemy = null,
        enemyNodeId = null,
        enemyTier = null,
        shop = null,
        event = value,
        status = null;

  const _CodexEntry.status(BattlerStatus value)
      : kind = _CodexEntryKind.status,
        archetype = null,
        item = null,
        augment = null,
        enemy = null,
        enemyNodeId = null,
        enemyTier = null,
        shop = null,
        event = null,
        status = value;

  Color get accent {
    switch (kind) {
      case _CodexEntryKind.archetype:
        return archetype!.accent;
      case _CodexEntryKind.item:
        return item!.rarity.accent;
      case _CodexEntryKind.augment:
        return augment!.accent;
      case _CodexEntryKind.enemy:
        return enemyTier!.accent;
      case _CodexEntryKind.shop:
        return shop!.accent;
      case _CodexEntryKind.event:
        return event!.accent;
      case _CodexEntryKind.status:
        final currentStatus = status!;
        if (currentStatus.hasTag(EntityTag.desafio)) {
          return EntityTag.desafio.accent;
        }
        return currentStatus.type.accent;
    }
  }

  IconData? get icon {
    switch (kind) {
      case _CodexEntryKind.augment:
        return augment!.icon;
      case _CodexEntryKind.status:
        return status!.icon;
      case _CodexEntryKind.shop:
        return null;
      case _CodexEntryKind.event:
        return null;
      case _CodexEntryKind.archetype:
      case _CodexEntryKind.item:
      case _CodexEntryKind.enemy:
        return null;
    }
  }

  String? get emojiIcon {
    switch (kind) {
      case _CodexEntryKind.archetype:
        return archetype!.playerIconEmoji;
      case _CodexEntryKind.item:
        return item!.iconEmoji;
      case _CodexEntryKind.enemy:
        return enemy!.iconEmoji;
      case _CodexEntryKind.shop:
        return shop!.iconEmoji;
      case _CodexEntryKind.event:
        return event!.iconEmoji;
      case _CodexEntryKind.augment:
      case _CodexEntryKind.status:
        return null;
    }
  }

  String? get imageAsset {
    switch (kind) {
      case _CodexEntryKind.enemy:
        return enemy!.imageAsset;
      case _CodexEntryKind.archetype:
      case _CodexEntryKind.item:
      case _CodexEntryKind.augment:
      case _CodexEntryKind.shop:
      case _CodexEntryKind.event:
      case _CodexEntryKind.status:
        return null;
    }
  }

  String get tooltip {
    switch (kind) {
      case _CodexEntryKind.archetype:
        return archetype!.label;
      case _CodexEntryKind.item:
        return item!.displayName;
      case _CodexEntryKind.augment:
        return augment!.displayName;
      case _CodexEntryKind.enemy:
        return enemy!.name;
      case _CodexEntryKind.shop:
        return shop!.label;
      case _CodexEntryKind.event:
        return event!.label;
      case _CodexEntryKind.status:
        return status!.name;
    }
  }

  String get sortName => tooltip.toLowerCase();

  int get raritySortIndex {
    switch (kind) {
      case _CodexEntryKind.archetype:
        return archetype!.rarity.index;
      case _CodexEntryKind.item:
        return item!.rarity.index;
      case _CodexEntryKind.augment:
        return augment!.rarity.index;
      case _CodexEntryKind.enemy:
        return enemyTier!.rarity.index;
      case _CodexEntryKind.shop:
        return shop!.rarity.index;
      case _CodexEntryKind.event:
        return event!.rarity.index;
      case _CodexEntryKind.status:
        return 0;
    }
  }

  String get codexKey {
    switch (kind) {
      case _CodexEntryKind.archetype:
        return CodexDiscoveryService.archetypeKey(archetype!.archetypeId);
      case _CodexEntryKind.item:
        return CodexDiscoveryService.itemKey(item!.catalogKey);
      case _CodexEntryKind.augment:
        return CodexDiscoveryService.augmentKey(augment!.id);
      case _CodexEntryKind.enemy:
        return CodexDiscoveryService.enemyKey(enemyNodeId!);
      case _CodexEntryKind.shop:
        return CodexDiscoveryService.shopKey(shop!.nodeId);
      case _CodexEntryKind.event:
        return CodexDiscoveryService.eventKey(event!.id);
      case _CodexEntryKind.status:
        return CodexDiscoveryService.statusKey(status!.id);
    }
  }

  _CodexArchetypeSectionKey get sectionKey {
    switch (kind) {
      case _CodexEntryKind.archetype:
        return _CodexArchetypeSectionKey.fromArchetypeId(
          archetype!.archetypeId,
        );
      case _CodexEntryKind.item:
        return _CodexArchetypeSectionKey.fromItemAffinities(
          <ItemArchetypeAffinity>[item!.affinity],
        );
      case _CodexEntryKind.augment:
        return _CodexArchetypeSectionKey.fromAugmentAffinity(
          augment!.affinity,
        );
      case _CodexEntryKind.shop:
        return _CodexArchetypeSectionKey.fromArchetypeIds(
          shop!.possibleArchetypes,
        );
      case _CodexEntryKind.event:
      case _CodexEntryKind.enemy:
      case _CodexEntryKind.status:
        return _CodexArchetypeSectionKey.general;
    }
  }
}

class _CodexSection {
  final String title;
  final Color accent;
  final List<_CodexEntry> entries;

  const _CodexSection({
    required this.title,
    required this.accent,
    required this.entries,
  });
}

enum _CodexArchetypeSectionKey {
  general,
  veloz,
  inamovible,
  imparable,
  mercante;

  String get label {
    switch (this) {
      case _CodexArchetypeSectionKey.general:
        return 'General';
      case _CodexArchetypeSectionKey.veloz:
        return ArchetypeId.veloz.label;
      case _CodexArchetypeSectionKey.inamovible:
        return ArchetypeId.inamovible.label;
      case _CodexArchetypeSectionKey.imparable:
        return ArchetypeId.imparable.label;
      case _CodexArchetypeSectionKey.mercante:
        return ArchetypeId.mercante.label;
    }
  }

  Color get accent {
    switch (this) {
      case _CodexArchetypeSectionKey.general:
        return EndpointPalette.neutralAccent;
      case _CodexArchetypeSectionKey.veloz:
        return const Color(0xFF59B7FF);
      case _CodexArchetypeSectionKey.inamovible:
        return const Color(0xFF5AF78E);
      case _CodexArchetypeSectionKey.imparable:
        return const Color(0xFFFF5A5F);
      case _CodexArchetypeSectionKey.mercante:
        return const Color(0xFFEBCB5A);
    }
  }

  static _CodexArchetypeSectionKey fromArchetypeId(ArchetypeId archetypeId) {
    switch (archetypeId) {
      case ArchetypeId.veloz:
        return _CodexArchetypeSectionKey.veloz;
      case ArchetypeId.inamovible:
        return _CodexArchetypeSectionKey.inamovible;
      case ArchetypeId.imparable:
        return _CodexArchetypeSectionKey.imparable;
      case ArchetypeId.mercante:
        return _CodexArchetypeSectionKey.mercante;
    }
  }

  static _CodexArchetypeSectionKey fromArchetypeIds(
    List<ArchetypeId> archetypeIds,
  ) {
    if (archetypeIds.isEmpty) return _CodexArchetypeSectionKey.general;

    return fromArchetypeId(archetypeIds.first);
  }

  static _CodexArchetypeSectionKey fromItemAffinities(
    List<ItemArchetypeAffinity> affinities,
  ) {
    final specificAffinities = affinities
        .where((affinity) => affinity.isSpecific)
        .toList(growable: false);
    if (specificAffinities.isEmpty) {
      return _CodexArchetypeSectionKey.general;
    }

    return fromArchetypeId(specificAffinities.first.archetypeId!);
  }

  static _CodexArchetypeSectionKey fromAugmentAffinity(
    AugmentAffinity affinity,
  ) {
    if (!affinity.isSpecific) return _CodexArchetypeSectionKey.general;

    return fromArchetypeId(affinity.archetypeId!);
  }
}

class _CodexCategoryData {
  final String title;
  final Color accent;
  final IconData? icon;
  final String? emojiIcon;

  const _CodexCategoryData({
    required this.title,
    required this.accent,
    this.icon,
    this.emojiIcon,
  });

  static _CodexCategoryData forCategory(_CodexCategory category) {
    switch (category) {
      case _CodexCategory.archetypes:
        return _CodexCategoryData(
          title: 'Arquetipos',
          accent: imparableArchetypeNode.accent,
          emojiIcon: imparableArchetypeNode.iconEmoji,
        );
      case _CodexCategory.items:
        return const _CodexCategoryData(
          title: 'Objetos',
          accent: EndpointPalette.warningAccent,
          emojiIcon: '\u{1F9F0}',
        );
      case _CodexCategory.augments:
        return const _CodexCategoryData(
          title: 'Aumentos',
          accent: EndpointPalette.warningAccent,
          icon: Icons.bolt_rounded,
        );
      case _CodexCategory.enemies:
        return _CodexCategoryData(
          title: 'Enemigos',
          accent: EndpointPalette.dangerAccent,
          emojiIcon: defaultEnemyBattler.iconEmoji,
        );
      case _CodexCategory.shops:
        return const _CodexCategoryData(
          title: 'Tiendas',
          accent: EndpointPalette.shopAccent,
          icon: Icons.storefront_rounded,
        );
      case _CodexCategory.events:
        return const _CodexCategoryData(
          title: 'Eventos',
          accent: EndpointPalette.infoAccent,
          icon: Icons.auto_awesome_rounded,
        );
      case _CodexCategory.buffs:
        return const _CodexCategoryData(
          title: 'Buffs',
          accent: EndpointPalette.primaryAccent,
          icon: Icons.graphic_eq_rounded,
        );
      case _CodexCategory.debuffs:
        return const _CodexCategoryData(
          title: 'Debuffs',
          accent: EndpointPalette.dangerAccent,
          icon: Icons.science_rounded,
        );
    }
  }
}
