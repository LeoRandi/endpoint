import '_imports.dart';

class WeaponShopPage extends StatelessWidget {
  const WeaponShopPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NodeSceneWrapper(
        showTitle: '¡Bienvenido a la tienda!',
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF090705),
                Color(0xFF11120A),
                Color(0xFF030403),
              ],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const _ShopBackdrop(),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: HoldTooltip(
                          message: 'Salir de la tienda',
                          child: IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: IconButton.styleFrom(
                              foregroundColor: const Color(0xFFE9E4C4),
                              backgroundColor: const Color(0xFF17130B),
                              side: const BorderSide(color: Color(0xFFDBB95A)),
                            ),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ),
                      ),
                      const Spacer(),
                      const EndpointEmojiSprite(
                        emoji: '\u{2694}',
                        accent: Color(0xFFDBB95A),
                        size: 144,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'TIENDA DE ARMAS',
                        textAlign: TextAlign.center,
                        style: textLargeBold.copyWith(
                          color: const Color(0xFFEEDB96),
                          letterSpacing: 2.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sin inventario disponible por ahora.',
                        textAlign: TextAlign.center,
                        style: textMedium.copyWith(
                          color: Colors.white.withOpacity(0.82),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShopBackdrop extends StatelessWidget {
  const _ShopBackdrop();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: CustomPaint(
        painter: _ShopBackdropPainter(),
      ),
    );
  }
}

class _ShopBackdropPainter extends CustomPainter {
  const _ShopBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0x12DBB95A)
      ..strokeWidth = 1;
    final beamPaint = Paint()
      ..color = const Color(0x1FDBB95A)
      ..strokeWidth = 2;

    for (double y = 28; y <= size.height; y += 34) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final beamOffsets = [
      size.width * 0.22,
      size.width * 0.5,
      size.width * 0.78,
    ];

    for (final dx in beamOffsets) {
      canvas.drawLine(
        Offset(dx, size.height * 0.18),
        Offset(dx, size.height * 0.82),
        beamPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
