String translateError(String error) {
  // Chuyển toàn bộ chuỗi lỗi về chữ thường để so sánh chính xác nhất
  final err = error.trim().toLowerCase();

  if (err.contains('28444') ||
      err.contains('developer console is not set up correctly')) {
    return 'Google Login chưa được cấu hình đúng. Vui lòng kiểm tra package name, SHA-1/SHA-256 và OAuth client trong Google Console.';
  }

  // ── 1. LỖI NGHIỆP VỤ LOGIC TỪ BACKEND C# ──────────────────────────────────
  if (err.contains('user not found')) {
    return 'Tài khoản email này không tồn tại.';
  }
  if (err.contains('account is not activated')) {
    return 'Tài khoản chưa được kích hoạt. Vui lòng kiểm tra email.';
  }
  if (err.contains('account has been locked') ||
      err.contains('account disabled')) {
    return 'Tài khoản này đã bị khóa bởi ban quản trị.';
  }
  if (err.contains('account locked for 5 minutes')) {
    return 'Tài khoản bị khóa 5 phút do nhập sai quá nhiều lần.';
  }
  if (err.contains('wrong password')) {
    final RegExp regExp = RegExp(r'\d+');
    final match = regExp.firstMatch(
      error,
    ); // Tìm trên chuỗi gốc chưa viết thường
    if (match != null) {
      return 'Mật khẩu chưa đúng. Bạn còn ${match.group(0)} lần thử.';
    }
    return 'Mật khẩu không chính xác.';
  }
  if (err.contains('try again after')) {
    return 'Tài khoản đang tạm khóa. Vui lòng thử lại sau.';
  }

  // ── 2. LỖI ĐỊNH DẠNG TỪ FLUENTVALIDATION C# ──────────────────────────────
  if (err.contains('email is required')) {
    return 'Vui lòng nhập địa chỉ email.';
  }
  if (err.contains('invalid email format')) {
    return 'Định dạng email không hợp lệ.';
  }
  if (err.contains('password is required')) {
    return 'Vui lòng nhập mật khẩu.';
  }
  if (err.contains('at least 6 characters') || err.contains('minimumlength')) {
    return 'Mật khẩu phải chứa ít nhất 6 ký tự.';
  }
  if (err.contains('uppercase letter') || error.contains('[A-Z]')) {
    return 'Mật khẩu phải có ít nhất một chữ cái viết hoa.';
  }
  if (err.contains('lowercase letter') || error.contains('[a-z]')) {
    return 'Mật khẩu phải có ít nhất một chữ cái viết thường.';
  }
  if (err.contains('number') || error.contains(r'\d')) {
    return 'Mật khẩu phải chứa ít nhất một chữ số (0-9).';
  }
  if (err.contains('special character') || error.contains(r'[\W_]')) {
    return 'Mật khẩu phải chứa ít nhất một ký tự đặc biệt.';
  }

  return error.isNotEmpty ? error : 'Đã xảy ra lỗi không xác định.';
}

String translateRegisterError(String error) => translateError(error);
String translateLoginError(String error) => translateError(error);
