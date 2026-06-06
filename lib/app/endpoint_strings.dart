import '../services/endpoint_preferences_models.dart';
import 'package:flutter/widgets.dart';

/// Stable identifiers for localized UI copy.
///
/// These keys let migrated widgets ask for text by meaning instead of hardcoded
/// strings, while unmigrated folders can continue using the legacy constants in
/// [EndpointStrings] during the transition.
enum EndpointTextKey {
  appTitle,
  continueRun,
  start,
  codex,
  settings,
  backToRoute,
  noItems,
  noAugments,
  routeTimelineDescription,
  codexUnavailable,
  settingsUnavailable,
  mainMenuTitle,
  mainMenuTutorialHelpTooltip,
  mainMenuShowcaseSkip,
  mainMenuShowcaseNext,
  mainMenuContinueTitle,
  mainMenuContinueDescription,
  mainMenuNoRunTooltip,
  mainMenuContinueRunTooltip,
  mainMenuStartTitle,
  mainMenuStartDescription,
  mainMenuStartTooltip,
  mainMenuTutorialButton,
  mainMenuTutorialTooltip,
  mainMenuTutorialBarrierLabel,
  mainMenuTutorialPromptTitle,
  mainMenuTutorialPromptQuestion,
  mainMenuTutorialCancel,
  mainMenuTutorialConfirm,
  mainMenuCodexTitle,
  mainMenuCodexDescription,
  mainMenuSettingsTitle,
  mainMenuSettingsDescription,
  mainMenuSettingsTooltip,
  settingsCloseTooltip,
  settingsHeaderTitle,
  settingsHeaderDescription,
  settingsSoundTitle,
  settingsVibrationTitle,
  settingsAnimationsTitle,
  settingsCustomAvatarTitle,
  settingsCustomAvatarSelectionTitle,
  settingsCustomAvatarSelectionCaption,
  settingsCustomAvatarSelectionButton,
  settingsGameModeTitle,
  settingsLanguageTitle,
  settingsLanguageCaption,
  settingsEnabled,
  settingsDisabled,
  settingsDisabledTooltip,
  settingsGameModeClassic,
  settingsGameModePattern,
  settingsLanguageSpanish,
  settingsLanguageEnglish,
}

/// App-level string registry and localization helpers.
///
/// The project is midway through migrating UI copy from direct Spanish strings
/// to key-based bundles. This class keeps the old constants available and owns
/// the newer localized maps used by settings and main-menu surfaces.
abstract final class EndpointStrings {
  static const defaultLanguage = EndpointLanguage.spanish;
  static const defaultBundle = EndpointTextBundle(defaultLanguage);

  static const appTitle = 'Death at Sunrise';
  static const continueRun = 'Continuar';
  static const start = 'Empezar';
  static const codex = 'Codex';
  static const settings = 'Ajustes';
  static const backToRoute = 'Volver a la ruta';
  static const noItems = 'No tienes ningun objeto';
  static const noAugments = 'No tienes ningun aumento';
  static const routeTimelineDescription =
      'Ruta de 5 dias: dia, anochecer, noche y boss diario.';
  static const codexUnavailable = 'Apartado no disponible';
  static const settingsUnavailable = 'Configuracion no disponible';

  static const Map<EndpointLanguage, Map<EndpointTextKey, String>> _localized =
      {
    EndpointLanguage.spanish: {
      EndpointTextKey.appTitle: 'Death at Sunrise',
      EndpointTextKey.continueRun: 'Continuar',
      EndpointTextKey.start: 'Empezar',
      EndpointTextKey.codex: 'Codex',
      EndpointTextKey.settings: 'Ajustes',
      EndpointTextKey.backToRoute: 'Volver a la ruta',
      EndpointTextKey.noItems: 'No tienes ningun objeto',
      EndpointTextKey.noAugments: 'No tienes ningun aumento',
      EndpointTextKey.routeTimelineDescription:
          'Ruta de 5 dias: dia, anochecer, noche y boss diario.',
      EndpointTextKey.codexUnavailable: 'Apartado no disponible',
      EndpointTextKey.settingsUnavailable: 'Configuracion no disponible',
      EndpointTextKey.mainMenuTitle: 'DEATH AT SUNRISE',
      EndpointTextKey.mainMenuTutorialHelpTooltip: 'Mostrar tutorial del menu',
      EndpointTextKey.mainMenuShowcaseSkip: 'SALIR',
      EndpointTextKey.mainMenuShowcaseNext: 'SIGUIENTE',
      EndpointTextKey.mainMenuContinueTitle: 'Continuar',
      EndpointTextKey.mainMenuContinueDescription:
          'Retoma la partida por donde lo dejaste.',
      EndpointTextKey.mainMenuNoRunTooltip: 'No hay ninguna run en curso',
      EndpointTextKey.mainMenuContinueRunTooltip: 'Continuar la run guardada',
      EndpointTextKey.mainMenuStartTitle: 'Empezar',
      EndpointTextKey.mainMenuStartDescription:
          'Empezar la partida desde 0. Deberas sobrevivir hasta ver el amanecer.',
      EndpointTextKey.mainMenuStartTooltip: 'Iniciar partida',
      EndpointTextKey.mainMenuTutorialButton: 'Tutorial',
      EndpointTextKey.mainMenuTutorialTooltip: 'Iniciar tutorial guiado',
      EndpointTextKey.mainMenuTutorialBarrierLabel: 'Confirmar tutorial',
      EndpointTextKey.mainMenuTutorialPromptTitle: 'TUTORIAL',
      EndpointTextKey.mainMenuTutorialPromptQuestion:
          'Quieres realizar el tutorial?',
      EndpointTextKey.mainMenuTutorialCancel: 'No',
      EndpointTextKey.mainMenuTutorialConfirm: 'Si',
      EndpointTextKey.mainMenuCodexTitle: 'Codex',
      EndpointTextKey.mainMenuCodexDescription:
          'Registro de objetos, enemigos, aumentos y eventos descubiertos.',
      EndpointTextKey.mainMenuSettingsTitle: 'Ajustes',
      EndpointTextKey.mainMenuSettingsDescription:
          'Desde los ajustes puedes configurar algunos efectos visuales o el modo de juego.',
      EndpointTextKey.mainMenuSettingsTooltip: 'Abrir configuracion',
      EndpointTextKey.settingsCloseTooltip: 'Cerrar configuracion',
      EndpointTextKey.settingsHeaderTitle: 'AJUSTES',
      EndpointTextKey.settingsHeaderDescription:
          'Ajustes base del perfil operativo.',
      EndpointTextKey.settingsSoundTitle: 'Sonido',
      EndpointTextKey.settingsVibrationTitle: 'Vibracion',
      EndpointTextKey.settingsAnimationsTitle: 'Velocidad de las animaciones',
      EndpointTextKey.settingsCustomAvatarTitle: 'Avatar personalizado',
      EndpointTextKey.settingsCustomAvatarSelectionTitle:
          'Seleccionar avatar personalizado',
      EndpointTextKey.settingsCustomAvatarSelectionCaption:
          'Visible, pero bloqueado por ahora.',
      EndpointTextKey.settingsCustomAvatarSelectionButton: 'Seleccionar',
      EndpointTextKey.settingsGameModeTitle: 'Modo de juego',
      EndpointTextKey.settingsLanguageTitle: 'Idioma',
      EndpointTextKey.settingsLanguageCaption:
          'Cambia el texto de las pantallas migradas.',
      EndpointTextKey.settingsEnabled: 'Activado',
      EndpointTextKey.settingsDisabled: 'Desactivado',
      EndpointTextKey.settingsDisabledTooltip: 'Opcion desactivada',
      EndpointTextKey.settingsGameModeClassic: 'Clásico',
      EndpointTextKey.settingsGameModePattern: 'Patrón',
      EndpointTextKey.settingsLanguageSpanish: 'Espanol',
      EndpointTextKey.settingsLanguageEnglish: 'English',
    },
    EndpointLanguage.english: {
      EndpointTextKey.appTitle: 'Death at Sunrise',
      EndpointTextKey.continueRun: 'Continue',
      EndpointTextKey.start: 'Start',
      EndpointTextKey.codex: 'Codex',
      EndpointTextKey.settings: 'Settings',
      EndpointTextKey.backToRoute: 'Back to route',
      EndpointTextKey.noItems: 'You have no items',
      EndpointTextKey.noAugments: 'You have no augments',
      EndpointTextKey.routeTimelineDescription:
          '5-day route: day, dusk, night, and daily boss.',
      EndpointTextKey.codexUnavailable: 'Section unavailable',
      EndpointTextKey.settingsUnavailable: 'Settings unavailable',
      EndpointTextKey.mainMenuTitle: 'DEATH AT SUNRISE',
      EndpointTextKey.mainMenuTutorialHelpTooltip: 'Show menu tutorial',
      EndpointTextKey.mainMenuShowcaseSkip: 'EXIT',
      EndpointTextKey.mainMenuShowcaseNext: 'NEXT',
      EndpointTextKey.mainMenuContinueTitle: 'Continue',
      EndpointTextKey.mainMenuContinueDescription:
          'Resume the game where you left it.',
      EndpointTextKey.mainMenuNoRunTooltip: 'No run in progress',
      EndpointTextKey.mainMenuContinueRunTooltip: 'Continue the saved run',
      EndpointTextKey.mainMenuStartTitle: 'Start',
      EndpointTextKey.mainMenuStartDescription:
          'Start a new game from zero. You must survive until sunrise.',
      EndpointTextKey.mainMenuStartTooltip: 'Start game',
      EndpointTextKey.mainMenuTutorialButton: 'Tutorial',
      EndpointTextKey.mainMenuTutorialTooltip: 'Start guided tutorial',
      EndpointTextKey.mainMenuTutorialBarrierLabel: 'Confirm tutorial',
      EndpointTextKey.mainMenuTutorialPromptTitle: 'TUTORIAL',
      EndpointTextKey.mainMenuTutorialPromptQuestion:
          'Do you want to play the tutorial?',
      EndpointTextKey.mainMenuTutorialCancel: 'No',
      EndpointTextKey.mainMenuTutorialConfirm: 'Yes',
      EndpointTextKey.mainMenuCodexTitle: 'Codex',
      EndpointTextKey.mainMenuCodexDescription:
          'Log of discovered items, enemies, augments, and events.',
      EndpointTextKey.mainMenuSettingsTitle: 'Settings',
      EndpointTextKey.mainMenuSettingsDescription:
          'From Settings you can configure visual effects or the game mode.',
      EndpointTextKey.mainMenuSettingsTooltip: 'Open settings',
      EndpointTextKey.settingsCloseTooltip: 'Close settings',
      EndpointTextKey.settingsHeaderTitle: 'SETTINGS',
      EndpointTextKey.settingsHeaderDescription:
          'Base settings for the operative profile.',
      EndpointTextKey.settingsSoundTitle: 'Sound',
      EndpointTextKey.settingsVibrationTitle: 'Vibration',
      EndpointTextKey.settingsAnimationsTitle: 'Animation speed',
      EndpointTextKey.settingsCustomAvatarTitle: 'Custom avatar',
      EndpointTextKey.settingsCustomAvatarSelectionTitle:
          'Select custom avatar',
      EndpointTextKey.settingsCustomAvatarSelectionCaption:
          'Visible, but locked for now.',
      EndpointTextKey.settingsCustomAvatarSelectionButton: 'Select',
      EndpointTextKey.settingsGameModeTitle: 'Game mode',
      EndpointTextKey.settingsLanguageTitle: 'Language',
      EndpointTextKey.settingsLanguageCaption:
          'Changes text on migrated screens.',
      EndpointTextKey.settingsEnabled: 'Enabled',
      EndpointTextKey.settingsDisabled: 'Disabled',
      EndpointTextKey.settingsDisabledTooltip: 'Option disabled',
      EndpointTextKey.settingsGameModeClassic: 'Classic',
      EndpointTextKey.settingsGameModePattern: 'Pattern',
      EndpointTextKey.settingsLanguageSpanish: 'Espanol',
      EndpointTextKey.settingsLanguageEnglish: 'English',
    },
  };

  static final RegExp _paramPattern = RegExp(r'\{([A-Za-z0-9_]+)\}');

  /// Returns the text key that labels [language] inside settings controls.
  ///
  /// Keeping this mapping beside the localized copy prevents settings widgets
  /// from depending on enum names or duplicating presentation decisions.
  static EndpointTextKey languageKey(EndpointLanguage language) {
    return switch (language) {
      EndpointLanguage.spanish => EndpointTextKey.settingsLanguageSpanish,
      EndpointLanguage.english => EndpointTextKey.settingsLanguageEnglish,
    };
  }

  /// Returns the text key that labels [gameMode] inside settings controls.
  ///
  /// Game-mode names belong to the app localization surface, while the service
  /// model only needs to describe the saved preference value.
  static EndpointTextKey gameModeKey(EndpointGameMode gameMode) {
    return switch (gameMode) {
      EndpointGameMode.classic => EndpointTextKey.settingsGameModeClassic,
      EndpointGameMode.pattern => EndpointTextKey.settingsGameModePattern,
    };
  }

  /// Resolves [key] into localized copy for [language].
  ///
  /// If a translation is missing, the method falls back to Spanish and finally
  /// to the key name, so incomplete migrations fail visibly without crashing.
  /// Placeholder tokens like `{amount}` are replaced from [params] when present.
  static String text(
    EndpointTextKey key, {
    EndpointLanguage language = defaultLanguage,
    Map<String, Object?> params = const {},
  }) {
    final template = _localized[language]?[key] ??
        _localized[defaultLanguage]?[key] ??
        key.name;
    if (params.isEmpty) return template;

    return template.replaceAllMapped(_paramPattern, (match) {
      final paramName = match.group(1);
      if (paramName == null || !params.containsKey(paramName)) {
        return match.group(0) ?? '';
      }

      return params[paramName].toString();
    });
  }
}

/// Lightweight localized text facade passed through [EndpointTextScope].
///
/// Widgets receive one bundle per active language and can use either
/// [text] or the callable form for compact build-method copy lookup.
class EndpointTextBundle {
  final EndpointLanguage language;

  /// Creates a text bundle pinned to [language].
  const EndpointTextBundle(this.language);

  /// Resolves [key] using this bundle's language.
  ///
  /// Parameters are forwarded to [EndpointStrings.text] so interpolated labels
  /// stay consistent whether called from a context or directly from services.
  String text(EndpointTextKey key, {Map<String, Object?> params = const {}}) {
    return EndpointStrings.text(key, language: language, params: params);
  }

  /// Shorthand for [text], useful where a local `strings` variable is present.
  String call(EndpointTextKey key, {Map<String, Object?> params = const {}}) {
    return text(key, params: params);
  }
}

/// Inherited localization scope for migrated Endpoint UI.
///
/// The scope is intentionally simple: preferences decide the active language,
/// and widgets below the scope rebuild only when that language changes.
class EndpointTextScope extends InheritedWidget {
  final EndpointTextBundle strings;

  /// Places localized Endpoint copy above [child] for the selected [language].
  EndpointTextScope({
    super.key,
    required EndpointLanguage language,
    required super.child,
  }) : strings = EndpointTextBundle(language);

  /// Reads the closest text bundle, falling back to the default language.
  ///
  /// This keeps isolated widgets and tests usable even when they are rendered
  /// outside the app shell that normally provides [EndpointTextScope].
  static EndpointTextBundle of(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<EndpointTextScope>()
            ?.strings ??
        EndpointStrings.defaultBundle;
  }

  /// Rebuilds dependents only when the active language changes.
  @override
  bool updateShouldNotify(covariant EndpointTextScope oldWidget) {
    return strings.language != oldWidget.strings.language;
  }
}

/// Convenience localization accessors on Flutter build contexts.
extension EndpointTextContext on BuildContext {
  /// Returns the localized bundle for the nearest [EndpointTextScope].
  EndpointTextBundle get endpointText => EndpointTextScope.of(this);

  /// Resolves [key] from the nearest [EndpointTextScope].
  ///
  /// This is the preferred form inside build methods because it registers the
  /// widget as dependent on language changes.
  String tr(EndpointTextKey key, {Map<String, Object?> params = const {}}) {
    return endpointText.text(key, params: params);
  }
}
