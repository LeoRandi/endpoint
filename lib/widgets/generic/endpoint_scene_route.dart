import '_imports.dart';

Route<T> buildEndpointSceneRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: EndpointMotion.sceneTransition,
    reverseTransitionDuration: EndpointMotion.sceneReverseTransition,
    pageBuilder: (context, animation, secondaryAnimation) {
      return page;
    },
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = EndpointMotion.curved(
        animation,
        curve: EndpointMotion.sceneCurve,
        reverseCurve: EndpointMotion.sceneCurve,
      );
      final incomingMotion = EndpointMotion.slideIn(
        curved,
        begin: EndpointMotion.sceneRouteOffset,
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
          SlideTransition(
            position: incomingMotion,
            child: FadeTransition(
              opacity: childOpacity,
              child: child,
            ),
          ),
        ],
      );
    },
  );
}
