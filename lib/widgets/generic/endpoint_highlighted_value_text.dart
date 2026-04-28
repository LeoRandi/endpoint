import '../_imports.dart';

const _effectHealingAccent = EndpointPalette.primaryAccent;
const _effectAttackAccent = EndpointPalette.dangerAccent;
const _effectBarrierAccent = EndpointPalette.infoAccent;
const _effectBuffAccent = EndpointPalette.warningAccent;
const _effectDebuffAccent = Color(0xFFB77945);
const _effectBurnAccent = Color(0xFFFF8C42);
const _effectPoisonAccent = Color(0xFFC178FF);

final RegExp _highlightedValuePattern = RegExp(
  r'x\d+|[+-]?\d+(?:[.,]\d+)?(?:%|C)?',
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

  List<TextSpan> _buildSpans(TextStyle baseStyle) {
    final spans = <TextSpan>[];
    var cursor = 0;

    for (final match in _highlightedValuePattern.allMatches(data)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: data.substring(cursor, match.start)));
      }

      final token = data.substring(match.start, match.end);
      final accent = _accentForValue(match.start, match.end);
      spans.add(
        TextSpan(
          text: token,
          style: baseStyle.copyWith(
            color: accent,
            fontWeight: FontWeight.w800,
            shadows: [
              Shadow(
                color: accent.withValues(alpha: 0.34),
                blurRadius: 8,
              ),
            ],
          ),
        ),
      );
      cursor = match.end;
    }

    if (cursor < data.length) {
      spans.add(TextSpan(text: data.substring(cursor)));
    }

    return spans;
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
    final lowerData = data.toLowerCase();
    const maxDistance = 56.0;
    final midpoint = (start + end) / 2;
    final candidates = [
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
        patterns: ['barrera', 'blindaje'],
      ),
      const _ValueAccentCandidate(
        color: _effectHealingAccent,
        patterns: [
          'cura',
          'curas',
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
          'desventaja',
          'fragilidad',
          'interferencia',
          'conmocion',
        ],
      ),
      const _ValueAccentCandidate(
        color: _effectAttackAccent,
        patterns: [
          'daño',
          'daño',
          'atk',
          'ataque',
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

class _ValueAccentCandidate {
  final Color color;
  final List<String> patterns;

  const _ValueAccentCandidate({
    required this.color,
    required this.patterns,
  });
}
