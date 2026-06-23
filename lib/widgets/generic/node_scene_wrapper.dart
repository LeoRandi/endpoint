import '_imports.dart';

class NodeSceneWrapper extends StatefulWidget {
  final String showTitle;
  final Widget child;

  const NodeSceneWrapper({
    super.key,
    required this.showTitle,
    required this.child,
  });

  @override
  State<NodeSceneWrapper> createState() => _NodeSceneWrapperState();
}

class _NodeSceneWrapperState extends State<NodeSceneWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _titleOpacity;
  late final Animation<double> _overlayOpacity;
  late final Animation<double> _titleScale;
  late final Animation<double> _titleOffsetY;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _titleOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 1),
        weight: 24,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1),
        weight: 38,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1, end: 0),
        weight: 38,
      ),
    ]).animate(curved);
    _overlayOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 0.18),
        weight: 18,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(0.18),
        weight: 32,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.18, end: 0),
        weight: 50,
      ),
    ]).animate(curved);
    _titleScale = Tween<double>(
      begin: 0.92,
      end: 1,
    ).animate(curved);
    _titleOffsetY = Tween<double>(
      begin: 18,
      end: 0,
    ).animate(curved);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              if (_titleOpacity.value <= 0.001 &&
                  _overlayOpacity.value <= 0.001) {
                return const SizedBox.shrink();
              }

              return Stack(
                fit: StackFit.expand,
                children: [
                  Opacity(
                    opacity: _overlayOpacity.value,
                    child: const ColoredBox(color: Colors.black),
                  ),
                  Center(
                    child: Transform.translate(
                      offset: Offset(0, _titleOffsetY.value),
                      child: Transform.scale(
                        scale: _titleScale.value,
                        child: Opacity(
                          opacity: _titleOpacity.value,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: EndpointPalette.panelBackgroundOpaque,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: EndpointPalette.primaryAccent,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              child: EndpointText(
                                widget.showTitle,
                                textAlign: TextAlign.center,
                                style: textLargeBold.copyWith(
                                  color: EndpointPalette.softForeground,
                                  letterSpacing: 1.8,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
