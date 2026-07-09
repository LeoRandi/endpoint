import '_imports.dart';

class ArchetypeSpecialEventPage extends StatefulWidget {
  final Battler player;
  final EventPathNode node;
  final RunRandomizer randomizer;
  final PathEventService eventService;
  final int dayNumber;

  const ArchetypeSpecialEventPage({
    super.key,
    required this.player,
    required this.node,
    required this.randomizer,
    required this.eventService,
    required this.dayNumber,
  });

  @override
  State<ArchetypeSpecialEventPage> createState() =>
      _ArchetypeSpecialEventPageState();
}

class _ArchetypeSpecialEventPageState extends State<ArchetypeSpecialEventPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _coinController;
  Item? _selectedItem;
  bool _isResolving = false;
  bool? _selectedCoinSide;
  bool? _coinResult;
  int _flavorPageIndex = 0;

  bool get _isFlavorIntroVisible {
    final flavorTexts = widget.node.flavorTexts;
    return flavorTexts.isNotEmpty && _flavorPageIndex < flavorTexts.length;
  }

  @override
  void initState() {
    super.initState();
    _coinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _coinController.dispose();
    super.dispose();
  }

  void _advanceFlavorIntro() {
    if (!_isFlavorIntroVisible) return;
    setState(() {
      _flavorPageIndex++;
    });
  }

  void _close() {
    Navigator.of(context).pop(
      PathEventVisitResult(
        player: widget.player,
        outcomeText: 'Sales del evento sin cerrar ningun trato.',
      ),
    );
  }

  void _resolve(PathEventVisitResult result) {
    if (_isResolving) return;
    setState(() {
      _isResolving = true;
    });
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return EndpointCenterStageScene(
      showTitle: widget.node.showTitle,
      background: EndpointGradients.event(widget.node.accent),
      foregroundOverlay: _isFlavorIntroVisible
          ? EndpointEventFlavorIntroOverlay(
              pages: widget.node.flavorTexts,
              pageIndex: _flavorPageIndex,
              emoji: widget.node.flavorEmoji ?? widget.node.iconEmoji,
              accent: widget.node.accent,
              onAdvance: _advanceFlavorIntro,
            )
          : null,
      onClose: _close,
      closeTooltip: EndpointStrings.backToRoute,
      accent: widget.node.accent,
      emoji: widget.node.iconEmoji,
      title: widget.node.eventTitle,
      content: _buildContent(),
    );
  }

  Widget _buildContent() {
    final content = switch (widget.node.id) {
      PathEventId.clinicaReflejos => _buildClinicaReflejos(),
      PathEventId.viktorOperations => _buildItemUpgradeEvent(
          items: widget.eventService.buildViktorOperationsEligibleItems(
            widget.player,
          ),
          actionLabel: 'OPERAR',
          emptyText: 'No tienes objetos deliciosos compatibles.',
          onResolve: (item) {
            final result = widget.eventService.resolveViktorOperationsUpgrade(
              player: widget.player,
              selectedItem: item,
            );
            if (result != null) _resolve(result);
          },
        ),
      PathEventId.arquitecbrosSl => _buildArquitecbros(),
      PathEventId.capillaStShieladurn => _buildItemUpgradeEvent(
          items: widget.eventService.buildOwnedItems(widget.player),
          actionLabel: 'OFRENDAR',
          emptyText: 'No tienes objetos que ofrecer.',
          onResolve: (item) => _resolve(
            widget.eventService.resolveCapillaOffering(
              player: widget.player,
              selectedItem: item,
              randomizer: widget.randomizer,
            ),
          ),
        ),
      PathEventId.contratontos => _buildContratontos(),
      PathEventId.hornoJuramentos => _buildItemUpgradeEvent(
          items: widget.eventService.buildHornoJuramentosEligibleItems(
            widget.player,
          ),
          actionLabel: 'ENTRAR',
          emptyText: 'No tienes objetos que el horno pueda mejorar.',
          onResolve: (item) {
            final result = widget.eventService.resolveHornoJuramentosUpgrade(
              player: widget.player,
              selectedItem: item,
            );
            if (result != null) _resolve(result);
          },
        ),
      PathEventId.auditoriaCreativa => _buildAuditoriaCreativa(),
      PathEventId.mercadoFuturos => _buildMercadoFuturos(),
      _ => EndpointText(widget.node.description),
    };

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 680),
      child: EndpointPanel(
        accent: widget.node.accent,
        backgroundColor: EndpointPalette.panelBackgroundSoft,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: content,
      ),
    );
  }

  Widget _buildIntro() {
    return EndpointText(
      widget.node.description,
      textAlign: TextAlign.center,
      maxLines: null,
      style: textSmallBold.copyWith(
        color: EndpointPalette.softForeground.withAlpha(214),
        letterSpacing: 0.6,
      ),
    );
  }

  Widget _buildClinicaReflejos() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildIntro(),
        const SizedBox(height: 12),
        _ChoiceGrid(
          children: [
            _eventButton(
              label: 'AUMENTO CREPITANS',
              icon: Icons.flash_on_rounded,
              tooltip: 'Recibir un aumento Crepitans aleatorio segun el dia',
              onPressed: () => _resolve(
                widget.eventService.resolveClinicaReflejosAugment(
                  player: widget.player,
                  randomizer: widget.randomizer,
                  dayNumber: widget.dayNumber,
                ),
              ),
            ),
            _eventButton(
              label: 'INYECTAR 6 QUEMADURA',
              icon: Icons.local_fire_department_rounded,
              tooltip: 'Recibir 6 Quemadura y +1 ATK permanente',
              onPressed: () => _resolve(
                widget.eventService.resolveClinicaReflejosBurnTraining(
                  widget.player,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildArquitecbros() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildIntro(),
        const SizedBox(height: 12),
        _ChoiceGrid(
          children: [
            _eventButton(
              label: 'ACEPTAR LA OBRA',
              icon: Icons.construction_rounded,
              tooltip: 'Prepara una muralla y gana stats permanentes',
              onPressed: () => _resolve(
                widget.eventService.resolveArquitecbrosWall(
                  player: widget.player,
                  randomizer: widget.randomizer,
                ),
              ),
            ),
            _eventButton(
              label: 'RETAR AL TERCERO',
              icon: Icons.sports_mma_rounded,
              tooltip: 'Entrar en combate contra un enemigo morado con +3 BP',
              onPressed: _startArquitecbrosFight,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContratontos() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildIntro(),
        const SizedBox(height: 12),
        _ChoiceGrid(
          children: [
            _eventButton(
              label: '4 QUEMADURA / 1 XP',
              icon: Icons.whatshot_rounded,
              tooltip: 'Ganar 1 XP y recibir 4 Quemadura',
              onPressed: () => _resolve(
                widget.eventService.resolveContratontosLight(widget.player),
              ),
            ),
            _eventButton(
              label: '8 QUEMADURA / AZUL',
              icon: Icons.fitness_center_rounded,
              tooltip: 'Recibir 8 Quemadura y un aumento Hercules azul',
              onPressed: () => _resolve(
                widget.eventService.resolveContratontosBlueAugment(
                  player: widget.player,
                  randomizer: widget.randomizer,
                ),
              ),
            ),
            _eventButton(
              label: '-20% HP / 4 XP',
              icon: Icons.trending_up_rounded,
              tooltip: 'Perder 20% de HP maximo y ganar 4 XP',
              onPressed: () => _resolve(
                widget.eventService.resolveContratontosMaxHpLoss(
                  widget.player,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAuditoriaCreativa() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildIntro(),
        const SizedBox(height: 12),
        _ChoiceGrid(
          children: [
            _eventButton(
              label: '-15% HP / 20C',
              icon: Icons.payments_rounded,
              tooltip: 'Perder 15% de HP maximo y ganar 20 creditos',
              onPressed: () => _resolve(
                widget.eventService.resolveAuditoriaCreativaCredits(
                  widget.player,
                ),
              ),
            ),
            _eventButton(
              label: 'DEUDA / AUMENTO VERDE',
              icon: Icons.request_quote_rounded,
              tooltip:
                  'Recibir Deuda y un aumento verde de cualquier arquetipo',
              onPressed: () => _resolve(
                widget.eventService.resolveAuditoriaCreativaDebtAugment(
                  player: widget.player,
                  randomizer: widget.randomizer,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMercadoFuturos() {
    final selectedSide = _selectedCoinSide;
    final result = _coinResult;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildIntro(),
        const SizedBox(height: 12),
        AnimatedBuilder(
          animation: _coinController,
          builder: (context, child) {
            final turns = _coinController.value * 10;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(turns * pi),
              child: child,
            );
          },
          child: Icon(
            result == null
                ? Icons.monetization_on_rounded
                : result
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
            size: 74,
            color: widget.node.accent,
          ),
        ),
        const SizedBox(height: 10),
        if (selectedSide == null)
          _ChoiceGrid(
            children: [
              _eventButton(
                label: 'CARA',
                icon: Icons.looks_one_rounded,
                tooltip: 'Apostar por cara',
                onPressed: () => _flipCoin(true),
              ),
              _eventButton(
                label: 'CRUZ',
                icon: Icons.looks_two_rounded,
                tooltip: 'Apostar por cruz',
                onPressed: () => _flipCoin(false),
              ),
            ],
          )
        else
          EndpointText(
            result == null
                ? 'La moneda esta girando...'
                : result
                    ? 'La moneda cae de tu lado.'
                    : 'La moneda cae del otro lado.',
            textAlign: TextAlign.center,
            style: textMediumBold.copyWith(color: widget.node.accent),
          ),
      ],
    );
  }

  Widget _buildItemUpgradeEvent({
    required List<Item> items,
    required String actionLabel,
    required String emptyText,
    required void Function(Item item) onResolve,
  }) {
    final selectedItem = _selectedItem;
    final canResolve = selectedItem != null && items.contains(selectedItem);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildIntro(),
        const SizedBox(height: 12),
        EndpointActionButton(
          label: selectedItem?.displayName ?? emptyText,
          icon: Icons.inventory_2_rounded,
          onPressed: items.isEmpty ? null : () => _openItemSelection(items),
          tooltip: items.isEmpty ? emptyText : 'Seleccionar objeto',
          accent: selectedItem?.rarity.accent ?? widget.node.accent,
          expands: true,
          labelMaxLines: 2,
          useMarquee: false,
        ),
        const SizedBox(height: 10),
        EndpointActionButton(
          label: actionLabel,
          icon: Icons.check_rounded,
          onPressed: canResolve && !_isResolving
              ? () => onResolve(selectedItem)
              : null,
          tooltip: canResolve ? 'Resolver evento' : 'Selecciona un objeto',
          accent: selectedItem?.rarity.accent ?? widget.node.accent,
          expands: true,
          useMarquee: false,
        ),
      ],
    );
  }

  Future<void> _openItemSelection(List<Item> items) async {
    final item = await showEndpointDialog<Item>(
      context: context,
      barrierLabel: 'Seleccionar objeto',
      barrierColor: EndpointPalette.overlayScrim,
      builder: (context) => _ItemSelectionDialog(
        items: items,
        accent: widget.node.accent,
      ),
    );
    if (!mounted || item == null) return;
    setState(() {
      _selectedItem = item;
    });
  }

  Future<void> _startArquitecbrosFight() async {
    if (_isResolving) return;
    setState(() {
      _isResolving = true;
    });
    final node = widget.eventService.buildArquitecbrosBrotherCombatNode(
      randomizer: widget.randomizer,
    );
    final result = await Navigator.of(context).push<BattleFlowResult>(
      buildEndpointSceneRoute<BattleFlowResult>(
        BattlePage(
          enemy: node.enemy,
          player: widget.player,
          randomizer: widget.randomizer,
          phase: RunHourPhase.night,
          showTitle: node.showTitle,
          victoryMoneyFactor: node.tier.factor,
          enemyTier: node.tier.factor,
          returnResultToCaller: true,
        ),
      ),
    );
    if (!mounted) return;
    if (result == null) {
      setState(() {
        _isResolving = false;
      });
      return;
    }

    Navigator.of(context).pop(
      PathEventVisitResult(
        player: result.player,
        outcomeText: result.type == BattleFlowResultType.victory
            ? 'El tercer hermano cae. El presupuesto queda cancelado.'
            : 'El tercer hermano gana la discusion.',
        defeatedEnemy: result.type == BattleFlowResultType.victory,
        defeatedEnemyBattler: node.enemy,
        defeatedEnemyRarity: node.tier.rarity,
      ),
    );
  }

  Future<void> _flipCoin(bool side) async {
    if (_isResolving) return;
    setState(() {
      _isResolving = true;
      _selectedCoinSide = side;
      _coinResult = null;
    });
    _coinController
      ..reset()
      ..forward();
    await Future<void>.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final landedSide = widget.randomizer.nextInt(2) == 0;
    final didWin = landedSide == side;
    setState(() {
      _coinResult = didWin;
    });
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    Navigator.of(context).pop(
      widget.eventService.resolveMercadoFuturosCoin(
        player: widget.player,
        didWin: didWin,
      ),
    );
  }

  Widget _eventButton({
    required String label,
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    return EndpointActionButton(
      label: label,
      icon: icon,
      tooltip: tooltip,
      onPressed: _isResolving ? null : onPressed,
      accent: widget.node.accent,
      backgroundColor: EndpointPalette.blend(
        EndpointPalette.panelBackgroundGold,
        widget.node.accent,
        0.14,
      ),
      foregroundColor: EndpointPalette.softForeground,
      expands: true,
      height: 56,
      useMarquee: false,
      labelMaxLines: 2,
    );
  }
}

class _ChoiceGrid extends StatelessWidget {
  final List<Widget> children;

  const _ChoiceGrid({
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useSingleColumn = constraints.maxWidth < 520;
        if (useSingleColumn) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final child in children) ...[
                child,
                if (child != children.last) const SizedBox(height: 8),
              ],
            ],
          );
        }

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final child in children)
              SizedBox(
                width: (constraints.maxWidth - 16) / 3,
                child: child,
              ),
          ],
        );
      },
    );
  }
}

class _ItemSelectionDialog extends StatelessWidget {
  final List<Item> items;
  final Color accent;

  const _ItemSelectionDialog({
    required this.items,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return EndpointPanel(
      accent: accent,
      backgroundColor: EndpointPalette.panelBackgroundStrong,
      padding: const EdgeInsets.all(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 460),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              EndpointText(
                'SELECCIONAR OBJETO',
                style: textMediumBold.copyWith(color: accent),
              ),
              const SizedBox(height: 10),
              for (final item in items) ...[
                EndpointActionButton(
                  label: '${item.iconEmoji} ${item.displayName} '
                      '(${item.rarity.label})',
                  icon: item.isWeaponLike
                      ? Icons.sports_martial_arts_rounded
                      : Icons.category_rounded,
                  tooltip: item.description,
                  accent: item.rarity.accent,
                  onPressed: () => Navigator.of(context).pop(item),
                  expands: true,
                  labelMaxLines: 2,
                  useMarquee: false,
                ),
                if (item != items.last) const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
