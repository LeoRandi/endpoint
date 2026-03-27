import '../_imports.dart';

class EndpointOverlayScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final String sectionLabel;
  final String sectionValue;
  final String closeTooltip;
  final Color accent;
  final Color backgroundColor;
  final double bottomInset;
  final double maxWidth;
  final double maxHeight;
  final Widget child;

  const EndpointOverlayScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.sectionLabel,
    required this.sectionValue,
    required this.closeTooltip,
    required this.child,
    this.accent = EndpointPalette.primaryAccent,
    this.backgroundColor = EndpointPalette.panelBackgroundOpaque,
    this.bottomInset = 112,
    this.maxWidth = 420,
    this.maxHeight = 360,
  });

  @override
  Widget build(BuildContext context) {
    final availableHeight = MediaQuery.of(context).size.height;
    final overlayHeight = max(
      220.0,
      min(maxHeight, availableHeight - bottomInset - 40),
    );

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.fromLTRB(12, 12, 12, bottomInset),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              maxHeight: overlayHeight,
            ),
            child: EndpointPanel(
              accent: accent,
              backgroundColor: backgroundColor,
              borderRadius: 18,
              glowOpacity: 0.12,
              blurRadius: 22,
              spreadRadius: 2,
              padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
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
                              title,
                              style: textTitleMediumBold.copyWith(
                                color: EndpointPalette.softForeground,
                                letterSpacing: 1.8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            EndpointText(
                              subtitle,
                              style: textSmallBold.copyWith(
                                color: Colors.white.withOpacity(0.72),
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      EndpointSceneCloseButton(
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: closeTooltip,
                        accent: accent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      EndpointText(
                        sectionLabel,
                        style: textSmallBold.copyWith(
                          color: accent,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const Spacer(),
                      EndpointText(
                        sectionValue,
                        style: textSmallBold.copyWith(
                          color: Colors.white.withOpacity(0.76),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Expanded(child: child),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
