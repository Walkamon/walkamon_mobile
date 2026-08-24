class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.walkamon.xyz',
  );
  // Auth Endpoints
  static const String register = '/api/auth/register';
  static const String verifyOtp = '/api/auth/register/verify';
  static const String resendOtp = '/api/auth/register/resend-otp';
  static const String forgotPassword = '/api/auth/forgot-password';
  static const String verifyForgotPasswordOtp =
      '/api/auth/forgot-password/verify';
  static const String resetForgotPassword = '/api/auth/forgot-password/reset';
  static const String resetForgotPasswordWithTicket =
      '/api/auth/forgot-password/reset-with-ticket';
  static const String changePassword = '/api/auth/change-password';
  static const String login = '/api/auth/login';
  static const String googleLogin = '/api/auth/google-login';
  static const String logout = '/api/auth/logout';
  static String friendProfile(String userId) =>
      '/api/auth/profile-friend/$userId';

  // settings Endpoints
  static const String profileTheme = '/api/auth/profile/theme';
  static const String userFeedback = '/api/user-feedback';

  // Daily Step Endpoints
  static const String stepSensorSession = '/api/step-sensor/session';
  static String stepSensorBatches(String sessionId) =>
      '/api/step-sensor/sessions/$sessionId/batches';

  // Daily Login Reward Endpoints
  static const String dailyLoginCalendar = '/api/daily-login-rewards/calendar';
  static const String claimDailyReward = '/api/daily-login-rewards/claim';

  // Step Goal Endpoints
  static const String stepGoal = '/api/Step-Goal';
  static const String stepGoalProgress = '/api/Step-Goal/progress';
  static const String stepGoalCurrentStreak = '/api/Step-Goal/current-streak';
  static const String stepGoalLongestStreak = '/api/Step-Goal/longest-streak';
  static const String stepGoalClaim = '/api/Step-Goal/claim';

  // Item Endpoints
  static const String items = '/api/items';
  static String itemById(String id) => '/api/items/$id';

  // Item Type Endpoints
  static const String itemTypes = '/api/item-types';
  static String itemTypeById(String id) => '/api/item-types/$id';

  // Inventory Endpoints
  static const String inventory = '/api/inventory';
  static String inventoryItemById(String id) => '/api/inventory/items/$id';
  static const String useInventoryItem = '/api/inventory/use';

  // Shop Endpoints
  static const String shopItems = '/api/shop';
  static String shopItemById(String id) => '/api/shop/$id';
  static const String buyShop = '/api/shop/buy';

  // Mission Endpoints
  static const String missions = '/api/missions';
  static String claimMission(String missionId) =>
      '/api/missions/$missionId/claim';

  // Challenge Endpoints
  static const String challengeRandom = '/api/challenges/random';
  static String claimChallenge(String userMissionId) =>
      '/api/challenges/$userMissionId/claim';
  static String cancelChallenge(String userMissionId) =>
      '/api/challenges/$userMissionId/cancel';

  // Achievement Endpoints
  static const String achievements = '/api/achievements';
  static String claimAchievement(String achievementId) =>
      '/api/achievements/$achievementId/claim';

  // Friend Endpoints
  static const String searchPlayers = '/api/friends/available-users';
  static const String friends = '/api/friends';
  static const String sendFriendRequest = '/api/friends/requests';
  static const String sentFriendRequests = '/api/friends/requests/sent';
  static String removeFriend(String friendId) => '/api/friends/$friendId';
  static String cancelFriendRequest(String requestId) =>
      '/api/friends/requests/$requestId';
  static const String receivedFriendRequests = '/api/friends/requests/received';
  static String respondToFriendRequest(String requestId) =>
      '/api/friends/requests/$requestId';

  // PvP Sprint Endpoints
  static const String pvpSprintMatches = '/api/pvp/sprint/matches';
  static const String pvpSprintInvites = '/api/pvp/sprint/invites';
  static const String pvpSprintMatchmaking = '/api/pvp/sprint/matchmaking';
  static const String pvpSprintMatchmakingStatus =
      '/api/pvp/sprint/matchmaking/status';
  static String pvpSprintMatchById(String matchId) =>
      '/api/pvp/sprint/matches/$matchId';
  static const String pvpSprintLoadout = '/api/pvp/sprint/loadout';
  static String pvpSprintMatchItems(String matchId) =>
      '/api/pvp/sprint/matches/$matchId/items/use';

  // Notification Endpoints
  static const String updateNotification = '/api/notifications/settings';
  static const String getNotifications = '/api/notifications';
  static String notificationDetail(String id) => '/api/notifications/$id';
  static const String registerDeviceToken = '/api/notifications/device-tokens';
  static const String deactivateDeviceToken =
      '/api/notifications/device-tokens/deactivate';
  static String deleteNotification(String id) => '/api/notifications/$id';

  // Pet Endpoints
  static const String petStatus = '/api/Pet/status';
  static const String petStoryStatus = '/api/Pet/story-status';
  static const String petMe = '/api/Pet/me';
  static const String petName = '/api/Pet/pet-name';
  static const String createStarterPet = '/api/Pet/create-stater-pet';
  static const String petTap = '/api/Pet/tap';
  static const String petFeed = '/api/Pet/feed';
  static String friendPet(String friendUserId) =>
      '/api/Pet/friend/$friendUserId';
}
