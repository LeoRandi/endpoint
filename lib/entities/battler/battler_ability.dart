import '_imports.dart';

enum BattlerAbility {
  defend(
    label: 'Defender',
    tooltip: 'Consume el turno sin atacar.',
    isImplemented: true,
  ),
  overclock(
    label: 'Overclock',
    tooltip: 'TODO: aplicar una mejora temporal de ataque.',
    isImplemented: false,
  ),
  purge(
    label: 'Purge',
    tooltip: 'TODO: aplicar una habilidad ofensiva especial.',
    isImplemented: false,
  );

  final String label;
  final String tooltip;
  final bool isImplemented;

  const BattlerAbility({
    required this.label,
    required this.tooltip,
    required this.isImplemented,
  });

  static BattlerAbility fromLegacy(Object value) {
    if (value is BattlerAbility) return value;
    if (value is! String) {
      throw ArgumentError.value(value, 'value', 'Unsupported ability value.');
    }

    switch (value.trim().toLowerCase()) {
      case 'defender':
        return BattlerAbility.defend;
      case 'overclock':
        return BattlerAbility.overclock;
      case 'purge':
        return BattlerAbility.purge;
    }

    throw ArgumentError.value(value, 'value', 'Unknown battler ability.');
  }
}
