/// Hàm chuyển dịch các thông báo lỗi liên quan đến OTPScreen.
String translateOtpError(String error) {
  final err = error.trim().toLowerCase();

  if (err.contains('otp is invalid') || err.contains('invalid otp')) {
    return 'Mã OTP không hợp lệ hoặc đã hết hạn.';
  }
  if (err.contains('request code not found') ||
      err.contains('request code is invalid')) {
    return 'Yêu cầu xác thực không hợp lệ. Vui lòng đăng ký lại.';
  }
  if (err.contains('session expired') ||
      err.contains('register session expired')) {
    return 'Phiên đăng ký đã hết hạn. Vui lòng đăng ký lại.';
  }
  if (err.contains('too many requests') || err.contains('rate limit')) {
    return 'Bạn đã gửi quá nhiều yêu cầu. Vui lòng thử lại sau vài phút.';
  }
  if (err.contains('internal server error')) {
    return 'Lỗi hệ thống từ máy chủ. Vui lòng thử lại sau.';
  }
  if (err.contains('connection error') ||
      err.contains('network error') ||
      err.contains('xmlhttprequest')) {
    return 'Lỗi kết nối mạng. Vui lòng kiểm tra lại kết nối internet.';
  }

  return error.isNotEmpty ? error : 'Đã xảy ra lỗi không xác định.';
}
