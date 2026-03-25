import '_imports.dart';

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
    if (battler.statuses.isEmpty) {
      return EndpointHealthBar(
        value: value,
        accent: accent,
        height: height,
      );
    }

    return SizedBox(
      height: height + badgeSize - badgeOverlap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: EndpointHealthBar(
              value: value,
              accent: accent,
              height: height,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: height - badgeOverlap,
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
    final badgeLabel = status.isIndefinite ? '∞' : '${status.remainingTurns}';

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
                    color: const Color(0xFF07120D),
                    border: Border.all(
                      color: accent.withOpacity(0.88),
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withOpacity(0.16),
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
                    border: Border.all(color: const Color(0xFF020403)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    child: EndpointText(
                      badgeLabel,
                      style: textSmallBold.copyWith(
                        color: const Color(0xFF020403),
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
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Detalle de estado',
      barrierColor: Colors.black.withOpacity(0.62),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _EndpointStatusDetailsDialog(
          battler: battler,
          status: status,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );

        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
            child: child,
          ),
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: min(380, screenSize.width - 48),
            maxHeight: screenSize.height * 0.72,
          ),
          child: EndpointPanel(
            accent: accent,
            backgroundColor: const Color(0xF207120D),
            borderRadius: 18,
            glowOpacity: 0.05,
            padding: EdgeInsets.zero,
            child: Scrollbar(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent.withOpacity(0.16),
                        border: Border.all(color: accent.withOpacity(0.7)),
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
                      style: textMediumBold.copyWith(
                        color: const Color(0xFFE6FFF0),
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
                    const SizedBox(height: 14),
                    EndpointText(
                      status.descriptionFor(battler),
                      textAlign: TextAlign.center,
                      maxLines: null,
                      style: textMedium.copyWith(
                        color: Colors.white.withOpacity(0.86),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 14),
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
