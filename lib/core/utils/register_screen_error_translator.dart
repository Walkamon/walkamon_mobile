/// Hàm chuyển dịch các thông báo lỗi liên quan đến RegisterScreen.
String translateError(String error) {
  final err = error.trim().toLowerCase();
  
  if (err.contains('email already exists') || err.contains('email is already registered')) {
    return 'Email này đã được đăng ký sử dụng.';
  }
  if (err.contains('username already exists') || err.contains('username is taken')) {
    return 'Tên tài khoản này đã tồn tại.';
  }
  if (err.contains('password is too weak') || err.contains('weak password')) {
    return 'Mật khẩu quá yếu. Vui lòng chọn mật khẩu mạnh hơn.';
  }
  if (err.contains('invalid email')) {
    return 'Định dạng email không hợp lệ.';
  }
  if (err.contains('too many requests') || err.contains('rate limit')) {
    return 'Bạn đã gửi quá nhiều yêu cầu. Vui lòng thử lại sau vài phút.';
  }
  if (err.contains('otp request is invalid')) {
    return 'Mã yêu cầu OTP không hợp lệ.';
  }
  if (err.contains('otp has expired')) {
    return 'Mã OTP đã hết hạn.';
  }
  if (err.contains('otp is invalid')) {
    return 'Mã OTP không chính xác.';
  }
  if (err.contains('new password is required')) {
    return 'Vui lòng nhập mật khẩu mới.';
  }
  if (err.contains('new password must')) {
    return 'Mật khẩu mới chưa đáp ứng yêu cầu bảo mật.';
  }
  if (err.contains('internal server error')) {
    return 'Lỗi hệ thống từ máy chủ. Vui lòng thử lại sau.';
  }
  if (err.contains('connection error') || err.contains('network error') || err.contains('xmlhttprequest')) {
    return 'Lỗi kết nối mạng. Vui lòng kiểm tra lại kết nối internet.';
  }
  
  return error.isNotEmpty ? error : 'Đã xảy ra lỗi không xác định.';
}

// Backward compatible alias
String translateRegisterError(String error) => translateError(error);
