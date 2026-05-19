import '../_imports.dart';

const _effectHealingAccent = EndpointPalette.primaryAccent;
const _effectAttackAccent = EndpointPalette.dangerAccent;
const _effectBarrierAccent = EndpointPalette.infoAccent;
const _effectBuffAccent = EndpointPalette.warningAccent;
const _effectDebuffAccent = Color(0xFFB77945);
const _effectBurnAccent = Color(0xFFFF8C42);
const _effectPoisonAccent = Color(0xFFC178FF);
const _effectResonanceAccent = Color(0xFFD0D5DE);
const _effectChallengeAccent = Color(0xFF55D6C2);

final RegExp _highlightedValuePattern = RegExp(
  r'x\d+|[+-]?\d+(?:[.,]\d+)?(?:%|C)?',
);
final RegExp _highlightedTermPattern = RegExp(
  r'\b(?:al usarse|usarse|desafio|desafío|desafÃ­o|resonancia|intoxicacion|intoxicación|intoxicaciÃ³n|quemaduras?|debuffs?|buffs?|potencia|calentando|inercia|ciclo|fragilidad|conmocion|conmoción|curar|curas?|curacion|curación|curaciÃ³n|recuperas?|recupera|vida|hp|barrera|bloquear|bloqueas?|bloquea|bloqueo|daño|daÃ±o|dano|ataques?|atacar|atacas|atk|economia|economía|economÃ­a|income|creditos?|créditos?)\b',
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
      text: TextSpan(
        style: baseStyle,
        children: _buildSpans(baseStyle),
      ),
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
    final tokens = <_HighlightedToken>[
      for (final match in _highlightedValuePattern.allMatches(data))
        _HighlightedToken(
          start: match.start,
          end: match.end,
          accent: _accentForValue(match.start, match.end),
        ),
      for (final match in _highlightedTermPattern.allMatches(data))
        _HighlightedToken.term(
          start: match.start,
          end: match.end,
          term: _metadataForTerm(match.group(0) ?? ''),
        ),
    ]..sort((left, right) {
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
        shadows: [
          Shadow(
            color: accent.withValues(alpha: 0.34),
            blurRadius: 8,
          ),
        ],
      );
      final term = tokenMatch.term;
      if (term == null) {
        spans.add(
          TextSpan(
            text: token,
            style: highlightedStyle,
          ),
        );
      } else {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: _HighlightedTermToken(
              token: token,
              style: highlightedStyle,
              accent: accent,
              metadata: term,
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
    final normalizedToken = token
        .toLowerCase()
        .replaceAll('ó', 'o')
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n');

    if (normalizedToken.contains('resonancia')) {
      return _effectResonanceAccent;
    }
    if (normalizedToken.contains('usarse')) {
      return EndpointPalette.infoAccent;
    }
    if (normalizedToken.contains('desafio')) {
      return _effectChallengeAccent;
    }
    if (normalizedToken.contains('intoxicacion')) {
      return _effectPoisonAccent;
    }
    if (normalizedToken.contains('quemadura')) {
      return _effectBurnAccent;
    }
    if (normalizedToken.startsWith('debuff')) {
      return _effectDebuffAccent;
    }
    if (normalizedToken.startsWith('buff')) {
      return _effectBuffAccent;
    }
    if (normalizedToken.startsWith('cur') ||
        normalizedToken == 'vida' ||
        normalizedToken.startsWith('recupera')) {
      return _effectHealingAccent;
    }
    if (normalizedToken.contains('barrera') ||
        normalizedToken.startsWith('bloque')) {
      return _effectBarrierAccent;
    }
    if (normalizedToken == 'atk' ||
        normalizedToken == 'dano' ||
        normalizedToken.startsWith('atac')) {
      return _effectAttackAccent;
    }

    return EndpointPalette.rewardAccent;
  }

  _HighlightTermMetadata _metadataForTerm(String token) {
    final normalizedToken = token.normalizedHighlightText;

    if (normalizedToken.contains('resonancia')) {
      return const _HighlightTermMetadata(
        accent: _effectResonanceAccent,
        icon: _HighlightIconSpec.material(Icons.graphic_eq_rounded),
        tooltip:
            'Resonancia: buff de carga defensiva acumulada. Algunos efectos la usan para infligir daño directo.',
      );
    }
    if (normalizedToken.contains('usarse')) {
      return const _HighlightTermMetadata(
        accent: EndpointPalette.infoAccent,
        icon: _HighlightIconSpec.material(Icons.route_rounded),
        tooltip:
            'Al usarse: este efecto solo se activa si el punto donde esta equipado el item forma parte del Patron final que dibujas.',
      );
    }
    if (normalizedToken.contains('desafio')) {
      return const _HighlightTermMetadata(
        accent: _effectChallengeAccent,
        icon: _HighlightIconSpec.material(Icons.sports_mma_rounded),
        tooltip:
            'Desafio: buff que guarda un golpe directo antes del siguiente ataque. Si llega al final del combate, cura.',
      );
    }
    if (normalizedToken.contains('intoxicacion')) {
      return const _HighlightTermMetadata(
        accent: _effectPoisonAccent,
        icon: _HighlightIconSpec.material(Icons.science_rounded),
        tooltip:
            'Intoxicacion: debuff. Hace daño al final del turno segun su valor, no baja por si solo, atraviesa Barrera y se limpia al terminar el combate.',
      );
    }
    if (normalizedToken.contains('quemadura')) {
      return const _HighlightTermMetadata(
        accent: _effectBurnAccent,
        icon: _HighlightIconSpec.material(Icons.whatshot_rounded),
        tooltip:
            'Quemadura: debuff. Hace daño al inicio del turno del portador segun su duracion restante, baja con los turnos y su daño pasa primero por Barrera.',
      );
    }
    if (normalizedToken.contains('fragilidad')) {
      return const _HighlightTermMetadata(
        accent: _effectDebuffAccent,
        icon: _HighlightIconSpec.material(Icons.flash_on_outlined),
        tooltip:
            'Fragilidad: debuff. Se acumula hasta 10. Si el objetivo recibe un ataque con 10, se limpia e inflige 10 daño directo que ignora Barrera.',
      );
    }
    if (normalizedToken.contains('conmocion')) {
      return const _HighlightTermMetadata(
        accent: _effectDebuffAccent,
        icon: _HighlightIconSpec.material(Icons.flash_off_rounded),
        tooltip:
            'Conmocion: debuff. Reduce el daño del siguiente ataque del portador y luego desaparece.',
      );
    }
    if (normalizedToken.startsWith('debuff')) {
      return const _HighlightTermMetadata(
        accent: _effectDebuffAccent,
        icon: _HighlightIconSpec.material(Icons.warning_amber_rounded),
        tooltip:
            'Debuff: estado perjudicial. Puede reducir recursos, bloquear acciones o aplicar daño.',
      );
    }
    if (normalizedToken.contains('potencia')) {
      return const _HighlightTermMetadata(
        accent: _effectBuffAccent,
        icon: _HighlightIconSpec.material(Icons.bolt_rounded),
        tooltip:
            'Potencia: buff. Aumenta el daño del siguiente golpe en su valor y luego se consume.',
      );
    }
    if (normalizedToken.contains('calentando')) {
      return const _HighlightTermMetadata(
        accent: _effectBuffAccent,
        icon: _HighlightIconSpec.material(Icons.local_fire_department_rounded),
        tooltip:
            'Calentando: buff. Suma su valor al daño del siguiente ataque y luego se consume. Se limpia al terminar el combate.',
      );
    }
    if (normalizedToken.contains('inercia')) {
      return const _HighlightTermMetadata(
        accent: _effectBuffAccent,
        icon: _HighlightIconSpec.material(Icons.motion_photos_on_rounded),
        tooltip:
            'Inercia: buff. Al final de tu turno genera una reserva temporal de ATK o Barrera.',
      );
    }
    if (normalizedToken.startsWith('buff')) {
      return const _HighlightTermMetadata(
        accent: _effectBuffAccent,
        icon: _HighlightIconSpec.material(Icons.auto_awesome_rounded),
        tooltip:
            'Buff: estado beneficioso. Mejora stats, guarda recursos o habilita efectos positivos.',
      );
    }
    if (normalizedToken.contains('ciclo')) {
      return const _HighlightTermMetadata(
        accent: _effectBuffAccent,
        icon: _HighlightIconSpec.material(Icons.brightness_medium_rounded),
        tooltip:
            'Ciclo: palabra clave de efectos que cambian entre dia y noche.',
      );
    }
    if (normalizedToken.contains('economia') ||
        normalizedToken == 'income' ||
        normalizedToken.startsWith('credito')) {
      return const _HighlightTermMetadata(
        accent: EndpointPalette.warningAccent,
        icon: _HighlightIconSpec.material(Icons.account_balance_wallet_rounded),
        tooltip:
            'Economia: recursos de creditos e income. Los creditos compran objetos y el income aumenta lo ganado.',
      );
    }
    if (normalizedToken.startsWith('cur') ||
        normalizedToken == 'vida' ||
        normalizedToken == 'hp' ||
        normalizedToken.startsWith('recupera')) {
      return const _HighlightTermMetadata(
        accent: _effectHealingAccent,
        icon: _HighlightIconSpec.asset('assets/images/icons/icon_health.png'),
        tooltip:
            'Vida: salud del combatiente. Si llega a 0, el combatiente cae derrotado.',
      );
    }
    if (normalizedToken.contains('barrera') ||
        normalizedToken.startsWith('bloque')) {
      return const _HighlightTermMetadata(
        accent: _effectBarrierAccent,
        icon: _HighlightIconSpec.asset('assets/images/icons/icon_shield.png'),
        tooltip:
            'Barrera: escudo que protege de la mayoria del daño. Se consume antes de la vida.',
      );
    }
    if (normalizedToken == 'atk' ||
        normalizedToken == 'dano' ||
        normalizedToken.startsWith('atac')) {
      return const _HighlightTermMetadata(
        accent: _effectAttackAccent,
        icon: _HighlightIconSpec.asset('assets/images/icons/icon_sword.png'),
        tooltip:
            'Ataque/daño: cantidad ofensiva que intenta quitar Barrera o vida al objetivo.',
      );
    }

    return _HighlightTermMetadata(
      accent: _accentForTerm(token),
      icon: const _HighlightIconSpec.material(Icons.info_outline_rounded),
      tooltip: 'Palabra clave de combate.',
    );
  }

  Color _accentForValue(int start, int end) {
    final tagSet = tags.toSet();
    final contextualAccent = _nearestContextualAccent(start, end);
    if (contextualAccent != null) return contextualAccent;

    if (tagSet.contains(EntityTag.intoxicacion)) {
      return _effectPoisonAccent;
    }
    if (tagSet.contains(EntityTag.quemadura)) {
      return _effectBurnAccent;
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

  Color? _nearestContextualAccent(int start, int end) {
    final lowerData = data.normalizedHighlightText;
    const maxDistance = 56.0;
    final midpoint = (start + end) / 2;
    final candidates = [
      const _ValueAccentCandidate(
        color: _effectResonanceAccent,
        patterns: ['resonancia'],
      ),
      const _ValueAccentCandidate(
        color: _effectChallengeAccent,
        patterns: ['desafio'],
      ),
      const _ValueAccentCandidate(
        color: _effectPoisonAccent,
        patterns: ['intoxicacion'],
      ),
      const _ValueAccentCandidate(
        color: _effectBurnAccent,
        patterns: ['quemadura'],
      ),
      const _ValueAccentCandidate(
        color: _effectBarrierAccent,
        patterns: ['barrera', 'blindaje', 'bloquea', 'bloquear', 'bloqueo'],
      ),
      const _ValueAccentCandidate(
        color: _effectHealingAccent,
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
        ],
      ),
      const _ValueAccentCandidate(
        color: _effectBuffAccent,
        patterns: [
          'potencia',
          'calentando',
          'inercia',
          'buff',
          'reserva',
        ],
      ),
      const _ValueAccentCandidate(
        color: _effectDebuffAccent,
        patterns: [
          'debuff',
          'debuffs',
          'desventaja',
          'fragilidad',
          'conmocion',
        ],
      ),
      const _ValueAccentCandidate(
        color: _effectAttackAccent,
        patterns: [
          'dano',
          'atk',
          'ataque',
          'ataques',
          'atacar',
          'atacas',
          'golpe',
        ],
      ),
    ];
    Color? bestColor;
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
            bestColor = candidate.color;
          }
          searchFrom = index + pattern.length;
        }
      }
    }

    if (bestDistance <= maxDistance) return bestColor;
    return null;
  }
}

class _HighlightedToken {
  final int start;
  final int end;
  final Color? _valueAccent;
  final _HighlightTermMetadata? term;

  const _HighlightedToken({
    required this.start,
    required this.end,
    required Color accent,
  })  : _valueAccent = accent,
        term = null;

  const _HighlightedToken.term({
    required this.start,
    required this.end,
    required this.term,
  }) : _valueAccent = null;

  Color get accent =>
      term?.accent ?? _valueAccent ?? EndpointPalette.rewardAccent;
}

class _HighlightedTermToken extends StatelessWidget {
  final String token;
  final TextStyle style;
  final Color accent;
  final _HighlightTermMetadata metadata;

  const _HighlightedTermToken({
    required this.token,
    required this.style,
    required this.accent,
    required this.metadata,
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
            _HighlightIcon(
              spec: metadata.icon,
              color: accent,
              size: iconSize,
            ),
            const SizedBox(width: 2),
            Text(
              token,
              style: style,
            ),
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
      );
    }

    return Icon(
      spec.icon!,
      color: color,
      size: size,
    );
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
  final Color color;
  final List<String> patterns;

  const _ValueAccentCandidate({
    required this.color,
    required this.patterns,
  });
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
