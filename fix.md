1. API thoát trận
POST /api/pvp/sprint/matches/{matchId}/forfeit
Authorization: Bearer <JWT>
Content-Length: 0
Không gửi request body.
Chỉ hiển thị nút “Thoát trận” khi:
statusCode = countdown
hoặc
statusCode = running
Khi người dùng xác nhận:
Disable nút để chống bấm hai lần.
Gọi API forfeit.
Dừng gửi step PvP và khóa các nút item.
Sau thành công chuyển sang màn kết quả.
Ví dụ response:
{
  "success": true,
  "status": 200,
  "message": "Sprint match forfeited.",
  "data": {
    "matchId": "c030422e-e747-4420-b9e8-11eab3fbda80",
    "statusCode": "finished",
    "finishReasonCode": "user_forfeit",
    "forfeitedByUserId": "USER_ID",
    "winnerUserId": "OPPONENT_USER_ID",
    "resolvedAt": "2026-07-28T18:30:00+07:00",

    "mmrBefore": 1000,
    "mmrDelta": -16,
    "mmrAfter": 984,

    "rankBefore": {},
    "rankAfter": {},
    "tierChanged": false,

    "canClaimReward": false,
    "claimedAt": null,
    "participants": []
  }
}
Lưu ý:
Ranked: người thoát bị trừ MMR.
Friendly: mmrDelta = 0.
Người thoát không nhận reward.
Đối thủ thắng và nhận reward bình thường.
Nếu đối thủ là bot thì winnerUserId có thể là null. Hãy đọc participants[].resultCode, không chỉ dựa vào winnerUserId.
Retry của chính người đã thoát trả lại 200, không trừ MMR lần hai.
Mất mạng, tắt app hoặc rớt SignalR không tự động đầu hàng.
Xử lý lỗi:
401: JWT không hợp lệ.
403: user không thuộc trận.
404: không tìm thấy trận.
409: trận không còn ở countdown/running.
Nếu gặp 409 hoặc request timeout:
Gọi GET /api/pvp/sprint/matches/{matchId}.
Nếu trận đã finished, gọi tiếp GET /api/pvp/sprint/matches/{matchId}/result.
Đồng bộ lại UI theo response backend.
2. SignalR mới
Đăng ký chính xác hai handler:
hubConnection.on('match.forfeited', handleMatchForfeited);
hubConnection.on('match.finished', handleMatchFinished);
Envelope:
{
  "eventId": "EVENT_ID",
  "eventType": "match.forfeited",
  "aggregateId": "MATCH_OR_USER_ID",
  "payload": {
    "matchId": "MATCH_ID",
    "statusCode": "finished",
    "sequence": 20,
    "serverTime": "2026-07-28T18:30:00+07:00",
    "details": {
      "finishReasonCode": "user_forfeit",
      "forfeitedByUserId": "USER_ID",
      "winnerUserId": "OPPONENT_USER_ID"
    }
  }
}
Thứ tự event:
match.forfeited
match.finished
Khi nhận match.forfeited:
Khóa bước chân PvP và item.
Dừng countdown/race timer.
Có thể hiện thông báo ai đã thoát.
Khi nhận match.finished:
GET /api/pvp/sprint/matches/{matchId}/result
Sau đó render màn kết quả từ REST response.
Quan trọng: một logical event có thể đến từ cả user group và match group. FE phải bỏ event nếu:
payload.sequence <= lastProcessedSequence
Không chỉ dedupe bằng eventId, vì hai outbox event có thể khác eventId nhưng cùng match sequence.
3. Thông tin pet mới
GET /matches/{matchId}, GET /matches và GET /result hiện bổ sung trong participants[]:
{
  "matchPlayerId": "...",
  "participantTypeCode": "user",
  "userId": "...",
  "botProfileId": null,
  "displayName": "HungTV",
  "avatarUrl": "https://...",

  "petId": "...",
  "petName": "Lumina của tôi",
  "petLevel": 12,
  "petStageNo": 2,
  "spiritAffinityCode": "warm_sun",
  "petVisualCode": "warm_sun_stage2",

  "resultCode": "win"
}
Quy tắc asset:
sprout_stage0
dawn_stage1
dawn_stage2
warm_sun_stage1
warm_sun_stage2
moonlight_stage1
moonlight_stage2
...
avatarUrl là avatar tài khoản/bot, không phải ảnh pet.
Pet trong đường đua phải được chọn bằng petVisualCode.
Flame map petVisualCode sang sprite/atlas local.
Nếu chưa tìm thấy asset tương ứng, fallback sprout_stage0.
Pet là snapshot lúc tạo trận; pet tiến hóa sau đó không làm thay đổi lịch sử trận.
4. Thay đổi thời gian
Backend hiện trả ISO 8601 với giờ Việt Nam:
2026-07-28T18:30:00+07:00
FE cần:
final time = DateTime.parse(value);
Không được:
Tự cộng thêm 7 giờ.
Gắn thêm chữ Z.
Xóa phần +07:00.
Dùng DateTime.parse(value + 'Z').
Countdown nên đồng bộ bằng serverTime:
final serverTime = DateTime.parse(data['serverTime']).toUtc();
final countdownEnd =
    DateTime.parse(data['countdownEndsAt']).toUtc();

final clockOffset =
    serverTime.difference(DateTime.now().toUtc());

DateTime get estimatedServerNow =>
    DateTime.now().toUtc().add(clockOffset);

Duration get remaining =>
    countdownEnd.difference(estimatedS