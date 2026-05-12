import 'app/_exports.dart';
import 'pages/main_menu/main_menu_page.dart';
import 'services/_exports.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
              _EndpointAppVersionBadge(version: appVersion),
            ],
          );
        },
        home: MainMenuPage(
          initialSettings: initialSettings,
          initialRunSnapshot: initialRunSnapshot,
        ),
      ),
    );
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

class _EndpointAppVersionBadge extends StatelessWidget {
  final String version;

  const _EndpointAppVersionBadge({
    required this.version,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SafeArea(
        child: Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: EndpointPalette.panelBackgroundOpaque
                    .withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.14),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                child: Text(
                  'v$version',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
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
