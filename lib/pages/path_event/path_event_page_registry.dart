import '../../entities/_exports.dart';
import '../../services/_exports.dart';
import 'package:flutter/widgets.dart';

import 'black_techno_market_event_page.dart';
import 'archetype_special_event_page.dart';
import 'pitonisa_quitapenas_event_page.dart';
import 'secret_path_event_page.dart';
import 'path_event_page.dart';
import 'sobre_kar_event_page.dart';
import 'su_basta_ya_event_page.dart';
import 'technosurgeon_event_page.dart';

typedef PathEventPageBuilder = Widget Function({
  required Battler player,
  required EventPathNode node,
  required RunRandomizer randomizer,
  required PathEventService eventService,
  required int dayNumber,
});

final pathEventPageBuilderById =
    Map<PathEventId, PathEventPageBuilder>.unmodifiable({
  PathEventId.strandedTrash: _buildDefaultPathEventPage,
  PathEventId.lostCache: _buildDefaultPathEventPage,
  PathEventId.shadyTechnosurgeon: _buildTechnosurgeonEventPage,
  PathEventId.afterHoursTechnosurgeon: _buildTechnosurgeonEventPage,
  PathEventId.blackTechnoMarket: _buildBlackTechnoMarketEventPage,
  PathEventId.pasadizoSecreto: _buildPasadizoSecretoEventPage,
  PathEventId.sobreKar: _buildSobreKarEventPage,
  PathEventId.suBastaYa: _buildSuBastaYaEventPage,
  PathEventId.pitonisaQuitapenas: _buildPitonisaQuitapenasEventPage,
  PathEventId.clinicaReflejos: _buildArchetypeSpecialEventPage,
  PathEventId.viktorOperations: _buildArchetypeSpecialEventPage,
  PathEventId.arquitecbrosSl: _buildArchetypeSpecialEventPage,
  PathEventId.capillaStShieladurn: _buildArchetypeSpecialEventPage,
  PathEventId.contratontos: _buildArchetypeSpecialEventPage,
  PathEventId.hornoJuramentos: _buildArchetypeSpecialEventPage,
  PathEventId.auditoriaCreativa: _buildArchetypeSpecialEventPage,
  PathEventId.mercadoFuturos: _buildArchetypeSpecialEventPage,
  PathEventId.debtCollection: _buildDefaultPathEventPage,
});

Widget buildPathEventPage({
  required Battler player,
  required EventPathNode node,
  required RunRandomizer randomizer,
  int dayNumber = 1,
  PathEventService eventService = const PathEventService(),
}) {
  final pageBuilder = pathEventPageBuilderById[node.id];
  if (pageBuilder != null) {
    return pageBuilder(
      player: player,
      node: node,
      randomizer: randomizer,
      eventService: eventService,
      dayNumber: dayNumber,
    );
  }

  throw StateError('No existe page builder para el evento ${node.id.name}.');
}

Widget _buildTechnosurgeonEventPage({
  required Battler player,
  required EventPathNode node,
  required RunRandomizer randomizer,
  required PathEventService eventService,
  required int dayNumber,
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
  required int dayNumber,
}) {
  return BlackTechnoMarketEventPage(
    player: player,
    node: node,
    randomizer: randomizer,
    eventService: eventService,
  );
}

Widget _buildPasadizoSecretoEventPage({
  required Battler player,
  required EventPathNode node,
  required RunRandomizer randomizer,
  required PathEventService eventService,
  required int dayNumber,
}) {
  return SecretPassageEventPage(
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
  required int dayNumber,
}) {
  return SobreKarEventPage(
    player: player,
    node: node,
    randomizer: randomizer,
    eventService: eventService,
  );
}

Widget _buildSuBastaYaEventPage({
  required Battler player,
  required EventPathNode node,
  required RunRandomizer randomizer,
  required PathEventService eventService,
  required int dayNumber,
}) {
  return SuBastaYaEventPage(
    player: player,
    node: node,
    randomizer: randomizer,
    eventService: eventService,
  );
}

Widget _buildPitonisaQuitapenasEventPage({
  required Battler player,
  required EventPathNode node,
  required RunRandomizer randomizer,
  required PathEventService eventService,
  required int dayNumber,
}) {
  return PitonisaQuitapenasEventPage(
    player: player,
    node: node,
    eventService: eventService,
  );
}

Widget _buildArchetypeSpecialEventPage({
  required Battler player,
  required EventPathNode node,
  required RunRandomizer randomizer,
  required PathEventService eventService,
  required int dayNumber,
}) {
  return ArchetypeSpecialEventPage(
    player: player,
    node: node,
    randomizer: randomizer,
    eventService: eventService,
    dayNumber: dayNumber,
  );
}

Widget _buildDefaultPathEventPage({
  required Battler player,
  required EventPathNode node,
  required RunRandomizer randomizer,
  required PathEventService eventService,
  required int dayNumber,
}) {
  return PathEventPage(
    player: player,
    node: node,
    randomizer: randomizer,
    eventService: eventService,
  );
}
