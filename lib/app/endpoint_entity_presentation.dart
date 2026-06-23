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
      };

  Color get accent => switch (this) {
        EntityTag.debuff => const Color(0xFFFF6B6B),
        EntityTag.buff => const Color(0xFF5AF78E),
        EntityTag.quemadura => const Color(0xFFFF8C42),
        EntityTag.intoxicacion => const Color(0xFF74D66A),
        EntityTag.contagio => const Color(0xFFB56DFF),
        EntityTag.ciclo => const Color(0xFFC0C0C0),
        EntityTag.vida => EndpointPalette.healthAccent,
        EntityTag.ataque => const Color(0xFFF3D35C),
        EntityTag.barrera => const Color(0xFF59B7FF),
        EntityTag.resonancia => const Color(0xFFD0D5DE),
        EntityTag.desafio => const Color(0xFF55D6C2),
        EntityTag.economia => const Color(0xFFEBCB5A),
        EntityTag.muralla => const Color(0xFFB8C0CC),
        EntityTag.arma => const Color(0xFFF3D35C),
        EntityTag.accesorio => const Color(0xFF9EA7B3),
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
}

extension BattlerAbilityActivationContextPresentation
    on BattlerAbilityActivationContext {
  String get label => switch (this) {
        BattlerAbilityActivationContext.battle => 'Combate',
        BattlerAbilityActivationContext.pathSelection => 'Ruta',
        BattlerAbilityActivationContext.shop => 'Tienda',
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

const _abilityIcons = <BattlerAbilityId, IconData>{
  BattlerAbilityId.weaknessHunter: Icons.track_changes_rounded,
  BattlerAbilityId.ghostMesh: Icons.security_rounded,
  BattlerAbilityId.ritmoCircadiano: Icons.av_timer_rounded,
  BattlerAbilityId.turnoDeNoche: Icons.bedtime_rounded,
  BattlerAbilityId.cashflow: Icons.payments_rounded,
  BattlerAbilityId.pulsoRepL: Icons.shield_rounded,
  BattlerAbilityId.masaCritica: Icons.hub_rounded,
  BattlerAbilityId.cortafuegosPortatil: Icons.security_rounded,
  BattlerAbilityId.triageAutomatico: Icons.medical_services_rounded,
  BattlerAbilityId.opresionTactica: Icons.control_camera_rounded,
  BattlerAbilityId.copiaDeSeguridad: Icons.backup_rounded,
  BattlerAbilityId.mandatoColiseo: Icons.stadium_rounded,
  BattlerAbilityId.hemostasiaAgresiva: Icons.favorite_rounded,
  BattlerAbilityId.mallaRebote: Icons.sync_alt_rounded,
  BattlerAbilityId.escanerRuptura: Icons.radar_rounded,
  BattlerAbilityId.nucleoParasitario: Icons.bloodtype_rounded,
  BattlerAbilityId.monopolio: Icons.storefront_rounded,
  BattlerAbilityId.diversificacionHostil: Icons.hub_rounded,
  BattlerAbilityId.furiaHematica: Icons.bloodtype_rounded,
  BattlerAbilityId.noHayRetirada: Icons.vertical_align_top_rounded,
  BattlerAbilityId.geometriaLimpia: Icons.grid_4x4_rounded,
  BattlerAbilityId.pulsoIsometrico: Icons.crop_square_rounded,
  BattlerAbilityId.corteTangencial: Icons.swipe_rounded,
  BattlerAbilityId.cortesAgudos: Icons.show_chart_rounded,
  BattlerAbilityId.rotoresDefensivos: Icons.rotate_90_degrees_ccw_rounded,
  BattlerAbilityId.polarizacion: Icons.compare_arrows_rounded,
  BattlerAbilityId.arquitecturaPesada: Icons.foundation_rounded,
  BattlerAbilityId.rutaContrabando: Icons.alt_route_rounded,
  BattlerAbilityId.ecoSimetria: Icons.flip_rounded,
  BattlerAbilityId.patronPerfecto: Icons.auto_awesome_rounded,
  BattlerAbilityId.encendidoBrutal: Icons.local_fire_department_rounded,
  BattlerAbilityId.combustionDirigida: Icons.bolt_rounded,
  BattlerAbilityId.puntoIgnicion: Icons.whatshot_rounded,
  BattlerAbilityId.deudaSangre: Icons.bloodtype_rounded,
  BattlerAbilityId.reventaCircular: Icons.replay_rounded,
  BattlerAbilityId.contratoReuso: Icons.assignment_return_rounded,
  BattlerAbilityId.mercadoRecursivo: Icons.currency_exchange_rounded,
  BattlerAbilityId.comisionRiesgo: Icons.trending_down_rounded,
  BattlerAbilityId.franquiciaTotal: Icons.storefront_rounded,
  BattlerAbilityId.agujaToxica: Icons.colorize_rounded,
  BattlerAbilityId.rastroInestable: Icons.timeline_rounded,
  BattlerAbilityId.cadenaNeurotoxica: Icons.hub_rounded,
  BattlerAbilityId.armaBiologica: Icons.biotech_rounded,
  BattlerAbilityId.inmunizacion: Icons.vaccines_rounded,
  BattlerAbilityId.cargaVirica: Icons.bubble_chart_rounded,
  BattlerAbilityId.epidemiologiaTactica: Icons.insights_rounded,
  BattlerAbilityId.sintomasCruzados: Icons.sync_alt_rounded,
  BattlerAbilityId.pacienteCero: Icons.personal_injury_rounded,
  BattlerAbilityId.aceleracionFotovoltaica: Icons.flash_on_rounded,
  BattlerAbilityId.b4r3b0n3d: Icons.data_object_rounded,
  BattlerAbilityId.compensadorRuta: Icons.route_rounded,
  BattlerAbilityId.aTodoRiesgo: Icons.policy_rounded,
  BattlerAbilityId.ultimaPieza: Icons.electric_bolt_rounded,
  BattlerAbilityId.geometriaBolsillo: Icons.category_rounded,
  BattlerAbilityId.adaptacion: Icons.extension_rounded,
  BattlerAbilityId.hornoSimetrico: Icons.local_fire_department_rounded,
  BattlerAbilityId.kilotonificacion: Icons.warning_amber_rounded,
};

extension BattlerAbilityPresentation on BattlerAbility {
  IconData get icon => _abilityIcons[id] ?? Icons.center_focus_strong_rounded;
  Color get accent => rarity.accent;
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

extension BattlerStatusPresentation on BattlerStatus {
  IconData get icon => _statusIcons[id] ?? Icons.auto_awesome_rounded;

  String localizedDescriptionFor(Battler owner) {
    if (this case CompensadorRutaStatus(:final stat, :final value)) {
      return '$description Bonus actual: +$value ${stat.shortLabel}.';
    }
    return descriptionFor(owner);
  }
}

extension ItemPresentation on Item {
  String get localizedDisplayDescription {
    if (id != ItemId.buzonVirtualAzul &&
        id != ItemId.buzonVirtualRojo &&
        id != ItemId.buzonVirtualVerde) {
      return displayDescription;
    }

    final focusTag = switch (id) {
      ItemId.buzonVirtualAzul => rarity.index <= RarityTier.gray.index
          ? EntityTag.accesorio
          : EntityTag.ciclo,
      ItemId.buzonVirtualRojo => rarity.index <= RarityTier.gray.index
          ? EntityTag.ataque
          : EntityTag.quemadura,
      ItemId.buzonVirtualVerde => rarity.index <= RarityTier.green.index
          ? EntityTag.barrera
          : EntityTag.resonancia,
      _ => EntityTag.economia,
    };
    final statLine =
        id == ItemId.buzonVirtualAzul ? '+1 PP mientras este equipado. ' : '';
    final localizedEffect =
        '${statLine}Al terminar un combate, si tienes espacio, ofrece un item ${rarity.label} aleatorio con tag ${focusTag.label} en la pantalla de recompensas.';
    final technicalEffect = effect?.descriptionFor(this);
    if (technicalEffect == null || technicalEffect.isEmpty) {
      return localizedEffect;
    }
    return displayDescription.replaceFirst(technicalEffect, localizedEffect);
  }

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
        OperativePatternRequirementKind.exactShape => switch (shapeKind) {
            OperativePatternShapeKind.literal => 'Figura',
            OperativePatternShapeKind.square => 'Cuadrado',
            OperativePatternShapeKind.diamond => 'Diamante',
            OperativePatternShapeKind.hourglass => 'Reloj arena',
            OperativePatternShapeKind.zigzag => 'Zigzag',
          },
      };

  String get shortLabel => switch (kind) {
        OperativePatternRequirementKind.firstPoint => 'INI',
        OperativePatternRequirementKind.middlePoint => 'MED',
        OperativePatternRequirementKind.lastPoint => 'FIN',
        OperativePatternRequirementKind.rightAngle => '90',
        OperativePatternRequirementKind.straightAngle => '180',
        OperativePatternRequirementKind.exactShape => _shortExactShapeLabel,
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
        OperativePatternRequirementKind.exactShape =>
          'El dibujo debe seguir esta figura en el orden indicado.',
      };

  String get _shortExactShapeLabel {
    final compactLabel = label.replaceAll(' ', '');
    if (compactLabel.length <= 3) return compactLabel.toUpperCase();
    return compactLabel.substring(0, 3).toUpperCase();
  }
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
