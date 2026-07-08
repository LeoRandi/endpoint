import 'package:flutter/material.dart';

/// Shared motion tokens for overlays, dialogs, scenes, and small UI effects.
abstract final class EndpointMotion {
  static const dialogTransition = Duration(milliseconds: 260);
  static const overlayTransition = Duration(milliseconds: 240);
  static const sceneTransition = Duration(milliseconds: 420);
  static const sceneReverseTransition = Duration(milliseconds: 360);
  static const nodeSceneIntro = Duration(milliseconds: 1800);
  static const upgradeSweep = Duration(milliseconds: 1150);

  static const Curve standardCurve = Curves.easeOutCubic;
  static const Curve standardReverseCurve = Curves.easeInCubic;
  static const Curve sceneCurve = Curves.easeInOutCubic;

  static const Offset dialogSlideOffset = Offset(0, 0.06);
  static const Offset sceneRouteOffset = Offset(0, 0.015);

  static CurvedAnimation curved(
    Animation<double> parent, {
    Curve curve = standardCurve,
    Curve? reverseCurve,
  }) {
    return CurvedAnimation(
      parent: parent,
      curve: curve,
      reverseCurve: reverseCurve,
    );
  }

  static Animation<double> fadeIn(Animation<double> parent) {
    return doubleTween(parent, begin: 0, end: 1);
  }

  static Animation<double> scaleIn(
    Animation<double> parent, {
    double begin = 0.94,
    double end = 1,
  }) {
    return doubleTween(parent, begin: begin, end: end);
  }

  static Animation<double> doubleTween(
    Animation<double> parent, {
    required double begin,
    required double end,
  }) {
    return Tween<double>(begin: begin, end: end).animate(parent);
  }

  static Animation<Offset> slideIn(
    Animation<double> parent, {
    Offset begin = dialogSlideOffset,
    Offset end = Offset.zero,
  }) {
    return Tween<Offset>(begin: begin, end: end).animate(parent);
  }
}
