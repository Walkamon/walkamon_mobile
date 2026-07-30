# Dữ liệu DB cần có cho Pet Animation

## Kết luận

Atlas/frame/clip nằm hoàn toàn ở mobile. SQL Server không cần 570 record tương
ứng 570 clip.

Để `GET /api/Pet/me` chọn đúng asset, DB chỉ cần cung cấp:

```text
pets.pvp_affinity_code
pet_stages.stage_no
trạng thái pet để backend tính animationType
```

Nguồn schema đã đối chiếu:

```text
C:\Đồ Án\walkamon_backend\Database\FINAlFINAL.sql
```

## 1. Catalog pet tối thiểu

Phải có đúng một pet master cho mỗi family:

| `pet_name` | `pvp_affinity_code` | Vai trò |
|---|---|---|
| `Lumina` | `sprout` | Starter/Mầm Non |
| `Tinh Linh Nắng Ấm` | `warm_sun` | Evolution family |
| `Tinh Linh Bình Minh` | `dawn` | Evolution family |
| `Tinh Linh Ánh Trăng` | `moonlight` | Evolution family |

Tên `Lumina` là bắt buộc với code hiện tại vì
`PetRepository.GetStarterPetAsync()` tìm chính xác:

```csharp
x.PetName == "Lumina"
```

Các stat/rate phải lớn hơn 0 theo catalog gameplay thực tế. Animation chỉ cần
affinity code; không nên suy luận family từ tên tiếng Việt.

## 2. Stage tối thiểu

DB nên có 7 stage:

| Pet family | `stage_no` trong DB | `required_level` | Asset identity |
|---|---:|---:|---|
| `sprout` | 1 | 1 | `sprout_stage0` |
| `warm_sun` | 1 | 5 | `warm_sun_stage1` |
| `warm_sun` | 2 | 10 | `warm_sun_stage2` |
| `dawn` | 1 | 5 | `dawn_stage1` |
| `dawn` | 2 | 10 | `dawn_stage2` |
| `moonlight` | 1 | 5 | `moonlight_stage1` |
| `moonlight` | 2 | 10 | `moonlight_stage2` |

Starter dùng `stage_no = 1` trong DB để tương thích
`GetCurrentAnimationAsync()`, vốn đang hard-code Stage 1 khi chưa có evolution
history. Mobile chủ động normalize `sprout` về asset Stage 0.

`state_url` chỉ nên là logical fallback, ví dụ:

```text
asset://pet-runtime-v7.2/sprout/stage0/idle_front
```

Không lưu tên atlas page vào `state_url`.

## 3. Animation record trong DB

### Trường hợp mobile chỉ dùng `/api/Pet/me`

Không bắt buộc seed `pet_animations`. Mobile lấy `animationType` từ `/me` rồi
resolve clip trong manifest local.

### Trường hợp vẫn giữ `/api/Pet/current-animation`

Seed tối thiểu 5 coarse state cho mỗi stage:

```text
idle
happy
sad
hungry
sleep
```

Tổng:

```text
7 identity × 5 state = 35 pet_animations
```

Để bao phủ action/transition admin API, có thể thêm:

```text
excited
tap_hello
feed_eat
```

Tổng đầy đủ:

```text
7 identity × 8 state = 56 pet_animations
```

`animation_url` nên là logical URI:

```text
asset://pet-runtime-v7.2/{affinity}/stage{assetStage}/{type_animation}
```

Không lưu 856 atlas path hoặc 570 clip variant trong SQL.

## 4. Dữ liệu theo user

Để một user thấy pet:

1. Có row trong `user_pets`.
2. `user_pets.pet_id` trỏ tới một trong bốn pet master.
3. Các max stat `pet_exp`, `pet_energy`, `pet_bond`, `pet_life_force` phải > 0.
4. Các current stat nằm trong `0..max`.
5. Nếu đã tiến hóa, có row `pet_evolution_history` trỏ đúng `stage_id`.

Nếu không có evolution history:

- `/api/Pet/me` lấy first stage của pet.
- Starter được mobile map về `sprout_stage0`.

Nếu có history:

- Backend lấy row mới nhất theo user.
- `stage_no` quyết định Stage 1 hoặc Stage 2.

## 5. `animationType` hiện được backend tính thế nào

| Điều kiện | Kết quả |
|---|---|
| Energy ≤ 20% | `sleep` |
| Life Force ≤ 20% | `hungry` |
| Bond ≤ 20% | `sad` |
| Energy, Bond và Life Force đều ≥ 80% | `happy` |
| Còn lại | `idle` |

Tap/feed/excited là command phía client sau khi API tương ứng thành công; không
nên ghi đè lâu dài vào DB.

## 6. Query audit trước khi seed

```sql
SELECT
    p.pet_id,
    p.pet_name,
    p.pvp_affinity_code,
    ps.stage_id,
    ps.stage_no,
    ps.stage_name,
    ps.required_level,
    ps.is_active
FROM dbo.pets p
LEFT JOIN dbo.pet_stages ps ON ps.pet_id = p.pet_id
WHERE p.pvp_affinity_code IN ('sprout', 'warm_sun', 'dawn', 'moonlight')
ORDER BY p.pvp_affinity_code, ps.stage_no;

SELECT
    p.pvp_affinity_code,
    pa.pet_stage_use,
    pa.type_animation,
    pa.animation_url,
    pa.is_active
FROM dbo.pet_animations pa
JOIN dbo.pets p ON p.pet_id = pa.pet_id
WHERE p.pvp_affinity_code IN ('sprout', 'warm_sun', 'dawn', 'moonlight')
ORDER BY p.pvp_affinity_code, pa.pet_stage_use, pa.type_animation;
```

## 7. Validation bắt buộc

Sau seed:

- Có đúng 4 affinity code.
- Có đúng 7 stage identity.
- Mỗi evolved family có Stage 1 và Stage 2.
- `GET /api/Pet/me` trả đúng `affinityCode`, `stageNo`, `animationType`.
- Starter trả affinity `sprout` và mobile resolve `sprout_stage0`.
- User đã evolve resolve đúng Stage 1/2 theo history mới nhất.
- Không API nào trả atlas filesystem path.

## 8. Việc chưa thực hiện

Tài liệu này chưa chạy câu lệnh ghi vào production DB. Trước khi seed thật cần:

1. Backup `.bak WITH COPY_ONLY, CHECKSUM`.
2. Audit dữ liệu hiện có bằng hai query phía trên.
3. Dùng script idempotent/transactional.
4. Không đổi `pet_id` đang được `user_pets` tham chiếu.
5. Chỉ insert row thiếu; update affinity/stage sai theo khóa hiện có.
