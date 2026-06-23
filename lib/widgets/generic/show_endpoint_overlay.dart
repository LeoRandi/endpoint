import '_imports.dart';

Future<T?> showEndpointOverlay<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  String barrierLabel = 'Cerrar menu',
  bool barrierDismissible = true,
  Color barrierColor = Colors.transparent,
  Duration transitionDuration = const Duration(milliseconds: 240),
}) {
  return showEndpointDialog<T>(
    context: context,
    barrierLabel: barrierLabel,
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor,
    transitionDuration: transitionDuration,
    transition: EndpointDialogTransition.slideUp,
    builder: builder,
  );
}
