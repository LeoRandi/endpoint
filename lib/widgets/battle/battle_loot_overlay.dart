import '../_imports.dart';
import '../../services/endpoint_preferences_models.dart';

const _rewardActionHeight = 56.0;

class BattleLootOverlay extends StatefulWidget {
  final Battler player;
  final Item? lootItem;
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
    this.lootAbility,
  });

  @override
  State<BattleLootOverlay> createState() => _BattleLootOverlayState();
}

class _BattleLootOverlayState extends State<BattleLootOverlay> {
  late Battler _player;
  late bool _isLootCollected;
  late bool _isMoneyCollected;

  bool get _hasLootReward =>
      widget.lootItem != null || widget.lootAbility != null;
  bool get _hasPendingLoot => _hasLootReward && !_isLootCollected;
  bool get _hasPendingMoney => widget.moneyReward > 0 && !_isMoneyCollected;
  bool get _hasPendingRewards => _hasPendingLoot || _hasPendingMoney;
  bool get _lootWillUpgradeItem =>
      widget.lootItem != null && _player.wouldUpgradeItem(widget.lootItem!);
  bool get _lootWillUpgradeAbility =>
      widget.lootAbility != null &&
      _player.wouldUpgradeAbility(widget.lootAbility!);
  bool get _canCollectLoot {
    final lootItem = widget.lootItem;
    return lootItem == null || _player.canReceiveItem(lootItem);
  }

  String? get _blockedLootReason {
    final lootItem = widget.lootItem;
    if (lootItem == null || _canCollectLoot) return null;
    return 'Inventario lleno (${Battler.maxInventoryItems}/${Battler.maxInventoryItems})';
  }

  @override
  void initState() {
    super.initState();
    _player = widget.player;
    _isLootCollected = !_hasLootReward;
    _isMoneyCollected = widget.moneyReward <= 0;
  }

  Battler _applyLoot(Battler player) {
    var updatedPlayer = player;

    if (widget.lootItem != null) {
      updatedPlayer = updatedPlayer.addItem(widget.lootItem!);
    }
    if (widget.lootAbility != null) {
      updatedPlayer =
          updatedPlayer.addAbility(widget.lootAbility!.resetState());
    }

    return updatedPlayer;
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

  void _collectLoot() {
    if (!_hasPendingLoot || !_canCollectLoot) return;

    setState(() {
      _player = _applyLoot(_player);
      _isLootCollected = true;
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
    if (_hasPendingLoot && !_canCollectLoot) return;

    var updatedPlayer = _player;

    if (_hasPendingLoot) {
      updatedPlayer = _applyLoot(updatedPlayer);
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
                      if (widget.lootItem != null)
                        _BattleLootRewardCard(
                          title: widget.lootItem!.displayName,
                          subtitle: widget.lootItem!.tooltipDescription,
                          tags: widget.lootItem!.tags,
                          accent: widget.lootItem!.rarity.accent,
                          emoji: widget.lootItem!.iconEmoji,
                          isCollected: _isLootCollected,
                          collectedLabel:
                              _lootWillUpgradeItem ? 'MEJORADO' : 'RECOGIDO',
                          pendingLabel: _blockedLootReason ??
                              (_lootWillUpgradeItem ? 'MEJORAR' : 'RECLAMAR'),
                          showUpgradeIndicator: _lootWillUpgradeItem,
                          upgradeIndicatorColor:
                              endpointUpgradeIndicatorNeonYellow,
                          onPressed: _collectLoot,
                          isEnabled: _canCollectLoot,
                        ),
                      if (widget.lootItem != null && widget.lootAbility != null)
                        const SizedBox(height: 12),
                      if (widget.lootAbility != null)
                        _BattleLootRewardCard(
                          title: widget.lootAbility!.displayName,
                          subtitle: widget.lootAbility!.displayDescription,
                          tags: widget.lootAbility!.tags,
                          accent: widget.lootAbility!.accent,
                          icon: widget.lootAbility!.icon,
                          isCollected: _isLootCollected,
                          collectedLabel: _lootWillUpgradeAbility
                              ? 'MEJORADA'
                              : 'APRENDIDA',
                          pendingLabel:
                              _lootWillUpgradeAbility ? 'MEJORAR' : 'APRENDER',
                          showUpgradeIndicator: _lootWillUpgradeAbility,
                          upgradeIndicatorColor:
                              endpointUpgradeIndicatorNeonYellow,
                          onPressed: _collectLoot,
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
                    onPressed: _hasPendingLoot && !_canCollectLoot
                        ? null
                        : _collectAll,
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
        _BattleLootRewardLead(
          accent: accent,
          emoji: emoji,
          icon: icon,
          isCollected: isCollected,
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
