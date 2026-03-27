import '../_imports.dart';

class EndpointTagPillMarquee extends StatefulWidget {
  final List<EntityTag> tags;
  final Color accent;
  final Alignment idleAlignment;
  final TextStyle? style;
  final double spacing;
  final double marqueeGap;
  final EdgeInsetsGeometry pillPadding;

  const EndpointTagPillMarquee({
    super.key,
    required this.tags,
    required this.accent,
    this.idleAlignment = Alignment.centerLeft,
    this.style,
    this.spacing = 8,
    this.marqueeGap = 28,
    this.pillPadding = const EdgeInsets.fromLTRB(4, 2, 4, 2),
  });

  @override
  State<EndpointTagPillMarquee> createState() => _EndpointTagPillMarqueeState();
}

class _EndpointTagPillMarqueeState extends State<EndpointTagPillMarquee>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  double _activeCycleDistance = 0;
  Duration? _activeDuration;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolvedTags = _resolvedTags(widget.tags);
    if (resolvedTags.isEmpty) {
      _stopMarquee();
      return const SizedBox.shrink();
    }

    final resolvedStyle =
        widget.style ??
        textSmallBold.copyWith(
          fontSize: 10,
          letterSpacing: 0.8,
        );
    final effectiveTextDirection = Directionality.of(context);
    final effectiveTextScaler = MediaQuery.textScalerOf(context);
    final resolvedPadding = widget.pillPadding.resolve(effectiveTextDirection);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.maxWidth.isFinite || constraints.maxWidth <= 0) {
          _stopMarquee();
          return _buildStaticRow(
            tags: resolvedTags,
            style: resolvedStyle,
            alignment: widget.idleAlignment,
          );
        }

        final metrics = _measureTagRow(
          tags: resolvedTags,
          style: resolvedStyle,
          textDirection: effectiveTextDirection,
          textScaler: effectiveTextScaler,
          padding: resolvedPadding,
        );

        if (metrics.totalWidth <= constraints.maxWidth + 0.5) {
          _stopMarquee();
          return _buildStaticRow(
            tags: resolvedTags,
            style: resolvedStyle,
            height: metrics.height,
            alignment: widget.idleAlignment,
          );
        }

        final cycleDistance = metrics.totalWidth + widget.marqueeGap;
        _ensureMarquee(cycleDistance);

        return ClipRect(
          child: SizedBox(
            width: constraints.maxWidth,
            height: metrics.height,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final dx = _controller.value * cycleDistance;

                return Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Transform.translate(
                      offset: Offset(-dx, 0),
                      child: SizedBox(
                        width: metrics.totalWidth,
                        child: _buildTagRow(
                          tags: resolvedTags,
                          style: resolvedStyle,
                        ),
                      ),
                    ),
                    Transform.translate(
                      offset: Offset(cycleDistance - dx, 0),
                      child: SizedBox(
                        width: metrics.totalWidth,
                        child: _buildTagRow(
                          tags: resolvedTags,
                          style: resolvedStyle,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildStaticRow({
    required List<EntityTag> tags,
    required TextStyle style,
    required Alignment alignment,
    double? height,
  }) {
    final content = _buildTagRow(tags: tags, style: style);
    if (height == null) {
      return Align(
        alignment: alignment,
        child: content,
      );
    }

    return SizedBox(
      height: height,
      child: Align(
        alignment: alignment,
        child: content,
      ),
    );
  }

  Widget _buildTagRow({
    required List<EntityTag> tags,
    required TextStyle style,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int index = 0; index < tags.length; index++) ...[
          if (index > 0) SizedBox(width: widget.spacing),
          _EndpointTagPill(
            tag: tags[index],
            accent: widget.accent,
            style: style,
            padding: widget.pillPadding,
          ),
        ],
      ],
    );
  }

  _TagRowMetrics _measureTagRow({
    required List<EntityTag> tags,
    required TextStyle style,
    required TextDirection textDirection,
    required TextScaler textScaler,
    required EdgeInsets padding,
  }) {
    var totalWidth = 0.0;
    var maxHeight = 0.0;

    for (int index = 0; index < tags.length; index++) {
      final painter = TextPainter(
        text: TextSpan(
          text: tags[index].label,
          style: style,
        ),
        textDirection: textDirection,
        textScaler: textScaler,
        maxLines: 1,
      )..layout(minWidth: 0, maxWidth: double.infinity);

      totalWidth += painter.width + padding.horizontal;
      maxHeight = max(maxHeight, painter.height + padding.vertical);

      if (index < tags.length - 1) {
        totalWidth += widget.spacing;
      }
    }

    return _TagRowMetrics(
      totalWidth: totalWidth,
      height: max(28, maxHeight),
    );
  }

  List<EntityTag> _resolvedTags(Iterable<EntityTag> tags) {
    final resolvedTags = <EntityTag>[];

    for (final tag in tags) {
      if (resolvedTags.contains(tag)) continue;
      resolvedTags.add(tag);
    }

    return resolvedTags;
  }

  void _ensureMarquee(double cycleDistance) {
    final duration = Duration(
      milliseconds: max(3200, (cycleDistance * 40).round()),
    );

    if (_activeCycleDistance == cycleDistance &&
        _activeDuration == duration &&
        _controller.isAnimating) {
      return;
    }

    _activeCycleDistance = cycleDistance;
    _activeDuration = duration;
    _controller
      ..duration = duration
      ..repeat();
  }

  void _stopMarquee() {
    _activeCycleDistance = 0;
    _activeDuration = null;
    if (_controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }
}

class _EndpointTagPill extends StatelessWidget {
  final EntityTag tag;
  final Color accent;
  final TextStyle style;
  final EdgeInsetsGeometry padding;

  const _EndpointTagPill({
    required this.tag,
    required this.accent,
    required this.style,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final pillAccent = EndpointPalette.blend(tag.accent, accent, 0.22);
    final backgroundColor = EndpointPalette.blend(
      EndpointPalette.panelBackground,
      pillAccent,
      0.18,
    );
    final foregroundColor = EndpointPalette.soften(pillAccent, amount: 0.2);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: pillAccent.withOpacity(0.72),
        ),
      ),
      child: EndpointText(
        tag.label,
        maxLines: 1,
        style: style.copyWith(
          color: foregroundColor,
        ),
      ),
    );
  }
}

class _TagRowMetrics {
  final double totalWidth;
  final double height;

  const _TagRowMetrics({
    required this.totalWidth,
    required this.height,
  });
}
