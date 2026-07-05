import '../entities/_exports.dart';
import 'package:flutter/material.dart';

import 'endpoint_palette.dart';

/// UI-only copy and visual tokens for domain entities.
///
/// Keeping these mappings outside `entities` lets the domain remain usable by
/// non-Flutter tools while preserving the existing widget-facing API.
extension ArchetypeIdPresentation on ArchetypeId {
  String get label => switch (this) {
        ArchetypeId.veloz => 'Veloz',
        ArchetypeId.inamovible => 'Inamovible',
        ArchetypeId.imparable => 'Imparable',
        ArchetypeId.mercante => 'Mercante',
      };
}

extension EntityTagPresentation on EntityTag {
  String get label => switch (this) {
        EntityTag.debuff => 'Debuff',
        EntityTag.buff => 'Buff',
        EntityTag.quemadura => 'Quemadura',
        EntityTag.intoxicacion => 'Intoxicacion',
        EntityTag.contagio => 'Contagio',
        EntityTag.ciclo => 'Ciclo',
        EntityTag.vida => 'Vida',
        EntityTag.ataque => 'Ataque',
        EntityTag.barrera => 'Barrera',
        EntityTag.resonancia => 'Resonancia',
        EntityTag.desafio => 'Desafio',
        EntityTag.economia => 'Economia',
        EntityTag.muralla => 'Muralla',
        EntityTag.arma => 'Arma',
        EntityTag.accesorio => 'Accesorio',
        EntityTag.cura => 'Cura',
      };

  Color get accent => switch (this) {
        EntityTag.debuff => const Color.fromARGB(255, 252, 98, 98),
        EntityTag.buff => const Color.fromARGB(255, 63, 157, 235),
        EntityTag.quemadura => const Color(0xFFFF8C42),
        EntityTag.intoxicacion => const Color.fromARGB(255, 177, 24, 182),
        EntityTag.contagio => const Color.fromARGB(255, 233, 162, 195),
        EntityTag.ciclo => const Color(0xFFC0C0C0),
        EntityTag.vida => EndpointPalette.healthAccent,
        EntityTag.ataque => const Color.fromARGB(255, 255, 0, 0),
        EntityTag.barrera => const Color.fromARGB(255, 38, 8, 170),
        EntityTag.resonancia => const Color(0xFFD0D5DE),
        EntityTag.desafio => const Color(0xFF55D6C2),
        EntityTag.economia => const Color(0xFFEBCB5A),
        EntityTag.muralla => const Color(0xFFB8C0CC),
        EntityTag.arma => const Color(0xFFF3D35C),
        EntityTag.accesorio => const Color(0xFF9EA7B3),
        EntityTag.cura => const Color(0xFF5AF78E),
      };

  String? get iconAssetPath => switch (this) {
        EntityTag.quemadura => 'assets/sprites/status/quemadura.png',
        EntityTag.intoxicacion => 'assets/sprites/status/intox.png',
        EntityTag.contagio => 'assets/sprites/status/contagion.png',
        EntityTag.vida || EntityTag.cura => 'assets/sprites/status/vida.png',
        EntityTag.barrera => 'assets/sprites/status/escudo.png',
        _ => null,
      };
}

extension RarityTierPresentation on RarityTier {
  String get label => switch (this) {
        RarityTier.gray => 'GRIS',
        RarityTier.green => 'VERDE',
        RarityTier.blue => 'AZUL',
        RarityTier.purple => 'MORADO',
        RarityTier.yellow => 'AMARILLO',
      };

  Color get accent => switch (this) {
        RarityTier.gray => const Color(0xFF9EA7B3),
        RarityTier.green => const Color(0xFF5AF78E),
        RarityTier.blue => const Color(0xFF59B7FF),
        RarityTier.purple => const Color(0xFFBE7CFF),
        RarityTier.yellow => const Color(0xFFF3D35C),
      };
}

extension BattlerStatPresentation on BattlerStat {
  String get label => switch (this) {
        BattlerStat.health => 'Vida',
        BattlerStat.attack => 'Ataque',
        BattlerStat.barrier => 'Barrera',
      };

  String get shortLabel => switch (this) {
        BattlerStat.health => 'HP',
        BattlerStat.attack => 'ATK',
        BattlerStat.barrier => 'BAR',
      };

  Color get accent => switch (this) {
        BattlerStat.health => EndpointPalette.healthAccent,
        BattlerStat.attack => const Color(0xFFF3D35C),
        BattlerStat.barrier => const Color(0xFF59B7FF),
      };

  String? get iconAssetPath => switch (this) {
        BattlerStat.health => 'assets/sprites/status/vida.png',
        BattlerStat.barrier => 'assets/sprites/status/escudo.png',
        _ => null,
      };
}

extension BattlerStatusTypePresentation on BattlerStatusType {
  String get label => switch (this) {
        BattlerStatusType.buff => 'Buff',
        BattlerStatusType.debuff => 'Debuff',
      };

  Color get accent => switch (this) {
        BattlerStatusType.buff => const Color(0xFF5AF78E),
        BattlerStatusType.debuff => const Color(0xFFFF6B6B),
      };

  Color get foreground => switch (this) {
        BattlerStatusType.buff => const Color(0xFFE6FFF0),
        BattlerStatusType.debuff => const Color(0xFFFFE3E3),
      };
}

extension AugmentPresentation on Augment {
  IconData get icon {
    if (hasTag(EntityTag.economia)) return Icons.currency_exchange_rounded;
    if (hasTag(EntityTag.desafio)) return Icons.local_activity_rounded;
    if (hasTag(EntityTag.barrera)) return Icons.shield_rounded;
    if (hasTag(EntityTag.ataque)) return Icons.join_inner_rounded;
    return Icons.auto_awesome_rounded;
  }

  Color get accent => rarity.accent;
}

extension AugmentAffinityPresentation on AugmentAffinity {
  String get label => switch (this) {
        AugmentAffinity.general => 'General',
        AugmentAffinity.veloz => ArchetypeId.veloz.label,
        AugmentAffinity.inamovible => ArchetypeId.inamovible.label,
        AugmentAffinity.imparable => ArchetypeId.imparable.label,
        AugmentAffinity.mercante => ArchetypeId.mercante.label,
      };

  IconData get icon => switch (this) {
        AugmentAffinity.general => Icons.all_inclusive_rounded,
        AugmentAffinity.veloz => Icons.flash_on_rounded,
        AugmentAffinity.inamovible => Icons.shield_rounded,
        AugmentAffinity.imparable => Icons.local_fire_department_rounded,
        AugmentAffinity.mercante => Icons.payments_rounded,
      };

  Color get accent => switch (this) {
        AugmentAffinity.general => EndpointPalette.neutralAccent,
        AugmentAffinity.veloz => const Color(0xFF59B7FF),
        AugmentAffinity.inamovible => const Color(0xFF5AF78E),
        AugmentAffinity.imparable => const Color(0xFFFF5A5F),
        AugmentAffinity.mercante => const Color(0xFFEBCB5A),
      };
}

const _statusIcons = <BattlerStatusId, IconData>{
  BattlerStatusId.calentando: Icons.local_fire_department_rounded,
  BattlerStatusId.potencia: Icons.bolt_rounded,
  BattlerStatusId.cicloEclipse: Icons.brightness_medium_rounded,
  BattlerStatusId.puntoCiego: Icons.visibility_off_rounded,
  BattlerStatusId.desafio: Icons.sports_mma_rounded,
  BattlerStatusId.desafioExcitante: Icons.local_activity_rounded,
  BattlerStatusId.resonancia: Icons.graphic_eq_rounded,
  BattlerStatusId.compensadorRuta: Icons.route_rounded,
  BattlerStatusId.mercadoFuturos: Icons.monetization_on_rounded,
  BattlerStatusId.quemadura: Icons.whatshot_rounded,
  BattlerStatusId.intoxicacion: Icons.science_rounded,
  BattlerStatusId.contagio: Icons.coronavirus_rounded,
  BattlerStatusId.catalisisCruel: Icons.biotech_rounded,
  BattlerStatusId.fragilidad: Icons.flash_on_outlined,
  BattlerStatusId.conmocion: Icons.flash_off_rounded,
  BattlerStatusId.deuda: Icons.receipt_long_rounded,
};

const _statusIconAssets = <BattlerStatusId, String>{
  BattlerStatusId.potencia: 'assets/sprites/status/potencia.png',
  BattlerStatusId.puntoCiego: 'assets/sprites/status/puntociego.png',
  BattlerStatusId.quemadura: 'assets/sprites/status/quemadura.png',
  BattlerStatusId.intoxicacion: 'assets/sprites/status/intox.png',
  BattlerStatusId.contagio: 'assets/sprites/status/contagion.png',
  BattlerStatusId.fragilidad: 'assets/sprites/status/fragilidad.png',
};

extension BattlerStatusPresentation on BattlerStatus {
  IconData get icon => _statusIcons[id] ?? Icons.auto_awesome_rounded;
  String? get iconAssetPath => _statusIconAssets[id];

  String localizedDescriptionFor(Battler owner) {
    if (this case CompensadorRutaStatus(:final stat, :final value)) {
      return '$description Bonus actual: +$value ${stat.shortLabel}.';
    }
    return descriptionFor(owner);
  }
}

extension ItemPresentation on Item {
  String get localizedDisplayDescription => displayDescription;

  String get localizedTooltipDescription => localizedDisplayDescription;
}

extension OperativePatternPointPresentation on OperativePatternPoint {
  String get label => debugLabel;
}

extension OperativePatternAdjacencyDirectionPresentation
    on OperativePatternAdjacencyDirection {
  String get label => switch (this) {
        OperativePatternAdjacencyDirection.north => 'Norte',
        OperativePatternAdjacencyDirection.east => 'Este',
        OperativePatternAdjacencyDirection.south => 'Sur',
        OperativePatternAdjacencyDirection.west => 'Oeste',
      };

  String get shortLabel => switch (this) {
        OperativePatternAdjacencyDirection.north => 'N',
        OperativePatternAdjacencyDirection.east => 'E',
        OperativePatternAdjacencyDirection.south => 'S',
        OperativePatternAdjacencyDirection.west => 'O',
      };
}

extension OperativePatternRequirementPresentation
    on OperativePatternRequirement {
  String get label => switch (kind) {
        OperativePatternRequirementKind.firstPoint => 'Inicio',
        OperativePatternRequirementKind.middlePoint => 'Centro',
        OperativePatternRequirementKind.lastPoint => 'Final',
        OperativePatternRequirementKind.rightAngle => 'Angulo 90',
        OperativePatternRequirementKind.straightAngle => 'Angulo 180',
      };

  String get shortLabel => switch (kind) {
        OperativePatternRequirementKind.firstPoint => 'INI',
        OperativePatternRequirementKind.middlePoint => 'MED',
        OperativePatternRequirementKind.lastPoint => 'FIN',
        OperativePatternRequirementKind.rightAngle => '90',
        OperativePatternRequirementKind.straightAngle => '180',
      };

  String get description => switch (kind) {
        OperativePatternRequirementKind.firstPoint =>
          'Debe ser el primer punto del trazo.',
        OperativePatternRequirementKind.middlePoint =>
          'Debe quedar en una posicion central del recorrido.',
        OperativePatternRequirementKind.lastPoint =>
          'Debe ser el ultimo vertice antes de cerrar.',
        OperativePatternRequirementKind.rightAngle =>
          'Debe ser el vertice de un angulo recto.',
        OperativePatternRequirementKind.straightAngle =>
          'Debe ser el vertice de un angulo llano de 180 grados.',
      };
}

extension PathNodePresentation on PathNode {
  String get localizedBadgeLabel => switch (this) {
        CombatPathNode(:final tier) => tier.badgeLabel,
        _ => badgeLabel,
      };

  Color get accent => switch (nodeId) {
        'archetype_imparable' => const Color(0xFFFF5A5F),
        'archetype_mercante' => const Color(0xFFEBCB5A),
        'shop_scrap_arsenal' => const Color(0xFFB8C0CC),
        'shop_first_aid_stand' => const Color(0xFFFF8BA7),
        'shop_imp_acts' => const Color(0xFFF3D35C),
        'shop_remiendos_and_donts' => const Color(0xFF59B7FF),
        'shop_ganganancias' ||
        'shop_cambient_gold_seller' =>
          const Color(0xFFEBCB5A),
        'shop_bulwark_workshop' => const Color(0xFF3FE88F),
        'shop_routine_market' => const Color(0xFFC0C0C0),
        'shop_luxury_relics' => const Color(0xFFFFD56B),
        'shop_ember_foundry' => const Color(0xFFFF6A2A),
        'shop_toxin_lab' => const Color(0xFFB9F25C),
        'shop_after_hours_arsenal' => const Color(0xFFFF4D6D),
        'shop_velvet_armory' ||
        'shop_tactics_and_treasures' =>
          const Color(0xFFA95CFF),
        'shop_chemical_exchange' => const Color(0xFF4DE7D2),
        'shop_debuff_broker' => const Color(0xFFFF5A5F),
        'shop_buff_parlor' => const Color(0xFFFF8BE8),
        'shop_resonance_bank' => const Color(0xFFD0D5DE),
        'shop_duelow_prices' => const Color(0xFF55D6C2),
        'shop_contagion_company' => const Color(0xFFB56DFF),
        _ => rarity.accent,
      };
}

extension CombatNodeTierPresentation on CombatNodeTier {
  Color get accent => rarity.accent;
  String get badgeLabel => rarity.label;
}
