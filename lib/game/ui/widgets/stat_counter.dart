import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';

class StatCounter extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final bool enabled;
  final String? hintText; // texto gris opcional al lado del label
  final ValueChanged<int> onChanged;

  const StatCounter({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 999,
    this.step = 1,
    this.enabled = true,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    final canDec = enabled && (value - step >= min);
    final canInc = enabled && (value + step <= max);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                if (hintText != null)
                  Text(
                    hintText!,
                    style: TextStyle(color: Theme.of(context).hintColor),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: canDec ? () => onChanged(value - step) : null,
            icon: const Icon(Icons.remove),
            tooltip: 'Bajar',
          ),
          SizedBox(
            width: 48,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
            ),
          ),
          IconButton(
            onPressed: canInc ? () => onChanged(value + step) : null,
            icon: const Icon(Icons.add),
            tooltip: 'Subir',
          ),
        ],
      ),
    );
  }
}
