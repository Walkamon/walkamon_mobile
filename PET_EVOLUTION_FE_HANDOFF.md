# FE handoff — Chi tiết và tiến hóa tinh linh

Tài liệu này mô tả contract backend hiện có cho màn chi tiết tinh linh, tab tiến hóa, lịch sử tiến hóa và nút tiến hóa. Tất cả endpoint yêu cầu:

```http
Authorization: Bearer <JWT>
```

Base route:

```text
/api/pet
```

## 1. Dữ liệu tổng quan của tinh linh

```http
GET /api/pet/me
```

Response:

```json
{
  "success": true,
  "status": 200,
  "message": "Pet overview retrieved successfully.",
  "data": {
    "petId": "00000000-0000-0000-0000-000000000000",
    "nickname": "chothanh",
    "formName": "Tinh Linh Nắng Ấm",
    "affinityCode": "warm_sun",
    "level": 15,
    "currentExp": 240,
    "maxExp": 500,
    "currentEnergy": 80,
    "maxEnergy": 100,
    "currentLifeForce": 90,
    "maxLifeForce": 100,
    "currentBond": 100,
    "maxBond": 100,
    "stageNo": 1,
    "stageName": "Dạng Chói",
    "animationType": "idle",
    "canEvolve": true,
    "nextEvolutionLevel": 15
  }
}
```

Mapping UI:

| UI | Field |
|---|---|
| Tên riêng của tinh linh | `nickname` |
| Dạng/họ tinh linh | `formName` |
| Cấp độ gameplay | `level` |
| EXP | `currentExp / maxExp` |
| Giai đoạn tiến hóa | `stageNo`, `stageName` |
| Năng lượng | `currentEnergy / maxEnergy` |
| Sinh lực | `currentLifeForce / maxLifeForce` |
| Gắn kết | `currentBond / maxBond` |
| Family/asset code | `affinityCode` |
| Animation nên phát | `animationType` |
| Đủ level tiến hóa tiếp | `canEvolve` |
| Level yêu cầu tiếp theo | `nextEvolutionLevel` |

`affinityCode` hiện có bốn giá trị:

| Code | Cách hiển thị đề xuất |
|---|---|
| `sprout` | Mầm Non |
| `dawn` | Bình Minh |
| `warm_sun` | Nắng Ấm |
| `moonlight` | Ánh Trăng |

Không dùng `formName` hoặc tên tiếng Việt để chạy logic. Dùng `affinityCode`.

## 2. Danh sách giai đoạn tiến hóa

```http
GET /api/pet/evolution/stages
```

Response:

```json
{
  "success": true,
  "status": 200,
  "message": "Get evolution stages successfully.",
  "data": [
    {
      "stageId": "00000000-0000-0000-0000-000000000000",
      "stageNo": 1,
      "stageName": "Dạng Chói",
      "stateUrl": "https://...",
      "requiredLevel": 5,
      "isCurrent": true,
      "isUnlocked": true,
      "animations": [
        {
          "typeAnimation": "idle",
          "animationUrl": "https://..."
        }
      ]
    },
    {
      "stageId": "00000000-0000-0000-0000-000000000001",
      "stageNo": 2,
      "stageName": "Dạng Rực Sáng",
      "stateUrl": "https://...",
      "requiredLevel": 15,
      "isCurrent": false,
      "isUnlocked": true,
      "animations": []
    }
  ]
}
```

Quy tắc FE:

- Sắp xếp theo `stageNo` tăng dần; backend hiện đã trả theo thứ tự này.
- `isCurrent` xác định stage hiện tại.
- `isUnlocked` hiện chỉ có nghĩa `level >= requiredLevel`.
- Không tự chuyển stage chỉ vì `isUnlocked == true`; chỉ server được tiến hóa.
- `stateUrl` dùng cho ảnh tĩnh.
- `animations[].animationUrl` dùng cho Flame animation tương ứng với `typeAnimation`.

## 3. Lịch sử tiến hóa

```http
GET /api/pet/evolution/history
```

Response:

```json
{
  "success": true,
  "status": 200,
  "message": "Get evolution history successfully.",
  "data": [
    {
      "petName": "Tinh Linh Nắng Ấm",
      "stageName": "Dạng Chói",
      "stageNo": 1,
      "level": 5,
      "evolvedAt": "2026-07-14T14:30:00+07:00"
    }
  ]
}
```

Backend hiện trả lịch sử theo `evolvedAt` cũ đến mới. Nếu UI muốn sự kiện mới nhất nằm trên cùng như ảnh mẫu, FE phải sort giảm dần.

Endpoint này chỉ chứa sự kiện tiến hóa. Các dòng như “Ăn no thành công”, “Chạm tinh linh” hoặc lịch sử tương tác chưa có trong response này.

## 4. Tiến hóa từ Lumina sang một family

Luồng này chỉ áp dụng khi pet hiện tại vẫn là starter `Lumina`.

### Lấy lựa chọn

```http
GET /api/pet/evolution/options
```

Điều kiện backend hiện tại:

- Pet hiện tại là `Lumina`.
- Level tối thiểu là `5`.

Response:

```json
{
  "success": true,
  "status": 200,
  "data": [
    {
      "petId": "00000000-0000-0000-0000-000000000000",
      "petName": "Tinh Linh Nắng Ấm",
      "stateUrl": "https://...",
      "requiredLevel": 5
    }
  ]
}
```

### Chọn family và tiến hóa

```http
POST /api/pet/evolution
Content-Type: application/json

{
  "petId": "petId lấy từ evolution/options"
}
```

Thành công:

```json
{
  "success": true,
  "status": 200,
  "message": "Evolution successful."
}
```

Sau HTTP `200`, gọi lại song song:

```text
GET /api/pet/me
GET /api/pet/evolution/stages
GET /api/pet/evolution/history
GET /api/pet/current-animation
```

Không giữ pet cũ từ local cache sau khi evolve.

## 5. Tiến hóa sang stage tiếp theo

Luồng này dùng sau khi user đã chọn family.

```http
POST /api/pet/evolution/next
```

Không có request body. Backend tự xác định stage hiện tại và stage kế tiếp.

Response:

```json
{
  "success": true,
  "status": 200,
  "message": "Evolution successful.",
  "data": {
    "stageId": "00000000-0000-0000-0000-000000000001",
    "stageNo": 2,
    "stageName": "Dạng Rực Sáng",
    "stateUrl": "https://...",
    "requiredLevel": 15,
    "isCurrent": true,
    "isUnlocked": true,
    "animations": []
  }
}
```

Backend bảo đảm:

- Chỉ tiến hóa đúng stage kế tiếp; không skip stage.
- Không cho tiến hóa nếu chưa đủ level.
- Không cho tiến hóa khi đã ở stage cuối.
- Chỉ ghi lịch sử sau khi thao tác thành công.

Sau `200`, refresh lại bốn endpoint giống mục 4.

## 6. Animation hiện tại

```http
GET /api/pet/current-animation
```

Response:

```json
{
  "success": true,
  "status": 200,
  "message": "Get current animation successfully.",
  "data": {
    "animationType": "idle",
    "animationUrl": "https://...",
    "stageNo": 1,
    "stageName": "Dạng Chói"
  }
}
```

`animationType` do server suy ra từ energy, bond và life force:

- `sleep`
- `hungry`
- `sad`
- `happy`
- `idle`

Flame tải đúng `animationUrl`; FE không tự suy ra animation từ phần trăm chỉ số.

## 7. Enable nút “Tiến hóa ngay”

Đối với stage evolution:

```text
enabled =
  overview.canEvolve == true
  && next stage tồn tại
  && request evolve chưa chạy
```

Trong lúc gọi API:

- Disable nút để tránh double tap.
- Thành công thì refresh dữ liệu trước khi đóng animation/modal.
- Thất bại thì dừng loading và hiển thị `message` từ `ApiResponse`.
- Không optimistic update stage.

Lỗi thường gặp:

| HTTP | Trường hợp |
|---:|---|
| `400` | Chưa đủ level, đã tiến hóa starter, hoặc đã ở stage cuối. |
| `401` | JWT thiếu/hết hạn. |
| `403` | Tài khoản không có role User hoặc bị chặn. |
| `404` | Không có pet, stage hoặc animation tương ứng. |

## 8. Các field trong ảnh nhưng BE chưa cung cấp

Các dữ liệu sau chưa tồn tại trong contract/database pet hiện tại:

| UI trong ảnh | Trạng thái |
|---|---|
| “Hệ Thực Vật” | Chưa có `elementCode/elementName`. |
| “Chói” như tính cách/đặc tính riêng | Chưa có `personalityCode/personalityName`. |
| “Độ gắn kết đạt yêu cầu” cho tiến hóa | Stage chưa có `requiredBond`; backend hiện chỉ kiểm tra level. |
| “Ăn no thành công” trong timeline | Chưa có API lịch sử tương tác pet cho player. |

FE không được hardcode các field trên hoặc dùng `currentBond == maxBond` làm điều kiện tiến hóa, vì backend chưa dùng điều kiện đó.

Nếu product bắt buộc UI giống chính xác ảnh mẫu, backend cần một đợt bổ sung contract riêng:

```text
PetOverviewResponse:
  elementCode
  elementName
  personalityCode
  personalityName

EvolutionStageResponse:
  requiredBond
  isLevelRequirementMet
  isBondRequirementMet
  canEvolve

API timeline:
  GET /api/pet/history
```

Những field/API trong block trên là đề xuất, chưa được implement.

## 9. Luồng tải màn hình khuyến nghị

```text
Mở màn chi tiết
→ GET /api/pet/me
→ gọi song song:
   - GET /api/pet/evolution/stages
   - GET /api/pet/evolution/history
   - GET /api/pet/current-animation
→ render tab Chỉ số và Tiến hóa
→ user bấm Tiến hóa ngay
→ POST /api/pet/evolution/next
→ HTTP 200
→ refresh toàn bộ dữ liệu pet
→ chạy animation tiến hóa bằng Flame
```

REST response là nguồn dữ liệu authoritative. Không tự cộng level, đổi stage hoặc dựng lịch sử từ local state.
