import '_imports.dart';

Future<T?> showEndpointOverlay<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  String barrierLabel = 'Cerrar menu',
  bool barrierDismissible = true,
  Color barrierColor = Colors.transparent,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierLabel: barrierLabel,
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor,
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );

      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
