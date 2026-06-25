/// Hàm chuyển dịch các thông báo lỗi liên quan đến gửi feedback.
String translateSendFeedbackError(String error) {
  final err = error.trim().toLowerCase();

  if (err.contains('you can only submit feedback once every 24') ||
      err.contains('24 hours') ||
      err.contains('24 giờ')) {
    return 'Bạn chỉ có thể gửi phản hồi một lần trong vòng 24 giờ.';
  }

  if (err.contains('connection error') ||
      err.contains('network error') ||
      err.contains('xmlhttprequest')) {
    return 'Lỗi kết nối mạng. Vui lòng kiểm tra lại kết nối internet.';
  }

  return error.isNotEmpty ? error : 'Đã xảy ra lỗi không xác định.';
}
