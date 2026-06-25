import 'dart:async';
import 'dart:convert';

import '../../entities/_exports.dart';
import '../persistence/endpoint_preferences_store.dart';
import 'package:flutter/foundation.dart';

class CodexDiscoveryNotice {
  final int count;
  final String? primaryKey;

  const CodexDiscoveryNotice({
    required this.count,
    required this.primaryKey,
  });

  bool get hasSeveralDiscoveries => count > 1;
}

abstract final class CodexDiscoveryService {
  static const String preferenceKey = 'endpoint.codex_discoveries';
  static final ValueNotifier<CodexDiscoveryNotice?> discoveryNotice =
      ValueNotifier<CodexDiscoveryNotice?>(null);
  static final List<String> _pendingNoticeKeys = <String>[];
  static Timer? _noticeBatchTimer;
  static Future<void> _mutationQueue = Future<void>.value();

  static String archetypeKey(ArchetypeId id) => 'archetype:${id.name}';
  static String itemKey(String catalogKey) => 'item:$catalogKey';
  static String augmentKey(int id) => 'augment:$id';
  static String abilityKey(BattlerAbilityId id) => 'ability:${id.name}';
  static String enemyKey(String nodeId) => 'enemy:$nodeId';
  static String statusKey(BattlerStatusId id) => 'status:${id.name}';
  static String shopKey(String nodeId) => 'shop:$nodeId';
  static String eventKey(PathEventId id) => 'event:${id.name}';

  static void registerHooks() {
    CodexDiscoveryHook.onItemAdded = (itemId) {
      unawaited(markIndexed(itemKey(itemId)));
    };
    CodexDiscoveryHook.onAugmentAdded = (augmentId) {
      unawaited(markIndexed(augmentKey(augmentId)));
    };
    CodexDiscoveryHook.onAbilityAdded = (abilityId) {
      unawaited(markIndexed(abilityKey(abilityId)));
    };
    CodexDiscoveryHook.onStatusApplied = (statusId) {
      unawaited(markIndexed(statusKey(statusId)));
    };
  }

  static Future<Set<String>> loadIndexedKeys() async {
    final rawValue = await EndpointPreferencesStore.readString(preferenceKey);
    if (rawValue == null || rawValue.trim().isEmpty) {
      return <String>{};
    }

    final decoded = jsonDecode(rawValue);
    if (decoded is! List) return <String>{};

    return decoded.whereType<String>().toSet();
  }

  static Future<void> saveIndexedKeys(Set<String> keys) {
    final sortedKeys = keys.toList()..sort();

    return EndpointPreferencesStore.writeString(
      key: preferenceKey,
      rawValue: jsonEncode(sortedKeys),
    );
  }

  static Future<void> markIndexed(String key) {
    final pendingMutation = _mutationQueue.then((_) async {
      final keys = await loadIndexedKeys();
      if (!keys.add(key)) return;

      await saveIndexedKeys(keys);
      _queueDiscoveryNotice(key);
    });
    _mutationQueue = pendingMutation.catchError((Object _) {});
    return pendingMutation;
  }

  static Future<void> markAllIndexed() {
    final pendingMutation = _mutationQueue.then((_) {
      return saveIndexedKeys(_allKnownKeys());
    });
    _mutationQueue = pendingMutation.catchError((Object _) {});
    return pendingMutation;
  }

  static Future<void> clearIndexed() {
    final pendingMutation = _mutationQueue.then((_) {
      return saveIndexedKeys(<String>{});
    });
    _mutationQueue = pendingMutation.catchError((Object _) {});
    return pendingMutation;
  }

  static void _queueDiscoveryNotice(String key) {
    _pendingNoticeKeys.add(key);
    _noticeBatchTimer ??= Timer(const Duration(milliseconds: 90), () {
      _noticeBatchTimer = null;
      final keys = List<String>.unmodifiable(_pendingNoticeKeys);
      _pendingNoticeKeys.clear();
      if (keys.isEmpty) return;

      discoveryNotice.value = CodexDiscoveryNotice(
        count: keys.length,
        primaryKey: keys.first,
      );
    });
  }

  static Set<String> _allKnownKeys() {
    final keys = <String>{
      for (final archetype in ArchetypeId.values) archetypeKey(archetype),
      for (final item in itemPresets) itemKey(item.catalogKey),
      for (final augment in augmentCatalog) augmentKey(augment.id),
      for (final node in combatPathNodeExamples) enemyKey(node.nodeId),
      for (final statusId in BattlerStatusId.values) statusKey(statusId),
      for (final node in _allShopNodes) shopKey(node.nodeId),
      for (final node in _allEventNodes) eventKey(node.id),
    };

    return keys;
  }

  static List<ShopPathNode> get _allShopNodes {
    final seen = <String>{};
    final result = <ShopPathNode>[];
    for (final node in [
      ...dayShopNodes,
      ...nightShopNodes,
    ]) {
      if (!seen.add(node.nodeId)) continue;
      result.add(node);
    }
    return result;
  }

  static List<EventPathNode> get _allEventNodes {
    final seen = <PathEventId>{};
    final result = <EventPathNode>[];
    for (final node in [
      ...dayEventNodes,
      ...nightEventNodes,
    ]) {
      if (!seen.add(node.id)) continue;
      result.add(node);
    }
    return result;
  }
}
