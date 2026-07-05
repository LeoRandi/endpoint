import '_imports.dart';

const _effectHealingAccent = EndpointPalette.primaryAccent;
const _effectAttackAccent = EndpointPalette.dangerAccent;
const _effectBarrierAccent = EndpointPalette.infoAccent;
const _effectBuffAccent = EndpointPalette.warningAccent;
const _effectDebuffAccent = Color(0xFFB77945);
const _effectBurnAccent = Color(0xFFFF8C42);
const _effectPoisonAccent = Color(0xFFC178FF);
const _effectContagionAccent = Color(0xFFB56DFF);
const _effectResonanceAccent = Color(0xFFD0D5DE);
const _effectChallengeAccent = Color(0xFF55D6C2);
const _effectWallAccent = Color(0xFFB8C0CC);

final RegExp _highlightedValuePattern = RegExp(
  r'x\d+|[+-]?\d+(?:[.,]\d+)?(?:%|C)?',
);
final RegExp _highlightedTermPattern = RegExp(
  r'\b(?:al usarse|usarse|patrones?|patrón|patron|puntos?|pp|desafio|desafío|desafÃ­o|resonancia|intoxicacion|intoxicación|intoxicaciÃ³n|quemaduras?|debuffs?|buffs?|potencia|calentando|ciclo|fragilidad|conmocion|conmoción|cúrate|curate|curar|curas?|curacion|curación|curaciÃ³n|recuperas?|recupera|heal|heals?|vida|hp|barrera|bloquear|bloqueas?|bloquea|bloqueo|shield|block|blocks?|daños?|danos?|ataques?|ataca(?:r|s)?|golpear|golpes?|atk|economia|economía|economÃ­a|income|creditos?|créditos?)\b',
  caseSensitive: false,
);

/// Renderiza descripciones mecanicas resaltando los importes numericos.
class EndpointHighlightedValueText extends StatelessWidget {
  final String data;
  final Iterable<EntityTag> tags;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final bool? softWrap;
  final TextOverflow? overflow;
  final TextDirection? textDirection;
  final Locale? locale;
  final StrutStyle? strutStyle;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final TextScaler? textScaler;

  static const _resonanceMetadata = _HighlightTermMetadata(
    accent: _effectResonanceAccent,
    icon: _HighlightIconSpec.material(Icons.graphic_eq_rounded),
    tooltip:
        'Resonancia: buff de carga defensiva acumulada. Algunos efectos la usan para infligir daño directo.',
  );
  static const _usedMetadata = _HighlightTermMetadata(
    accent: EndpointPalette.infoAccent,
    icon: _HighlightIconSpec.material(Icons.route_rounded),
    tooltip:
        'Al usarse: este efecto solo se activa si el punto donde esta equipado el item forma parte del Patron final que dibujas.',
  );
  static const _patternMetadata = _HighlightTermMetadata(
    accent: EndpointPalette.patternAccent,
    icon: _HighlightIconSpec.material(Icons.gesture_rounded),
    tooltip:
        'Patron: dibujo que trazas en la matriz durante tu turno. Sus puntos y orden pueden activar efectos.',
  );
  static const _challengeMetadata = _HighlightTermMetadata(
    accent: _effectChallengeAccent,
    icon: _HighlightIconSpec.material(Icons.sports_mma_rounded),
    tooltip:
        'Desafio: buff que guarda un golpe directo antes del siguiente ataque. Si llega al final del combate, cura.',
  );
  static const _contagionMetadata = _HighlightTermMetadata(
    accent: _effectContagionAccent,
    icon: _HighlightIconSpec.asset('assets/sprites/status/contagion.png'),
    tooltip:
        'Contagio: debuff permanente durante el combate. Cuando otro debuff se aplica al portador, aumenta ese debuff por su valor y Contagio baja en 1.',
  );
  static const _poisonMetadata = _HighlightTermMetadata(
    accent: _effectPoisonAccent,
    icon: _HighlightIconSpec.asset('assets/sprites/status/intox.png'),
    tooltip:
        'Intoxicacion: debuff. Hace daño al final del turno segun su valor, no baja por si solo, atraviesa Barrera y se limpia al terminar el combate.',
  );
  static const _burnMetadata = _HighlightTermMetadata(
    accent: _effectBurnAccent,
    icon: _HighlightIconSpec.asset('assets/sprites/status/quemadura.png'),
    tooltip:
        'Quemadura: debuff. Hace daño al inicio del turno del portador segun su duracion restante, baja con los turnos y su daño pasa primero por Barrera.',
  );
  static const _wallMetadata = _HighlightTermMetadata(
    accent: _effectWallAccent,
    icon: _HighlightIconSpec.material(Icons.linear_scale_rounded),
    tooltip:
        'Muralla: obstaculo del Patron. Bloquea el trazo entre puntos y puede ser creada, movida o destruida por efectos.',
  );
  static const _fragilityMetadata = _HighlightTermMetadata(
    accent: _effectDebuffAccent,
    icon: _HighlightIconSpec.asset('assets/sprites/status/fragilidad.png'),
    tooltip:
        'Fragilidad: debuff. Se acumula hasta 10. Si el objetivo recibe un ataque con 10, se limpia e inflige 10 daño directo que ignora Barrera.',
  );
  static const _concussionMetadata = _HighlightTermMetadata(
    accent: _effectDebuffAccent,
    icon: _HighlightIconSpec.material(Icons.flash_off_rounded),
    tooltip:
        'Conmocion: debuff. Reduce el daño del siguiente ataque del portador y luego desaparece.',
  );
  static const _debuffMetadata = _HighlightTermMetadata(
    accent: _effectDebuffAccent,
    icon: _HighlightIconSpec.material(Icons.warning_amber_rounded),
    tooltip:
        'Debuff: estado perjudicial. Puede reducir recursos, bloquear acciones o aplicar daño.',
  );
  static const _powerMetadata = _HighlightTermMetadata(
    accent: _effectBuffAccent,
    icon: _HighlightIconSpec.asset('assets/sprites/status/potencia.png'),
    tooltip:
        'Potencia: buff. Aumenta el daño de tus golpes durante este combate.',
  );
  static const _blindSpotMetadata = _HighlightTermMetadata(
    accent: _effectBuffAccent,
    icon: _HighlightIconSpec.asset('assets/sprites/status/puntociego.png'),
    tooltip:
        'Punto Ciego: buff que hace fallar los ataques enemigos contra el portador mientras permanezca activo.',
  );
  static const _warmingMetadata = _HighlightTermMetadata(
    accent: _effectBuffAccent,
    icon: _HighlightIconSpec.material(Icons.local_fire_department_rounded),
    tooltip:
        'Calentando: buff. Suma su valor al daño del siguiente ataque y luego se consume. Se limpia al terminar el combate.',
  );
  static const _buffMetadata = _HighlightTermMetadata(
    accent: _effectBuffAccent,
    icon: _HighlightIconSpec.material(Icons.auto_awesome_rounded),
    tooltip:
        'Buff: estado beneficioso. Mejora stats, guarda recursos o habilita efectos positivos.',
  );
  static const _cycleMetadata = _HighlightTermMetadata(
    accent: _effectBuffAccent,
    icon: _HighlightIconSpec.material(Icons.brightness_medium_rounded),
    tooltip: 'Ciclo: palabra clave de efectos que cambian entre dia y noche.',
  );
  static const _economyMetadata = _HighlightTermMetadata(
    accent: EndpointPalette.warningAccent,
    icon: _HighlightIconSpec.material(Icons.account_balance_wallet_rounded),
    tooltip:
        'Economia: recursos de creditos e income. Los creditos compran objetos y el income aumenta lo ganado.',
  );
  static const _healingMetadata = _HighlightTermMetadata(
    accent: _effectHealingAccent,
    icon: _HighlightIconSpec.asset('assets/sprites/status/vida.png'),
    tooltip:
        'Vida: salud del combatiente. Si llega a 0, el combatiente cae derrotado.',
  );
  static const _barrierMetadata = _HighlightTermMetadata(
    accent: _effectBarrierAccent,
    icon: _HighlightIconSpec.asset('assets/sprites/status/escudo.png'),
    tooltip:
        'Barrera: escudo que protege de la mayoria del daño. Se consume antes de la vida.',
  );
  static const _damageMetadata = _HighlightTermMetadata(
    accent: _effectAttackAccent,
    icon: _HighlightIconSpec.asset('assets/sprites/status/daño.png'),
    tooltip: 'DaÃ±o: cantidad que intenta quitar Barrera o vida al objetivo.',
  );
  static const _attackMetadata = _HighlightTermMetadata(
    accent: _effectAttackAccent,
    icon: _HighlightIconSpec.asset('assets/images/icons/icon_sword.png'),
    tooltip: 'Ataque: accion ofensiva que puede producir daño al objetivo.',
  );

  const EndpointHighlightedValueText(
    this.data, {
    super.key,
    this.tags = const [],
    this.style,
    this.textAlign,
    this.maxLines = 1,
    this.softWrap,
    this.overflow,
    this.textDirection,
    this.locale,
    this.strutStyle,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.textScaler,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = DefaultTextStyle.of(context).style.merge(style).copyWith(
          decoration: TextDecoration.none,
          decorationColor: Colors.transparent,
        );

    return RichText(
      text: TextSpan(style: baseStyle, children: _buildSpans(baseStyle)),
      textAlign: textAlign ?? TextAlign.start,
      maxLines: maxLines,
      softWrap: softWrap ?? true,
      overflow: overflow ?? TextOverflow.clip,
      textDirection: textDirection,
      locale: locale,
      strutStyle: strutStyle,
      textWidthBasis: textWidthBasis ?? TextWidthBasis.parent,
      textHeightBehavior: textHeightBehavior,
      textScaler: textScaler ?? MediaQuery.textScalerOf(context),
    );
  }

  List<InlineSpan> _buildSpans(TextStyle baseStyle) {
    final spans = <InlineSpan>[];
    final tokens = <_HighlightedToken>[];
    for (final match in _highlightedValuePattern.allMatches(data)) {
      final metadata = _metadataForValue(match.start, match.end);
      tokens.add(
        _HighlightedToken(
          start: match.start,
          end: match.end,
          accent: metadata?.accent ?? _fallbackAccentForValue(),
          metadata: metadata,
        ),
      );
    }
    for (final match in _highlightedTermPattern.allMatches(data)) {
      tokens.add(
        _HighlightedToken.term(
          start: match.start,
          end: match.end,
          metadata: _metadataForTerm(match.group(0) ?? ''),
        ),
      );
    }
    for (final match in RegExp(
      r'\bcontagio\b',
      caseSensitive: false,
    ).allMatches(data)) {
      tokens.add(
        _HighlightedToken.term(
          start: match.start,
          end: match.end,
          metadata: _metadataForTerm(match.group(0) ?? ''),
        ),
      );
    }
    for (final match in RegExp(
      r'\b(?:punto ciego|blind spots?|blindspot)\b',
      caseSensitive: false,
    ).allMatches(data)) {
      tokens.add(
        _HighlightedToken.term(
          start: match.start,
          end: match.end,
          metadata: _metadataForTerm(match.group(0) ?? ''),
        ),
      );
    }
    for (final match in RegExp(
      r'\bmurallas?\b',
      caseSensitive: false,
    ).allMatches(data)) {
      tokens.add(
        _HighlightedToken.term(
          start: match.start,
          end: match.end,
          metadata: _metadataForTerm(match.group(0) ?? ''),
        ),
      );
    }
    for (final match in RegExp(
      r'\b(?:patterns?|points?|challenge|resonance|poison|poisons?|poisoned|burns?|burned|burning|contagion|power|warming|cycle|fragility|concussion|healing|barriers?|shields?|blocking|damage|damages|attacks?|attacking|hits?|economy|credits?)\b',
      caseSensitive: false,
    ).allMatches(data)) {
      tokens.add(
        _HighlightedToken.term(
          start: match.start,
          end: match.end,
          metadata: _metadataForTerm(match.group(0) ?? ''),
        ),
      );
    }

    tokens.sort((left, right) {
      final startComparison = left.start.compareTo(right.start);
      if (startComparison != 0) return startComparison;
      return (right.end - right.start).compareTo(left.end - left.start);
    });
    var cursor = 0;

    for (final tokenMatch in tokens) {
      if (tokenMatch.start < cursor) continue;

      if (tokenMatch.start > cursor) {
        spans.add(TextSpan(text: data.substring(cursor, tokenMatch.start)));
      }

      final token = data.substring(tokenMatch.start, tokenMatch.end);
      final accent = tokenMatch.accent;
      final highlightedStyle = baseStyle.copyWith(
        color: accent,
        fontWeight: FontWeight.w800,
        shadows: [Shadow(color: accent.withValues(alpha: 0.34), blurRadius: 8)],
      );
      final metadata = tokenMatch.metadata;
      if (metadata == null) {
        spans.add(TextSpan(text: token, style: highlightedStyle));
      } else {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: _HighlightedTermToken(
              token: token,
              style: highlightedStyle,
              accent: accent,
              metadata: metadata,
              showIcon: tokenMatch.showIcon,
            ),
          ),
        );
      }
      cursor = tokenMatch.end;
    }

    if (cursor < data.length) {
      spans.add(TextSpan(text: data.substring(cursor)));
    }

    return spans;
  }

  Color _accentForTerm(String token) {
    final normalizedToken = token.normalizedHighlightText;

    if (normalizedToken.contains('resonancia') ||
        normalizedToken.contains('resonance')) {
      return _effectResonanceAccent;
    }
    if (normalizedToken.contains('usarse')) {
      return EndpointPalette.infoAccent;
    }
    if (normalizedToken.contains('desafio') ||
        normalizedToken.contains('challenge')) {
      return _effectChallengeAccent;
    }
    if (normalizedToken.contains('contagio') ||
        normalizedToken.contains('contagion')) {
      return _effectContagionAccent;
    }
    if (normalizedToken.contains('punto ciego') ||
        normalizedToken.contains('blind spot') ||
        normalizedToken.contains('blindspot')) {
      return _effectBuffAccent;
    }
    if (normalizedToken.contains('intoxicacion') ||
        normalizedToken.startsWith('poison')) {
      return _effectPoisonAccent;
    }
    if (normalizedToken.contains('quemadura') ||
        normalizedToken.startsWith('burn')) {
      return _effectBurnAccent;
    }
    if (normalizedToken.contains('muralla')) {
      return _effectWallAccent;
    }
    if (normalizedToken.startsWith('debuff')) {
      return _effectDebuffAccent;
    }
    if (normalizedToken.startsWith('buff')) {
      return _effectBuffAccent;
    }
    if (normalizedToken.startsWith('cur') ||
        normalizedToken.startsWith('heal') ||
        normalizedToken == 'vida' ||
        normalizedToken.startsWith('recupera')) {
      return _effectHealingAccent;
    }
    if (normalizedToken.contains('barrera') ||
        normalizedToken.startsWith('bloque') ||
        normalizedToken.startsWith('block') ||
        normalizedToken.startsWith('barrier') ||
        normalizedToken.startsWith('shield')) {
      return _effectBarrierAccent;
    }
    if (normalizedToken == 'atk' ||
        normalizedToken.startsWith('dano') ||
        normalizedToken.startsWith('atac') ||
        normalizedToken.startsWith('attack') ||
        normalizedToken.startsWith('damage') ||
        normalizedToken.startsWith('golp') ||
        normalizedToken.startsWith('hit')) {
      return _effectAttackAccent;
    }

    return EndpointPalette.rewardAccent;
  }

  _HighlightTermMetadata _metadataForTerm(String token) {
    final normalizedToken = token.normalizedHighlightText;

    if (normalizedToken.contains('resonancia') ||
        normalizedToken.contains('resonance')) {
      return _resonanceMetadata;
    }
    if (normalizedToken.contains('usarse')) {
      return _usedMetadata;
    }
    if (normalizedToken.contains('punto ciego') ||
        normalizedToken.contains('blind spot') ||
        normalizedToken.contains('blindspot')) {
      return _blindSpotMetadata;
    }
    if (normalizedToken.contains('patron') ||
        normalizedToken.startsWith('pattern') ||
        normalizedToken.startsWith('punto') ||
        normalizedToken.startsWith('point') ||
        normalizedToken == 'pp') {
      return _patternMetadata;
    }
    if (normalizedToken.contains('desafio') ||
        normalizedToken.contains('challenge')) {
      return _challengeMetadata;
    }
    if (normalizedToken.contains('contagio') ||
        normalizedToken.contains('contagion')) {
      return _contagionMetadata;
    }
    if (normalizedToken.contains('intoxicacion') ||
        normalizedToken.startsWith('poison')) {
      return _poisonMetadata;
    }
    if (normalizedToken.contains('quemadura') ||
        normalizedToken.startsWith('burn')) {
      return _burnMetadata;
    }
    if (normalizedToken.contains('muralla')) {
      return _wallMetadata;
    }
    if (normalizedToken.contains('fragilidad') ||
        normalizedToken.contains('fragility')) {
      return _fragilityMetadata;
    }
    if (normalizedToken.contains('conmocion') ||
        normalizedToken.contains('concussion')) {
      return _concussionMetadata;
    }
    if (normalizedToken.startsWith('debuff')) {
      return _debuffMetadata;
    }
    if (normalizedToken.contains('potencia') ||
        normalizedToken.contains('power')) {
      return _powerMetadata;
    }
    if (normalizedToken.contains('calentando') ||
        normalizedToken.contains('warming')) {
      return _warmingMetadata;
    }
    if (normalizedToken.startsWith('buff')) {
      return _buffMetadata;
    }
    if (normalizedToken.contains('ciclo') ||
        normalizedToken.contains('cycle')) {
      return _cycleMetadata;
    }
    if (normalizedToken.contains('economia') ||
        normalizedToken.contains('economy') ||
        normalizedToken == 'income' ||
        normalizedToken.startsWith('credito') ||
        normalizedToken.startsWith('credit')) {
      return _economyMetadata;
    }
    if (normalizedToken.startsWith('cur') ||
        normalizedToken.startsWith('heal') ||
        normalizedToken == 'vida' ||
        normalizedToken == 'hp' ||
        normalizedToken.startsWith('recupera')) {
      return _healingMetadata;
    }
    if (normalizedToken.contains('barrera') ||
        normalizedToken.startsWith('bloque') ||
        normalizedToken.startsWith('block') ||
        normalizedToken.startsWith('barrier') ||
        normalizedToken.startsWith('shield')) {
      return _barrierMetadata;
    }
    if (normalizedToken.startsWith('dano') ||
        normalizedToken.startsWith('damage')) {
      return _damageMetadata;
    }
    if (normalizedToken == 'atk' ||
        normalizedToken.startsWith('atac') ||
        normalizedToken.startsWith('attack') ||
        normalizedToken.startsWith('golp') ||
        normalizedToken.startsWith('hit')) {
      return _attackMetadata;
    }

    return _HighlightTermMetadata(
      accent: _accentForTerm(token),
      icon: const _HighlightIconSpec.material(Icons.info_outline_rounded),
      tooltip: 'Palabra clave de combate.',
    );
  }

  _HighlightTermMetadata? _metadataForValue(int start, int end) {
    final contextualMetadata = _nearestContextualMetadata(start, end);
    if (contextualMetadata != null) return contextualMetadata;

    return null;
  }

  Color _fallbackAccentForValue() {
    final tagSet = tags.toSet();
    if (tagSet.contains(EntityTag.intoxicacion)) {
      return _effectPoisonAccent;
    }
    if (tagSet.contains(EntityTag.quemadura)) {
      return _effectBurnAccent;
    }
    if (tagSet.contains(EntityTag.muralla)) {
      return _effectWallAccent;
    }
    if (tagSet.contains(EntityTag.barrera)) {
      return _effectBarrierAccent;
    }
    if (tagSet.contains(EntityTag.resonancia)) {
      return _effectResonanceAccent;
    }
    if (tagSet.contains(EntityTag.desafio)) {
      return _effectChallengeAccent;
    }
    if (tagSet.contains(EntityTag.contagio)) {
      return _effectContagionAccent;
    }
    if (tagSet.contains(EntityTag.vida)) {
      return _effectHealingAccent;
    }
    if (tagSet.contains(EntityTag.buff)) {
      return _effectBuffAccent;
    }
    if (tagSet.contains(EntityTag.debuff)) {
      return _effectDebuffAccent;
    }
    if (tagSet.contains(EntityTag.ataque)) {
      return _effectAttackAccent;
    }

    return EndpointPalette.rewardAccent;
  }

  _HighlightTermMetadata? _nearestContextualMetadata(int start, int end) {
    final lowerData = data.normalizedHighlightText;
    const maxDistance = 56.0;
    final midpoint = (start + end) / 2;
    const blindSpotPatterns = ['punto ciego', 'blind spot', 'blindspot'];
    for (final pattern in blindSpotPatterns) {
      var searchFrom = 0;
      while (searchFrom < lowerData.length) {
        final index = lowerData.indexOf(pattern, searchFrom);
        if (index < 0) break;

        final patternMidpoint = index + (pattern.length / 2);
        if ((midpoint - patternMidpoint).abs() <= maxDistance) {
          return _blindSpotMetadata;
        }
        searchFrom = index + pattern.length;
      }
    }
    final candidates = [
      const _ValueAccentCandidate(
        metadata: _patternMetadata,
        patterns: [
          'patron',
          'patrones',
          'pattern',
          'patterns',
          'punto',
          'puntos',
          'point',
          'points',
          'pp',
        ],
      ),
      const _ValueAccentCandidate(
        metadata: _resonanceMetadata,
        patterns: ['resonancia', 'resonance'],
      ),
      const _ValueAccentCandidate(
        metadata: _challengeMetadata,
        patterns: ['desafio', 'challenge'],
      ),
      const _ValueAccentCandidate(
        metadata: _contagionMetadata,
        patterns: ['contagio', 'contagion'],
      ),
      const _ValueAccentCandidate(
        metadata: _poisonMetadata,
        patterns: ['intoxicacion', 'poison', 'poisons'],
      ),
      const _ValueAccentCandidate(
        metadata: _burnMetadata,
        patterns: ['quemadura', 'quemaduras', 'burn', 'burns'],
      ),
      const _ValueAccentCandidate(
        metadata: _wallMetadata,
        patterns: ['muralla', 'murallas'],
      ),
      const _ValueAccentCandidate(
        metadata: _barrierMetadata,
        patterns: [
          'barrera',
          'blindaje',
          'bloquea',
          'bloquear',
          'bloqueo',
          'barrier',
          'barriers',
          'block',
          'blocks',
          'shield',
          'shields',
        ],
      ),
      const _ValueAccentCandidate(
        metadata: _healingMetadata,
        patterns: [
          'cura',
          'curas',
          'curar',
          'curacion',
          'recupera',
          'recuperas',
          'hp',
          'vida',
          'drena',
          'heal',
          'heals',
          'healing',
        ],
      ),
      const _ValueAccentCandidate(
        metadata: _powerMetadata,
        patterns: ['potencia', 'power'],
      ),
      const _ValueAccentCandidate(
        metadata: _fragilityMetadata,
        patterns: ['fragilidad', 'fragility'],
      ),
      const _ValueAccentCandidate(
        metadata: _buffMetadata,
        patterns: [
          'calentando',
          'warming',
          'buff',
          'reserva',
        ],
      ),
      const _ValueAccentCandidate(
        metadata: _debuffMetadata,
        patterns: [
          'debuff',
          'debuffs',
          'desventaja',
          'conmocion',
          'concussion',
        ],
      ),
      const _ValueAccentCandidate(
        metadata: _damageMetadata,
        patterns: [
          'dano',
          'damage',
          'damages',
        ],
      ),
      const _ValueAccentCandidate(
        metadata: _attackMetadata,
        patterns: [
          'atk',
          'ataque',
          'ataques',
          'attack',
          'attacks',
          'attacking',
          'ataca',
          'atacar',
          'atacas',
          'golpe',
          'golpes',
          'hit',
          'hits',
        ],
      ),
    ];
    _HighlightTermMetadata? bestMetadata;
    var bestDistance = double.infinity;

    for (final candidate in candidates) {
      for (final pattern in candidate.patterns) {
        var searchFrom = 0;
        while (searchFrom < lowerData.length) {
          final index = lowerData.indexOf(pattern, searchFrom);
          if (index < 0) break;

          final patternMidpoint = index + (pattern.length / 2);
          final distance = (midpoint - patternMidpoint).abs();
          if (distance < bestDistance) {
            bestDistance = distance;
            bestMetadata = candidate.metadata;
          }
          searchFrom = index + pattern.length;
        }
      }
    }

    if (bestDistance <= maxDistance) return bestMetadata;
    return null;
  }
}

class _HighlightedToken {
  final int start;
  final int end;
  final Color? _valueAccent;
  final _HighlightTermMetadata? metadata;
  final bool showIcon;

  _HighlightedToken({
    required this.start,
    required this.end,
    required Color accent,
    this.metadata,
  })  : _valueAccent = accent,
        showIcon = metadata != null;

  _HighlightedToken.term({
    required this.start,
    required this.end,
    required this.metadata,
  })  : _valueAccent = null,
        showIcon = metadata?.icon.assetPath != null;

  Color get accent =>
      metadata?.accent ?? _valueAccent ?? EndpointPalette.rewardAccent;
}

class _HighlightedTermToken extends StatelessWidget {
  final String token;
  final TextStyle style;
  final Color accent;
  final _HighlightTermMetadata metadata;
  final bool showIcon;

  const _HighlightedTermToken({
    required this.token,
    required this.style,
    required this.accent,
    required this.metadata,
    required this.showIcon,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize =
        ((style.fontSize ?? 14) * 0.86).clamp(10.0, 15.0).toDouble();

    return Tooltip(
      message: metadata.tooltip,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (showIcon) ...[
              _HighlightIcon(
                spec: metadata.icon,
                color: accent,
                size: iconSize,
              ),
              const SizedBox(width: 2),
            ],
            Text(token, style: style),
          ],
        ),
      ),
    );
  }
}

class _HighlightIcon extends StatelessWidget {
  final _HighlightIconSpec spec;
  final Color color;
  final double size;

  const _HighlightIcon({
    required this.spec,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final assetPath = spec.assetPath;
    if (assetPath != null) {
      return Image.asset(
        assetPath,
        width: size,
        height: size,
        color: color,
        filterQuality: FilterQuality.none,
        errorBuilder: (context, error, stackTrace) {
          return Icon(Icons.image_not_supported_rounded,
              color: color, size: size);
        },
      );
    }

    return Icon(spec.icon!, color: color, size: size);
  }
}

class _HighlightTermMetadata {
  final Color accent;
  final _HighlightIconSpec icon;
  final String tooltip;

  const _HighlightTermMetadata({
    required this.accent,
    required this.icon,
    required this.tooltip,
  });
}

class _HighlightIconSpec {
  final IconData? icon;
  final String? assetPath;

  const _HighlightIconSpec.material(this.icon) : assetPath = null;

  const _HighlightIconSpec.asset(this.assetPath) : icon = null;
}

class _ValueAccentCandidate {
  final _HighlightTermMetadata metadata;
  final List<String> patterns;

  const _ValueAccentCandidate({required this.metadata, required this.patterns});
}

extension _HighlightTextNormalization on String {
  String get normalizedHighlightText {
    return toLowerCase()
        .replaceAll('ó', 'o')
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n')
        .replaceAll('Ã³', 'o')
        .replaceAll('Ã¡', 'a')
        .replaceAll('Ã©', 'e')
        .replaceAll('Ã­', 'i')
        .replaceAll('Ãº', 'u')
        .replaceAll('Ã±', 'n');
  }
}
