import '_imports.dart';
import '../../services/_exports.dart';

const _rewardActionHeight = 56.0;

class BattleLootOverlay extends StatefulWidget {
  final Battler player;
  final Item? lootItem;
  final List<BattleItemReward> itemRewards;
  final BattlerAbility? lootAbility;
  final int moneyReward;
  final String enemyName;
  final EndpointGameMode gameMode;

  const BattleLootOverlay({
    super.key,
    required this.player,
    required this.moneyReward,
    required this.enemyName,
    this.gameMode = EndpointGameMode.pattern,
    this.lootItem,
    this.itemRewards = const <BattleItemReward>[],
    this.lootAbility,
  });

  @override
  State<BattleLootOverlay> createState() => _BattleLootOverlayState();
}

class _BattleLootOverlayState extends State<BattleLootOverlay> {
  static const _runtimeService = CatalogRuntimeService();

  late Battler _player;
  late Set<int> _collectedItemRewardIndexes;
  late bool _isAbilityCollected;
  late bool _isMoneyCollected;

  List<BattleItemReward> get _itemRewards => widget.itemRewards.isNotEmpty
      ? widget.itemRewards
      : [
          if (widget.lootItem != null) BattleItemReward(item: widget.lootItem!),
        ];
  bool get _hasLootReward =>
      _itemRewards.isNotEmpty || widget.lootAbility != null;
  bool get _hasPendingLoot =>
      _collectedItemRewardIndexes.length < _itemRewards.length ||
      (widget.lootAbility != null && !_isAbilityCollected);
  bool get _hasPendingMoney => widget.moneyReward > 0 && !_isMoneyCollected;
  bool get _hasPendingRewards => _hasPendingLoot || _hasPendingMoney;
  bool get _lootWillUpgradeAbility =>
      widget.lootAbility != null &&
      _player.wouldUpgradeAbility(widget.lootAbility!);

  bool _itemRewardWillUpgrade(int index) {
    return _player.wouldUpgradeItem(_itemRewards[index].item);
  }

  bool _canCollectItemReward(int index) {
    final reward = _itemRewards[index];
    if (reward.hasSource) {
      return _player.canReceiveItemInInventoryOrEquipment(reward.item);
    }

    return _player.canReceiveItem(reward.item);
  }

  String? _blockedItemRewardReason(int index) {
    if (_canCollectItemReward(index)) return null;
    return 'Inventario lleno (${Battler.maxInventoryItems}/${Battler.maxInventoryItems})';
  }

  @override
  void initState() {
    super.initState();
    _player = widget.player;
    _collectedItemRewardIndexes = <int>{};
    _isAbilityCollected = widget.lootAbility == null;
    _isMoneyCollected = widget.moneyReward <= 0;
  }

  Future<void> _handleBackNavigation() async {
    final shouldClose = await _shouldClose();
    if (!shouldClose || !mounted) return;

    Navigator.of(context).pop(_player);
  }

  Future<void> _handleClosePressed() async {
    final shouldClose = await _shouldClose();
    if (!shouldClose || !mounted) return;

    Navigator.of(context).pop(_player);
  }

  Future<bool> _shouldClose() async {
    if (!_hasPendingRewards) return true;

    return await _showLeaveRewardsDialog();
  }

  Future<bool> _showLeaveRewardsDialog() async {
    final shouldLeave = await showEndpointDialog<bool>(
      context: context,
      barrierLabel: 'Confirmar salida de recompensas',
      barrierColor: EndpointPalette.overlayScrimStrong,
      transitionDuration: const Duration(milliseconds: 200),
      builder: (context) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: EndpointPanel(
                accent: EndpointPalette.rewardAccent,
                backgroundColor: EndpointPalette.panelBackgroundBattleOpaque,
                borderRadius: 18,
                glowOpacity: 0.1,
                blurRadius: 24,
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EndpointText(
                      'RECOMPENSAS PENDIENTES',
                      style: textMediumBold.copyWith(
                        color: EndpointPalette.rewardAccent,
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(height: 10),
                    EndpointText(
                      'Te has dejado recompensas. Seguro que quieres seguir?',
                      maxLines: null,
                      style: textMedium.copyWith(
                        color: EndpointPalette.softForeground.withValues(
                          alpha: 0.84,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: EndpointActionButton(
                            label: 'No',
                            onPressed: () => Navigator.of(context).pop(false),
                            accent: EndpointPalette.primaryAccent,
                            backgroundColor:
                                EndpointPalette.closeButtonBackground,
                            foregroundColor: EndpointPalette.softForeground,
                            textStyle: textMediumBold.copyWith(
                              fontSize: 15,
                              letterSpacing: 0.9,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: EndpointActionButton(
                            label: 'Si',
                            onPressed: () => Navigator.of(context).pop(true),
                            accent: EndpointPalette.dangerAccent,
                            backgroundColor: EndpointPalette.blend(
                              EndpointPalette.panelBackgroundBattle,
                              EndpointPalette.dangerAccent,
                              0.42,
                            ),
                            foregroundColor: EndpointPalette.soften(
                                EndpointPalette.dangerAccent),
                            textStyle: textMediumBold.copyWith(
                              fontSize: 15,
                              letterSpacing: 0.9,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    return shouldLeave ?? false;
  }

  void _collectItemReward(int index) {
    if (_collectedItemRewardIndexes.contains(index) ||
        !_canCollectItemReward(index)) {
      return;
    }

    setState(() {
      final reward = _itemRewards[index];
      _player = reward.hasSource
          ? _player.addItemToInventoryOrEquipment(reward.item)
          : _player.addItem(reward.item);
      _collectedItemRewardIndexes = <int>{
        ..._collectedItemRewardIndexes,
        index,
      };
    });
  }

  void _collectAbility() {
    if (widget.lootAbility == null || _isAbilityCollected) return;

    setState(() {
      _player = _player.addAbility(
        _runtimeService.runtimeAbility(widget.lootAbility!),
      );
      _isAbilityCollected = true;
    });
  }

  void _collectMoney() {
    if (!_hasPendingMoney) return;

    setState(() {
      _player = _player.earnMoney(widget.moneyReward);
      _isMoneyCollected = true;
    });
  }

  void _collectAll() {
    var updatedPlayer = _player;
    final collectedIndexes = <int>{..._collectedItemRewardIndexes};

    for (var index = 0; index < _itemRewards.length; index++) {
      if (collectedIndexes.contains(index)) continue;
      final reward = _itemRewards[index];
      final canReceive = reward.hasSource
          ? updatedPlayer.canReceiveItemInInventoryOrEquipment(reward.item)
          : updatedPlayer.canReceiveItem(reward.item);
      if (!canReceive) return;
      updatedPlayer = reward.hasSource
          ? updatedPlayer.addItemToInventoryOrEquipment(reward.item)
          : updatedPlayer.addItem(reward.item);
      collectedIndexes.add(index);
    }
    if (widget.lootAbility != null && !_isAbilityCollected) {
      updatedPlayer = updatedPlayer.addAbility(
        _runtimeService.runtimeAbility(widget.lootAbility!),
      );
    }
    if (_hasPendingMoney) {
      updatedPlayer = updatedPlayer.earnMoney(widget.moneyReward);
    }

    Navigator.of(context).pop(updatedPlayer);
  }

  Future<void> _openOperatives() async {
    await showEndpointOverlay<void>(
      context: context,
      barrierColor: EndpointPalette.overlayScrimStrong,
      builder: (_) => OperativesOverlay(
        player: _player,
        gameMode: widget.gameMode,
        onPlayerChanged: (updatedPlayer) {
          setState(() {
            _player = updatedPlayer;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const accent = EndpointPalette.rewardAccent;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackNavigation();
      },
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: EndpointPanel(
            accent: accent,
            backgroundColor: EndpointPalette.panelBackgroundBattleOpaque,
            borderRadius: 20,
            glowOpacity: 0.12,
            blurRadius: 28,
            spreadRadius: 3,
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          EndpointText(
                            'BOTIN ASEGURADO',
                            style: textLargeBold.copyWith(
                              color: EndpointPalette.softForegroundWarm,
                              letterSpacing: 1.8,
                            ),
                          ),
                          const SizedBox(height: 6),
                          EndpointText(
                            'Recoge las recompensas del combate contra ${widget.enemyName}.',
                            maxLines: null,
                            style: textMedium.copyWith(
                              color: EndpointPalette.softForeground.withValues(
                                alpha: 0.76,
                              ),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    EndpointActionButton(
                      label: 'Equipo',
                      icon: Icons.inventory_2_outlined,
                      onPressed: () => unawaited(_openOperatives()),
                      tooltip: 'Abrir inventario y equipo',
                      accent: EndpointPalette.primaryAccent,
                      backgroundColor: EndpointPalette.closeButtonBackground,
                      foregroundColor: EndpointPalette.softForeground,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      textStyle: textSmallBold.copyWith(
                        fontSize: 12,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(width: 8),
                    EndpointSceneCloseButton(
                      onPressed: _handleClosePressed,
                      tooltip: 'Cerrar recompensas',
                      accent: accent,
                      foregroundColor: EndpointPalette.softForegroundWarm,
                      backgroundColor: EndpointPalette.blend(
                        EndpointPalette.panelBackgroundGold,
                        accent,
                        0.08,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                EndpointText(
                  'TOCA CADA CARD PARA RECLAMARLA',
                  style: textSmallBold.copyWith(
                    color: accent,
                    fontSize: 10,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    children: [
                      for (var index = 0;
                          index < _itemRewards.length;
                          index++) ...[
                        if (index > 0) const SizedBox(height: 12),
                        _BattleLootRewardCard(
                          title: _itemRewards[index].item.displayName,
                          subtitle: _itemRewards[index].item.tooltipDescription,
                          tags: _itemRewards[index].item.tags,
                          accent: _itemRewards[index].item.rarity.accent,
                          emoji: _itemRewards[index].item.iconEmoji,
                          sourceEmoji:
                              _itemRewards[index].sourceItem?.iconEmoji,
                          sourceTooltip: _itemRewards[index].sourceItem == null
                              ? null
                              : 'Generado por ${_itemRewards[index].sourceItem!.displayName}',
                          isCollected:
                              _collectedItemRewardIndexes.contains(index),
                          collectedLabel: _itemRewardWillUpgrade(index)
                              ? 'MEJORADO'
                              : 'RECOGIDO',
                          pendingLabel: _blockedItemRewardReason(index) ??
                              (_itemRewardWillUpgrade(index)
                                  ? 'MEJORAR'
                                  : 'RECLAMAR'),
                          showUpgradeIndicator: _itemRewardWillUpgrade(index),
                          upgradeIndicatorColor:
                              endpointUpgradeIndicatorNeonYellow,
                          onPressed: () => _collectItemReward(index),
                          isEnabled: _canCollectItemReward(index),
                        ),
                      ],
                      if (_itemRewards.isNotEmpty && widget.lootAbility != null)
                        const SizedBox(height: 12),
                      if (widget.lootAbility != null)
                        _BattleLootRewardCard(
                          title: widget.lootAbility!.displayName,
                          subtitle: widget.lootAbility!.displayDescription,
                          tags: widget.lootAbility!.tags,
                          accent: widget.lootAbility!.accent,
                          icon: widget.lootAbility!.icon,
                          isCollected: _isAbilityCollected,
                          collectedLabel: _lootWillUpgradeAbility
                              ? 'MEJORADA'
                              : 'APRENDIDA',
                          pendingLabel:
                              _lootWillUpgradeAbility ? 'MEJORAR' : 'APRENDER',
                          showUpgradeIndicator: _lootWillUpgradeAbility,
                          upgradeIndicatorColor:
                              endpointUpgradeIndicatorNeonYellow,
                          onPressed: _collectAbility,
                        ),
                      if (_hasLootReward && widget.moneyReward > 0)
                        const SizedBox(height: 12),
                      if (widget.moneyReward > 0)
                        _BattleLootRewardCard(
                          title: '${widget.moneyReward} CREDITOS',
                          subtitle: 'Recompensa economica del encuentro.',
                          accent: EndpointPalette.warningAccent,
                          icon: Icons.monetization_on_rounded,
                          isCollected: _isMoneyCollected,
                          collectedLabel: 'COBRADO',
                          pendingLabel: 'COBRAR',
                          onPressed: _collectMoney,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: _rewardActionHeight,
                  child: EndpointActionButton(
                    label: 'Saquear todo',
                    icon: Icons.download_rounded,
                    onPressed: _collectAll,
                    tooltip: 'Recoger todas las recompensas y salir',
                    accent: accent,
                    backgroundColor: EndpointPalette.blend(
                      EndpointPalette.panelBackgroundGold,
                      accent,
                      0.12,
                    ),
                    foregroundColor: EndpointPalette.softForegroundWarm,
                    expands: true,
                    iconSize: 20,
                    textStyle: textMediumBold.copyWith(
                      fontSize: 15,
                      letterSpacing: 1,
                    ),
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

class _BattleLootRewardCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Iterable<EntityTag> tags;
  final Color accent;
  final String? emoji;
  final String? sourceEmoji;
  final String? sourceTooltip;
  final IconData? icon;
  final bool isCollected;
  final String collectedLabel;
  final String pendingLabel;
  final bool showUpgradeIndicator;
  final Color? upgradeIndicatorColor;
  final VoidCallback onPressed;
  final bool isEnabled;

  const _BattleLootRewardCard({
    required this.title,
    required this.subtitle,
    this.tags = const [],
    required this.accent,
    required this.isCollected,
    required this.collectedLabel,
    required this.pendingLabel,
    this.showUpgradeIndicator = false,
    this.upgradeIndicatorColor,
    required this.onPressed,
    this.isEnabled = true,
    this.emoji,
    this.sourceEmoji,
    this.sourceTooltip,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final foregroundColor = isCollected
        ? Colors.white.withValues(alpha: 0.5)
        : EndpointPalette.softForeground;
    final statusColor =
        isCollected ? Colors.white.withValues(alpha: 0.54) : accent;
    final rewardContent = Row(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            _BattleLootRewardLead(
              accent: accent,
              emoji: emoji,
              icon: icon,
              isCollected: isCollected,
            ),
            if (sourceEmoji != null)
              Positioned(
                right: -5,
                bottom: -5,
                child: Tooltip(
                  message: sourceTooltip ?? 'Generado por item',
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: EndpointPalette.panelBackgroundBattleOpaque,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.72),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: EndpointText(
                      sourceEmoji!,
                      style: TextStyle(
                        fontSize: 10,
                        color: isCollected
                            ? Colors.white.withValues(alpha: 0.56)
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EndpointText(
                title,
                overflow: TextOverflow.ellipsis,
                style: textMediumBold.copyWith(
                  color: foregroundColor,
                  fontSize: 14,
                  letterSpacing: 0.9,
                ),
              ),
              const SizedBox(height: 2),
              EndpointHighlightedValueText(
                subtitle,
                tags: tags,
                overflow: TextOverflow.ellipsis,
                style: textSmallBold.copyWith(
                  color: foregroundColor.withValues(alpha: 0.72),
                  fontSize: 10,
                  letterSpacing: 0.7,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        EndpointText(
          isCollected ? collectedLabel : pendingLabel,
          textAlign: TextAlign.right,
          style: textSmallBold.copyWith(
            color: statusColor,
            fontSize: 10,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
    final rewardPanel = EndpointPanel(
      accent: accent,
      backgroundColor: isCollected
          ? EndpointPalette.panelBackgroundMuted
          : EndpointPalette.panelBackgroundSoft,
      borderRadius: 14,
      glowOpacity: isCollected ? 0.01 : 0.05,
      padding: EdgeInsets.zero,
      child: !isCollected && showUpgradeIndicator
          ? EndpointUpgradeBackdrop(
              color:
                  upgradeIndicatorColor ?? endpointUpgradeIndicatorNeonYellow,
              iconSize: 19,
              spacing: 4,
              horizontalInset: 8,
              borderRadius: BorderRadius.circular(14),
              child: SizedBox.expand(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
                  child: rewardContent,
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
              child: rewardContent,
            ),
    );

    return SizedBox(
      width: double.infinity,
      height: _rewardActionHeight,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isCollected || !isEnabled ? null : onPressed,
          borderRadius: BorderRadius.circular(14),
          child: rewardPanel,
        ),
      ),
    );
  }
}

class _BattleLootRewardLead extends StatelessWidget {
  final Color accent;
  final String? emoji;
  final IconData? icon;
  final bool isCollected;

  const _BattleLootRewardLead({
    required this.accent,
    required this.isCollected,
    this.emoji,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: isCollected ? 0.16 : 0.24),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: accent.withValues(alpha: isCollected ? 0.28 : 0.56),
        ),
      ),
      alignment: Alignment.center,
      child: emoji != null
          ? EndpointText(
              emoji!,
              style: TextStyle(
                fontSize: 18,
                color:
                    isCollected ? Colors.white.withValues(alpha: 0.56) : null,
              ),
            )
          : Icon(
              icon,
              size: 18,
              color:
                  isCollected ? Colors.white.withValues(alpha: 0.56) : accent,
            ),
    );
  }
}
