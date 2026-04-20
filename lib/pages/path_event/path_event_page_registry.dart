import '../../entities/_exports.dart';
import '../../services/_exports.dart';
import 'package:flutter/widgets.dart';

import 'black_techno_market_event_page.dart';
import 'path_event_page.dart';
import 'sobre_kar_event_page.dart';
import 'technosurgeon_event_page.dart';

typedef PathEventPageBuilder = Widget Function({
  required Battler player,
  required EventPathNode node,
  required RunRandomizer randomizer,
  required PathEventService eventService,
});

final pathEventPageBuilderById =
    Map<PathEventId, PathEventPageBuilder>.unmodifiable({
  PathEventId.shadyTechnosurgeon: _buildTechnosurgeonEventPage,
  PathEventId.afterHoursTechnosurgeon: _buildTechnosurgeonEventPage,
  PathEventId.blackTechnoMarket: _buildBlackTechnoMarketEventPage,
  PathEventId.sobreKar: _buildSobreKarEventPage,
  PathEventId.debtCollection: _buildDefaultPathEventPage,
});

Widget buildPathEventPage({
  required Battler player,
  required EventPathNode node,
  required RunRandomizer randomizer,
  PathEventService eventService = const PathEventService(),
}) {
  final pageBuilder = pathEventPageBuilderById[node.id];
  if (pageBuilder != null) {
    return pageBuilder(
      player: player,
      node: node,
      randomizer: randomizer,
      eventService: eventService,
    );
  }

  throw StateError('No existe page builder para el evento ${node.id.name}.');
}

Widget _buildTechnosurgeonEventPage({
  required Battler player,
  required EventPathNode node,
  required RunRandomizer randomizer,
  required PathEventService eventService,
}) {
  return TechnosurgeonEventPage(
    player: player,
    node: node,
    randomizer: randomizer,
    eventService: eventService,
  );
}

Widget _buildBlackTechnoMarketEventPage({
  required Battler player,
  required EventPathNode node,
  required RunRandomizer randomizer,
  required PathEventService eventService,
}) {
  return BlackTechnoMarketEventPage(
    player: player,
    node: node,
    randomizer: randomizer,
    eventService: eventService,
  );
}

Widget _buildSobreKarEventPage({
  required Battler player,
  required EventPathNode node,
  required RunRandomizer randomizer,
  required PathEventService eventService,
}) {
  return SobreKarEventPage(
    player: player,
    node: node,
    randomizer: randomizer,
    eventService: eventService,
  );
}

Widget _buildDefaultPathEventPage({
  required Battler player,
  required EventPathNode node,
  required RunRandomizer randomizer,
  required PathEventService eventService,
}) {
  return PathEventPage(
    player: player,
    node: node,
    eventService: eventService,
  );
}
