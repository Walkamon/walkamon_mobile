abstract final class AppAssets {
  static const root = 'assets/Mobile';

  // Auth and onboarding
  static const authGarden = '$root/Auth/auth_garden_portrait.png';
  static const welcome = '$root/Onboarding/welcome_portrait.png';
  static const onboardingSeed = '$root/Onboarding/onboarding_seed_portrait.png';
  static const onboardingNamePet =
      '$root/Onboarding/onboarding_name_pet_portrait.png';
  static const dailyReward = '$root/Onboarding/daily_reward_portrait.png';
  static const menuBackdrop = '$root/Menu/menu_backdrop_portrait.png';

  // Notifications and action feedback
  static const toastFeedbackFrame = '$root/ui_frames/toast_feedback_9slice.png';
  static const rewardResultFrame = '$root/ui_frames/reward_result_9slice.png';
  static const eventFallbackBanner =
      '$root/Notifications/event_fallback_banner.png';

  static const notificationMaintenance = '$root/icon/system/maintenance.png';
  static const notificationPatchNotes = '$root/icon/system/patch_notes.png';
  static const notificationNews = '$root/icon/system/news.png';
  static const notificationAnnouncement = '$root/icon/system/announcement.png';
  static const notificationSuccess = '$root/icon/actions/34_confirm.png';
  static const notificationError = '$root/icon/system/error.png';
  static const notificationWarning = '$root/icon/system/warning.png';
  static const notificationInfo = '$root/icon/system/info.png';
  static const notificationEvent = '$root/icon/system/calendar.png';
  static const notificationRewardClaim =
      '$root/icon/actions/45_claim_reward.png';

  static const notificationCatalogAssets = [
    toastFeedbackFrame,
    rewardResultFrame,
    eventFallbackBanner,
    notificationMaintenance,
    notificationPatchNotes,
    notificationNews,
    notificationAnnouncement,
    notificationSuccess,
    notificationError,
    notificationWarning,
    notificationInfo,
    notificationEvent,
    notificationRewardClaim,
  ];

  static const authLoginSteps = '$root/icon/auth/login_steps.png';
  static const authRegisterSeed = '$root/icon/auth/register_seed.png';
  static const authKey = '$root/icon/auth/key.png';
  static const authLock = '$root/icon/auth/lock.png';
  static const authVisibility = '$root/icon/auth/visibility.png';
  static const authVisibilityOff = '$root/icon/auth/visibility_off.png';
  static const authResetPassword = '$root/icon/auth/reset_password.png';
  static const authVerified = '$root/icon/auth/verified.png';
  static const authMail = '$root/icon/auth/mail.png';
  static const authSend = '$root/icon/auth/send.png';
  static const authLanguage = '$root/icon/auth/language.png';
  static const authPrivacy = '$root/icon/auth/privacy.png';

  // Home
  static const homeSprout = '$root/HomeBackgrounds/home_mam_non_portrait.png';
  static const homeDawn = '$root/HomeBackgrounds/home_binh_minh_portrait.png';
  static const homeWarmSun = '$root/HomeBackgrounds/home_nang_am_portrait.png';
  static const homeMoonlight =
      '$root/HomeBackgrounds/home_anh_trang_portrait.png';

  // Home chrome / navigation icons
  static const iconHomeNav = '$root/icon/navigation/01_home.png';
  static const iconStepsNav = '$root/icon/navigation/03_steps.png';
  static const iconMissionNav = '$root/icon/navigation/04_mission.png';
  static const iconInventoryNav = '$root/icon/navigation/05_inventory.png';
  static const iconShopNav = '$root/icon/navigation/06_shop.png';
  static const iconFriendsNav = '$root/icon/navigation/08_friends.png';
  static const iconProfileNav = '$root/icon/navigation/09_profile.png';
  static const iconSettingsNav = '$root/icon/navigation/10_settings.png';
  static const iconSteps = '$root/icon/resources/11_step.png';
  static const iconDewDrop = '$root/icon/resources/15_dew_drop.png';
  static const iconDailyReward = '$root/icon/resources/20_daily_reward.png';
  static const iconNotificationBell = '$root/icon/system/notification_bell.png';
  static const iconInfo = '$root/icon/actions/53_info.png';
  static const iconClose = '$root/icon/action_button/basic_actions/06_close.png';
  static const iconPvpBattle =
      '$root/icon/friend_battle_pvp/friend_battle_start/14_battle.png';

  static List<String> get homeChromeAssets => [
    iconHomeNav,
    iconStepsNav,
    iconMissionNav,
    iconInventoryNav,
    iconShopNav,
    iconFriendsNav,
    iconProfileNav,
    iconSettingsNav,
    iconSteps,
    iconDewDrop,
    iconDailyReward,
    iconNotificationBell,
    iconInfo,
    iconClose,
    iconPvpBattle,
    homeSprout,
    homeDawn,
    homeWarmSun,
    homeMoonlight,
  ];

  // Pet runtime assets (catalog + fallbacks only; master atlases stay offline)
  static const petRuntimeRoot = '$root/flame/pet_runtime_v7_2';
  static const petRuntimeCatalogV1 =
      '$petRuntimeRoot/pet_runtime_catalog_v1.json';
  static const petRuntimeAnimationsV4 =
      '$petRuntimeRoot/pet_animations_v4.json';

  static const petRuntimeManifestAssets = [
    '$petRuntimeRoot/manifest_sprout_stage0_v4.json',
    '$petRuntimeRoot/manifest_warm_sun_stage1_v4.json',
    '$petRuntimeRoot/manifest_warm_sun_stage2_v4.json',
    '$petRuntimeRoot/manifest_dawn_stage1_v4.json',
    '$petRuntimeRoot/manifest_dawn_stage2_v4.json',
    '$petRuntimeRoot/manifest_moonlight_stage1_v4.json',
    '$petRuntimeRoot/manifest_moonlight_stage2_v4.json',
  ];

  static const petRuntimeFallbackAssets = [
    '$petRuntimeRoot/fallback_sprout_stage0_eef089f06193e311.png',
    '$petRuntimeRoot/fallback_warm_sun_stage1_e2992a6362d2f2f0.png',
    '$petRuntimeRoot/fallback_warm_sun_stage2_854ad2fb82016339.png',
    '$petRuntimeRoot/fallback_dawn_stage1_d1a28f0045a3211e.png',
    '$petRuntimeRoot/fallback_dawn_stage2_83a65898a5d2f264.png',
    '$petRuntimeRoot/fallback_moonlight_stage1_892833fec78f85bb.png',
    '$petRuntimeRoot/fallback_moonlight_stage2_6a3c74cc5bd6ddcd.png',
  ];

  static List<String> get petRuntimeCatalogAssets => [
    petRuntimeCatalogV1,
    petRuntimeAnimationsV4,
    ...petRuntimeManifestAssets,
    ...petRuntimeFallbackAssets,
  ];

  // PvP lobby / friend-battle icons
  static const pvpIconAutoBattle =
      '$root/icon/friend_battle_pvp/battle_pvp/24_auto_battle.png';
  static const pvpIconChallenge =
      '$root/icon/friend_battle_pvp/friend_battle_start/15_challenge.png';
  static const pvpIconBattleHistory =
      '$root/icon/friend_battle_pvp/battle_pvp/21_battle_history.png';
  static const pvpIconInviteFriend =
      '$root/icon/friend_battle_pvp/friend_social_continued/09_invite_friend.png';

  // PvP maps
  static const pvpMapMorningStart =
      '$root/PVP/Maps/pvp_map_morning_start_portrait.png';
  static const pvpMapMorningLoop =
      '$root/PVP/Maps/pvp_map_morning_loop_portrait.png';
  static const pvpMapMorningFinish =
      '$root/PVP/Maps/pvp_map_morning_finish_portrait.png';
  static const pvpMapNightStart =
      '$root/PVP/Maps/pvp_map_night_start_portrait.png';
  static const pvpMapNightLoop =
      '$root/PVP/Maps/pvp_map_night_loop_portrait.png';
  static const pvpMapNightFinish =
      '$root/PVP/Maps/pvp_map_night_finish_portrait.png';

  // Backward-compatible defaults while the PvP scene adopts phase switching.
  static const pvpMapMorning = pvpMapMorningStart;
  static const pvpMapNight = pvpMapNightStart;

  // PvP realtime items
  static const pvpHasteItem = '$root/PVP/items/01_haste_nectar.png';
  static const pvpSlowItem = '$root/PVP/items/02_slow_mist_vial.png';
  static const pvpCleanseItem = '$root/PVP/items/03_cleanse_dew.png';
  static const pvpShieldItem = '$root/PVP/items/04_shield_acorn.png';

  // PvP status
  static const pvpHasteStatus = '$root/PVP/status/haste.png';
  static const pvpSlowStatus = '$root/PVP/status/slow.png';
  static const pvpCleanseStatus = '$root/PVP/status/cleanse.png';
  static const pvpShieldStatus = '$root/PVP/status/shield.png';

  // PvP spirit passives
  static const pvpDawnPassive =
      '$root/PVP/passives/passive_binh_minh_stage1.png';
  static const pvpWarmSunPassive =
      '$root/PVP/passives/passive_nang_am_stage1.png';
  static const pvpMoonlightPassive =
      '$root/PVP/passives/passive_anh_trang_stage1.png';

  // PvP ranks
  static const pvpRankSprout = '$root/PVP/ranks/rank_01_mam_dong.png';
  static const pvpRankLeaf = '$root/PVP/ranks/rank_02_la_bac.png';
  static const pvpRankBud = '$root/PVP/ranks/rank_03_nu_vang.png';
  static const pvpRankFlower = '$root/PVP/ranks/rank_04_hoa_lam.png';
  static const pvpRankMoon = '$root/PVP/ranks/rank_05_trang_tim.png';
  static const pvpRankLumina = '$root/PVP/ranks/rank_06_tinh_linh_cau_vong.png';

  static const pvpTwoSlotHud = '$root/PVP/ui/pvp_two_slot_hud_9slice.png';

  static List<String> pvpSpeedTrailFrames() =>
      _numberedFrames('speed_trail', 'speed_trail');

  static List<String> pvpSlowMistFrames() =>
      _numberedFrames('slow_mist', 'slow_mist');

  static List<String> pvpCleanseBurstFrames() =>
      _numberedFrames('cleanse_burst', 'cleanse_burst');

  static List<String> pvpShieldBubbleFrames() =>
      _numberedFrames('shield_bubble', 'shield_bubble');

  static List<String> pvpRankUpFrames() =>
      _numberedFrames('rank_up', 'rank_up');

  static List<String> _numberedFrames(
    String folder,
    String prefix,
  ) => List.generate(
    8,
    (index) =>
        '$root/PVP/vfx/$folder/${prefix}_F${(index + 1).toString().padLeft(2, '0')}.png',
    growable: false,
  );

  static List<String> get pvpCatalogAssets => [
    pvpIconAutoBattle,
    pvpIconChallenge,
    pvpIconBattleHistory,
    pvpIconInviteFriend,
    pvpMapMorning,
    pvpMapNight,
    pvpHasteItem,
    pvpSlowItem,
    pvpCleanseItem,
    pvpShieldItem,
    pvpHasteStatus,
    pvpSlowStatus,
    pvpCleanseStatus,
    pvpShieldStatus,
    pvpDawnPassive,
    pvpWarmSunPassive,
    pvpMoonlightPassive,
    pvpRankSprout,
    pvpRankLeaf,
    pvpRankBud,
    pvpRankFlower,
    pvpRankMoon,
    pvpRankLumina,
    pvpTwoSlotHud,
    ...pvpSpeedTrailFrames(),
    ...pvpSlowMistFrames(),
    ...pvpCleanseBurstFrames(),
    ...pvpShieldBubbleFrames(),
    ...pvpRankUpFrames(),
  ];
}
