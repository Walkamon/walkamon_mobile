/// Typed PvP item/effect models shared by the provider, HUD and race renderer.
///
/// The API uses machine codes (for example `pvp_speed_up`) while the mobile
/// asset pack uses short presentation codes (`haste`).  Keep that translation
/// in this file so a widget never becomes the owner of gameplay semantics.
enum PvpItemKind { haste, slow, cleanse, shield, unknown }

enum PvpEffectKind { speedUp, speedDown, cleanse, shield, unknown }

class PvpEffectPresentationMapper {
  const PvpEffectPresentationMapper._();

  static PvpItemKind itemKind(String? code) {
    switch ((code ?? '').trim().toLowerCase()) {
      case 'haste':
      case 'pvp_speed_up':
        return PvpItemKind.haste;
      case 'slow':
      case 'pvp_speed_down':
        return PvpItemKind.slow;
      case 'cleanse':
      case 'pvp_cleanse':
        return PvpItemKind.cleanse;
      case 'shield':
      case 'pvp_shield':
        return PvpItemKind.shield;
      default:
        return PvpItemKind.unknown;
    }
  }

  static PvpEffectKind effectKind(String? code) {
    switch ((code ?? '').trim().toLowerCase()) {
      case 'haste':
      case 'pvp_speed_up':
        return PvpEffectKind.speedUp;
      case 'slow':
      case 'pvp_speed_down':
        return PvpEffectKind.speedDown;
      case 'cleanse':
      case 'pvp_cleanse':
        return PvpEffectKind.cleanse;
      case 'shield':
      case 'pvp_shield':
        return PvpEffectKind.shield;
      default:
        return PvpEffectKind.unknown;
    }
  }

  static String? assetCode(String? code) {
    switch (itemKind(code)) {
      case PvpItemKind.haste:
        return 'haste';
      case PvpItemKind.slow:
        return 'slow';
      case PvpItemKind.cleanse:
        return 'cleanse';
      case PvpItemKind.shield:
        return 'shield';
      case PvpItemKind.unknown:
        return null;
    }
  }
}

DateTime? pvpDateTimeFromJson(dynamic raw) {
  if (raw is! String || raw.trim().isEmpty) return null;
  return DateTime.tryParse(raw)?.toUtc();
}

class PvpLoadoutSlot {
  const PvpLoadoutSlot({
    required this.slotNo,
    this.itemId,
    this.itemName,
    this.effectCode,
    this.assetKey,
    this.quantity,
    this.usedAt,
  });

  final int slotNo;
  final String? itemId;
  final String? itemName;
  final String? effectCode;
  final String? assetKey;
  final int? quantity;
  final DateTime? usedAt;

  bool get isConfigured =>
      (itemId?.isNotEmpty ?? false) ||
      (effectCode?.isNotEmpty ?? false) ||
      (assetKey?.isNotEmpty ?? false);
  bool get isUsed => usedAt != null;
  bool get isAvailable => isConfigured && !isUsed && (quantity ?? 1) > 0;
  PvpItemKind get itemKind =>
      PvpEffectPresentationMapper.itemKind(effectCode ?? assetKey);
  String? get presentationCode =>
      PvpEffectPresentationMapper.assetCode(effectCode ?? assetKey);

  PvpLoadoutSlot copyWith({DateTime? usedAt, int? quantity}) {
    return PvpLoadoutSlot(
      slotNo: slotNo,
      itemId: itemId,
      itemName: itemName,
      effectCode: effectCode,
      assetKey: assetKey,
      quantity: quantity ?? this.quantity,
      usedAt: usedAt ?? this.usedAt,
    );
  }

  factory PvpLoadoutSlot.fromJson(Map<String, dynamic> json) {
    return PvpLoadoutSlot(
      slotNo:
          (json['slotNo'] as num?)?.toInt() ??
          int.tryParse('${json['slotNo'] ?? 0}') ??
          0,
      itemId: json['itemId']?.toString(),
      itemName: json['itemName']?.toString(),
      effectCode: json['effectCode']?.toString(),
      assetKey: json['assetKey']?.toString(),
      quantity: (json['quantity'] as num?)?.toInt(),
      usedAt: pvpDateTimeFromJson(json['usedAt']),
    );
  }
}

class PvpLoadoutResponse {
  const PvpLoadoutResponse({this.slots = const <PvpLoadoutSlot>[]});

  final List<PvpLoadoutSlot> slots;

  factory PvpLoadoutResponse.fromJson(dynamic json) {
    final raw = json is Map ? json['slots'] ?? json['Slots'] : json;
    final values = raw is List ? raw : const <dynamic>[];
    return PvpLoadoutResponse(
      slots: values
          .whereType<Map>()
          .map(
            (value) =>
                PvpLoadoutSlot.fromJson(Map<String, dynamic>.from(value)),
          )
          .where((slot) => slot.slotNo > 0)
          .toList(growable: false),
    );
  }
}

class PvpActiveEffect {
  const PvpActiveEffect({
    required this.effectId,
    required this.targetMatchPlayerId,
    required this.effectCode,
    this.effectKindCode,
    this.magnitudeBps,
    this.startsAt,
    this.endsAt,
  });

  final String? effectId;
  final String? targetMatchPlayerId;
  final String effectCode;
  final String? effectKindCode;
  final int? magnitudeBps;
  final DateTime? startsAt;
  final DateTime? endsAt;

  PvpEffectKind get kind =>
      PvpEffectPresentationMapper.effectKind(effectKindCode ?? effectCode);
  String? get presentationCode =>
      PvpEffectPresentationMapper.assetCode(effectCode);
  bool isActiveAt(DateTime now) =>
      (startsAt == null || !now.isBefore(startsAt!)) &&
      (endsAt == null || now.isBefore(endsAt!));

  factory PvpActiveEffect.fromJson(Map<String, dynamic> json) {
    return PvpActiveEffect(
      effectId: json['effectId']?.toString(),
      targetMatchPlayerId: json['targetMatchPlayerId']?.toString(),
      effectCode: json['effectCode']?.toString() ?? '',
      effectKindCode: json['effectKindCode']?.toString(),
      magnitudeBps: (json['magnitudeBps'] as num?)?.toInt(),
      startsAt: pvpDateTimeFromJson(json['startsAt']),
      endsAt: pvpDateTimeFromJson(json['endsAt']),
    );
  }
}

class PvpItemActionResponse {
  const PvpItemActionResponse({
    required this.actionId,
    required this.clientActionId,
    required this.resultCode,
    this.effectCode,
    this.remainingQuantity,
    this.serverTime,
    this.effect,
  });

  final String? actionId;
  final String clientActionId;
  final String resultCode;
  final String? effectCode;
  final int? remainingQuantity;
  final DateTime? serverTime;
  final PvpActiveEffect? effect;

  bool get accepted =>
      resultCode.toLowerCase() == 'applied' ||
      resultCode.toLowerCase() == 'blocked' ||
      resultCode.toLowerCase() == 'cleansed' ||
      resultCode.toLowerCase() == 'accepted' ||
      resultCode.toLowerCase() == 'ok' ||
      resultCode.toLowerCase() == 'success';

  factory PvpItemActionResponse.fromJson(Map<String, dynamic> json) {
    final rawEffect = json['effect'];
    return PvpItemActionResponse(
      actionId: json['actionId']?.toString(),
      clientActionId: json['clientActionId']?.toString() ?? '',
      resultCode: json['resultCode']?.toString() ?? 'unknown',
      effectCode: json['effectCode']?.toString(),
      remainingQuantity: (json['remainingQuantity'] as num?)?.toInt(),
      serverTime: pvpDateTimeFromJson(json['serverTime']),
      effect: rawEffect is Map
          ? PvpActiveEffect.fromJson(Map<String, dynamic>.from(rawEffect))
          : null,
    );
  }
}
