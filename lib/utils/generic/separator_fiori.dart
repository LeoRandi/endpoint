// ignore_for_file: use_key_in_widget_constructors

import '_imports.dart';

const _baseSeparatorHeight = 25.0;

/// Public spacing scale shared by gaps, padding helpers, and future layout code.
enum EndpointSpacingSize {
  quarter,
  half,
  threeQuarter,
  normal,
  oneHalf,
  double,
}

/// Converts a symbolic spacing size into a multiplier on the shared base unit.
extension EndpointSpacingSizeValue on EndpointSpacingSize {
  double get multiplier {
    switch (this) {
      case EndpointSpacingSize.quarter:
        return 0.25;
      case EndpointSpacingSize.half:
        return 0.5;
      case EndpointSpacingSize.threeQuarter:
        return 0.75;
      case EndpointSpacingSize.normal:
        return 1;
      case EndpointSpacingSize.oneHalf:
        return 1.5;
      case EndpointSpacingSize.double:
        return 2;
    }
  }

  double get height => EndpointSpacing.height(this);
}

/// Named helpers for the app spacing system.
abstract final class EndpointSpacing {
  static const base = _baseSeparatorHeight;

  static double height(EndpointSpacingSize size) => base * size.multiplier;

  static EdgeInsets vertical(
    EndpointSpacingSize size, {
    bool top = true,
    bool bottom = true,
  }) {
    final value = height(size);

    return EdgeInsets.only(
      top: top ? value : 0,
      bottom: bottom ? value : 0,
    );
  }

  static SizedBox verticalGap(EndpointSpacingSize size) {
    return SizedBox(height: height(size));
  }
}

/// Multipliers supported by the legacy spacing helpers.
enum _SeparatorType {
  quarter,
  half,
  oneHalf,
  third,
  normal,
  double,
}

/// Converts a symbolic spacing size into an actual vertical logical pixel value.
extension _SeparatorTypeHeight on _SeparatorType {
  /// Returns the public spacing size represented by this legacy value.
  EndpointSpacingSize get size {
    switch (this) {
      case _SeparatorType.quarter:
        return EndpointSpacingSize.quarter;
      case _SeparatorType.half:
        return EndpointSpacingSize.half;
      case _SeparatorType.oneHalf:
        return EndpointSpacingSize.oneHalf;
      case _SeparatorType.third:
        return EndpointSpacingSize.threeQuarter;
      case _SeparatorType.normal:
        return EndpointSpacingSize.normal;
      case _SeparatorType.double:
        return EndpointSpacingSize.double;
    }
  }

  /// Returns the final spacing height used by separators and vertical padding.
  double get height => size.height;
}

/// Renders a vertical gap using the shared spacing scale.
class SeparatorFiori extends StatelessWidget {
  final _SeparatorType _separator;
  final bool isShowedOnlyInMobile;

  /// Creates a quarter-height vertical gap.
  const SeparatorFiori.quarter([this.isShowedOnlyInMobile = false])
      : _separator = _SeparatorType.quarter;

  /// Creates a half-height vertical gap.
  const SeparatorFiori.half([this.isShowedOnlyInMobile = false])
      : _separator = _SeparatorType.half;

  /// Creates a one-and-a-half-height vertical gap.
  const SeparatorFiori.oneHalf([this.isShowedOnlyInMobile = false])
      : _separator = _SeparatorType.oneHalf;

  /// Creates a three-quarter-height vertical gap.
  const SeparatorFiori.third([this.isShowedOnlyInMobile = false])
      : _separator = _SeparatorType.third;

  /// Creates a double-height vertical gap.
  const SeparatorFiori.double([this.isShowedOnlyInMobile = false])
      : _separator = _SeparatorType.double;

  /// Creates a normal-height vertical gap.
  const SeparatorFiori([this.isShowedOnlyInMobile = false])
      : _separator = _SeparatorType.normal;

  /// Builds the configured empty vertical space.
  ///
  /// The legacy [isShowedOnlyInMobile] flag is preserved as-is: when true, this
  /// widget produces no spacing.
  @override
  Widget build(BuildContext context) {
    if (isShowedOnlyInMobile) return const SizedBox();

    return SizedBox(height: _separator.height);
  }
}

/// Wraps a child with vertical padding from the shared spacing scale.
class PaddingVerticalCustom extends StatelessWidget {
  final _SeparatorType _separator;
  final bool isOnlyMobile;
  final bool isOnlyTop;
  final bool isOnlyBottom;
  final Widget child;

  /// Adds quarter-height vertical padding around [child].
  const PaddingVerticalCustom.quarter(
    this.child, {
    this.isOnlyTop = false,
    this.isOnlyBottom = false,
    this.isOnlyMobile = false,
  }) : _separator = _SeparatorType.quarter;

  /// Adds half-height vertical padding around [child].
  const PaddingVerticalCustom.half(
    this.child, {
    this.isOnlyTop = false,
    this.isOnlyBottom = false,
    this.isOnlyMobile = false,
  }) : _separator = _SeparatorType.half;

  /// Adds one-and-a-half-height vertical padding around [child].
  const PaddingVerticalCustom.oneHalf(
    this.child, {
    this.isOnlyTop = false,
    this.isOnlyBottom = false,
    this.isOnlyMobile = false,
  }) : _separator = _SeparatorType.oneHalf;

  /// Adds three-quarter-height vertical padding around [child].
  const PaddingVerticalCustom.third(
    this.child, {
    this.isOnlyTop = false,
    this.isOnlyBottom = false,
    this.isOnlyMobile = false,
  }) : _separator = _SeparatorType.third;

  /// Adds double-height vertical padding around [child].
  const PaddingVerticalCustom.double(
    this.child, {
    this.isOnlyTop = false,
    this.isOnlyBottom = false,
    this.isOnlyMobile = false,
  }) : _separator = _SeparatorType.double;

  /// Adds normal-height vertical padding around [child].
  const PaddingVerticalCustom(
    this.child, {
    this.isOnlyTop = false,
    this.isOnlyBottom = false,
    this.isOnlyMobile = false,
  }) : _separator = _SeparatorType.normal;

  /// Builds the child with top, bottom, or symmetric vertical padding.
  ///
  /// The legacy [isOnlyMobile] flag is preserved as-is: when true, the child is
  /// returned without adding any padding.
  @override
  Widget build(BuildContext context) {
    if (isOnlyMobile) return child;

    if (isOnlyTop) {
      return Padding(
        padding: EndpointSpacing.vertical(
          _separator.size,
          bottom: false,
        ),
        child: child,
      );
    }

    if (isOnlyBottom) {
      return Padding(
        padding: EndpointSpacing.vertical(
          _separator.size,
          top: false,
        ),
        child: child,
      );
    }

    return Padding(
      padding: EndpointSpacing.vertical(_separator.size),
      child: child,
    );
  }
}

/// Adds expressive vertical spacing helpers directly to widgets.
extension WidgetExtPadding on Widget {
  /// Wraps this widget with quarter-height symmetric vertical padding.
  Widget separatorQuarter() => PaddingVerticalCustom.quarter(this);

  /// Wraps this widget with quarter-height bottom padding.
  Widget separatorQuarterBottom() =>
      PaddingVerticalCustom.quarter(this, isOnlyBottom: true);

  /// Wraps this widget with quarter-height top padding.
  Widget separatorQuarterTop() =>
      PaddingVerticalCustom.quarter(this, isOnlyTop: true);

  /// Wraps this widget with half-height symmetric vertical padding.
  Widget separatorHalf() => PaddingVerticalCustom.half(this);

  /// Wraps this widget with half-height bottom padding.
  Widget separatorHalfBottom() =>
      PaddingVerticalCustom.half(this, isOnlyBottom: true);

  /// Wraps this widget with half-height top padding.
  Widget separatorHalfTop() =>
      PaddingVerticalCustom.half(this, isOnlyTop: true);

  /// Wraps this widget with normal-height symmetric vertical padding.
  Widget separator() => PaddingVerticalCustom(this);

  /// Wraps this widget with normal-height bottom padding.
  Widget separatorBottom() => PaddingVerticalCustom(this, isOnlyBottom: true);

  /// Wraps this widget with normal-height top padding.
  Widget separatorTop() => PaddingVerticalCustom(this, isOnlyTop: true);

  /// Wraps this widget with double-height symmetric vertical padding.
  Widget separatorDouble() => PaddingVerticalCustom.double(this);

  /// Wraps this widget with double-height bottom padding.
  Widget separatorDoubleBottom() =>
      PaddingVerticalCustom.double(this, isOnlyBottom: true);

  /// Wraps this widget with double-height top padding.
  Widget separatorDoubleTop() =>
      PaddingVerticalCustom.double(this, isOnlyTop: true);

  /// Wraps this widget with three-quarter-height symmetric vertical padding.
  Widget separatorThird() => PaddingVerticalCustom.third(this);

  /// Wraps this widget with three-quarter-height bottom padding.
  Widget separatorThirdBottom() =>
      PaddingVerticalCustom.third(this, isOnlyBottom: true);

  /// Wraps this widget with three-quarter-height top padding.
  Widget separatorThirdTop() =>
      PaddingVerticalCustom.third(this, isOnlyTop: true);

  /// Wraps this widget with one-and-a-half-height symmetric vertical padding.
  Widget separatorOneHalf() => PaddingVerticalCustom.oneHalf(this);

  /// Wraps this widget with one-and-a-half-height bottom padding.
  Widget separatorOneHalfBottom() =>
      PaddingVerticalCustom.oneHalf(this, isOnlyBottom: true);

  /// Wraps this widget with one-and-a-half-height top padding.
  Widget separatorOneHalfTop() =>
      PaddingVerticalCustom.oneHalf(this, isOnlyTop: true);
}
