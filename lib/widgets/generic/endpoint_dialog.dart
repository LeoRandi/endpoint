import '../_imports.dart';

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
  Duration transitionDuration = const Duration(milliseconds: 260),
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
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      return FadeTransition(
        opacity: curved,
        child: switch (transition) {
          EndpointDialogTransition.scale => ScaleTransition(
              scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
              child: child,
            ),
          EndpointDialogTransition.slideUp => SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.06),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
        },
      );
    },
  );
}
