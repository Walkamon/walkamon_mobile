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

  // PvP maps
  static const pvpMapMorning = '$root/PVP/Maps/pvp_map_morning_portrait.png';
  static const pvpMapNight = '$root/PVP/Maps/pvp_map_night_portrait.png';

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
