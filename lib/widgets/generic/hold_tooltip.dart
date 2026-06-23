import '_imports.dart';

class HoldTooltip extends StatefulWidget {
  final String message;
  final Widget child;

  const HoldTooltip({
    super.key,
    required this.message,
    required this.child,
  });

  @override
  State<HoldTooltip> createState() => _HoldTooltipState();
}

class _HoldTooltipState extends State<HoldTooltip> {
  final _tooltipKey = GlobalKey<TooltipState>();

  void _showTooltip(LongPressStartDetails _) {
    _tooltipKey.currentState?.ensureTooltipVisible();
  }

  void _hideTooltip([Object? _]) {
    Tooltip.dismissAllToolTips();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPressStart: _showTooltip,
      onLongPressEnd: _hideTooltip,
      onLongPressCancel: _hideTooltip,
      child: Tooltip(
        key: _tooltipKey,
        message: widget.message,
        triggerMode: TooltipTriggerMode.manual,
        waitDuration: Duration.zero,
        showDuration: const Duration(days: 1),
        preferBelow: false,
        textStyle: textMedium.copyWith(color: EndpointPalette.softForeground),
        decoration: BoxDecoration(
          color: EndpointPalette.panelBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: EndpointPalette.primaryAccent),
        ),
        child: widget.child,
      ),
    );
  }
}
