import '_imports.dart';

class EndpointMarqueeText extends StatefulWidget {
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final bool? softWrap;
  final TextOverflow? overflow;
  final TextDirection? textDirection;
  final Locale? locale;
  final StrutStyle? strutStyle;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final TextScaler? textScaler;
  final double marqueeGap;

  const EndpointMarqueeText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines = 1,
    this.softWrap,
    this.overflow,
    this.textDirection,
    this.locale,
    this.strutStyle,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.textScaler,
    this.marqueeGap = 28,
  });

  @override
  State<EndpointMarqueeText> createState() => _EndpointMarqueeTextState();
}

class _EndpointMarqueeTextState extends State<EndpointMarqueeText>
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
    final resolvedStyle = _resolvedStyle(context);
    final effectiveTextDirection =
        widget.textDirection ?? Directionality.of(context);
    final effectiveTextScaler =
        widget.textScaler ?? MediaQuery.textScalerOf(context);
    final effectiveMaxLines = widget.maxLines ?? 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (effectiveMaxLines != 1 ||
            !constraints.maxWidth.isFinite ||
            constraints.maxWidth <= 0) {
          _stopMarquee();
          return _buildPlainText(
            style: resolvedStyle,
            maxLines: effectiveMaxLines,
          );
        }

        final painter = TextPainter(
          text: TextSpan(text: widget.data, style: resolvedStyle),
          textDirection: effectiveTextDirection,
          textScaler: effectiveTextScaler,
          locale: widget.locale,
          maxLines: 1,
          strutStyle: widget.strutStyle,
          textWidthBasis: widget.textWidthBasis ?? TextWidthBasis.parent,
          textHeightBehavior: widget.textHeightBehavior,
        )..layout(minWidth: 0, maxWidth: double.infinity);

        if (painter.width <= constraints.maxWidth + 0.5) {
          _stopMarquee();
          return _buildPlainText(
            style: resolvedStyle,
            maxLines: 1,
          );
        }

        final textWidth = painter.width;
        final textHeight = painter.height;
        final cycleDistance = textWidth + widget.marqueeGap;
        _ensureMarquee(cycleDistance);

        return ClipRect(
          child: SizedBox(
            width: constraints.maxWidth,
            height: textHeight,
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
                        width: textWidth,
                        child: _buildOverflowText(resolvedStyle),
                      ),
                    ),
                    Transform.translate(
                      offset: Offset(cycleDistance - dx, 0),
                      child: SizedBox(
                        width: textWidth,
                        child: _buildOverflowText(resolvedStyle),
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

  TextStyle _resolvedStyle(BuildContext context) {
    final baseStyle = DefaultTextStyle.of(context).style.merge(widget.style);
    return baseStyle.copyWith(
      decoration: TextDecoration.none,
      decorationColor: Colors.transparent,
    );
  }

  Widget _buildPlainText({
    required TextStyle style,
    required int? maxLines,
  }) {
    return EndpointText(
      widget.data,
      style: style,
      textAlign: widget.textAlign,
      maxLines: maxLines,
      softWrap: widget.softWrap,
      overflow: widget.overflow,
      textDirection: widget.textDirection,
      locale: widget.locale,
      strutStyle: widget.strutStyle,
      textWidthBasis: widget.textWidthBasis,
      textHeightBehavior: widget.textHeightBehavior,
      textScaler: widget.textScaler,
    );
  }

  Widget _buildOverflowText(TextStyle style) {
    return EndpointText(
      widget.data,
      style: style,
      textAlign: widget.textAlign,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.visible,
      textDirection: widget.textDirection,
      locale: widget.locale,
      strutStyle: widget.strutStyle,
      textWidthBasis: widget.textWidthBasis,
      textHeightBehavior: widget.textHeightBehavior,
      textScaler: widget.textScaler,
    );
  }

  void _ensureMarquee(double cycleDistance) {
    final duration = Duration(
      milliseconds: max(3600, (cycleDistance * 55).round()),
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
