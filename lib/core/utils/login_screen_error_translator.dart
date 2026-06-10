String translateError(String error) {
  final err = error.trim().toLowerCase();

  // ── Thêm các lỗi liên quan đến Đăng Nhập (Login) ──────────────────────────
  if (err.contains('invalid credentials') ||
      err.contains('wrong password') ||
      err.contains('user not found') ||
      err.contains('incorrect email or password')) {
    return 'Email hoặc mật khẩu không chính xác.';
  }
  if (err.contains('account is locked') || err.contains('account disabled')) {
    return 'Tài khoản của bạn đã bị khóa hoặc vô hiệu hóa.';
  }
  if (err.contains('email not verified') ||
      err.contains('please verify your email')) {
    return 'Email của bạn chưa được xác thực. Vui lòng xác thực trước.';
  }

  return error.isNotEmpty ? error : 'Đã xảy ra lỗi không xác định.';
}

// Giữ lại các alias cũ để tránh broken code ở màn Register
String translateRegisterError(String error) => translateError(error);
String translateLoginError(String error) => translateError(error);
