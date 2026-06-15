/// Chuyển dịch lỗi đổi mật khẩu từ backend sang tiếng Việt.
String translateChangePasswordError(String error) {
  final err = error.trim().toLowerCase();

  if (err.contains('current password is required') ||
      err.contains('currentpassword')) {
    return 'Vui lòng nhập mật khẩu hiện tại.';
  }
  if (err.contains('new password is required')) {
    return 'Vui lòng nhập mật khẩu mới.';
  }
  if (err.contains('new password must be at least 6 characters')) {
    return 'Mật khẩu mới phải có ít nhất 6 ký tự.';
  }
  if (err.contains('new password must contain at least one uppercase letter')) {
    return 'Mật khẩu mới phải chứa ít nhất một chữ hoa.';
  }
  if (err.contains('new password must contain at least one lowercase letter')) {
    return 'Mật khẩu mới phải chứa ít nhất một chữ thường.';
  }
  if (err.contains('new password must contain at least one number')) {
    return 'Mật khẩu mới phải chứa ít nhất một chữ số.';
  }
  if (err.contains(
    'new password must contain at least one special character',
  )) {
    return 'Mật khẩu mới phải chứa ít nhất một ký tự đặc biệt.';
  }
  if (err.contains('internal server error')) {
    return 'Lỗi hệ thống từ máy chủ. Vui lòng thử lại sau.';
  }
  if (err.contains('current password is invalid')) {
    return 'Mật khẩu hiện tại không đúng.';
  }
  if (err.contains('connection error') ||
      err.contains('network error') ||
      err.contains('xmlhttprequest')) {
    return 'Lỗi kết nối mạng. Vui lòng kiểm tra lại kết nối internet.';
  }

  return error.isNotEmpty ? error : 'Đã xảy ra lỗi không xác định.';
}
