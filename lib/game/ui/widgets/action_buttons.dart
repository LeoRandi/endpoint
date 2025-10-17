import 'package:flutter/material.dart';

class ActionButtons extends StatelessWidget {
  final VoidCallback onAttack;
  final VoidCallback onDefend;
  const ActionButtons({super.key, required this.onAttack, required this.onDefend});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(child: ElevatedButton(onPressed: onAttack, child: const Text('Atacar'))),
            const SizedBox(width: 12),
            Expanded(child: OutlinedButton(onPressed: onDefend, child: const Text('Defender'))),
          ],
        ),
      ),
    );
  }
}
