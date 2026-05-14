import '../_imports.dart';

@immutable
class EndpointScenePreset {
  final Color accent;
  final Color foreground;
  final Color mutedForeground;
  final Gradient background;
  final Color panelBackground;
  final Color closeButtonBackground;
  final EdgeInsetsGeometry viewportPadding;
  final EdgeInsetsGeometry panelPadding;
  final double panelBorderRadius;
  final double panelGlowOpacity;
  final double panelBlurRadius;
  final double panelSpreadRadius;
  final double? maxContentWidth;

  const EndpointScenePreset({
    required this.accent,
    required this.foreground,
    required this.mutedForeground,
    required this.background,
    this.panelBackground = EndpointPalette.panelBackgroundStrong,
    this.closeButtonBackground = EndpointPalette.closeButtonBackground,
    this.viewportPadding = const EdgeInsets.fromLTRB(10, 8, 10, 12),
    this.panelPadding = const EdgeInsets.all(18),
    this.panelBorderRadius = 18,
    this.panelGlowOpacity = 0.08,
    this.panelBlurRadius = 28,
    this.panelSpreadRadius = 3,
    this.maxContentWidth,
  });

  EndpointSectionPreset createSection({
    Color? accent,
    Color? foreground,
    Color? mutedForeground,
    Color? captionColor,
    Color? backgroundColor,
    EdgeInsetsGeometry? padding,
    double? borderRadius,
    double? borderOpacity,
    double? glowOpacity,
    double? blurRadius,
    double? spreadRadius,
    Border? border,
  }) {
    return EndpointSectionPreset(
      accent: accent ?? this.accent,
      foreground: foreground ?? this.foreground,
      mutedForeground: mutedForeground ?? this.mutedForeground,
      captionColor: captionColor,
      backgroundColor: backgroundColor ?? panelBackground,
      padding: padding ?? panelPadding,
      borderRadius: borderRadius ?? panelBorderRadius,
      borderOpacity: borderOpacity ?? 0.7,
      glowOpacity: glowOpacity ?? panelGlowOpacity,
      blurRadius: blurRadius ?? panelBlurRadius,
      spreadRadius: spreadRadius ?? panelSpreadRadius,
      border: border,
    );
  }
}

@immutable
class EndpointSectionPreset {
  final Color accent;
  final Color foreground;
  final Color mutedForeground;
  final Color? captionColor;
  final Color backgroundColor;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double borderOpacity;
  final double glowOpacity;
  final double blurRadius;
  final double spreadRadius;
  final Border? border;

  const EndpointSectionPreset({
    required this.accent,
    required this.foreground,
    required this.mutedForeground,
    this.captionColor,
    required this.backgroundColor,
    required this.padding,
    required this.borderRadius,
    this.borderOpacity = 0.7,
    required this.glowOpacity,
    required this.blurRadius,
    required this.spreadRadius,
    this.border,
  });

  Color get effectiveCaptionColor => captionColor ?? accent;

  EndpointSectionPreset copyWith({
    Color? accent,
    Color? foreground,
    Color? mutedForeground,
    Color? captionColor,
    Color? backgroundColor,
    EdgeInsetsGeometry? padding,
    double? borderRadius,
    double? borderOpacity,
    double? glowOpacity,
    double? blurRadius,
    double? spreadRadius,
    Border? border,
  }) {
    return EndpointSectionPreset(
      accent: accent ?? this.accent,
      foreground: foreground ?? this.foreground,
      mutedForeground: mutedForeground ?? this.mutedForeground,
      captionColor: captionColor ?? this.captionColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      padding: padding ?? this.padding,
      borderRadius: borderRadius ?? this.borderRadius,
      borderOpacity: borderOpacity ?? this.borderOpacity,
      glowOpacity: glowOpacity ?? this.glowOpacity,
      blurRadius: blurRadius ?? this.blurRadius,
      spreadRadius: spreadRadius ?? this.spreadRadius,
      border: border ?? this.border,
    );
  }
}

class EndpointSceneLayout extends StatelessWidget {
  final EndpointScenePreset preset;
  final Widget child;
  final Widget? backdrop;
  final VoidCallback? onClose;
  final String closeTooltip;
  final double contentSpacing;
  final bool centerContent;
  final bool expandContent;
  final double? maxContentWidth;
  final EdgeInsetsGeometry? padding;

  const EndpointSceneLayout({
    super.key,
    required this.preset,
    required this.child,
    this.backdrop,
    this.onClose,
    this.closeTooltip = 'Cerrar',
    this.contentSpacing = 12,
    this.centerContent = false,
    this.expandContent = true,
    this.maxContentWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = child;
    final resolvedMaxWidth = maxContentWidth ?? preset.maxContentWidth;

    if (resolvedMaxWidth != null) {
      content = Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: resolvedMaxWidth),
          child: child,
        ),
      );
    } else if (centerContent) {
      content = Center(child: child);
    }

    return DecoratedBox(
      decoration: BoxDecoration(gradient: preset.background),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (backdrop != null) backdrop!,
          SafeArea(
            child: Padding(
              padding: padding ?? preset.viewportPadding,
              child: Column(
                children: [
                  if (onClose != null) ...[
                    Align(
                      alignment: Alignment.topRight,
                      child: EndpointSceneCloseButton(
                        onPressed: onClose!,
                        tooltip: closeTooltip,
                        accent: preset.accent,
                        foregroundColor: preset.foreground,
                        backgroundColor: preset.closeButtonBackground,
                      ),
                    ),
                    SizedBox(height: contentSpacing),
                  ],
                  if (expandContent) Expanded(child: content) else content,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EndpointSceneHeader extends StatelessWidget {
  final String title;
  final String? description;
  final Color foreground;
  final Color? descriptionColor;
  final TextStyle? titleStyle;
  final TextStyle? descriptionStyle;
  final TextAlign textAlign;
  final double spacing;

  const EndpointSceneHeader({
    super.key,
    required this.title,
    this.description,
    required this.foreground,
    this.descriptionColor,
    this.titleStyle,
    this.descriptionStyle,
    this.textAlign = TextAlign.left,
    this.spacing = 4,
  });

  @override
  Widget build(BuildContext context) {
    final crossAxisAlignment = switch (textAlign) {
      TextAlign.center => CrossAxisAlignment.center,
      TextAlign.end || TextAlign.right => CrossAxisAlignment.end,
      _ => CrossAxisAlignment.start,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        EndpointText(
          title,
          textAlign: textAlign,
          maxLines: null,
          style: (titleStyle ?? textExtraLargeBold).copyWith(color: foreground),
        ),
        if (description != null) ...[
          SizedBox(height: spacing),
          EndpointText(
            description!,
            textAlign: textAlign,
            maxLines: null,
            style: (descriptionStyle ?? textMedium).copyWith(
              color: descriptionColor ?? foreground.withValues(alpha: 0.72),
            ),
          ),
        ],
      ],
    );
  }
}

class EndpointSectionHeader extends StatelessWidget {
  final String title;
  final String? caption;
  final Widget? trailing;
  final Color foreground;
  final Color accent;
  final Color? captionColor;
  final TextStyle? titleStyle;
  final TextStyle? captionStyle;

  const EndpointSectionHeader({
    super.key,
    required this.title,
    this.caption,
    this.trailing,
    required this.foreground,
    required this.accent,
    this.captionColor,
    this.titleStyle,
    this.captionStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: EndpointText(
            title,
            maxLines: null,
            style: (titleStyle ?? textMediumBold).copyWith(color: foreground),
          ),
        ),
        if (caption != null) ...[
          const SizedBox(width: 12),
          EndpointText(
            caption!,
            style: (captionStyle ?? textSmallBold).copyWith(
              color: captionColor ?? accent,
            ),
          ),
        ],
        if (trailing != null) ...[
          const SizedBox(width: 12),
          trailing!,
        ],
      ],
    );
  }
}

class EndpointSectionPanel extends StatelessWidget {
  final EndpointSectionPreset preset;
  final Widget child;
  final String? title;
  final String? caption;
  final Widget? trailing;
  final bool enabled;
  final double headerSpacing;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final Color? captionColor;
  final TextStyle? titleStyle;
  final TextStyle? captionStyle;

  const EndpointSectionPanel({
    super.key,
    required this.preset,
    required this.child,
    this.title,
    this.caption,
    this.trailing,
    this.enabled = true,
    this.headerSpacing = 10,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.min,
    this.captionColor,
    this.titleStyle,
    this.captionStyle,
  });

  bool get _hasHeader => title != null || caption != null || trailing != null;

  @override
  Widget build(BuildContext context) {
    final sectionBody = EndpointPanel(
      accent: preset.accent,
      backgroundColor: preset.backgroundColor,
      padding: preset.padding,
      borderRadius: preset.borderRadius,
      borderOpacity: preset.borderOpacity,
      glowOpacity: preset.glowOpacity,
      blurRadius: preset.blurRadius,
      spreadRadius: preset.spreadRadius,
      border: preset.border,
      child: _hasHeader
          ? Column(
              mainAxisSize: mainAxisSize,
              crossAxisAlignment: crossAxisAlignment,
              children: [
                EndpointSectionHeader(
                  title: title ?? '',
                  caption: caption,
                  trailing: trailing,
                  foreground: preset.foreground,
                  accent: preset.accent,
                  captionColor: captionColor ?? preset.effectiveCaptionColor,
                  titleStyle: titleStyle,
                  captionStyle: captionStyle,
                ),
                SizedBox(height: headerSpacing),
                child,
              ],
            )
          : child,
    );

    if (enabled) return sectionBody;

    return Opacity(
      opacity: 0.64,
      child: sectionBody,
    );
  }
}

class EndpointSceneActionWrap extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final WrapAlignment alignment;
  final WrapCrossAlignment crossAxisAlignment;

  const EndpointSceneActionWrap({
    super.key,
    required this.children,
    this.spacing = 8,
    this.runSpacing = 8,
    this.alignment = WrapAlignment.start,
    this.crossAxisAlignment = WrapCrossAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: alignment,
      spacing: spacing,
      runSpacing: runSpacing,
      crossAxisAlignment: crossAxisAlignment,
      children: children,
    );
  }
}
