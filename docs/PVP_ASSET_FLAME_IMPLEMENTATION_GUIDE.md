# Hướng dẫn dùng asset PVP trong Flame

## 1. Mục tiêu

PVP Sprint là cuộc đua hai làn kéo dài tối đa 30 giây. Background, pet, animation và VFX được Flame render; HUD, modal và accessibility vẫn có thể giữ bằng Flutter.

Ba ảnh map của mỗi chủ đề là ba pha của cùng một đường đua, không phải ba map ngẫu nhiên:

| Thời gian trận | Pha | Ảnh |
| --- | --- | --- |
| `0.0s <= t < 5.0s` | Xuất phát | `pvp_map_<theme>_start_portrait.png` |
| `5.0s <= t < 25.0s` | Đường giữa | `pvp_map_<theme>_loop_portrait.png` |
| `25.0s <= t <= 30.0s` | Về đích | `pvp_map_<theme>_finish_portrait.png` |

Mỗi ảnh có đúng hai làn chạy ngang:

- `start`: có vạch xuất phát bên trái, không có vạch đích.
- `loop`: không có vạch xuất phát và không có vạch đích.
- `finish`: có vạch đích caro bên phải, không có vạch xuất phát.

Không kéo dài một animation pet thành 30 giây. Chuỗi `race` là một vòng chạy ngắn lặp liên tục; tiến độ ngang của pet là dữ liệu độc lập lấy từ trạng thái trận.

## 2. Asset map

Root: `assets/Mobile/PVP/Maps/`

| Theme | Start | Loop | Finish |
| --- | --- | --- | --- |
| Morning | `pvp_map_morning_start_portrait.png` | `pvp_map_morning_loop_portrait.png` | `pvp_map_morning_finish_portrait.png` |
| Night | `pvp_map_night_start_portrait.png` | `pvp_map_night_loop_portrait.png` | `pvp_map_night_finish_portrait.png` |

Tất cả map là `1440x2560`. Ba ảnh trong cùng theme có cùng camera, cảnh vật và hai làn; chỉ vạch đường thay đổi. Không pan ba ảnh nối tiếp theo chiều ngang. Khi đổi pha, thay texture toàn màn hình tại cùng một registration.

Giá trị trong `PVP_ASSET_MANIFEST.json` là nguồn chuẩn cho tên file và mốc thời gian. `AppAssets` có constant tương ứng để code Dart không tự ghép chuỗi đường dẫn.

### Chuyển pha không giật

- Preload đủ ba ảnh của theme trước countdown.
- Giữ hai `SpriteComponent` cùng position/size trong lúc chuyển pha.
- Crossfade ngắn `120-160ms`; không scale, slide hoặc đổi camera.
- Chỉ đổi pha một lần theo `elapsed`, không dùng nhiều `Future.delayed`.
- Khi app resume, tính lại pha trực tiếp từ thời gian server; không chạy bù từng transition đã bỏ lỡ.

```dart
enum PvpTrackPhase { start, loop, finish }

PvpTrackPhase phaseFor(Duration elapsed) {
  final seconds = elapsed.inMilliseconds / 1000;
  if (seconds < 5) return PvpTrackPhase.start;
  if (seconds < 25) return PvpTrackPhase.loop;
  return PvpTrackPhase.finish;
}
```

## 3. Asset pet dùng trong PVP

Mỗi form/stage có cùng contract:

| State | File | Frame | FPS | Playback |
| --- | --- | ---: | ---: | --- |
| Chạy | `pvp/race/race_F01.png` ... `race_F12.png` | 12 | 12 | Loop, `83.333ms/frame` |
| Thắng | `pvp/win/win_F01.png` ... `win_F08.png` | 8 | 10 | One-shot, giữ F08 khoảng `1500ms` |
| Thua | `pvp/lose/lose_F01.png` ... `lose_F08.png` | 8 | 10 | One-shot, giữ F08 khoảng `1500ms` |

Tất cả frame hiện tại là PNG RGBA `512x512`.

### Đường dẫn chính xác

| Affinity/stage | Root PVP |
| --- | --- |
| `sprout`, stage `0` | `assets/Mobile/Mầm Non/pvp/` |
| `dawn`, stage `1` | `assets/Mobile/Tinh Linh Bình Minh/stage1/pvp/` |
| `dawn`, stage `2` | `assets/Mobile/Tinh Linh Bình Minh/stage2/pvp/` |
| `moonlight`, stage `1` | `assets/Mobile/TInh Linh Ánh Trăng/stage1/pvp/` |
| `moonlight`, stage `2` | `assets/Mobile/TInh Linh Ánh Trăng/stage2/pvp/` |
| `warm_sun`, stage `1` | `assets/Mobile/TinhLinhNangAm/Stage1/pvp/` |
| `warm_sun`, stage `2` | `assets/Mobile/TinhLinhNangAm/stage2/pvp/` |

Tên thư mục hiện tại có dấu, khoảng trắng và khác chữ hoa/thường. Android phân biệt hoa/thường, vì vậy phải dùng nguyên văn đường dẫn trên. Nên tập trung mapping vào một `PvpPetAssetCatalog`, không ghép tên thư mục từ `affinityCode` ở nhiều nơi.

`run/` và `fly/` không phải lựa chọn chính cho Sprint. Chúng phục vụ di chuyển dài ngoài PVP và không có đủ cho mọi stage. Trong trận Sprint luôn ưu tiên `pvp/race` để giữ đúng góc nhìn và contract chung.

## 4. Timeline trận 30 giây

```text
Preload/countdown
  -> 0-5s: start map + race loop
  -> 5-25s: loop map + race loop
  -> 25-30s: finish map + race loop
  -> server result: stop race -> win/lose one-shot -> hold -> result modal
```

### Tiến độ pet

- `SpriteAnimation` chỉ làm chuyển động chân/thân.
- `position.x` phản ánh `progress` do server xác nhận, không phản ánh chỉ số frame.
- Dùng anchor `bottomCenter` cho cả hai pet.
- Đặt baseline làn trên khoảng `0.58 * viewportHeight`, làn dưới khoảng `0.73 * viewportHeight`, sau đó tinh chỉnh bằng golden test theo viewport thực.
- Giới hạn vùng chạy từ sau vạch trái đến trước vạch phải, ví dụ `x = lerp(0.10W, 0.90W, progress01)`.
- Không để pet vượt vạch đích trước khi server xác nhận kết quả.

Khi nhận snapshot mới, không teleport đến tọa độ mới. Nội suy visual progress trong `100-180ms`, nhưng giữ authoritative progress riêng:

```dart
visualProgress += (serverProgress - visualProgress) *
    (1 - math.exp(-12 * dt));
```

Nếu chênh lệch lớn do reconnect, snap có kiểm soát sau fade hoặc countdown-resume, không chạy một tween dài xuyên màn hình.

### Đồng hồ

- Lưu `startedAtUtc` hoặc elapsed authoritative từ SignalR.
- Trong `update(dt)`, tính `elapsed = serverNowEstimate - startedAtUtc`.
- `dt` chỉ phục vụ render/interpolation, không là nguồn sự thật cho kết quả trận.
- Pause/resume và mất frame không làm trận kéo dài hơn 30 giây.

## 5. Flame component đề xuất

```text
PvpSprintGame
├── PvpTrackComponent       (start/loop/finish + crossfade)
├── TrackDecorationLayer
├── OpponentRunnerComponent (race/win/lose)
├── PlayerRunnerComponent   (race/win/lose)
├── PvpVfxLayer
└── PvpEventDirector        (server snapshot -> visual command)
```

`PvpRacingEnvironment` hiện tại còn dựng track bằng `Container` và dùng `Icons.pets`. Khi triển khai asset thật, thay phần environment bằng một `GameWidget<PvpSprintGame>`; Flutter HUD đặt phía trên bằng `Stack`.

### Load chuỗi frame hiện tại

```dart
Future<SpriteAnimation> loadSequence({
  required String folder,
  required String prefix,
  required int frameCount,
  required double fps,
  required bool loop,
}) async {
  final sprites = <Sprite>[];
  for (var i = 1; i <= frameCount; i++) {
    final name = '$folder/${prefix}_F${i.toString().padLeft(2, '0')}.png';
    sprites.add(Sprite(await images.load(name)));
  }
  return SpriteAnimation.spriteList(
    sprites,
    stepTime: 1 / fps,
    loop: loop,
  );
}
```

Khi có atlas PVP sau này, thay loader nhưng giữ nguyên state machine. Không cần tăng `race` lên 30 hoặc 60 FPS bằng cách nhân bản frame; game render ở 60 FPS, còn artwork 12 FPS giữ nhịp hoạt hình gốc.

## 6. Item, status, passive, rank và VFX

Root: `assets/Mobile/PVP/`

### Item và status

| Effect code API | Item PNG | Status PNG | VFX |
| --- | --- | --- | --- |
| `pvp_speed_up` | `items/01_haste_nectar.png` | `status/haste.png` | `vfx/speed_trail/` |
| `pvp_speed_down` | `items/02_slow_mist_vial.png` | `status/slow.png` | `vfx/slow_mist/` |
| `pvp_cleanse` | `items/03_cleanse_dew.png` | `status/cleanse.png` | `vfx/cleanse_burst/` |
| `pvp_shield` | `items/04_shield_acorn.png` | `status/shield.png` | `vfx/shield_bubble/` |

VFX đã được mô tả trong `PVP_ASSET_MANIFEST.json`:

| VFX | Frame/FPS | Loop | Layer |
| --- | --- | --- | --- |
| `speed_trail` | 8 / 12 FPS | Có | Sau pet |
| `slow_mist` | 8 / 8 FPS | Có | Dưới chân pet |
| `cleanse_burst` | 8 / 12 FPS | Không | Trên pet |
| `shield_bubble` | 8 / 10 FPS | Có | Bao quanh pet |
| `rank_up` | 8 / 10 FPS | Không | Trên pet ở màn kết quả |

Item icon là nút sử dụng. Status icon là trạng thái đang hiệu lực. Không dùng item icon làm status icon.

### Passive

- `passives/passive_binh_minh_stage1.png`
- `passives/passive_nang_am_stage1.png`
- `passives/passive_anh_trang_stage1.png`

Mầm Non không có passive badge riêng. UI chỉ hiện badge khi server/catalog trả passive tương ứng.

### Rank

Theo thứ tự:

1. `ranks/rank_01_mam_dong.png`
2. `ranks/rank_02_la_bac.png`
3. `ranks/rank_03_nu_vang.png`
4. `ranks/rank_04_hoa_lam.png`
5. `ranks/rank_05_trang_tim.png`
6. `ranks/rank_06_tinh_linh_cau_vong.png`

Database trả `asset_key`; `PvpRankTierResponse.flutterAssetPath` chuyển `Assets/Mobile/...` thành `assets/Mobile/...`.

## 7. Dữ liệu nào nằm trong database

Database chỉ cần giữ asset key cho dữ liệu do server phát hành:

- `items.img_url`: 4 item PVP.
- `pvp_item_effect_definitions.asset_key`: 4 effect.
- `pvp_rank_tiers.asset_key`: 6 rank.
- Pet animation catalog hiện giữ đường dẫn logic/first-frame theo schema hiện có.

Không thêm mỗi frame map/VFX vào SQL. Map, status, passive, VFX và phase timing là catalog đóng gói trong mobile (`PVP_ASSET_MANIFEST.json`). Điều này tránh làm DB phụ thuộc vào số page atlas hoặc chi tiết render của client.

## 8. Preload và bộ nhớ

Trước khi hiện `GO`, tải:

- 3 map của theme đã chọn.
- `race`, `win`, `lose` của hai pet tham gia.
- 4 item, 4 status và các VFX có thể dùng trong loadout.
- HUD 9-slice và passive badge cần thiết.

Không gọi `images.load` lần đầu giữa cuộc đua. Sau result modal và khi rời màn, giải phóng cache riêng của `PvpSprintGame` nếu các texture này không dùng ở scene khác.

Với PNG rời hiện tại, một người chơi có `28` frame PVP; hai người là `56` frame. Khi profile cho thấy decode/upload gây spike, đóng riêng chúng thành atlas theo form/stage. Không giảm độ phân giải hoặc đổi naming contract trước khi đo trên thiết bị thật.

## 9. Input, action lock và kết quả

- Một slot item chỉ gửi một request trong lúc pending.
- Cooldown và inventory được xác nhận từ server; visual cooldown có thể nội suy local.
- Retry cùng command/event ID không phát VFX hoặc trừ item hai lần.
- Khi server trả finished, khóa item input, dừng race ở chu kỳ gần nhất rồi phát `win`/`lose` one-shot.
- Trường hợp hòa: có thể giữ frame cuối `race` hoặc dùng pose trung tính; không tự chọn cả hai là win.
- Modal kết quả chỉ xuất hiện sau khi result animation đã chạy hoặc sau timeout an toàn.

## 10. Kiểm thử bắt buộc

### Asset

- Đủ 6 map, cùng kích thước `1440x2560`.
- Start không có finish; loop không có cả hai; finish không có start.
- Mỗi form/stage có đúng `12 race + 8 win + 8 lose` frame, đúng `512x512`.
- Mọi đường dẫn phân biệt hoa/thường đều tồn tại trên Android.
- JSON manifest parse được và không tham chiếu file cũ.

### Runtime 30 giây

- `0-5s`, `5-25s`, `25-30s` dùng đúng map.
- Không thấy flash/decode stall tại giây 5 và 25.
- Race loop không khựng ở vòng `F12 -> F01`.
- Pet không teleport khi snapshot progress đến trễ.
- Pause ở giây 4/15/27 rồi resume vẫn chọn đúng phase.
- Reconnect không chạy lại start hoặc `food/item` event cũ.
- Kết quả phát đúng một `win` và một `lose`, không bị race cắt ngang.
- Frame time p95 dưới `16.7ms` trên thiết bị mục tiêu.

### Golden/layout

Kiểm tra tối thiểu `360x640`, `390x844`, `412x915`:

- Cả hai lane và pet nhìn rõ.
- Tên người chơi/HUD không che pet.
- Pet không crop khi chạm gần đích.
- Vạch xuất phát/đích vẫn nằm trong safe viewport.

## 11. Thứ tự triển khai an toàn

1. Viết `PvpAssetCatalog` đọc manifest và test tất cả path.
2. Tạo `PvpTrackComponent` với ba pha, test đúng mốc 5/25/30 giây.
3. Tạo `PvpRunnerComponent` với `race/win/lose`.
4. Nối progress server vào vị trí, không nối vào frame animation.
5. Thêm item/status/VFX và action lock.
6. Nhúng `GameWidget` dưới Flutter HUD.
7. Chạy golden, profile và test reconnect/pause-resume.

Không cần thay public API chỉ để hiển thị map hoặc phát sprite. Chỉ cần backend tiếp tục trả state trận, progress, result, item effect và asset key catalog như hiện tại.
