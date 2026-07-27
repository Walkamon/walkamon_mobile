# PvP Lumina Sprint — FE handoff đã đối chiếu backend

Tài liệu này là contract chuẩn sau đợt sửa ngày **27/07/2026** cho UC-67 đến UC-74. Nếu nội dung khác với `PVP_FE_HANDOFF_UC67_UC74.md` cũ thì ưu tiên tài liệu này.

| UC | Chức năng |
|---|---|
| UC-67 | Invite/Receive friend |
| UC-68 | Find opponent |
| UC-69 | View sprint result |
| UC-70 | View sprint history |
| UC-71 | Claim sprint reward |
| UC-72 | View sprint match |
| UC-73 | View challenge invites |
| UC-74 | Configure sprint rewards |

Backend production được self-host trên một máy local/Ubuntu, public qua domain của hệ thống. Không dùng Azure SignalR và không dùng Redis. SignalR chạy in-process; deployment blue/green bảo đảm chỉ API slot đang active được phát outbox.

## 1. Các điểm FE phải sửa so với handoff cũ

| Nội dung cũ | Contract hiện tại |
|---|---|
| Waiting trả `Guid.Empty` | Waiting trả `matchId: null` |
| Waiting có thời gian mặc định `0001-01-01` | Có `serverTime`, `queuedAt`, `botFallbackAt` hợp lệ |
| Không có API kiểm tra queue | Có `GET /matchmaking/status` |
| History có thể lẫn trận active | Mặc định chỉ trả `finished` và `cancelled`; thêm `includeActive=true` nếu cần |
| Match không có nguồn và sequence cuối | Có `sourceCode` và `lastEventSequence` |
| Participant không có ID ổn định | Có `matchPlayerId`; event progress/effect dùng ID này |
| Chưa có `match.settling`/`match.cancelled` | Hai event này đã được phát |
| Match event đôi khi dùng `status` | Tất cả match event dùng `statusCode` |
| Reward GET thiếu danh sách item | `rewardItems` đã trả đủ |
| Reward có thể đổi khi admin sửa giữa trận | Reward được snapshot lúc tạo match; trận hiện tại không đổi |
| Worker chung phát SignalR | Worker chỉ chạy lifecycle; active API slot phát SignalR |

FE phải xóa mọi logic so sánh `matchId` với `00000000-0000-0000-0000-000000000000`.

## 2. URL, JWT và envelope

```text
REST player: {API_BASE_URL}/api/pvp/sprint
REST admin:  {API_BASE_URL}/api/admin/pvp/sprint
SignalR:     {API_BASE_URL}/hubs/pvp-sprint
```

Player endpoint/hub yêu cầu JWT role `User`; admin endpoint yêu cầu role `Admin`.

```http
Authorization: Bearer <access-token>
Content-Type: application/json
```

Success:

```json
{
  "success": true,
  "status": 200,
  "message": "Sprint match retrieved.",
  "data": {}
}
```

Error nghiệp vụ:

```json
{
  "success": false,
  "status": 409,
  "message": "Player already has an active PvP activity.",
  "data": null,
  "traceId": "..."
}
```

FE xử lý theo HTTP status và field dữ liệu, không xử lý logic bằng chuỗi `message`.

| HTTP | Xử lý FE |
|---:|---|
| 400 | Request/filter không hợp lệ; sửa input |
| 401 | Refresh token hoặc đăng nhập lại, sau đó reconnect hub |
| 403 | User không có quyền/không thuộc trận/không phải bạn bè |
| 404 | Resource không tồn tại hoặc đã bị dọn |
| 409 | State đã đổi hoặc request cạnh tranh; gọi GET authoritative state |
| 500 | Hiển thị retry; gửi `traceId` cho BE |

## 3. State machine

```text
idle
  ├─ invite_pending
  └─ queue_waiting
         └─ match_countdown
                └─ match_running
                       └─ match_settling
                              ├─ finished
                              └─ cancelled
```

Mỗi user chỉ có một activity PvP tại một thời điểm. Nếu POST trả `409`, FE không tự ghi đè local state; gọi `GET /matchmaking/status`, `GET /invites` hoặc `GET /matches/{id}`.

Timer:

- Invite hết hạn sau 60 giây.
- Queue thử tìm human trong khoảng MMR ±100.
- Sau 15 giây, backend chỉ ghép bot nếu đang có bot `is_active = true`.
- Nếu không có bot active, user vẫn ở queue; 15 giây không có nghĩa chắc chắn gặp bot.
- Countdown 5 giây.
- Running 30 giây.
- Settling khoảng 10 giây.

FE luôn tính timer từ `serverTime` với mốc `countdownEndsAt`, `endedAt`, `settlementEndsAt`; không dùng đồng hồ thiết bị làm nguồn chính.

## 4. SignalR bắt buộc

### 4.1 Kết nối

Ví dụ với `signalr_netcore`:

```dart
final connection = HubConnectionBuilder()
    .withUrl(
      '$apiBaseUrl/hubs/pvp-sprint',
      options: HttpConnectionOptions(
        accessTokenFactory: () async => tokenRepository.accessToken,
        transport: HttpTransportType.webSockets,
      ),
    )
    .withAutomaticReconnect()
    .build();

await connection.start();
```

`accessTokenFactory` trả token thuần, không thêm `Bearer `. Backend nhận token từ query `access_token` cho hub.

Khi connect, backend tự đưa connection vào group `user:{currentUserId}`. FE không cần và không được tự join user group.

Khi đã biết `matchId`:

```dart
await connection.invoke('JoinMatch', args: [matchId]);
```

Chỉ participant của match mới join được group `match:{matchId}`.

### 4.2 Envelope

Tên SignalR method chính là `eventType`. Payload:

```json
{
  "eventId": "uuid",
  "eventType": "match.progress",
  "aggregateId": "match-or-user-uuid",
  "payload": {
    "matchId": "uuid",
    "statusCode": "running",
    "sequence": 12,
    "serverTime": "2026-07-27T03:00:00Z",
    "details": {}
  }
}
```

`payload` là JSON object, không phải chuỗi JSON.

### 4.3 Event cần đăng ký

User group:

- `invite.created`
- `invite.declined`
- `invite.cancelled`
- `invite.expired`
- `queue.waiting`
- `match.assigned`
- `match.finished`
- `match.cancelled`
- `reward.claimed`

Match group:

- `match.created`
- `match.started`
- `match.progress`
- `match.item.used`
- `match.effect.applied`
- `match.effect.blocked`
- `match.effect.cleansed`
- `match.effect.expired`
- `match.settling`
- `match.finished`
- `match.cancelled`

`match.assigned`:

```json
{
  "eventId": "uuid",
  "eventType": "match.assigned",
  "aggregateId": "current-user-id",
  "payload": {
    "matchId": "uuid",
    "matchTypeCode": "ranked",
    "sourceCode": "matchmaking",
    "statusCode": "countdown",
    "countdownEndsAt": "2026-07-27T03:00:05Z",
    "lastEventSequence": 0,
    "serverTime": "2026-07-27T03:00:00Z"
  }
}
```

Ngay khi nhận event:

1. Dedupe bằng `eventId`.
2. Lưu `matchId`.
3. Gọi `JoinMatch(matchId)`.
4. Gọi `GET /matches/{matchId}`.
5. Render từ GET, rồi mới áp event mới hơn.

### 4.4 Sequence, reconnect và deploy

- Lưu `lastSequence` theo từng `matchId`.
- Bỏ event có `sequence <= lastSequence`.
- Nếu nhận `sequence > lastSequence + 1`, gọi GET match.
- Mỗi lần reconnect thành công: gọi `GET /matchmaking/status`; nếu có `matchId`, gọi `JoinMatch`, rồi GET match.
- Event là at-least-once nên duplicate là bình thường.
- Khi local production đổi blue/green slot, WebSocket cũ có thể bị đóng. Auto reconnect là bắt buộc.
- GET match là nguồn authoritative; SignalR chỉ giúp cập nhật nhanh.

## 5. UC-67 và UC-73 — invite/receive friend

### Tạo invite

```http
POST /api/pvp/sprint/invites
```

```json
{
  "targetUserId": "uuid"
}
```

Điều kiện:

- Không tự invite.
- Hai user đang là bạn bè.
- Hai user active.
- Cả hai không có activity PvP khác.
- Không có pending invite trùng cặp.

Response `data`:

```json
{
  "inviteId": "uuid",
  "user": {
    "userId": "uuid",
    "username": "Player B",
    "avatarUrl": null
  },
  "statusCode": "pending",
  "expiresAt": "2026-07-27T03:01:00Z",
  "createdAt": "2026-07-27T03:00:00Z",
  "matchId": null
}
```

### Accept/decline

```http
POST /api/pvp/sprint/invites/{inviteId}/response
```

```json
{ "accept": true }
```

- Chỉ invitee được gọi.
- Accept tạo friendly match và trả `matchId`.
- Decline trả `statusCode: "declined"` và `matchId: null`.
- Nếu accept: FE join match group và GET match ngay từ response; không cần chờ `match.assigned`.

### Cancel

```http
DELETE /api/pvp/sprint/invites/{inviteId}
```

Chỉ inviter được cancel pending invite.

### Danh sách invite

```http
GET /api/pvp/sprint/invites?direction=incoming&status=pending&page=1&pageSize=20
GET /api/pvp/sprint/invites?direction=sent&status=pending&page=1&pageSize=20
```

`direction`: `incoming|sent`.

`status`: `pending|accepted|declined|cancelled|expired`. Có thể bỏ status để lấy tất cả.

```json
{
  "page": 1,
  "pageSize": 20,
  "total": 1,
  "items": [
    {
      "inviteId": "uuid",
      "user": {
        "userId": "uuid",
        "username": "Player B",
        "avatarUrl": null
      },
      "statusCode": "pending",
      "expiresAt": "2026-07-27T03:01:00Z",
      "createdAt": "2026-07-27T03:00:00Z",
      "matchId": null
    }
  ]
}
```

## 6. UC-68 — matchmaking

### Join

```http
POST /api/pvp/sprint/matchmaking
```

```json
{ "matchTypeCode": "ranked" }
```

Waiting:

```json
{
  "activityType": "queue_waiting",
  "statusCode": "waiting",
  "matchId": null,
  "queuedAt": "2026-07-27T03:00:00Z",
  "botFallbackAt": "2026-07-27T03:00:15Z",
  "serverTime": "2026-07-27T03:00:00Z"
}
```

Ghép ngay:

```json
{
  "activityType": "match_countdown",
  "statusCode": "countdown",
  "matchId": "uuid",
  "queuedAt": null,
  "botFallbackAt": null,
  "serverTime": "2026-07-27T03:00:00Z"
}
```

Nếu `matchId` có giá trị, join group và GET match ngay.

### Kiểm tra state sau reconnect

```http
GET /api/pvp/sprint/matchmaking/status
```

Idle:

```json
{
  "activityType": "idle",
  "statusCode": "idle",
  "matchId": null,
  "queuedAt": null,
  "botFallbackAt": null,
  "serverTime": "2026-07-27T03:00:00Z"
}
```

Response cũng có thể là `waiting`, `countdown`, `running` hoặc `settling`.

### Rời queue

```http
DELETE /api/pvp/sprint/matchmaking
```

Chỉ gọi khi status hiện tại là `waiting`. Nếu request cạnh tranh với ghép trận và nhận `404/409`, gọi status lại.

## 7. UC-72 — view match

```http
GET /api/pvp/sprint/matches/{matchId}
```

Chỉ participant được xem.

```json
{
  "matchId": "uuid",
  "matchTypeCode": "ranked",
  "sourceCode": "matchmaking",
  "statusCode": "running",
  "createdAt": "2026-07-27T03:00:00Z",
  "countdownEndsAt": "2026-07-27T03:00:05Z",
  "startedAt": "2026-07-27T03:00:05Z",
  "endedAt": "2026-07-27T03:00:35Z",
  "settlementEndsAt": null,
  "serverTime": "2026-07-27T03:00:10Z",
  "ruleVersion": 1,
  "lastEventSequence": 12,
  "activeEffects": [],
  "loadout": [],
  "participants": [
    {
      "matchPlayerId": "uuid",
      "participantTypeCode": "user",
      "userId": "uuid",
      "botProfileId": null,
      "displayName": "Player A",
      "avatarUrl": null,
      "score": 12,
      "validatedSteps": 11,
      "distanceUnits": 120000,
      "speedMultiplierBps": 11000,
      "spiritAffinityCode": "dawn",
      "passiveSpeedBps": 1000,
      "resultCode": null
    }
  ]
}
```

Lưu ý:

- `participantTypeCode`: `user|bot`.
- Bot có `userId: null` và `botProfileId` khác null.
- `distanceUnits` quyết định thắng/thua.
- `validatedSteps` là raw step hợp lệ trong race.
- `speedMultiplierBps`: `10000 = 100%`, `11000 = 110%`.
- `score` là field tương thích UI cũ, được suy ra từ distance; không dùng để tự tính lại kết quả.
- Dùng `matchPlayerId` để map event progress/effect vào đúng runner.

## 8. Step session trong PvP

Chỉ tạo khi match đang `running`:

```http
POST /api/pvp/sprint/matches/{matchId}/step-session
```

```json
{
  "platformCode": "android",
  "sensorModeCode": "detector"
}
```

Submit:

```http
POST /api/pvp/sprint/matches/{matchId}/step-sessions/{sessionId}/batches
```

Contract sensor v2/canonical hash nằm trong tài liệu sensor riêng. FE không cộng điểm local. Chỉ update HUD từ response hoặc `match.progress`.

`match.progress.payload.details`:

```json
{
  "playerId": "match-player-uuid",
  "acceptedSteps": 2,
  "validatedSteps": 11,
  "distanceUnits": 120000,
  "speedMultiplierBps": 11000
}
```

## 9. UC-69 — result

```http
GET /api/pvp/sprint/matches/{matchId}/result
```

Chỉ gọi khi match `finished`; trước đó trả `409`.

Response gồm toàn bộ field của GET match và:

```json
{
  "mmrBefore": 1000,
  "mmrDelta": 16,
  "mmrAfter": 1016,
  "rankBefore": {
    "tierCode": "mam_sang",
    "displayName": "Mầm Sáng",
    "minMmr": -2147483648,
    "assetKey": "Assets/Mobile/PVP/Rank/mam_sang.png",
    "colorHex": "#91B95A"
  },
  "rankAfter": {},
  "tierChanged": false,
  "canClaimReward": true,
  "claimedAt": null
}
```

Ranked mới đổi MMR. Friendly có `mmrDelta = 0`.

## 10. UC-70 — history
r
```http
GET /api/pvp/sprint/matches?page=1&pageSize=20
```

Đây là danh sách phân trang, không phải API trả từng trận.

Filter:

- `matchType=ranked|friendly|event`
- `result=win|draw|lose`
- `from=<UTC ISO-8601>`
- `to=<UTC ISO-8601>`
- `includeActive=false|true`

Mặc định `includeActive=false`, chỉ có `finished` và `cancelled`.

```json
{
  "page": 1,
  "pageSize": 20,
  "total": 25,
  "items": [
    {
      "matchId": "uuid",
      "matchTypeCode": "ranked",
      "sourceCode": "bot",
      "statusCode": "finished",
      "participants": []
    }
  ]
}
```

Mỗi phần tử là `PvpMatchResponse` đầy đủ. FE không gọi GET detail cho toàn bộ list; chỉ gọi khi user mở một trận hoặc cần resync.

## 11. UC-71 — claim reward

```http
POST /api/pvp/sprint/matches/{matchId}/reward-claim
```

Không có body.

```json
{
  "walletBalance": 1250,
  "walletReward": 30,
  "rewardItems": [
    {
      "itemId": "uuid",
      "quantity": 1
    }
  ]
}
```

Quy tắc:

- Chỉ participant có entitlement mới claim được.
- Chỉ claim một lần.
- Wallet và inventory update trong cùng transaction.
- Retry sau timeout có thể nhận `409 already claimed`; FE gọi result, nếu `claimedAt != null` thì coi là thành công.
- Reward đã snapshot lúc tạo match nên admin thay config giữa trận không làm đổi reward trận đó.

## 12. UC-74 — admin configure rewards

```http
GET /api/admin/pvp/sprint/reward-rules
```

Trả đúng 9 rule khi hệ thống đã cấu hình:

```json
[
  {
    "matchTypeCode": "ranked",
    "resultCode": "win",
    "walletAmount": 30,
    "rewardItems": [
      {
        "itemId": "uuid",
        "quantity": 1
      }
    ],
    "isActive": true
  }
]
```

Update:

```http
PUT /api/admin/pvp/sprint/reward-rules
```

```json
{
  "rules": [
    {
      "matchTypeCode": "ranked",
      "resultCode": "win",
      "walletAmount": 30,
      "rewardItems": []
    }
  ]
}
```

Request thực tế bắt buộc đúng **9 tổ hợp**:

```text
ranked   × win/draw/lose
friendly × win/draw/lose
event    × win/draw/lose
```

Mỗi rule phải có `walletAmount > 0` hoặc ít nhất một reward item. Item phải active; quantity phải > 0.

Database mới không tự đoán giá trị economy. Admin phải cấu hình đủ 9 rule trước khi mở matchmaking/invite; thiếu matrix thì API tạo activity/match trả `409`.

## 13. Loadout và item realtime

```text
GET /api/pvp/sprint/loadout
PUT /api/pvp/sprint/loadout
POST /api/pvp/sprint/matches/{matchId}/items/use
```

Loadout tối đa 2 slot, không trùng item/effect. User phải sở hữu item.

Use:

```json
{
  "slotNo": 1,
  "clientActionId": "new-uuid-per-user-action"
}
```

Giữ nguyên `clientActionId` khi retry cùng một thao tác. Không tạo UUID mới vì có thể trừ item lần nữa cho một thao tác người dùng khác.

Chỉ dùng khi `running`. Response/event từ server mới quyết định `applied|blocked|cleansed`; mobile không tự áp hiệu ứng trước.

## 14. Checklist FE

- [ ] Dùng tài liệu này thay các warning cũ về `Guid.Empty`.
- [ ] Connect SignalR trước khi queue/invite.
- [ ] Đăng ký handler trước khi gọi API.
- [ ] Sau reconnect gọi matchmaking status.
- [ ] Khi có match: `JoinMatch` rồi GET match.
- [ ] Dedupe `eventId`.
- [ ] Theo dõi sequence theo match và GET khi có gap.
- [ ] Render participant bằng `matchPlayerId`.
- [ ] Timer dựa trên `serverTime`.
- [ ] History mặc định terminal-only.
- [ ] Claim retry an toàn bằng cách kiểm tra result.
- [ ] Dùng `clientActionId` ổn định khi retry item.
- [ ] Không tự tính điểm, effect, kết quả, MMR hoặc reward.
- [ ] Auto reconnect khi deployment local đổi slot.

## 15. Checklist BE/DevOps local production

- Chỉ container `worker` chạy notification scheduler và PvP lifecycle.
- `worker` phải có `BackgroundServices__PvpOutboxDispatcherEnabled=false`.
- Hai API slot có outbox dispatcher bật, nhưng chỉ slot khớp `/run/walkamon-deploy/active-slot` được publish.
- `active-slot` phải là `blue` hoặc `green` và được mount read-only vào API.
- Khi file thiếu/đọc lỗi, dispatcher fail-closed để tránh phát trùng.
- Không scale nhiều API active đồng thời nếu chưa có SignalR backplane.
- Cloudflare/proxy phải cho WebSocket path `/hubs/*` và không cache.
- Sau deploy smoke test: connect hub → queue → `match.assigned` → `JoinMatch` → `match.started`.
