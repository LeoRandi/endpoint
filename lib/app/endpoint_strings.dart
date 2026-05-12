import '../services/endpoint_preferences_models.dart';
import 'package:flutter/widgets.dart';

enum EndpointTextKey {
  appTitle,
  continueRun,
  start,
  codex,
  settings,
  backToRoute,
  noItems,
  noSkills,
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
  settingsGameModeDrawing,
  settingsGameModePattern,
  settingsLanguageSpanish,
  settingsLanguageEnglish,
}

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
  static const noSkills = 'No tienes ninguna habilidad';
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
      EndpointTextKey.noSkills: 'No tienes ninguna habilidad',
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
          'Registro de objetos, enemigos, habilidades y eventos descubiertos.',
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
      EndpointTextKey.settingsGameModeClassic: 'Clasico',
      EndpointTextKey.settingsGameModeDrawing: 'Dibujo',
      EndpointTextKey.settingsGameModePattern: 'Patron',
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
      EndpointTextKey.noSkills: 'You have no skills',
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
          'Log of discovered items, enemies, skills, and events.',
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
      EndpointTextKey.settingsGameModeDrawing: 'Drawing',
      EndpointTextKey.settingsGameModePattern: 'Pattern',
      EndpointTextKey.settingsLanguageSpanish: 'Espanol',
      EndpointTextKey.settingsLanguageEnglish: 'English',
    },
  };

  static final RegExp _paramPattern = RegExp(r'\{([A-Za-z0-9_]+)\}');

  static EndpointTextKey languageKey(EndpointLanguage language) {
    return switch (language) {
      EndpointLanguage.spanish => EndpointTextKey.settingsLanguageSpanish,
      EndpointLanguage.english => EndpointTextKey.settingsLanguageEnglish,
    };
  }

  static EndpointTextKey gameModeKey(EndpointGameMode gameMode) {
    return switch (gameMode) {
      EndpointGameMode.classic => EndpointTextKey.settingsGameModeClassic,
      EndpointGameMode.drawing => EndpointTextKey.settingsGameModeDrawing,
      EndpointGameMode.pattern => EndpointTextKey.settingsGameModePattern,
    };
  }

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

class EndpointTextBundle {
  final EndpointLanguage language;

  const EndpointTextBundle(this.language);

  String text(
    EndpointTextKey key, {
    Map<String, Object?> params = const {},
  }) {
    return EndpointStrings.text(key, language: language, params: params);
  }

  String call(
    EndpointTextKey key, {
    Map<String, Object?> params = const {},
  }) {
    return text(key, params: params);
  }
}

class EndpointTextScope extends InheritedWidget {
  final EndpointTextBundle strings;

  EndpointTextScope({
    super.key,
    required EndpointLanguage language,
    required super.child,
  }) : strings = EndpointTextBundle(language);

  static EndpointTextBundle of(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<EndpointTextScope>()
            ?.strings ??
        EndpointStrings.defaultBundle;
  }

  @override
  bool updateShouldNotify(covariant EndpointTextScope oldWidget) {
    return strings.language != oldWidget.strings.language;
  }
}

extension EndpointTextContext on BuildContext {
  EndpointTextBundle get endpointText => EndpointTextScope.of(this);

  String tr(
    EndpointTextKey key, {
    Map<String, Object?> params = const {},
  }) {
    return endpointText.text(key, params: params);
  }
}
