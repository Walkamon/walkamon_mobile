import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../data/datasources/remote/notification_datasource.dart';
import '../../data/models/notification_response.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final NotificationDatasource _datasource;
  List<NotificationItem> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _datasource = NotificationDatasourceImpl(ApiClient());
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final data = await _datasource.getNotifications(1, 20); //[cite: 2]
      setState(() {
        _notifications = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showNotificationDetail(NotificationItem item) async {
    // 1. Cập nhật giao diện mờ đi (đã đọc) ngay lập tức
    if (!item.isRead) {
      setState(() {
        item.isRead = true;
      });
    }

    // 2. Hiển thị Popup
    showDialog(
      context: context,
      barrierColor: Colors.black45,
      builder: (context) {
        return Dialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          child: FutureBuilder<NotificationDetail>(
            future: _datasource.getNotificationDetail(item.notificationId),
            builder: (context, snapshot) {
              return Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Tiêu đề
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        // Thời gian tạo
                        Text(
                          _formatTimeAgo(item.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Xử lý trạng thái tải API chi tiết
                        if (snapshot.connectionState == ConnectionState.waiting)
                          const Padding(
                            padding: EdgeInsets.all(24.0),
                            child: CircularProgressIndicator(),
                          )
                        else if (snapshot.hasError)
                          const Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Text("Đã có lỗi xảy ra khi tải nội dung."),
                          )
                        else if (snapshot.hasData)
                          Flexible(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 1. Hiển thị Ảnh bo góc (imageUrl)
                                  if (snapshot.data!.imageUrl != null &&
                                      snapshot.data!.imageUrl!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 16.0,
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Image.network(
                                          snapshot.data!.imageUrl!,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const SizedBox.shrink(),
                                        ),
                                      ),
                                    ),

                                  // Row chứa Icon và Nhãn (typeCode)
                                  if ((snapshot.data!.icon != null &&
                                          snapshot.data!.icon!.isNotEmpty) ||
                                      (snapshot.data!.typeCode != null &&
                                          snapshot.data!.typeCode!.isNotEmpty))
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12.0,
                                      ),
                                      child: Row(
                                        children: [
                                          // 2. Hiển thị Icon (Ảnh nhỏ)
                                          if (snapshot.data!.icon != null &&
                                              snapshot.data!.icon!.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                right: 8.0,
                                              ),
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary
                                                      .withOpacity(0.1),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  _getNotificationIcon(
                                                    snapshot.data!.icon,
                                                  ),
                                                  size: 20,
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                                ),
                                              ),
                                            ),

                                          // 3. Hiển thị Nhãn (typeCode)
                                          if (snapshot.data!.typeCode != null &&
                                              snapshot
                                                  .data!
                                                  .typeCode!
                                                  .isNotEmpty)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                    .withOpacity(
                                                      0.1,
                                                    ), // Nền màu xanh nhạt
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              child: Text(
                                                _translateTypeCode(
                                                  snapshot.data!.typeCode,
                                                ),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary, // Màu chữ xanh
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),

                                  // 4. Hiển thị Nội dung (Body)
                                  Text(
                                    snapshot.data!.body,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.8),
                                      height: 1.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Nút Tắt (X) góc trên bên phải
                  Positioned(
                    top: 12,
                    right: 12,
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return "${diff.inDays} ngày trước";
    if (diff.inHours > 0) return "${diff.inHours} giờ trước";
    if (diff.inMinutes > 0) return "${diff.inMinutes} phút trước";
    return "Vừa xong";
  }

  IconData _getNotificationIcon(String? iconName) {
    if (iconName == null || iconName.isEmpty) return Icons.notifications;

    switch (iconName.toLowerCase()) {
      case 'megaphone':
        return Icons.campaign; // Icon cái loa
      case 'gift':
        return Icons.card_giftcard; // Icon hộp quà
      case 'sword':
      case 'swords':
        return Icons.sports_martial_arts; // Icon đánh nhau/PVP
      case 'warning':
        return Icons.warning_amber_rounded; // Icon cảnh báo
      case 'info':
        return Icons.info_outline; // Icon thông tin
      // Thêm các trường hợp khác tùy theo backend trả về nhé
      default:
        return Icons.notifications; // Mặc định vẫn là cái chuông
    }
  }

  String _translateTypeCode(String? typeCode) {
    if (typeCode == null || typeCode.isEmpty) return '';
    switch (typeCode) {
      case 'daily_reward':
        return 'Quà đăng nhập hàng ngày';
      case 'streak_reward':
        return 'Quà chuỗi điểm danh';
      case 'mission_complete':
        return 'Hoàn thành nhiệm vụ';
      case 'achievement_complete':
        return 'Hoàn thành thành tựu';
      case 'challenge_invite':
        return 'Lời mời thử thách';
      case 'pvp_invite':
        return 'Lời mời đấu PvP';
      case 'friend_request':
        return 'Yêu cầu kết bạn';
      case 'friend_accepted':
        return 'Chấp nhận kết bạn';
      case 'friend_removed':
        return 'Hủy kết bạn';
      case 'spirit_hungry':
        return 'Lumina đang đói';
      case 'spirit_ready_evolution':
        return 'Đủ điều kiện tiến hóa';
      case 'spirit_energy_full':
        return 'Năng lượng đã đầy';
      case 'spirit_bond_low':
        return 'Sinh mệnh thấp';
      case 'spirit_level_up':
        return 'Lên cấp';
      case 'item_purchased':
        return 'Mua vật phẩm thành công';
      case 'pvp_result':
        return 'Kết quả đấu PvP';
      case 'maintenance':
        return 'Thông báo bảo trì';
      case 'patch_notes':
        return 'Ghi chú cập nhật';
      case 'news':
        return 'Tin tức mới';
      case 'event':
        return 'Sự kiện';
      case 'compensation':
        return 'Quà đền bù';
      case 'server_announcement':
        return 'Thông báo từ máy chủ';
      default:
        return typeCode;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            style: IconButton.styleFrom(
              backgroundColor: theme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: theme.dividerColor),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: const Text(
          'Thông Báo', //[cite: 1]
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
          ? const Center(
              child: Text(
                'Không có thông báo nào.', //[cite: 1]
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final item = _notifications[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: item.isRead
                        ? theme.cardColor.withOpacity(0.5)
                        : theme.cardColor, //
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: item.isRead
                          ? theme.dividerColor
                          : theme.colorScheme.primary.withOpacity(
                              0.3,
                            ), //[cite: 11]
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => _showNotificationDetail(item),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!item.isRead) ...[
                                // Chấm cam biểu thị chưa đọc
                                Container(
                                  width: 10,
                                  height: 10,
                                  margin: const EdgeInsets.only(
                                    top: 4,
                                    right: 8,
                                  ),
                                  decoration: const BoxDecoration(
                                    color: Colors.orange, //[cite: 11]
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: item.isRead
                                        ? theme.textTheme.bodyMedium?.color
                                              ?.withOpacity(0.6)
                                        : theme
                                              .textTheme
                                              .bodyLarge
                                              ?.color, //[cite: 11]
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.shortBody,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatTimeAgo(item.createdAt),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.bodySmall?.color
                                  ?.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
