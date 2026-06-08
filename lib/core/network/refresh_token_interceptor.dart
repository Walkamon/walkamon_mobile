/*
   Khi bạn đang dùng app mà Token đăng nhập bị hết hạn, server sẽ trả về lỗi 401 Unauthorized. File này sẽ tự động chặn lỗi này lại, âm thầm gọi API lấy Token mới (Refresh Token), cập nhật lại Token mới vào máy, rồi gửi lại request bị lỗi ban đầu. Tất cả diễn ra ngầm, người dùng không hề biết và không bị văng ra màn hình đăng nhập.
*/
