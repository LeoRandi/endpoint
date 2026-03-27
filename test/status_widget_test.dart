import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:endpoint/entities/_exports.dart';
import 'package:endpoint/pages/path_selection/path_selection_page.dart';
import 'package:endpoint/widgets/path/path_node_card.dart';
import 'test_battler_factory.dart';

void main() {
  testWidgets(
    'status badge opens details and keeps remaining turns after combat',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PathSelectionPage(
            player: buildTestBattler(
              name: 'Player',
              attack: 5,
              defense: 1,
              health: 10,
              statuses: const [CalentandoStatus()],
            ),
            availableNodes: [
              CombatPathNode(
                enemy: buildTestBattler(
                  name: 'Enemy',
                  attack: 1,
                  defense: 0,
                  health: 4,
                ),
                tier: CombatNodeTier.green,
                label: 'Enemy',
              ),
            ],
            battleEnemyTurnDelay: const Duration(milliseconds: 10),
            battleCombatEndDelay: const Duration(milliseconds: 40),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 80));

      expect(find.byIcon(Icons.local_fire_department_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.local_fire_department_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 260));

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.text('Calentando'), findsOneWidget);
      expect(find.textContaining('Dano actual: +1'), findsOneWidget);
      expect(find.text('Duracion restante: 5 turnos'), findsOneWidget);

      await tester.tapAt(const Offset(12, 12));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 260));

      await tester.tap(find.byType(PathNodeCard).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 420));

      await tester.tap(find.text('Atacar'));
      await tester.pump();

      expect(find.text('COMBATE FINALIZADO'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 60));
      await tester.pump(const Duration(milliseconds: 420));

      expect(find.byType(PathNodeCard), findsOneWidget);

      await tester.tap(find.byIcon(Icons.local_fire_department_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 260));

      expect(find.textContaining('Dano actual: +2'), findsOneWidget);
      expect(find.text('Duracion restante: 4 turnos'), findsOneWidget);
    },
  );
}
