import 'package:flutter/material.dart';
import '../../domain/player.dart';
import '../../domain/enemy.dart';
import '../../domain/party.dart';
import '../../services/battle_state.dart';
import '../../services/combat_engine.dart';
import '../widgets/message_log.dart';
import '../widgets/action_buttons.dart';

class BattleScreen extends StatefulWidget {
  const BattleScreen({super.key});

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  late final BattleState state;
  late final CombatEngine engine;
  final controller = MessageLogController();

  @override
  void initState() {
    super.initState();
    final party = Party(players: [Player.basic(name: 'Héroe')]);
    final foes = [Enemy.basic(name: 'Slime')];
    state = BattleState.fromParties(party: party, enemies: foes);
    engine = CombatEngine(state: state, onLog: controller.add);
    controller.add('¡Empieza el combate!');
  }

  void _onAttack() {
    engine.playerBasicAttack();
    setState(() {});
  }

  void _onDefend() {
    engine.playerDefend();
    setState(() {});
  }

  void _finishBattle() {
    // Vuelve a la pantalla de inicio
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final outcome = state.outcome;

    // Mostrar stats de la primera unidad viva si existe; si no, “—”
    String heroLine() {
      final alive = state.party.players.where((p) => p.isAlive).toList();
      if (alive.isEmpty) return 'Héroe: —';
      final h = alive.first;
      return 'Héroe: ${h.name} HP ${h.currentHp}/${h.stats.maxHp}';
    }

    String foeLine() {
      final alive = state.enemies.where((e) => e.isAlive).toList();
      if (alive.isEmpty) return 'Enemigo: —';
      final f = alive.first;
      return 'Enemigo: ${f.name} HP ${f.currentHp}/${f.stats.maxHp}';
    }

    Widget bottomArea;
    if (outcome == BattleOutcome.ongoing) {
      bottomArea = ActionButtons(onAttack: _onAttack, onDefend: _onDefend);
    } else {
      final text = outcome == BattleOutcome.victory ? '¡Victoria!' : 'Has sido derrotado...';
      bottomArea = SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _finishBattle,
                  child: const Text('Terminar combate'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Combate')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(heroLine()),
                Text(foeLine()),
                const SizedBox(height: 12),
                MessageLog(controller: controller),
              ],
            ),
          ),
          bottomArea,
        ],
      ),
    );
  }
}
