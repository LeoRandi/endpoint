import 'dart:ui';

import 'package:flutter/material.dart';

class StatCounter extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;

  const StatCounter({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 999,
    this.step = 1,
  });

  @override
  Widget build(BuildContext context) {
    final canDec = value - step >= min;
    final canInc = value + step <= max;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
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
