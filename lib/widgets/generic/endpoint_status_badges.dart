import '../_imports.dart';

class EndpointHealthBarWithStatuses extends StatelessWidget {
  final Battler battler;
  final double value;
  final Color accent;
  final double height;
  final double badgeSize;
  final double badgeOverlap;
  final WrapAlignment badgeAlignment;

  const EndpointHealthBarWithStatuses({
    super.key,
    required this.battler,
    required this.value,
    required this.accent,
    this.height = 12,
    this.badgeSize = 28,
    this.badgeOverlap = 6,
    this.badgeAlignment = WrapAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final hasStatuses = battler.statuses.isNotEmpty;
    final showsBarrier = battler.hasCombatFlag(Battler.combatActiveFlag) &&
        battler.maxBarrier > 0;
    final barrierHeight = max(5.0, height - 4);
    final barSpacing = showsBarrier ? 4.0 : 0.0;
    final barsHeight =
        height + (showsBarrier ? barrierHeight + barSpacing : 0.0);
    final barrierValue = battler.maxBarrier <= 0
        ? 0.0
        : (battler.currentBarrier / battler.maxBarrier)
            .clamp(0.0, 1.0)
            .toDouble();

    final bars = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showsBarrier) ...[
          EndpointHealthBar(
            value: barrierValue,
            accent: BattlerStat.barrier.accent,
            height: barrierHeight,
            trackOpacity: 0.16,
            fillStartOpacity: 0.22,
            fillEndOpacity: 0.56,
          ),
          SizedBox(height: barSpacing),
        ],
        EndpointHealthBar(
          value: value,
          accent: accent,
          height: height,
        ),
      ],
    );

    if (!hasStatuses) {
      return bars;
    }

    return SizedBox(
      height: barsHeight + badgeSize - badgeOverlap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: bars,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: barsHeight - badgeOverlap,
            child: EndpointStatusBadges(
              battler: battler,
              alignment: badgeAlignment,
              badgeSize: badgeSize,
            ),
          ),
        ],
      ),
    );
  }
}

class EndpointStatusBadges extends StatelessWidget {
  final Battler battler;
  final WrapAlignment alignment;
  final double badgeSize;
  final double spacing;

  const EndpointStatusBadges({
    super.key,
    required this.battler,
    this.alignment = WrapAlignment.start,
    this.badgeSize = 28,
    this.spacing = 6,
  });

  @override
  Widget build(BuildContext context) {
    if (battler.statuses.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      alignment: alignment,
      children: [
        for (final status in battler.statuses)
          _EndpointStatusBadge(
            battler: battler,
            status: status,
            size: badgeSize,
          ),
      ],
    );
  }
}

class _EndpointStatusBadge extends StatelessWidget {
  final Battler battler;
  final BattlerStatus status;
  final double size;

  const _EndpointStatusBadge({
    required this.battler,
    required this.status,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final accent = status.type.accent;
    final badgeLabel = status.badgeLabelFor(battler);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _showStatusDetails(context),
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: EndpointPalette.panelBackground,
                    border: Border.all(
                      color: accent.withAlpha(224),
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withAlpha(41),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      status.icon,
                      size: size * 0.56,
                      color: status.type.foreground,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -2,
                right: -2,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(999),
                    border:
                        Border.all(color: EndpointPalette.scaffoldBackground),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: EndpointText(
                      badgeLabel,
                      style: textSmallBold.copyWith(
                        color: EndpointPalette.scaffoldBackground,
                        fontSize: 8,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showStatusDetails(BuildContext context) async {
    await showEndpointDialog<void>(
      context: context,
      barrierLabel: 'Detalle de estado',
      barrierColor: EndpointPalette.overlayScrim,
      builder: (context) {
        return _EndpointStatusDetailsDialog(
          battler: battler,
          status: status,
        );
      },
    );
  }
}

class _EndpointStatusDetailsDialog extends StatelessWidget {
  final Battler battler;
  final BattlerStatus status;

  const _EndpointStatusDetailsDialog({
    required this.battler,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final accent = status.type.accent;
    final screenSize = MediaQuery.sizeOf(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: min(380, screenSize.width - 48),
            maxHeight: screenSize.height * 0.72,
          ),
          child: EndpointPanel(
            accent: accent,
            backgroundColor: EndpointPalette.panelBackgroundOpaque,
            borderRadius: 18,
            glowOpacity: 0.05,
            padding: EdgeInsets.zero,
            child: Scrollbar(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent.withAlpha(41),
                        border: Border.all(color: accent.withAlpha(179)),
                      ),
                      child: Icon(
                        status.icon,
                        size: 28,
                        color: status.type.foreground,
                      ),
                    ),
                    const SizedBox(height: 12),
                    EndpointText(
                      status.name,
                      textAlign: TextAlign.center,
                      maxLines: null,
                      style: textTitleMediumBold.copyWith(
                        color: EndpointPalette.softForeground,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    EndpointText(
                      status.type.label.toUpperCase(),
                      textAlign: TextAlign.center,
                      maxLines: null,
                      style: textSmallBold.copyWith(
                        color: accent,
                        fontSize: 12,
                        letterSpacing: 1.4,
                      ),
                    ),
                    if (status.hasTags) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: EndpointTagPillMarquee(
                          tags: status.tags,
                          accent: accent,
                          idleAlignment: Alignment.center,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    EndpointText(
                      status.descriptionFor(battler),
                      textAlign: TextAlign.center,
                      maxLines: null,
                      style: textMedium.copyWith(
                        color: EndpointPalette.softForeground.withAlpha(219),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    EndpointText(
                      'Duracion restante: ${status.remainingTurnsLabel}',
                      textAlign: TextAlign.center,
                      maxLines: null,
                      style: textSmallBold.copyWith(
                        color: accent,
                        fontSize: 12,
                        letterSpacing: 0.9,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
