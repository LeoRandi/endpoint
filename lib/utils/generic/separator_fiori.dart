// ignore_for_file: prefer_const_constructors, use_key_in_widget_constructors, unnecessary_this, curly_braces_in_flow_control_structures

import '../_imports.dart';

enum _SeparatorType {
  quarter,
  half,
  oneHalf,
  third,
  normal,
  double,
}

class SeparatorFiori extends StatelessWidget {
  final _SeparatorType _separator;
  final bool isShowedOnlyInMobile;

  const SeparatorFiori.quarter([this.isShowedOnlyInMobile = false])
      : this._separator = _SeparatorType.quarter;
  const SeparatorFiori.half([this.isShowedOnlyInMobile = false])
      : this._separator = _SeparatorType.half;
  const SeparatorFiori.oneHalf([this.isShowedOnlyInMobile = false])
      : this._separator = _SeparatorType.oneHalf;
  const SeparatorFiori.third([this.isShowedOnlyInMobile = false])
      : this._separator = _SeparatorType.third;
  const SeparatorFiori.double([this.isShowedOnlyInMobile = false])
      : this._separator = _SeparatorType.double;
  const SeparatorFiori([this.isShowedOnlyInMobile = false])
      : this._separator = _SeparatorType.normal;

  @override
  Widget build(BuildContext context) {
    if (isShowedOnlyInMobile) return SizedBox();
    double height = 25;
    if (height != 0)
      switch (_separator) {
        case _SeparatorType.quarter:
          height *= 0.25;
          break;
        case _SeparatorType.half:
          height *= 0.50;
          break;
        case _SeparatorType.normal:
          break;
        case _SeparatorType.double:
          height *= 2;
          break;
        case _SeparatorType.third:
          height *= 0.75;
          break;
        case _SeparatorType.oneHalf:
          height *= 1.50;
          break;
      }
    return SizedBox(height: height);
  }
}

class PaddingVerticalCustom extends StatelessWidget {
  final _SeparatorType _separator;
  final bool isOnlyMobile;
  final bool isOnlyTop;
  final bool isOnlyBottom;
  final Widget child;

  const PaddingVerticalCustom.quarter(
    this.child, {
    this.isOnlyTop = false,
    this.isOnlyBottom = false,
    this.isOnlyMobile = false,
  }) : this._separator = _SeparatorType.quarter;
  const PaddingVerticalCustom.half(
    this.child, {
    this.isOnlyTop = false,
    this.isOnlyBottom = false,
    this.isOnlyMobile = false,
  }) : this._separator = _SeparatorType.half;
  const PaddingVerticalCustom.oneHalf(
    this.child, {
    this.isOnlyTop = false,
    this.isOnlyBottom = false,
    this.isOnlyMobile = false,
  }) : this._separator = _SeparatorType.oneHalf;
  const PaddingVerticalCustom.third(
    this.child, {
    this.isOnlyTop = false,
    this.isOnlyBottom = false,
    this.isOnlyMobile = false,
  }) : this._separator = _SeparatorType.third;
  const PaddingVerticalCustom.double(
    this.child, {
    this.isOnlyTop = false,
    this.isOnlyBottom = false,
    this.isOnlyMobile = false,
  }) : this._separator = _SeparatorType.double;
  const PaddingVerticalCustom(
    this.child, {
    this.isOnlyTop = false,
    this.isOnlyBottom = false,
    this.isOnlyMobile = false,
  }) : this._separator = _SeparatorType.normal;

  @override
  Widget build(BuildContext context) {
    if (isOnlyMobile) return child;
    double height = 25;
    if (height != 0)
      switch (_separator) {
        case _SeparatorType.quarter:
          height *= 0.25;
          break;
        case _SeparatorType.half:
          height *= 0.50;
          break;
        case _SeparatorType.normal:
          break;
        case _SeparatorType.double:
          height *= 2;
          break;
        case _SeparatorType.third:
          height *= 0.75;
          break;
        case _SeparatorType.oneHalf:
          height *= 1.50;
          break;
      }

    if (isOnlyTop)
      return Padding(
        padding: EdgeInsets.only(top: height),
        child: child,
      );
    else if (isOnlyBottom)
      return Padding(
        padding: EdgeInsets.only(bottom: height),
        child: child,
      );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: height),
      child: child,
    );
  }
}

extension WidgetExtPadding on Widget {
  Widget separatorQuarter() => PaddingVerticalCustom.quarter(this);
  Widget separatorQuarterBottom() =>
      PaddingVerticalCustom.quarter(this, isOnlyBottom: true);
  Widget separatorQuarterTop() =>
      PaddingVerticalCustom.quarter(this, isOnlyTop: true);

  Widget separatorHalf() => PaddingVerticalCustom.half(this);
  Widget separatorHalfBottom() =>
      PaddingVerticalCustom.half(this, isOnlyBottom: true);
  Widget separatorHalfTop() =>
      PaddingVerticalCustom.half(this, isOnlyTop: true);

  Widget separator() => PaddingVerticalCustom(this);
  Widget separatorBottom() => PaddingVerticalCustom(this, isOnlyBottom: true);
  Widget separatorTop() => PaddingVerticalCustom(this, isOnlyTop: true);

  Widget separatorDouble() => PaddingVerticalCustom.double(this);
  Widget separatorDoubleBottom() =>
      PaddingVerticalCustom.double(this, isOnlyBottom: true);
  Widget separatorDoubleTop() =>
      PaddingVerticalCustom.double(this, isOnlyTop: true);

  Widget separatorThird() => PaddingVerticalCustom.third(this);
  Widget separatorThirdBottom() =>
      PaddingVerticalCustom.third(this, isOnlyBottom: true);
  Widget separatorThirdTop() =>
      PaddingVerticalCustom.third(this, isOnlyTop: true);

  Widget separatorOneHalf() => PaddingVerticalCustom.oneHalf(this);
  Widget separatorOneHalfBottom() =>
      PaddingVerticalCustom.oneHalf(this, isOnlyBottom: true);
  Widget separatorOneHalfTop() =>
      PaddingVerticalCustom.oneHalf(this, isOnlyTop: true);
}
