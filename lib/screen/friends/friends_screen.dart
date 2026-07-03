import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/friends_repository.dart';
import '../../data/models/friends_response.dart';

class FriendsScreen extends StatefulWidget {
  final bool isEmbedded;
  const FriendsScreen({super.key, this.isEmbedded = false});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  List<dynamic> friends = [];

  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final filteredFriends = friends
        .where(
          (f) => f['name'].toString().toLowerCase().contains(
            searchQuery.toLowerCase(),
          ),
        )
        .toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(24, widget.isEmbedded ? 8 : 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.isEmbedded)
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _showFriendRequestsPopup(context),
                    icon: const Icon(Icons.notifications_none, size: 18),
                    label: const Text(
                      "Yêu cầu",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.onSurface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddFriendPopup(context),
                    icon: const Icon(Icons.person_add_alt_1, size: 18),
                    label: const Text(
                      "Thêm Bạn",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),

          Container(
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outline.withOpacity(0.5)),
            ),
            child: TextField(
              onChanged: (val) => setState(() => searchQuery = val),
              decoration: const InputDecoration(
                hintText: 'Tìm kiếm bạn bè...',
                prefixIcon: Icon(Icons.search, size: 20),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),

          Text(
            "DANH SÁCH (${filteredFriends.length})",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: friends.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.group_add_rounded,
                          size: 64,
                          color: colorScheme.primary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Chưa có đồng đội nào!",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Bấm 'Thêm Bạn' để bắt đầu hành trình nhé.",
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : filteredFriends.isEmpty
                ? Center(
                    child: Text(
                      "Không tìm thấy người bạn này.",
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 110),
                    itemCount: filteredFriends.length,
                    itemBuilder: (context, index) {
                      final friend = filteredFriends[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: colorScheme.outline.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                  backgroundColor: colorScheme.surfaceVariant,
                                  child: Text(
                                    friend['name'][0],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: friend['status'] == 'online'
                                          ? Colors.green
                                          : Colors.grey,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: colorScheme.surface,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    friend['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.local_fire_department,
                                        size: 14,
                                        color: Colors.orange,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${friend['streak']} ngày',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.person_remove,
                                size: 20,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showFriendRequestsPopup(BuildContext context) {
    final friendsRepo = context.read<FriendsRepository>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Provider.value(
        value: friendsRepo,
        child: const FriendRequestsBottomSheet(),
      ),
    );
  }

  void _showAddFriendPopup(BuildContext context) {
    final friendsRepo = context.read<FriendsRepository>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Provider.value(
        value: friendsRepo,
        child: const AddFriendBottomSheet(),
      ),
    );
  }
}

class AddFriendBottomSheet extends StatefulWidget {
  const AddFriendBottomSheet({super.key});

  @override
  State<AddFriendBottomSheet> createState() => _AddFriendBottomSheetState();
}

class _AddFriendBottomSheetState extends State<AddFriendBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<FriendsResponse> _searchResults = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAvailableUsers();
    });
  }

  // Hàm tải danh sách Gợi ý ban đầu
  Future<void> _loadAvailableUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final repo = context.read<FriendsRepository>();
      final results = await repo.getAvailableUsers();
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      debugPrint("LỖI GET AVAILABLE USERS: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải danh sách: $e')));
      }
      setState(() {
        _searchResults = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Hàm Tìm kiếm người chơi
  Future<void> _fetchSearchResults(String query) async {
    if (query.isEmpty) {
      _loadAvailableUsers();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final repo = context.read<FriendsRepository>();
      final results = await repo.searchPlayers(query);
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      debugPrint("LỖI TÌM KIẾM USERS: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tìm kiếm: $e')));
      }
      setState(() {
        _searchResults = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleSearch() {
    final query = _searchController.text.trim();
    _fetchSearchResults(query);
  }

  void _showGameNotification(String message, bool isSuccess) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(
        0.25,
      ), // Làm tối nền nhẹ phía sau để nổi bật popup giữa màn hình
      barrierDismissible: false,
      builder: (dialogContext) {
        // Tự động đóng popup sau 2.2 giây
        Future.delayed(const Duration(milliseconds: 2200), () {
          if (dialogContext.mounted && Navigator.canPop(dialogContext)) {
            Navigator.pop(dialogContext);
          }
        });

        // Lấy colorScheme đang chạy của ứng dụng (Tự động đổi theo Light/Dark Mode của app_theme.dart)
        final colorScheme = Theme.of(context).colorScheme;

        // Đặt màu sắc động: Thành công lấy màu Primary, Thất bại lấy màu Error của hệ thống
        final bgColor = isSuccess ? colorScheme.primary : colorScheme.error;
        final contentColor = isSuccess
            ? colorScheme.onPrimary
            : colorScheme.onError;

        return Align(
          alignment: Alignment.center, // 🎯 Đưa popup ra CHÍNH GIỮA màn hình
          child: Material(
            color: Colors.transparent,
            child: Container(
              width:
                  MediaQuery.of(context).size.width *
                  0.75, // Độ rộng bằng 75% màn hình vuông vức
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: bgColor, // Màu nền chuẩn theo cấu hình Theme của bạn
                borderRadius: BorderRadius.circular(
                  20,
                ), // Bo góc vuông dày kiểu UI game hiện đại
                border: Border.all(
                  color: contentColor,
                  width: 3,
                ), // Viền dày 3px tiệp màu chữ cực nét
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(
                      0,
                      10,
                    ), // Đổ bóng khối 3D đổ xuống dưới
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize
                    .min, // Tự co giãn chiều cao khít theo nội dung chữ
                children: [
                  // Icon đặt ở trên cùng
                  Icon(
                    isSuccess
                        ? Icons.check_circle_outline
                        : Icons.warning_amber_rounded,
                    color: contentColor,
                    size: 48, // Tăng kích thước icon to rõ ràng
                  ),
                  const SizedBox(height: 16),

                  // Text nội dung đặt ở dưới
                  Text(
                    message,
                    style: TextStyle(
                      color: contentColor,
                      fontSize: 15,
                      fontWeight:
                          FontWeight.w900, // Chữ siêu đậm chuẩn style game
                      letterSpacing: 0.5,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _sendRequest(FriendsResponse player) async {
    try {
      // Gọi API gửi kết bạn
      await context.read<FriendsRepository>().sendFriendRequest(player.userId);

      // Gọi thông báo thành công
      if (mounted) {
        _showGameNotification('Đã thả lời mời tới ${player.username}!', true);
      }

      // Ẩn người dùng khỏi danh sách sau khi gửi
      setState(() {
        _searchResults.removeWhere((user) => user.userId == player.userId);
      });
    } catch (e) {
      if (mounted) {
        String rawMessage = e.toString().replaceAll('Exception: ', '');
        String gameText = "Bồ câu lạc đường! Vui lòng thử lại sau.";

        // Xử lý các câu báo lỗi
        if (rawMessage.contains("already sent")) {
          gameText = "Bạn đã thả lời mời cho người này rồi!";
        } else if (rawMessage.contains("already friend")) {
          gameText = "Ê, hai bạn đã là hảo hữu rồi nha!";
        } else if (rawMessage.contains("not found")) {
          gameText = "Không tìm thấy tung tích của người này...";
        } else {
          final regex = RegExp(r'"message":"(.*?)"');
          final match = regex.firstMatch(rawMessage);
          if (match != null) {
            gameText = match.group(1) ?? rawMessage;
          } else {
            gameText = rawMessage;
          }
        }

        // Gọi thông báo thất bại
        _showGameNotification(gameText, false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, bottomInset + 24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Thêm Bạn Mới",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onSubmitted: (_) => _handleSearch(),
                  onChanged: (value) {
                    if (value.trim().isEmpty) {
                      _loadAvailableUsers();
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Nhập tên người chơi...',
                    filled: true,
                    fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: _handleSearch,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: colorScheme.onPrimary,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          Icons.search,
                          color: colorScheme.onPrimary,
                          size: 20,
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Text(
            _searchController.text.trim().isEmpty
                ? "GỢI Ý KẾT BẠN (${_searchResults.length})"
                : "KẾT QUẢ TÌM KIẾM (${_searchResults.length})",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),

          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text("Không có người chơi nào khả dụng"),
                    ),
                  )
                : SingleChildScrollView(
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final player = _searchResults[index];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withOpacity(
                              0.3,
                            ),
                            borderRadius: BorderRadius.circular(
                              16,
                            ), // Thẻ bo tròn
                            border: Border.all(
                              color: colorScheme.primary.withOpacity(0.1),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              // 1. AVATAR GAME (Dùng icon Thú Cưng/Game thay vì chữ cái)
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: colorScheme.surface,
                                  borderRadius: BorderRadius.circular(
                                    14,
                                  ), // Khối vuông bo góc chuẩn avatar game
                                  border: Border.all(
                                    color: colorScheme.primary.withOpacity(0.5),
                                    width: 2,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child:
                                      player.avatarUrl != null &&
                                          player.avatarUrl!.isNotEmpty
                                      ? Image.network(
                                          player.avatarUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Icon(
                                            Icons.pets,
                                            color: colorScheme.primary,
                                          ),
                                        )
                                      : Icon(
                                          Icons
                                              .pets, // Có thể đổi thành Icons.sports_esports hoặc Icons.directions_walk
                                          color: colorScheme.primary,
                                          size: 26,
                                        ),
                                ),
                              ),
                              const SizedBox(width: 14),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      player.username,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        letterSpacing: 0.2,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        // Huy hiệu Level (Giả lập)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.withOpacity(
                                              0.2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            border: Border.all(
                                              color: Colors.amber.withOpacity(
                                                0.5,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.star_rounded,
                                                size: 12,
                                                color: Colors.amber,
                                              ),
                                              const SizedBox(width: 2),
                                              Text(
                                                "Lv.1", // Sau này Backend có Level thì thay bằng: player.level.toString()
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.amber.shade700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Player Tag (Cắt 6 ký tự đầu của userId)
                                        Text(
                                          "ID: #${player.userId.substring(0, 6).toUpperCase()}",
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme.onSurfaceVariant
                                                .withOpacity(0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // 3. NÚT THÊM BẠN (Giữ nguyên logic của bạn)
                              ElevatedButton(
                                onPressed: () => _sendRequest(player),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: colorScheme.onPrimary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 0,
                                  ),
                                  minimumSize: const Size(0, 36), // Thu gọn nút
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  "Thêm",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class FriendRequestsBottomSheet extends StatefulWidget {
  const FriendRequestsBottomSheet({super.key});

  @override
  State<FriendRequestsBottomSheet> createState() =>
      _FriendRequestsBottomSheetState();
}

class _FriendRequestsBottomSheetState extends State<FriendRequestsBottomSheet> {
  bool _isSentTab = false;
  List<FriendRequestResponse> _sentRequests = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSentRequests();
    });
  }

  Future<void> _loadSentRequests() async {
    setState(() => _isLoading = true);
    try {
      final repo = context.read<FriendsRepository>();
      final results = await repo.getSentFriendRequests();
      final pendingRequests = results.where((req) {
        return req.statusCode.toLowerCase() == 'pending';
      }).toList();

      if (!mounted) return;

      setState(() => _sentRequests = pendingRequests);
    } catch (e) {
      if (!mounted) return;
      _showNotification("Không thể tải danh sách lời mời.", false);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _cancelRequest(FriendRequestResponse request) async {
    try {
      final repo = context.read<FriendsRepository>();
      await repo.cancelFriendRequest(request.requestId);

      if (!mounted) return;

      setState(() {
        _sentRequests = List.from(_sentRequests)
          ..removeWhere((item) => item.requestId == request.requestId);
      });

      _showNotification("Đã thu hồi lời mời kết bạn!", true);
    } catch (e) {
      if (!mounted) return;
      _showNotification("Hủy yêu cầu thất bại. Thử lại sau!", false);
    }
  }

  void _showNotification(String message, bool isSuccess) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.25),
      barrierDismissible: false,
      builder: (ctx) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (ctx.mounted && Navigator.canPop(ctx)) Navigator.pop(ctx);
        });

        final colorScheme = Theme.of(context).colorScheme;
        final bgColor = isSuccess ? colorScheme.primary : colorScheme.error;
        final contentColor = isSuccess
            ? colorScheme.onPrimary
            : colorScheme.onError;

        return Align(
          alignment: Alignment.center,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.75,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: contentColor, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSuccess
                        ? Icons.check_circle_outline
                        : Icons.warning_amber_rounded,
                    color: contentColor,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: TextStyle(
                      color: contentColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Hộp Thư Kết Bạn",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Nút Tab phong cách Game
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(
                    child: Text(
                      "Lời mời đã nhận",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  selected: !_isSentTab,
                  selectedColor: colorScheme.primary,
                  labelStyle: TextStyle(
                    color: !_isSentTab
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface,
                  ),
                  showCheckmark: false,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (val) => setState(() => _isSentTab = false),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Center(
                    child: Text(
                      "Đã gửi đi",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  selected: _isSentTab,
                  selectedColor: colorScheme.primary,
                  labelStyle: TextStyle(
                    color: _isSentTab
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface,
                  ),
                  showCheckmark: false,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (val) {
                    if (!_isSentTab) {
                      setState(() => _isSentTab = true);
                      _loadSentRequests();
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: colorScheme.primary,
                    ),
                  )
                : !_isSentTab
                ? Center(
                    child: Text(
                      "Tính năng Lời mời đã nhận đang phát triển...",
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  )
                : _sentRequests.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        "Bạn chưa gửi lời mời nào gần đây.",
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _sentRequests.length,
                    itemBuilder: (context, index) {
                      final req = _sentRequests[index];
                      final targetUser = req.user;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          // Đồng bộ màu nền thẻ giống Thêm Bạn
                          color: colorScheme.primaryContainer.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.primary.withOpacity(0.1),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            // 1. AVATAR GAME đồng bộ
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: colorScheme.primary.withOpacity(0.5),
                                  width: 2,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child:
                                    targetUser.avatarUrl != null &&
                                        targetUser.avatarUrl!.isNotEmpty
                                    ? Image.network(
                                        targetUser.avatarUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Icon(
                                          Icons.pets,
                                          color: colorScheme.primary,
                                        ),
                                      )
                                    : Icon(
                                        Icons.pets,
                                        color: colorScheme.primary,
                                        size: 26,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // 2. THÔNG TIN NGƯỜI CHƠI (Tên, Level, ID)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    targetUser.username,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      letterSpacing: 0.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      // Tag Level
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: Colors.amber.withOpacity(
                                              0.5,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.star_rounded,
                                              size: 12,
                                              color: Colors.amber,
                                            ),
                                            const SizedBox(width: 2),
                                            Text(
                                              "Lv.1",
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.amber.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Tag ID
                                      Text(
                                        "ID: #${targetUser.userId.substring(0, 6).toUpperCase()}",
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.onSurfaceVariant
                                              .withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // 3. NÚT HỦY đồng bộ kích thước với nút Thêm
                            ElevatedButton(
                              onPressed: () => _cancelRequest(req),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.secondary,
                                foregroundColor: colorScheme.onSecondary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 0,
                                ),
                                minimumSize: const Size(
                                  0,
                                  36,
                                ), // Đồng bộ size 36 giống hệt nút "Thêm"
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                "Hủy",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
