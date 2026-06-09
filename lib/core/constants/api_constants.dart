class ApiConstants {
  static const String baseUrl = 'https://walkamon-api-cmahbse2dnhtb8gj.malaysiawest-01.azurewebsites.net';

  // Auth Endpoints
  static const String register = '/api/auth/register';
  static const String verifyOtp = '/api/auth/register/verify';
  static const String resendOtp = '/api/auth/register/resend-otp';
  static const String forgotPassword = '/api/auth/forgot-password';
  static const String resetForgotPassword = '/api/auth/forgot-password/reset';

  // Item Endpoints
  static const String items = '/api/items';
  static String itemById(String id) => '/api/items/$id';

  // Item Type Endpoints
  static const String itemTypes = '/api/item-types';
  static String itemTypeById(String id) => '/api/item-types/$id';
}
