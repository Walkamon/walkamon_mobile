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
    this.itemNameVi,
    this.itemNameEn,
    this.descriptionVi,
    this.descriptionEn,
    this.effectCode,
    this.targetCode,
    this.magnitudeBps,
    this.durationMs,
    this.cooldownMs,
    this.assetKey,
    this.quantity,
    this.usedAt,
  });

  final int slotNo;
  final String? itemId;
  final String? itemName;
  final String? itemNameVi;
  final String? itemNameEn;
  final String? descriptionVi;
  final String? descriptionEn;
  final String? effectCode;
  final String? targetCode;
  final int? magnitudeBps;
  final int? durationMs;
  final int? cooldownMs;
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
      itemNameVi: itemNameVi,
      itemNameEn: itemNameEn,
      descriptionVi: descriptionVi,
      descriptionEn: descriptionEn,
      effectCode: effectCode,
      targetCode: targetCode,
      magnitudeBps: magnitudeBps,
      durationMs: durationMs,
      cooldownMs: cooldownMs,
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
      itemNameVi: json['itemNameVi']?.toString(),
      itemNameEn: json['itemNameEn']?.toString(),
      descriptionVi: json['descriptionVi']?.toString(),
      descriptionEn: json['descriptionEn']?.toString(),
      effectCode: json['effectCode']?.toString(),
      targetCode: json['targetCode']?.toString(),
      magnitudeBps: (json['magnitudeBps'] as num?)?.toInt(),
      durationMs: (json['durationMs'] as num?)?.toInt(),
      cooldownMs: (json['cooldownMs'] as num?)?.toInt(),
      assetKey: json['assetKey']?.toString(),
      quantity: (json['quantity'] as num?)?.toInt(),
      usedAt: pvpDateTimeFromJson(json['usedAt']),
    );
  }
}

class PvpAvailableLoadoutItem {
  const PvpAvailableLoadoutItem({
    required this.itemId,
    required this.itemName,
    this.itemNameVi,
    this.itemNameEn,
    this.descriptionVi,
    this.descriptionEn,
    required this.effectCode,
    required this.targetCode,
    required this.magnitudeBps,
    required this.durationMs,
    required this.cooldownMs,
    required this.assetKey,
    required this.quantity,
  });

  final String itemId;
  final String itemName;
  final String? itemNameVi;
  final String? itemNameEn;
  final String? descriptionVi;
  final String? descriptionEn;
  final String effectCode;
  final String targetCode;
  final int magnitudeBps;
  final int durationMs;
  final int cooldownMs;
  final String assetKey;
  final int quantity;

  bool get isOwned => quantity > 0;
  PvpItemKind get itemKind => PvpEffectPresentationMapper.itemKind(effectCode);
  String? get presentationCode =>
      PvpEffectPresentationMapper.assetCode(effectCode);

  PvpLoadoutSlot toSlot(int slotNo) => PvpLoadoutSlot(
    slotNo: slotNo,
    itemId: itemId,
    itemName: itemName,
    itemNameVi: itemNameVi,
    itemNameEn: itemNameEn,
    descriptionVi: descriptionVi,
    descriptionEn: descriptionEn,
    effectCode: effectCode,
    targetCode: targetCode,
    magnitudeBps: magnitudeBps,
    durationMs: durationMs,
    cooldownMs: cooldownMs,
    assetKey: assetKey,
    quantity: quantity,
  );

  factory PvpAvailableLoadoutItem.fromJson(Map<String, dynamic> json) {
    int readInt(String key) =>
        (json[key] as num?)?.toInt() ?? int.tryParse('${json[key] ?? 0}') ?? 0;
    return PvpAvailableLoadoutItem(
      itemId: json['itemId']?.toString() ?? '',
      itemName: json['itemName']?.toString() ?? '',
      itemNameVi: json['itemNameVi']?.toString(),
      itemNameEn: json['itemNameEn']?.toString(),
      descriptionVi: json['descriptionVi']?.toString(),
      descriptionEn: json['descriptionEn']?.toString(),
      effectCode: json['effectCode']?.toString() ?? '',
      targetCode: json['targetCode']?.toString() ?? 'self',
      magnitudeBps: readInt('magnitudeBps'),
      durationMs: readInt('durationMs'),
      cooldownMs: readInt('cooldownMs'),
      assetKey: json['assetKey']?.toString() ?? '',
      quantity: readInt('quantity'),
    );
  }
}

class PvpLoadoutResponse {
  const PvpLoadoutResponse({
    this.slotLimit = 2,
    this.slots = const <PvpLoadoutSlot>[],
    this.availableItems = const <PvpAvailableLoadoutItem>[],
  });

  final int slotLimit;
  final List<PvpLoadoutSlot> slots;
  final List<PvpAvailableLoadoutItem> availableItems;

  factory PvpLoadoutResponse.fromJson(dynamic json) {
    final raw = json is Map ? json['slots'] ?? json['Slots'] : json;
    final values = raw is List ? raw : const <dynamic>[];
    final rawAvailable = json is Map
        ? json['availableItems'] ?? json['AvailableItems']
        : null;
    final available = rawAvailable is List
        ? rawAvailable
              .whereType<Map>()
              .map(
                (value) => PvpAvailableLoadoutItem.fromJson(
                  Map<String, dynamic>.from(value),
                ),
              )
              .where((item) => item.itemId.isNotEmpty)
              .toList(growable: false)
        : const <PvpAvailableLoadoutItem>[];
    return PvpLoadoutResponse(
      slotLimit: json is Map
          ? (json['slotLimit'] as num?)?.toInt() ??
                (json['SlotLimit'] as num?)?.toInt() ??
                2
          : 2,
      slots: values
          .whereType<Map>()
          .map(
            (value) =>
                PvpLoadoutSlot.fromJson(Map<String, dynamic>.from(value)),
          )
          .where((slot) => slot.slotNo > 0)
          .toList(growable: false),
      availableItems: available,
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
