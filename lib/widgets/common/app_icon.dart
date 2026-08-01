import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';

/// Renders Walkamon artwork for Material icon semantics that have a matching
/// asset, and falls back to Flutter's [Icon] for controls without custom art.
///
/// Existing screens can keep their `IconData` models while the visual mapping
/// stays centralized and testable. Pass [asset] when a screen needs a more
/// specific illustration than the default semantic mapping.
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.icon, {
    super.key,
    this.asset,
    this.size,
    this.color,
    this.semanticLabel,
    this.textDirection,
    this.shadows,
    this.tintAsset = false,
    this.useAsset = true,
  });

  final IconData? icon;
  final String? asset;
  final double? size;
  final Color? color;
  final String? semanticLabel;
  final TextDirection? textDirection;
  final List<Shadow>? shadows;

  /// Set only for artwork that is intentionally used as a monochrome glyph.
  /// Walkamon icons are full-color by default and should normally stay so.
  final bool tintAsset;

  /// Disable for tiny structural glyphs where bitmap artwork would lose detail.
  final bool useAsset;

  static String? assetFor(IconData? icon) => _materialAssetMap[icon];

  @override
  Widget build(BuildContext context) {
    final assetPath = useAsset ? (asset ?? assetFor(icon)) : null;
    if (assetPath == null) {
      return Icon(
        icon,
        size: size,
        color: color,
        semanticLabel: semanticLabel,
        textDirection: textDirection,
        shadows: shadows,
      );
    }

    final iconTheme = IconTheme.of(context);
    final effectiveSize = size ?? iconTheme.size ?? 24;
    final tint = tintAsset ? (color ?? iconTheme.color) : null;

    return Image.asset(
      assetPath,
      width: effectiveSize,
      height: effectiveSize,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      color: tint,
      colorBlendMode: tint == null ? null : BlendMode.srcIn,
      semanticLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
      errorBuilder: (context, error, stackTrace) => Icon(
        icon ?? Icons.image_not_supported,
        size: effectiveSize,
        color: color,
        semanticLabel: semanticLabel,
        textDirection: textDirection,
        shadows: shadows,
      ),
    );
  }
}

final Map<IconData, String> _materialAssetMap = Map.unmodifiable({
  // Actions and feedback.
  Icons.arrow_back: AppAssets.iconBack,
  Icons.arrow_back_rounded: AppAssets.iconBack,
  Icons.arrow_back_ios_new_rounded: AppAssets.iconBack,
  Icons.chevron_left: AppAssets.iconBack,
  Icons.chevron_left_rounded: AppAssets.iconBack,
  Icons.close: AppAssets.iconCloseAction,
  Icons.close_rounded: AppAssets.iconCloseAction,
  Icons.check: AppAssets.iconConfirm,
  Icons.check_rounded: AppAssets.iconConfirm,
  Icons.check_circle_outline: AppAssets.iconConfirm,
  Icons.check_circle_outline_rounded: AppAssets.iconConfirm,
  Icons.check_circle_rounded: AppAssets.iconConfirm,
  Icons.refresh: AppAssets.iconRefresh,
  Icons.refresh_rounded: AppAssets.iconRefresh,
  Icons.search: AppAssets.iconSearch,
  Icons.shuffle: AppAssets.iconSort,
  Icons.edit_rounded: AppAssets.iconEdit,
  Icons.delete_outline: AppAssets.iconTrash,
  Icons.info_outline: AppAssets.iconInfo,
  Icons.info_outline_rounded: AppAssets.iconInfo,
  Icons.help_outline: AppAssets.iconInfo,
  Icons.lightbulb_outline: AppAssets.iconInfo,
  Icons.send_rounded: AppAssets.iconSend,
  Icons.message_outlined: AppAssets.iconSend,
  Icons.touch_app: AppAssets.iconUse,
  Icons.logout_rounded: AppAssets.iconCloseAction,

  // Auth.
  Icons.lock_rounded: AppAssets.authLock,
  Icons.key_rounded: AppAssets.authKey,
  Icons.email_rounded: AppAssets.authMail,
  Icons.mail_rounded: AppAssets.authMail,
  Icons.gavel_rounded: AppAssets.authPrivacy,

  // Navigation and primary feature areas.
  Icons.home_rounded: AppAssets.iconHomeNav,
  Icons.storefront_outlined: AppAssets.iconShopNav,
  Icons.storefront_rounded: AppAssets.iconShopNav,
  Icons.backpack_outlined: AppAssets.iconInventoryNav,
  Icons.backpack_rounded: AppAssets.iconInventoryNav,
  Icons.track_changes_rounded: AppAssets.iconMissionNav,
  Icons.person_rounded: AppAssets.iconProfileNav,
  Icons.pets: AppAssets.iconSpiritNav,
  Icons.spa_outlined: AppAssets.iconSpiritNav,
  Icons.spa_rounded: AppAssets.iconSpiritNav,
  Icons.eco_rounded: AppAssets.iconSpiritNav,
  Icons.emoji_nature_rounded: AppAssets.iconSpiritNav,
  Icons.local_florist_outlined: AppAssets.iconSpiritNav,
  Icons.local_florist_rounded: AppAssets.iconSpiritNav,

  // Friends and battle.
  Icons.person_add_alt_1: AppAssets.iconAddFriend,
  Icons.person_add_alt_1_rounded: AppAssets.iconAddFriend,
  Icons.group_add_rounded: AppAssets.iconInviteFriend,
  Icons.person_remove: AppAssets.iconRemoveFriend,
  Icons.block: AppAssets.iconBlock,
  Icons.sports_kabaddi: AppAssets.iconBattle,
  Icons.sports_martial_arts: AppAssets.iconAttack,
  Icons.sports_esports: AppAssets.iconBattle,
  Icons.security: AppAssets.iconDefense,
  Icons.handshake: AppAssets.iconDraw,
  Icons.history_rounded: AppAssets.iconBattleHistory,
  Icons.speed: AppAssets.iconPower,
  Icons.military_tech: AppAssets.iconWin,

  // Inventory and resources.
  Icons.cake_outlined: AppAssets.iconFood,
  Icons.restaurant: AppAssets.iconFood,
  Icons.auto_awesome: AppAssets.iconMagicOrb,
  Icons.auto_awesome_rounded: AppAssets.iconMagicOrb,
  Icons.shopping_bag_outlined: AppAssets.iconShoppingBag,
  Icons.card_giftcard: AppAssets.iconDailyRewardRes,
  Icons.card_giftcard_rounded: AppAssets.iconDailyRewardRes,
  Icons.water_drop: AppAssets.iconDewDrop,
  Icons.water_drop_outlined: AppAssets.iconDewDrop,
  Icons.directions_walk: AppAssets.iconStep,
  Icons.directions_walk_outlined: AppAssets.iconStep,
  Icons.directions_walk_rounded: AppAssets.iconStep,
  Icons.bolt: AppAssets.iconEnergy,
  Icons.bolt_outlined: AppAssets.iconEnergy,
  Icons.bolt_rounded: AppAssets.iconEnergy,
  Icons.flash_on: AppAssets.iconEnergy,
  Icons.flash_on_rounded: AppAssets.iconEnergy,
  Icons.favorite_border_rounded: AppAssets.iconBond,
  Icons.favorite_rounded: AppAssets.iconBond,
  Icons.local_fire_department_rounded: AppAssets.iconStreakRes,
  Icons.monetization_on: AppAssets.iconCoin,
  Icons.flag_outlined: AppAssets.iconDailyGoal,
  Icons.tune_rounded: AppAssets.iconDailyGoal,

  // Profile and progress.
  Icons.emoji_events: AppAssets.iconAchievement,
  Icons.emoji_events_rounded: AppAssets.iconAchievement,
  Icons.bar_chart_rounded: AppAssets.iconStatistics,
  Icons.calendar_month_outlined: AppAssets.iconCalendar,
  Icons.calendar_month_rounded: AppAssets.iconCalendar,
  Icons.calendar_today_rounded: AppAssets.iconCalendar,
  Icons.schedule_outlined: AppAssets.iconSchedule,
  Icons.trending_up: AppAssets.iconTrend,
  Icons.trending_up_outlined: AppAssets.iconTrend,
  Icons.trending_up_rounded: AppAssets.iconTrend,
  Icons.card_membership_rounded: AppAssets.iconMembership,
  Icons.camera_alt_rounded: AppAssets.iconCameraSystem,
  Icons.star: AppAssets.iconLevelUp,
  Icons.star_rounded: AppAssets.iconLevelUp,
  Icons.stars_rounded: AppAssets.iconReadyToEvolve,
  Icons.chevron_right: AppAssets.iconChevronRight,
  Icons.chevron_right_rounded: AppAssets.iconChevronRight,
  Icons.expand_more_rounded: AppAssets.iconDropdown,
  Icons.keyboard_arrow_down_rounded: AppAssets.iconDropdown,

  // System and state.
  Icons.notifications: AppAssets.iconNotificationBell,
  Icons.notifications_none: AppAssets.iconNotificationBell,
  Icons.notifications_none_rounded: AppAssets.iconNotificationBell,
  Icons.campaign: AppAssets.iconAnnouncement,
  Icons.warning_amber_rounded: AppAssets.iconWarningSystem,
  Icons.warning_rounded: AppAssets.iconWarningSystem,
  Icons.error_outline: AppAssets.iconErrorSystem,
  Icons.error_outline_rounded: AppAssets.iconErrorSystem,
  Icons.error_rounded: AppAssets.iconErrorSystem,
  Icons.broken_image: AppAssets.iconImagePlaceholder,
  Icons.image_not_supported: AppAssets.iconImagePlaceholder,
  Icons.wifi_off: AppAssets.iconWifiOff,
  Icons.wifi_off_rounded: AppAssets.iconWifiOff,
  Icons.language: AppAssets.iconLanguageSystem,
  Icons.explore_outlined: AppAssets.iconExplore,
  Icons.music_note: AppAssets.iconMusic,
  Icons.volume_up_outlined: AppAssets.iconVolume,
  Icons.wb_sunny_outlined: AppAssets.iconSun,
  Icons.nightlight_round: AppAssets.iconMoon,
  Icons.dark_mode_outlined: AppAssets.iconThemeToggleDark,
  Icons.bug_report_outlined: AppAssets.iconReport,
  Icons.hourglass_top: AppAssets.iconTired,
});
