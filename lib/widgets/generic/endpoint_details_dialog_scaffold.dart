import '../_imports.dart';

class EndpointDetailsDialogScaffold extends StatelessWidget {
  final Color accent;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color closeBackgroundColor;
  final String closeTooltip;
  final Widget child;
  final double maxWidth;
  final double maxHeightFactor;

  const EndpointDetailsDialogScaffold({
    super.key,
    required this.accent,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.closeBackgroundColor,
    required this.child,
    this.closeTooltip = 'Cerrar detalle',
    this.maxWidth = 480,
    this.maxHeightFactor = 0.82,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: min(maxWidth, screenSize.width - 48),
                maxHeight: screenSize.height * maxHeightFactor,
              ),
              child: EndpointPanel(
                accent: accent,
                backgroundColor: backgroundColor,
                borderRadius: 18,
                glowOpacity: 0.12,
                blurRadius: 26,
                padding: EdgeInsets.zero,
                child: Scrollbar(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                    child: child,
                  ),
                ),
              ),
            ),
            Positioned(
              top: -18,
              right: -10,
              child: EndpointSceneCloseButton(
                onPressed: () => Navigator.of(context).pop(),
                tooltip: closeTooltip,
                accent: accent,
                foregroundColor: foregroundColor,
                backgroundColor: closeBackgroundColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
