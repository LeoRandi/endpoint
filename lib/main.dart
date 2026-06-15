import 'dart:async';

import 'app/_exports.dart';
import 'entities/_exports.dart';
import 'pages/main_menu/main_menu_page.dart';
import 'services/_exports.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  CodexDiscoveryService.registerHooks();
  final initialSettings =
      await EndpointPreferencesService.loadSettingsSnapshot();
  final initialRunSnapshot =
      await EndpointPreferencesService.loadCurrentRunSnapshot();
  final appVersion = await _loadAppVersionFromPubspec();
  runApp(
    EndpointApp(
      initialSettings: initialSettings,
      initialRunSnapshot: initialRunSnapshot,
      appVersion: appVersion,
    ),
  );
}

Future<String> _loadAppVersionFromPubspec() async {
  try {
    final pubspecContent = await rootBundle.loadString('pubspec.yaml');
    final versionMatch = RegExp(
      r'^version:\s*([^\s#]+)',
      multiLine: true,
    ).firstMatch(pubspecContent);
    return versionMatch?.group(1) ?? 'unknown';
  } catch (_) {
    return 'unknown';
  }
}

class EndpointApp extends StatelessWidget {
  final EndpointSettingsSnapshot initialSettings;
  final EndpointCurrentRunSnapshot? initialRunSnapshot;
  final String appVersion;

  const EndpointApp({
    super.key,
    this.initialSettings = const EndpointSettingsSnapshot.defaults(),
    this.initialRunSnapshot,
    this.appVersion = 'unknown',
  });

  @override
  Widget build(BuildContext context) {
    return EndpointTextScope(
      language: initialSettings.language,
      child: MaterialApp(
        title: EndpointStrings.text(
          EndpointTextKey.appTitle,
          language: initialSettings.language,
        ),
        theme: EndpointTheme.build(),
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          return Stack(
            fit: StackFit.expand,
            children: [
              child ?? const SizedBox.shrink(),
              const _EndpointCodexDiscoveryNoticeOverlay(),
            ],
          );
        },
        home: MainMenuPage(
          initialSettings: initialSettings,
          initialRunSnapshot: initialRunSnapshot,
          appVersion: appVersion,
        ),
      ),
    );
  }
}

class _EndpointCodexDiscoveryNoticeOverlay extends StatefulWidget {
  const _EndpointCodexDiscoveryNoticeOverlay();

  @override
  State<_EndpointCodexDiscoveryNoticeOverlay> createState() =>
      _EndpointCodexDiscoveryNoticeOverlayState();
}

class _EndpointCodexDiscoveryNoticeOverlayState
    extends State<_EndpointCodexDiscoveryNoticeOverlay> {
  Timer? _hideTimer;
  CodexDiscoveryNotice? _notice;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    CodexDiscoveryService.discoveryNotice.addListener(_handleNoticeChanged);
  }

  @override
  void dispose() {
    CodexDiscoveryService.discoveryNotice.removeListener(_handleNoticeChanged);
    _hideTimer?.cancel();
    super.dispose();
  }

  void _handleNoticeChanged() {
    final notice = CodexDiscoveryService.discoveryNotice.value;
    if (notice == null) return;

    _hideTimer?.cancel();
    setState(() {
      _notice = notice;
      _isVisible = true;
    });
    _hideTimer = Timer(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      setState(() {
        _isVisible = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    const accent = EndpointPalette.infoAccent;
    final notice = _notice;

    return Positioned(
      top: 0,
      bottom: 0,
      right: 8,
      child: IgnorePointer(
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          offset: _isVisible ? Offset.zero : const Offset(1.1, 0),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: _isVisible ? 1 : 0,
            child: Center(
              child: SizedBox(
                width: 142,
                height: 142,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: EndpointPalette.panelBackgroundBattle.withAlpha(238),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: accent.withAlpha(210),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withAlpha(46),
                        blurRadius: 18,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'CODEX',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: accent,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _CodexDiscoveryNoticeIcon(
                          notice: notice,
                          accent: accent,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          notice?.hasSeveralDiscoveries == true
                              ? 'Several new discoveries!'
                              : 'New discovery!',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: EndpointPalette.softForeground.withAlpha(
                              236,
                            ),
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            height: 1.08,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CodexDiscoveryNoticeIcon extends StatelessWidget {
  final CodexDiscoveryNotice? notice;
  final Color accent;

  const _CodexDiscoveryNoticeIcon({
    required this.notice,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final notice = this.notice;
    if (notice?.hasSeveralDiscoveries == true) {
      return Icon(
        Icons.auto_awesome_rounded,
        color: accent,
        size: 32,
      );
    }

    final iconData = _iconForKey(notice?.primaryKey);
    if (iconData != null) {
      return Icon(
        iconData,
        color: accent,
        size: 32,
      );
    }

    final emoji = _emojiForKey(notice?.primaryKey);
    if (emoji != null) {
      return Text(
        emoji,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 30,
          height: 1,
          decoration: TextDecoration.none,
        ),
      );
    }

    return Icon(
      Icons.auto_awesome_rounded,
      color: accent,
      size: 32,
    );
  }

  IconData? _iconForKey(String? key) {
    if (key == null) return null;
    if (key.startsWith('status:')) {
      final statusName = key.substring('status:'.length);
      final status = [
        calentandoStatus,
        potenciaStatus,
        cicloEclipseStatus,
        puntoCiegoStatus,
        desafioStatus,
        desafioExcitanteStatus,
        const ResonanciaStatus(),
        quemaduraStatus,
        intoxicacionStatus,
        contagioStatus,
        catalisisCruelStatus,
        fragilidadStatus,
        conmocionStatus,
        deudaStatus,
      ];
      for (final status in status) {
        if (status.id.name == statusName) return status.icon;
      }
      return null;
    }

    if (key.startsWith('ability:')) {
      final abilityName = key.substring('ability:'.length);
      for (final ability in abilityPresets) {
        if (ability.id.name == abilityName) return ability.icon;
      }
      return null;
    }

    return null;
  }

  String? _emojiForKey(String? key) {
    if (key == null) return null;
    if (key.startsWith('item:')) {
      final itemName = key.substring('item:'.length);
      for (final item in itemPresets) {
        if (item.id.name == itemName) return item.iconEmoji;
      }
      return null;
    }
    if (key.startsWith('archetype:')) {
      final archetypeName = key.substring('archetype:'.length);
      for (final archetype in openingArchetypeNodes) {
        if (archetype.archetypeId.name == archetypeName) {
          return archetype.playerIconEmoji;
        }
      }
      return null;
    }
    if (key.startsWith('enemy:')) {
      final nodeId = key.substring('enemy:'.length);
      for (final node in combatPathNodeExamples) {
        if (node.nodeId == nodeId) return node.enemy.iconEmoji;
      }
      return null;
    }
    if (key.startsWith('shop:')) {
      final nodeId = key.substring('shop:'.length);
      for (final node in [
        ...dayShopNodes,
        ...nightShopNodes,
      ]) {
        if (node.nodeId == nodeId) return node.iconEmoji;
      }
      return null;
    }
    if (key.startsWith('event:')) {
      final eventName = key.substring('event:'.length);
      for (final node in [
        ...dayEventNodes,
        ...nightEventNodes,
      ]) {
        if (node.id.name == eventName) return node.iconEmoji;
      }
      return null;
    }

    return null;
  }
}

class Endpoint extends EndpointApp {
  const Endpoint({
    super.key,
    super.initialSettings,
    super.initialRunSnapshot,
    super.appVersion,
  });
}
