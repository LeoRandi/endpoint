import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:endpoint/entities/_exports.dart';
import 'package:endpoint/main.dart';
import 'package:endpoint/pages/battle/battle_page.dart';
import 'package:endpoint/pages/path_selection/path_selection_page.dart';
import 'package:endpoint/widgets/path/path_node_card.dart';

void main() {
  testWidgets('main menu renders title and actions',
      (WidgetTester tester) async {
    await tester.pumpWidget(const Endpoint());

    expect(find.text('ENDPOINT'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Codex'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('start opens path selection screen with nodes and controls',
      (WidgetTester tester) async {
    await tester.pumpWidget(const Endpoint());

    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();

    expect(find.text('SELECCION DE RUTA'), findsOneWidget);
    expect(find.text('Operativos'), findsOneWidget);
    expect(find.text('Objetos'), findsOneWidget);
    expect(find.byType(PathNodeCard), findsNWidgets(3));
  });

  testWidgets('tooltip appears only while holding a button',
      (WidgetTester tester) async {
    await tester.pumpWidget(const Endpoint());

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Start')),
    );
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));

    expect(find.text('Abrir rutas de encuentro'), findsOneWidget);

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Abrir rutas de encuentro'), findsNothing);
  });

  testWidgets('path node opens battle screen with title and action buttons',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PathSelectionPage(
          availableNodes: [
            CombatPathNode(
              enemy: Battler.legacy(
                name: 'Enemy',
                attack: 4,
                defense: 1,
                health: 8,
              ),
              tier: CombatNodeTier.green,
              label: 'Enemy',
            ),
          ],
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byType(PathNodeCard).first);
    await tester.pump();

    expect(find.text('!Un enemigo aparece!'), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('Atacar'), findsOneWidget);
    expect(find.text('Habilidades'), findsOneWidget);
    expect(find.text('Huir'), findsOneWidget);
    expect(find.text('Objetos'), findsOneWidget);
  });

  testWidgets('camp site heals player and returns to path selection',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PathSelectionPage(
          player: Battler.legacy(
            name: 'Player',
            attack: 3,
            defense: 1,
            health: 4,
            maxHealth: 10,
          ),
          availableNodes: const [
            PathNode.campSite(),
          ],
        ),
      ),
    );

    expect(find.text('4 / 10'), findsOneWidget);
    expect(find.text('Acampada'), findsNWidgets(3));

    await tester.tap(find.byType(PathNodeCard).first);
    await tester.pump();

    expect(find.text('!Has encontrado una zona de acampada!'), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('ZONA DE ACAMPADA'), findsOneWidget);
    expect(find.text('4 / 10  ->  9 / 10'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.text('SELECCION DE RUTA'), findsOneWidget);
    expect(find.text('9 / 10'), findsOneWidget);
  });

  testWidgets('attack damages enemy and enemy answers on its turn',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BattlePage(
          enemy: Battler.legacy(
            name: 'Enemy',
            attack: 6,
            defense: 5,
            health: 12,
          ),
          player: Battler.legacy(
            name: 'Player',
            attack: 9,
            defense: 4,
            health: 15,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('12 / 12'), findsOneWidget);
    expect(find.text('15 / 15'), findsOneWidget);
    expect(find.text('TURNO DEL JUGADOR'), findsOneWidget);

    await tester.tap(find.text('Atacar'));
    await tester.pump();

    expect(find.text('8 / 12'), findsOneWidget);
    expect(find.text('TURNO ENEMIGO'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 950));

    expect(find.text('13 / 15'), findsOneWidget);
    expect(find.text('TURNO DEL JUGADOR'), findsOneWidget);
  });

  testWidgets('huir returns to the first route immediately',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PathSelectionPage(
                          availableNodes: [
                            CombatPathNode(
                              enemy: Battler.legacy(
                                name: 'Enemy',
                                attack: 4,
                                defense: 1,
                                health: 8,
                              ),
                              tier: CombatNodeTier.green,
                              label: 'Enemy',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: const Text('Open Path'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open Path'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PathNodeCard).first);
    await tester.pump();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Huir'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('Open Path'), findsOneWidget);
  });

  testWidgets(
      'weapon shop node opens shop title and close returns to path selection',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PathSelectionPage(
          availableNodes: [
            PathNode.weaponShop(),
          ],
        ),
      ),
    );

    expect(find.text('Tienda'), findsNWidgets(3));

    await tester.tap(find.byType(PathNodeCard).first);
    await tester.pump();

    expect(find.text('!Bienvenido a la tienda!'), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('TIENDA DE ARMAS'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.text('SELECCION DE RUTA'), findsOneWidget);
    expect(find.byType(PathNodeCard), findsNWidgets(3));
  });

  testWidgets('path objetos opens an empty route inventory dialog',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PathSelectionPage(),
      ),
    );

    await tester.tap(find.text('Objetos'));
    await tester.pumpAndSettle();

    expect(find.text('Inventario de ruta'), findsOneWidget);
    expect(find.text('No tienes ningun objeto'), findsOneWidget);
    expect(find.text('Cerrar'), findsOneWidget);

    await tester.tap(find.text('Cerrar'));
    await tester.pumpAndSettle();

    expect(find.text('Inventario de ruta'), findsNothing);
  });

  testWidgets('objetos opens an empty inventory dialog',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: BattlePage(),
      ),
    );

    await tester.tap(find.text('Objetos'));
    await tester.pumpAndSettle();

    expect(find.text('Objetos'), findsNWidgets(2));
    expect(find.text('No tienes ningun objeto'), findsOneWidget);
    expect(find.text('Cerrar'), findsOneWidget);

    await tester.tap(find.text('Cerrar'));
    await tester.pumpAndSettle();

    expect(find.text('No tienes ningun objeto'), findsNothing);
  });

  testWidgets('habilidades opens floating menu and defender spends turn',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BattlePage(
          enemy: Battler.legacy(
            name: 'Enemy',
            attack: 5,
            defense: 1,
            health: 10,
          ),
          player: Battler.legacy(
            name: 'Player',
            attack: 4,
            defense: 2,
            health: 10,
            abilities: ['Defender'],
          ),
          enemyTurnDelay: const Duration(milliseconds: 50),
        ),
      ),
    );

    await tester.tap(find.text('Habilidades'));
    await tester.pumpAndSettle();

    expect(find.text('Defender'), findsOneWidget);

    await tester.tap(find.text('Defender'));
    await tester.pump();

    expect(find.text('TURNO ENEMIGO'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 80));

    expect(find.text('7 / 10'), findsOneWidget);
    expect(find.text('TURNO DEL JUGADOR'), findsOneWidget);
  });

  testWidgets('combat returns to the main route after a kill',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BattlePage(
                          enemy: Battler.legacy(
                            name: 'Enemy',
                            attack: 1,
                            defense: 0,
                            health: 1,
                          ),
                          player: Battler.legacy(
                            name: 'Player',
                            attack: 1,
                            defense: 0,
                            health: 1,
                          ),
                          enemyTurnDelay: Duration.zero,
                          combatEndDelay: const Duration(milliseconds: 250),
                        ),
                      ),
                    );
                  },
                  child: const Text('Open Battle'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open Battle'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Atacar'));
    await tester.pump();

    expect(find.text('COMBATE FINALIZADO'), findsOneWidget);
    expect(find.text('Objetivo neutralizado.'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('Open Battle'), findsOneWidget);
  });

  testWidgets('path keeps player health after combat',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PathSelectionPage(
          player: Battler.legacy(
            name: 'Player',
            attack: 3,
            defense: 0,
            health: 10,
          ),
          availableNodes: [
            CombatPathNode(
              enemy: Battler.legacy(
                name: 'Enemy',
                attack: 2,
                defense: 0,
                health: 5,
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

    expect(find.text('10 / 10'), findsOneWidget);

    await tester.tap(find.byType(PathNodeCard).first);
    await tester.pump();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Atacar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    await tester.tap(find.text('Atacar'));
    await tester.pump();

    expect(find.text('COMBATE FINALIZADO'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 60));
    await tester.pumpAndSettle();

    expect(find.text('SELECCION DE RUTA'), findsOneWidget);
    expect(find.text('8 / 10'), findsOneWidget);
  });

  testWidgets('player defeat from path returns to the main route',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PathSelectionPage(
                          player: Battler.legacy(
                            name: 'Player',
                            attack: 1,
                            defense: 0,
                            health: 2,
                          ),
                          availableNodes: [
                            CombatPathNode(
                              enemy: Battler.legacy(
                                name: 'Enemy',
                                attack: 4,
                                defense: 0,
                                health: 6,
                              ),
                              tier: CombatNodeTier.green,
                              label: 'Enemy',
                            ),
                            CombatPathNode(
                              enemy: Battler.legacy(
                                name: 'Enemy',
                                attack: 4,
                                defense: 0,
                                health: 6,
                              ),
                              tier: CombatNodeTier.green,
                              label: 'Enemy',
                            ),
                            CombatPathNode(
                              enemy: Battler.legacy(
                                name: 'Enemy',
                                attack: 4,
                                defense: 0,
                                health: 6,
                              ),
                              tier: CombatNodeTier.green,
                              label: 'Enemy',
                            ),
                          ],
                          battleEnemyTurnDelay:
                              const Duration(milliseconds: 10),
                          battleCombatEndDelay:
                              const Duration(milliseconds: 40),
                        ),
                      ),
                    );
                  },
                  child: const Text('Open Path'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open Path'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PathNodeCard).first);
    await tester.pump();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Atacar'));
    await tester.pump();

    expect(find.text('TURNO ENEMIGO'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 20));

    expect(find.text('COMBATE FINALIZADO'), findsOneWidget);
    expect(find.text('La unidad ha caido.'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 60));
    await tester.pumpAndSettle();

    expect(find.text('Open Path'), findsOneWidget);
  });
}
