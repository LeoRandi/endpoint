import '_imports.dart';

/// Describe las reglas que debe cumplir un objeto para aparecer en una tienda.
///
/// Un criterio puede expresar rareza, rango de rareza, stat positiva y tags. El
/// servicio de stock lo aplica sobre `itemPresets` para construir inventarios.
class ShopInventoryCriterion {
  final String label;
  final String description;
  final RarityTier? exactRarity;
  final RarityTier? minimumRarity;
  final RarityTier? maximumRarity;
  final BattlerStat? requiredPositiveModifierStat;
  final List<EntityTag> requiredTags;
  final bool matchAnyRequiredTag;

  /// Crea un criterio declarativo que puede combinar rareza, tags y stat requerida.
  ShopInventoryCriterion({
    required this.label,
    required this.description,
    this.exactRarity,
    this.minimumRarity,
    this.maximumRarity,
    this.requiredPositiveModifierStat,
    List<EntityTag> requiredTags = const [],
    this.matchAnyRequiredTag = false,
  })  : requiredTags = List<EntityTag>.unmodifiable(requiredTags),
        assert(
          exactRarity == null ||
              (minimumRarity == null && maximumRarity == null),
        ),
        assert(
          minimumRarity == null ||
              maximumRarity == null ||
              minimumRarity.index <= maximumRarity.index,
        );

  /// Comprueba si un objeto concreto cumple todas las reglas del criterio.
  ///
  /// La validacion sale pronto en la primera regla fallida para mantener barato
  /// el filtrado de pools grandes de items.
  bool matches(Item item) {
    if (exactRarity != null && item.rarity != exactRarity) {
      return false;
    }
    if (minimumRarity != null && item.rarity.index < minimumRarity!.index) {
      return false;
    }
    if (maximumRarity != null && item.rarity.index > maximumRarity!.index) {
      return false;
    }
    if (requiredPositiveModifierStat != null &&
        item.modifier(requiredPositiveModifierStat!) <= 0) {
      return false;
    }
    if (requiredTags.isNotEmpty) {
      final matchesTags = matchAnyRequiredTag
          ? requiredTags.any(item.hasTag)
          : requiredTags.every(item.hasTag);
      if (!matchesTags) {
        return false;
      }
    }

    return true;
  }
}

/// Define una tienda de ruta con su criterio de stock y el multiplicador de precios aplicado.
///
/// El nodo describe que aparece en ruta y como se presenta la tienda; la pagina
/// y los servicios se encargan de comprar, vender y resolver stock concreto.
class ShopPathNode extends PathNode {
  final String showTitle;
  final String shopTitle;
  final String shopSubtitle;
  final ShopInventoryCriterion stockCriterion;
  final List<ArchetypeId> possibleArchetypes;
  final double priceMultiplier;

  /// Crea una tienda concreta con su criterio de stock y multiplicador de precio.
  ShopPathNode({
    String? nodeId,
    required String label,
    required String tooltip,
    required String iconEmoji,
    required RarityTier rarity,
    required String badgeLabel,
    required this.showTitle,
    required this.shopTitle,
    required this.shopSubtitle,
    required this.stockCriterion,
    List<ArchetypeId> possibleArchetypes = const [],
    this.priceMultiplier = 1,
  })  : possibleArchetypes = List<ArchetypeId>.unmodifiable(
          possibleArchetypes,
        ),
        super.base(
          type: PathNodeType.shop,
          nodeId: nodeId ?? 'shop:$label',
          label: label,
          tooltip: tooltip,
          iconEmoji: iconEmoji,
          rarity: rarity,
          badgeLabel: badgeLabel,
        );

  /// Indica si la tienda puede aparecer para el arquetipo actual.
  ///
  /// Mercante ignora restricciones para preservar su fantasia de acceso
  /// comercial, mientras que tiendas sin lista especifica son generalistas.
  bool canAppearForArchetype(ArchetypeId? archetypeId) {
    if (archetypeId == ArchetypeId.mercante) return true;
    if (possibleArchetypes.isEmpty) return true;
    if (archetypeId == null) return false;

    return possibleArchetypes.contains(archetypeId);
  }

  /// Clona el nodo cambiando solo el multiplicador para variantes premium o rebajadas.
  ///
  /// `PathNodeService` usa esta copia para tiendas de convencion o nodos
  /// especiales sin mutar el preset canonico registrado por id.
  ShopPathNode withPriceMultiplier(double multiplier) {
    return ShopPathNode(
      nodeId: nodeId,
      label: label,
      tooltip: tooltip,
      iconEmoji: iconEmoji,
      rarity: rarity,
      badgeLabel: badgeLabel,
      showTitle: showTitle,
      shopTitle: shopTitle,
      shopSubtitle: shopSubtitle,
      stockCriterion: stockCriterion,
      possibleArchetypes: possibleArchetypes,
      priceMultiplier: multiplier,
    );
  }
}
