import '_imports.dart';

Future<T?> showEndpointOverlay<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  String barrierLabel = 'Cerrar menu',
  bool barrierDismissible = true,
  Color barrierColor = Colors.transparent,
}) {
  return showEndpointDialog<T>(
    context: context,
    barrierLabel: barrierLabel,
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor,
    transitionDuration: const Duration(milliseconds: 180),
    transition: EndpointDialogTransition.slideUp,
    builder: builder,
  );
}
