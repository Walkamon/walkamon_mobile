class ApiConstants {
  static const String baseUrl = 'https://walkamon.azurewebsites.net';

  // Auth Endpoints
  static const String register = '/api/auth/register';
  static const String verifyOtp = '/api/auth/register/verify';
  static const String resendOtp = '/api/auth/register/resend-otp';
  static const String forgotPassword = '/api/auth/forgot-password';
  static const String resetForgotPassword = '/api/auth/forgot-password/reset';
  static const String login = '/api/auth/login';

  // Item Endpoints
  static const String items = '/api/items';
  static String itemById(String id) => '/api/items/$id';

  // Item Type Endpoints
  static const String itemTypes = '/api/item-types';
  static String itemTypeById(String id) => '/api/item-types/$id';
}
