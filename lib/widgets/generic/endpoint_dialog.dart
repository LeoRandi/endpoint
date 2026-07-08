import '_imports.dart';

enum EndpointDialogTransition {
  scale,
  slideUp,
}

Future<T?> showEndpointDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  String barrierLabel = 'Cerrar',
  bool barrierDismissible = true,
  Color barrierColor = EndpointPalette.overlayScrim,
  Duration transitionDuration = EndpointMotion.dialogTransition,
  EndpointDialogTransition transition = EndpointDialogTransition.scale,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierLabel: barrierLabel,
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor,
    transitionDuration: transitionDuration,
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = EndpointMotion.curved(
        animation,
        reverseCurve: EndpointMotion.standardReverseCurve,
      );

      return FadeTransition(
        opacity: curved,
        child: switch (transition) {
          EndpointDialogTransition.scale => ScaleTransition(
              scale: EndpointMotion.scaleIn(curved),
              child: child,
            ),
          EndpointDialogTransition.slideUp => SlideTransition(
              position: EndpointMotion.slideIn(curved),
              child: child,
            ),
        },
      );
    },
  );
}
