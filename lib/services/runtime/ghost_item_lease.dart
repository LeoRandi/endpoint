import 'dart:math';

import '../persistence/endpoint_json_utils.dart';

class GhostItemLease {
  final String itemInstanceId;
  final int combatsRemaining;

  const GhostItemLease({
    required this.itemInstanceId,
    required this.combatsRemaining,
  });

  bool get isDue => combatsRemaining <= 0;

  GhostItemLease afterCombat() {
    return GhostItemLease(
      itemInstanceId: itemInstanceId,
      combatsRemaining: max(0, combatsRemaining - 1),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'itemInstanceId': itemInstanceId,
      'combatsRemaining': combatsRemaining,
    };
  }

  static GhostItemLease? fromJson(Object? rawValue) {
    final json = EndpointJsonUtils.asJsonMap(rawValue);
    if (json == null) return null;

    final itemInstanceId =
        EndpointJsonUtils.readNullableString(json['itemInstanceId']);
    if (itemInstanceId == null || itemInstanceId.isEmpty) return null;

    return GhostItemLease(
      itemInstanceId: itemInstanceId,
      combatsRemaining: EndpointJsonUtils.readInt(
        json['combatsRemaining'],
        fallback: 2,
      ),
    );
  }
}
