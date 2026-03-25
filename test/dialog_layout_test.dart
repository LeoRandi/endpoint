import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:endpoint/entities/_exports.dart';
import 'package:endpoint/widgets/generic/endpoint_item_details_dialog.dart';

void main() {
  testWidgets(
    'item details dialog uses a scrollable layout for long content',
    (WidgetTester tester) async {
      const longItem = Item(
        id: ItemId.woodenStick,
        name:
            'Palo de Diagnostico Experimental de Alcance Extendiendo la Descripcion',
        description:
            'Descripcion extensa para comprobar que el dialogo no fuerza una sola linea y puede crecer o desplazarse cuando el contenido ocupa bastante espacio en pantalla.',
        iconEmoji: '\u{1FAB5}',
        slot: ItemSlot.weapon,
        rarity: RarityTier.blue,
        statModifiers: {
          BattlerStat.attack: 3,
        },
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EndpointItemDetailsDialog(
              item: longItem,
              accent: Color(0xFF59B7FF),
              price: 99,
              statusText:
                  'Estado actual: descripcion larga para confirmar que este bloque tambien puede ocupar varias lineas sin truncarse dentro del dialogo.',
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(
        find.textContaining('Palo de Diagnostico Experimental'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Descripcion extensa para comprobar que el dialogo',
        ),
        findsOneWidget,
      );
    },
  );
}
