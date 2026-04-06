import '../_imports.dart';

const _settingsAccent = Color(0xFFB8C0C8);
const _settingsAccentMuted = Color(0xFF6E767E);
const _settingsForeground = Color(0xFFF1F4F7);
const _settingsForegroundMuted = Color(0xFFB7C0C8);
const _settingsPanelBackground = Color(0xD911151A);
const _settingsCardBackground = Color(0xCC171D23);
const _settingsCardDisabledBackground = Color(0xA012171C);
const _settingsButtonBackground = Color(0xFF1A2229);
const _settingsButtonSelectedBackground = Color(0xFF2A333B);
const _settingsCloseBackground = Color(0xFF182026);
const _settingsGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0xFF07090B),
    Color(0xFF10151A),
    Color(0xFF050607),
  ],
);

class SettingsPage extends StatefulWidget {
  final EndpointSettingsSnapshot initialSettings;

  const SettingsPage({
    super.key,
    this.initialSettings = const EndpointSettingsSnapshot.defaults(),
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late EndpointSettingsSnapshot _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings;
  }

  void _close() {
    Navigator.of(context).pop(_settings);
  }

  void _applySettings(EndpointSettingsSnapshot nextSettings) {
    if (nextSettings == _settings) return;

    setState(() {
      _settings = nextSettings;
    });
    unawaited(
      EndpointPreferencesService.saveSettingsSnapshot(nextSettings),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: _settingsGradient,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const _SettingsBackdrop(),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: EndpointSceneCloseButton(
                        onPressed: _close,
                        tooltip: 'Cerrar configuracion',
                        accent: _settingsAccent,
                        foregroundColor: _settingsForeground,
                        backgroundColor: _settingsCloseBackground,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: EndpointPanel(
                            accent: _settingsAccent,
                            backgroundColor: _settingsPanelBackground,
                            borderRadius: 18,
                            glowOpacity: 0.08,
                            blurRadius: 28,
                            spreadRadius: 3,
                            padding: const EdgeInsets.fromLTRB(
                              18,
                              18,
                              18,
                              18,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                EndpointText(
                                  'SETTINGS',
                                  style: textExtraLargeBold.copyWith(
                                    color: _settingsForeground,
                                    fontSize: 34,
                                    letterSpacing: 2.6,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                EndpointText(
                                  'Ajustes base del perfil operativo.',
                                  maxLines: null,
                                  style: textMedium.copyWith(
                                    color: _settingsForegroundMuted,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: Column(
                                      children: [
                                        _SettingsOptionCard(
                                          title: 'Sonido',
                                          child: _SettingsChoiceWrap(
                                            children: [
                                              _SettingsChoiceButton(
                                                label: 'Activado',
                                                selected:
                                                    _settings.soundEnabled,
                                                onPressed: () {
                                                  _applySettings(
                                                    _settings.copyWith(
                                                      soundEnabled: true,
                                                    ),
                                                  );
                                                },
                                              ),
                                              _SettingsChoiceButton(
                                                label: 'Desactivado',
                                                selected:
                                                    !_settings.soundEnabled,
                                                onPressed: () {
                                                  _applySettings(
                                                    _settings.copyWith(
                                                      soundEnabled: false,
                                                    ),
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        _SettingsOptionCard(
                                          title: 'Vibracion',
                                          child: _SettingsChoiceWrap(
                                            children: [
                                              _SettingsChoiceButton(
                                                label: 'Activado',
                                                selected:
                                                    _settings.vibrationEnabled,
                                                onPressed: () {
                                                  _applySettings(
                                                    _settings.copyWith(
                                                      vibrationEnabled: true,
                                                    ),
                                                  );
                                                },
                                              ),
                                              _SettingsChoiceButton(
                                                label: 'Desactivado',
                                                selected: !_settings
                                                    .vibrationEnabled,
                                                onPressed: () {
                                                  _applySettings(
                                                    _settings.copyWith(
                                                      vibrationEnabled: false,
                                                    ),
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        _SettingsOptionCard(
                                          title:
                                              'Velocidad de las animaciones',
                                          child: _SettingsChoiceWrap(
                                            children: [
                                              _SettingsChoiceButton(
                                                label: '1',
                                                selected:
                                                    _settings.animationSpeed ==
                                                        1,
                                                onPressed: () {
                                                  _applySettings(
                                                    _settings.copyWith(
                                                      animationSpeed: 1,
                                                    ),
                                                  );
                                                },
                                              ),
                                              _SettingsChoiceButton(
                                                label: '2',
                                                selected:
                                                    _settings.animationSpeed ==
                                                        2,
                                                onPressed: () {
                                                  _applySettings(
                                                    _settings.copyWith(
                                                      animationSpeed: 2,
                                                    ),
                                                  );
                                                },
                                              ),
                                              _SettingsChoiceButton(
                                                label: '3',
                                                selected:
                                                    _settings.animationSpeed ==
                                                        3,
                                                onPressed: () {
                                                  _applySettings(
                                                    _settings.copyWith(
                                                      animationSpeed: 3,
                                                    ),
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        _SettingsOptionCard(
                                          title: 'Avatar personalizado',
                                          child: _SettingsChoiceWrap(
                                            children: [
                                              _SettingsChoiceButton(
                                                label: 'Activado',
                                                selected:
                                                    _settings
                                                        .customAvatarEnabled,
                                                onPressed: () {
                                                  _applySettings(
                                                    _settings.copyWith(
                                                      customAvatarEnabled: true,
                                                    ),
                                                  );
                                                },
                                              ),
                                              _SettingsChoiceButton(
                                                label: 'Desactivado',
                                                selected:
                                                    !_settings
                                                        .customAvatarEnabled,
                                                onPressed: () {
                                                  _applySettings(
                                                    _settings.copyWith(
                                                      customAvatarEnabled:
                                                          false,
                                                    ),
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        _SettingsOptionCard(
                                          title:
                                              'Seleccionar avatar personalizado',
                                          caption:
                                              'Visible, pero bloqueado por ahora.',
                                          enabled: _settings
                                              .customAvatarSelectionEnabled,
                                          child: _SettingsChoiceWrap(
                                            children: [
                                              _SettingsChoiceButton(
                                                label: 'Seleccionar',
                                                enabled: _settings
                                                    .customAvatarSelectionEnabled,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        _SettingsOptionCard(
                                          title: 'Modo de juego',
                                          child: _SettingsChoiceWrap(
                                            children: [
                                              _SettingsChoiceButton(
                                                label: 'Clasico',
                                                selected: _settings.gameMode ==
                                                    EndpointGameMode.classic,
                                                onPressed: () {
                                                  _applySettings(
                                                    _settings.copyWith(
                                                      gameMode: EndpointGameMode
                                                          .classic,
                                                    ),
                                                  );
                                                },
                                              ),
                                              _SettingsChoiceButton(
                                                label: 'Dibujo',
                                                selected: _settings.gameMode ==
                                                    EndpointGameMode.drawing,
                                                onPressed: () {
                                                  _applySettings(
                                                    _settings.copyWith(
                                                      gameMode: EndpointGameMode
                                                          .drawing,
                                                    ),
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsOptionCard extends StatelessWidget {
  final String title;
  final String? caption;
  final Widget child;
  final bool enabled;

  const _SettingsOptionCard({
    required this.title,
    this.caption,
    required this.child,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final accent = enabled ? _settingsAccent : _settingsAccentMuted;
    final foreground = enabled ? _settingsForeground : _settingsForegroundMuted;

    return Opacity(
      opacity: enabled ? 1 : 0.64,
      child: EndpointPanel(
        accent: accent,
        backgroundColor: enabled
            ? _settingsCardBackground
            : _settingsCardDisabledBackground,
        borderRadius: 16,
        glowOpacity: enabled ? 0.05 : 0,
        blurRadius: 18,
        spreadRadius: 1,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EndpointText(
              title,
              maxLines: null,
              style: textMediumBold.copyWith(
                color: foreground,
                letterSpacing: 1,
              ),
            ),
            if (caption != null) ...[
              const SizedBox(height: 4),
              EndpointText(
                caption!,
                maxLines: null,
                style: textSmall.copyWith(
                  color: _settingsForegroundMuted,
                  fontSize: 11,
                ),
              ),
            ],
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _SettingsChoiceWrap extends StatelessWidget {
  final List<Widget> children;

  const _SettingsChoiceWrap({
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: children,
    );
  }
}

class _SettingsChoiceButton extends StatelessWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback? onPressed;

  const _SettingsChoiceButton({
    required this.label,
    this.selected = false,
    this.enabled = true,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 92),
      child: EndpointActionButton(
        label: label,
        onPressed: enabled ? onPressed : null,
        tooltip: enabled ? '' : 'Opcion desactivada',
        allowDisabledTooltip: true,
        useMarquee: false,
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        borderRadius: 10,
        borderWidth: 1.4,
        accent: selected ? _settingsAccent : _settingsAccentMuted,
        backgroundColor: selected
            ? _settingsButtonSelectedBackground
            : _settingsButtonBackground,
        foregroundColor: enabled
            ? _settingsForeground
            : _settingsForeground.withValues(alpha: 0.46),
        textStyle: textSmallBold.copyWith(
          fontSize: 12,
          letterSpacing: 0.9,
        ),
      ),
    );
  }
}

class _SettingsBackdrop extends StatelessWidget {
  const _SettingsBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Align(
          alignment: const Alignment(-0.82, -0.86),
          child: Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _settingsAccent.withValues(alpha: 0.12),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Align(
          alignment: const Alignment(0.88, 0.72),
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _settingsAccentMuted.withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        const IgnorePointer(
          child: CustomPaint(
            painter: _SettingsBackdropPainter(),
          ),
        ),
      ],
    );
  }
}

class _SettingsBackdropPainter extends CustomPainter {
  const _SettingsBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final scanlinePaint = Paint()
      ..color = _settingsAccent.withValues(alpha: 0.03)
      ..strokeWidth = 1;
    final gridPaint = Paint()
      ..color = _settingsAccentMuted.withValues(alpha: 0.08)
      ..strokeWidth = 1;

    for (double y = 0; y <= size.height; y += 22) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), scanlinePaint);
    }

    for (double x = 0; x <= size.width; x += 52) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
