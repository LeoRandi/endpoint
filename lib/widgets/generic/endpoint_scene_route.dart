import '_imports.dart';

Route<T> buildEndpointSceneRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 420),
    reverseTransitionDuration: const Duration(milliseconds: 360),
    pageBuilder: (context, animation, secondaryAnimation) {
      return page;
    },
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOutCubic,
      );
      final blackoutOpacity = TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(begin: 0, end: 1),
          weight: 52,
        ),
        TweenSequenceItem(
          tween: ConstantTween<double>(1),
          weight: 48,
        ),
      ]).animate(curved);
      final childOpacity = TweenSequence<double>([
        TweenSequenceItem(
          tween: ConstantTween<double>(0),
          weight: 38,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: 0, end: 1),
          weight: 62,
        ),
      ]).animate(curved);

      return Stack(
        fit: StackFit.expand,
        children: [
          FadeTransition(
            opacity: blackoutOpacity,
            child: const ColoredBox(color: Colors.black),
          ),
          FadeTransition(
            opacity: childOpacity,
            child: child,
          ),
        ],
      );
    },
  );
}
