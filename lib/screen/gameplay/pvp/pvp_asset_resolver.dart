import 'dart:ui' show Rect;

import '../../../core/constants/app_assets.dart';
import '../../../data/models/pvp_models.dart';

/// Maps API codes → bundled `assets/Mobile/PVP` paths from the V1 manifest.
abstract final class PvpAssetResolver {
  static const hudCenterSlice = Rect.fromLTWH(352, 128, 64, 128);

  static String mapForNow(DateTime now) {
    return mapsForNow(now).first;
  }

  static List<String> mapsForNow(DateTime now) {
    final hour = now.hour;
    final isNight = hour >= 18 || hour < 6;
    return isNight
        ? const [
            AppAssets.pvpMapNightStart,
            AppAssets.pvpMapNightLoop,
            AppAssets.pvpMapNightFinish,
          ]
        : const [
            AppAssets.pvpMapMorningStart,
            AppAssets.pvpMapMorningLoop,
            AppAssets.pvpMapMorningFinish,
          ];
  }

  static List<String> petAnimationFrames({
    required String affinityCode,
    required int stageNo,
    String state = 'race',
  }) {
    final normalizedAffinity = affinityCode.trim().toLowerCase();
    final requestedState = state.trim().toLowerCase();
    final normalizedState =
        const {'race', 'win', 'lose'}.contains(requestedState)
        ? requestedState
        : 'race';
    final frameCount = normalizedState == 'race' ? 12 : 8;

    final root = switch (normalizedAffinity) {
      'dawn' =>
        'assets/Mobile/Tinh Linh Bình Minh/stage${stageNo.clamp(1, 2)}/pvp',
      'moonlight' =>
        'assets/Mobile/TInh Linh Ánh Trăng/stage${stageNo.clamp(1, 2)}/pvp',
      'warm_sun' when stageNo.clamp(1, 2) == 1 =>
        'assets/Mobile/TinhLinhNangAm/Stage1/pvp',
      'warm_sun' => 'assets/Mobile/TinhLinhNangAm/stage2/pvp',
      _ => 'assets/Mobile/Mầm Non/pvp',
    };

    return List<String>.generate(
      frameCount,
      (index) =>
          '$root/$normalizedState/${normalizedState}_F${(index + 1).toString().padLeft(2, '0')}.png',
      growable: false,
    );
  }

  static String affinityDisplayName(String? affinityCode) {
    switch ((affinityCode ?? '').trim().toLowerCase()) {
      case 'warm_sun':
        return 'Nắng Ấm';
      case 'dawn':
        return 'Bình Minh';
      case 'moonlight':
        return 'Ánh Trăng';
      case 'sprout':
        return 'Thực Vật';
      default:
        return affinityCode?.trim().isNotEmpty == true
            ? affinityCode!.trim()
            : 'Thực Vật';
    }
  }

  static String? passiveForAffinity(String? affinityCode) {
    switch ((affinityCode ?? '').trim().toLowerCase()) {
      case 'dawn':
        return AppAssets.pvpDawnPassive;
      case 'warm_sun':
        return AppAssets.pvpWarmSunPassive;
      case 'moonlight':
        return AppAssets.pvpMoonlightPassive;
      default:
        return null;
    }
  }

  static String rankAsset({String? tierCode, String? flutterAssetPath}) {
    final fromApi = flutterAssetPath?.trim();
    if (fromApi != null && fromApi.isNotEmpty) {
      return fromApi;
    }

    switch ((tierCode ?? '').trim().toLowerCase()) {
      case 'mam_dong':
        return AppAssets.pvpRankSprout;
      case 'la_bac':
        return AppAssets.pvpRankLeaf;
      case 'nu_vang':
        return AppAssets.pvpRankBud;
      case 'hoa_lam':
        return AppAssets.pvpRankFlower;
      case 'trang_tim':
        return AppAssets.pvpRankMoon;
      case 'tinh_linh_cau_vong':
        return AppAssets.pvpRankLumina;
      default:
        return AppAssets.pvpRankSprout;
    }
  }

  static String rankAssetFromTier(PvpRankTierResponse? rank) {
    return rankAsset(
      tierCode: rank?.tierCode,
      flutterAssetPath: rank?.flutterAssetPath,
    );
  }

  static String? itemIcon(String itemCode) {
    switch (itemCode.trim().toLowerCase()) {
      case 'haste':
        return AppAssets.pvpHasteItem;
      case 'slow':
        return AppAssets.pvpSlowItem;
      case 'cleanse':
        return AppAssets.pvpCleanseItem;
      case 'shield':
        return AppAssets.pvpShieldItem;
      default:
        return null;
    }
  }

  static String? statusIcon(String statusCode) {
    switch (statusCode.trim().toLowerCase()) {
      case 'haste':
        return AppAssets.pvpHasteStatus;
      case 'slow':
        return AppAssets.pvpSlowStatus;
      case 'cleanse':
        return AppAssets.pvpCleanseStatus;
      case 'shield':
        return AppAssets.pvpShieldStatus;
      default:
        return null;
    }
  }

  static List<String> vfxFrames(String effectCode) {
    switch (effectCode.trim().toLowerCase()) {
      case 'haste':
        return AppAssets.pvpSpeedTrailFrames();
      case 'slow':
        return AppAssets.pvpSlowMistFrames();
      case 'cleanse':
        return AppAssets.pvpCleanseBurstFrames();
      case 'shield':
        return AppAssets.pvpShieldBubbleFrames();
      case 'rank_up':
        return AppAssets.pvpRankUpFrames();
      default:
        return const <String>[];
    }
  }

  static int vfxFps(String effectCode) {
    switch (effectCode.trim().toLowerCase()) {
      case 'slow':
        return 8;
      case 'shield':
      case 'rank_up':
        return 10;
      default:
        return 12;
    }
  }

  static bool vfxLoops(String effectCode) {
    switch (effectCode.trim().toLowerCase()) {
      case 'cleanse':
      case 'rank_up':
        return false;
      default:
        return true;
    }
  }
}
