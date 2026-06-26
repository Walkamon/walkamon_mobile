class ApiConstants {
  static const String baseUrl = 'https://walkamon.azurewebsites.net';
  // Auth Endpoints
  static const String register = '/api/auth/register';
  static const String verifyOtp = '/api/auth/register/verify';
  static const String resendOtp = '/api/auth/register/resend-otp';
  static const String forgotPassword = '/api/auth/forgot-password';
  static const String resetForgotPassword = '/api/auth/forgot-password/reset';
  static const String changePassword = '/api/auth/change-password';
  static const String login = '/api/auth/login';
  static const String googleLogin = '/api/auth/google-login';
  static const String logout = '/api/auth/logout';

  // settings Endpoints
  static const String userFeedback = '/api/user-feedback';

  // Daily Step Endpoints
  static const String dailySteps = '/api/daily-steps';

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
  static String claimMission(String missionId) => '/api/missions/$missionId/claim';

  // Challenge Endpoints
  static const String challengeRandom = '/api/challenges/random';
  static String cancelChallenge(String userMissionId) =>
      '/api/challenges/$userMissionId/cancel';
}
