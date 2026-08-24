import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:walkamon_mobile/core/constants/app_assets.dart';
import 'package:walkamon_mobile/core/theme/app_colors.dart';
import 'package:walkamon_mobile/widgets/common/app_icon.dart';
import 'package:walkamon_mobile/widgets/common/asset_only_icon_button.dart';
import 'package:walkamon_mobile/widgets/common/game_button_label.dart';
import 'package:walkamon_mobile/widgets/common/game_confirmation_dialog.dart';
import 'package:walkamon_mobile/widgets/common/game_notification_dialog.dart';

import '../../data/repositories/friends_repository.dart';
import '../../data/models/friends_response.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/presence_provider.dart';
import '../profile/friend_player_profile_screen.dart';

class FriendsScreen extends StatefulWidget {
  final bool isEmbedded;
  const FriendsScreen({super.key, this.isEmbedded = false});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with WidgetsBindingObserver {
  List<FriendsResponse> friends = [];
  bool isLoading = true;
  String searchQuery = '';
  int _pendingReceivedRequestCount = 0;
  bool _isRefreshingPendingRequests = false;
  Timer? _pendingRequestRefreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFriends();
      _loadPendingFriendRequestCount();
    });
    _pendingRequestRefreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _loadPendingFriendRequestCount(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pendingRequestRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadFriends();
      _loadPendingFriendRequestCount();
    }
  }

  Future<void> _loadPendingFriendRequestCount() async {
    if (!mounted || _isRefreshingPendingRequests) return;
    _isRefreshingPendingRequests = true;
    try {
      final requests = await context
          .read<FriendsRepository>()
          .getReceivedFriendRequests();
      final pendingCount = requests
          .where((request) => request.statusCode.toLowerCase() == 'pending')
          .length;
      if (!mounted || pendingCount == _pendingReceivedRequestCount) return;
      setState(() => _pendingReceivedRequestCount = pendingCount);
    } catch (error) {
      debugPrint('Không thể cập nhật badge lời mời kết bạn: $error');
    } finally {
      _isRefreshingPendingRequests = false;
    }
  }

  Future<void> _loadFriends() async {
    setState(() => isLoading = true);
    try {
      final repo = context.read<FriendsRepository>();
      final data = await repo.getFriends();
      if (mounted) {
        setState(() => friends = data);
      }
    } catch (e) {
      debugPrint("Lỗi tải danh sách bạn bè: $e");
      if (mounted) {
        showGameNotificationDialog(
          context,
          message: AppLocalizations.of(context).friendsLoadError,
          isSuccess: false,
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _removeFriend(FriendsResponse friend) async {
    // 1. Hiển thị popup xác nhận trước khi xóa
    final l10n = AppLocalizations.of(context);
    final repo = context.read<FriendsRepository>();
    final confirm = await showGameConfirmationDialog(
      context,
      title: l10n.friendsRemoveTitle,
      message: l10n.friendsRemoveConfirm(friend.username),
      cancelLabel: l10n.friendsCancel,
      confirmLabel: l10n.friendsRemove,
      destructive: true,
    );

    // 2. Nếu người dùng chọn Hủy thì dừng lại
    if (!confirm) return;

    // 3. Gọi API xóa bạn
    try {
      await repo.removeFriend(friend.userId);

      if (mounted) {
        // Cập nhật lại danh sách trên UI bằng cách xóa phần tử
        setState(() {
          friends.removeWhere((f) => f.userId == friend.userId);
        });

        // Hiện popup thông báo Xóa thành công
        _showNotification(
          AppLocalizations.of(context).friendsRemoveSuccess(friend.username),
          true,
        );
      }
    } catch (e) {
      if (mounted) {
        // Hiện popup thông báo Lỗi
        _showNotification(
          AppLocalizations.of(context).friendsRemoveFailure,
          false,
        );
      }
    }
  }

  void _showNotification(String message, bool isSuccess) {
    showGameNotificationDialog(context, message: message, isSuccess: isSuccess);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelColor = isDark ? AppColors.darkMuted : AppColors.leafLight;
    final presence = context.watch<PresenceProvider>();
    final effectiveFriends = friends.map(presence.applyPresence).toList();
    final filteredFriends = effectiveFriends
        .where(
          (friend) => friend.username.toLowerCase().contains(
            searchQuery.trim().toLowerCase(),
          ),
        )
        .toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(18, widget.isEmbedded ? 2 : 18, 18, 4),
      child: Column(
        children: [
          if (widget.isEmbedded) ...[
            _buildHeaderActions(l10n),
            const SizedBox(height: 8),
          ],
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // MainLayout uses extendBody, so its navigation overlays the
                // bottom of this screen. Reserve that area for embedded tabs.
                final systemBottom = MediaQuery.viewPaddingOf(context).bottom;
                final bottomClearance = widget.isEmbedded
                    ? 80.0 + systemBottom.clamp(10.0, 40.0).toDouble()
                    : 0.0;
                final maxPanelHeight = (constraints.maxHeight - bottomClearance)
                    .clamp(0.0, constraints.maxHeight);
                final contentHeight = filteredFriends.isEmpty
                    ? 220.0
                    : 116.0 + (filteredFriends.length * 69.0);
                final panelHeight = contentHeight.clamp(0.0, maxPanelHeight);

                return Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    height: panelHeight,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.fromLTRB(10, 28, 10, 10),
                          decoration: BoxDecoration(
                            color: panelColor.withValues(alpha: 0.96),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: AppColors.woodDeep,
                              width: 2.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.woodDeep.withValues(
                                  alpha: 0.18,
                                ),
                                blurRadius: 7,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: _buildFriendsList(
                                  effectiveFriends,
                                  filteredFriends,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildSearchBar(l10n),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 0,
                          left: 42,
                          right: 42,
                          child: Center(
                            child: Container(
                              constraints: const BoxConstraints(minWidth: 132),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.woodLight,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.woodDeep,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.woodDeep.withValues(
                                      alpha: 0.18,
                                    ),
                                    blurRadius: 3,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: GameButtonLabel(
                                l10n.socialFriends,
                                fontSize: 16,
                                outlineWidth: 2.8,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderActions(AppLocalizations l10n) {
    return Padding(
      padding: EdgeInsets.zero,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AssetOnlyIconButton(
                onPressed: () => _showFriendRequestsPopup(context),
                semanticLabel: l10n.friendsRequest,
                asset: AppAssets.iconFriendRequest,
                buttonSize: 48,
                assetSize: 44,
              ),
              if (_pendingReceivedRequestCount > 0)
                Positioned(
                  top: -1,
                  right: -1,
                  child: Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.woodDeep.withValues(alpha: 0.3),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          AssetOnlyIconButton(
            onPressed: () => _showAddFriendPopup(context),
            semanticLabel: l10n.friendsAdd,
            asset: AppAssets.iconAddFriend,
            buttonSize: 48,
            assetSize: 44,
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsList(
    List<FriendsResponse> effectiveFriends,
    List<FriendsResponse> filteredFriends,
  ) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.oliveDeep),
      );
    }

    if (effectiveFriends.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppIcon(
                Icons.group_add_rounded,
                size: 52,
                color: AppColors.olive,
              ),
              const SizedBox(height: 10),
              Text(
                l10n.friendsEmptyTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.inkDark,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                l10n.friendsEmptySubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.inkBrown,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (filteredFriends.isEmpty) {
      return Center(
        child: Text(
          l10n.friendsNoResult,
          style: TextStyle(
            color: isDark ? AppColors.darkForeground : AppColors.inkBrown,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 2),
      physics: const BouncingScrollPhysics(),
      itemCount: filteredFriends.length,
      separatorBuilder: (_, _) => const SizedBox(height: 7),
      itemBuilder: (_, index) => _buildFriendRow(filteredFriends[index]),
    );
  }

  Widget _buildFriendRow(FriendsResponse friend) {
    final l10n = AppLocalizations.of(context);
    final hasAvatar = friend.avatarUrl?.trim().isNotEmpty == true;
    final isVietnamese =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'vi';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkForeground : AppColors.inkDark;
    final mutedColor = isDark
        ? AppColors.darkMutedForeground
        : AppColors.inkBrown;

    void openProfile() {
      Navigator.pushNamed(
        context,
        '/profile/friend',
        arguments: FriendPlayerProfileArguments(
          userId: friend.userId,
          initialName: friend.username,
          initialAvatarUrl: friend.avatarUrl,
        ),
      );
    }

    return Material(
      color: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkNestedCard
          : AppColors.authCard.withValues(alpha: 0.98),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(13),
        side: BorderSide(
          color: isDark ? AppColors.darkCardBorder : AppColors.wood,
          width: 1.6,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: openProfile,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 62),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 5, 6),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.creamDeep,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? AppColors.darkIconBorder : AppColors.wood,
                      width: 1.5,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: hasAvatar
                      ? Image.network(
                          friend.avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _avatarInitial(friend),
                        )
                      : _avatarInitial(friend),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        friend.username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Image.asset(
                            friend.isOnline
                                ? AppAssets.iconOnline
                                : AppAssets.iconOffline,
                            width: 18,
                            height: 18,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              friend.isOnline
                                  ? (isVietnamese ? 'Đang online' : 'Online')
                                  : (isVietnamese ? 'Ngoại tuyến' : 'Offline'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: friend.isOnline
                                    ? AppColors.oliveDeep
                                    : mutedColor,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _friendAction(
                  tooltip: l10n.friendProfileTitle,
                  asset: AppAssets.iconFriendProfile,
                  onTap: openProfile,
                ),
                const SizedBox(width: 3),
                _friendAction(
                  tooltip: l10n.friendsRemove,
                  asset: AppAssets.iconRemoveFriend,
                  onTap: () => _removeFriend(friend),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _avatarInitial(FriendsResponse friend) {
    return Center(
      child: Text(
        friend.username.isNotEmpty ? friend.username[0].toUpperCase() : '?',
        style: TextStyle(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkForeground
              : AppColors.woodDeep,
          fontWeight: FontWeight.w900,
          fontSize: 21,
        ),
      ),
    );
  }

  Widget _friendAction({
    required String tooltip,
    required String asset,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 23,
        child: SizedBox(
          width: 41,
          height: 41,
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Image.asset(asset, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isVietnamese =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'vi';

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 42,
            child: TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
              style: const TextStyle(
                color: AppColors.inkDark,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                hintText: l10n.friendsSearchHint,
                hintStyle: const TextStyle(color: AppColors.outlineBrown),
                filled: true,
                fillColor: AppColors.authCard,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 12,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.wood,
                    width: 1.6,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.woodDeep,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 7),
        SizedBox(
          height: 42,
          child: FilledButton(
            onPressed: () => FocusScope.of(context).unfocus(),
            style: FilledButton.styleFrom(
              minimumSize: const Size(66, 42),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              backgroundColor: isDark
                  ? AppColors.darkLife
                  : AppColors.buttonGreen,
              foregroundColor: isDark
                  ? AppColors.darkTextOutline
                  : AppColors.buttonText,
              side: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.woodDeep,
                width: 1.6,
              ),
              shape: const StadiumBorder(),
            ),
            child: GameButtonLabel(
              isVietnamese ? 'Tìm' : 'Find',
              fontSize: 13,
              outlineWidth: 2.2,
            ),
          ),
        ),
      ],
    );
  }

  void _showFriendRequestsPopup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: FriendRequestsBottomSheet(
            onFriendAccepted: (newFriend) {
              if (mounted) {
                // Optimistic UI Update: Thêm ngay bạn mới vào danh sách tại chỗ
                setState(() {
                  // Chỉ thêm nếu danh sách chưa có bạn này
                  if (!friends.any((f) => f.userId == newFriend.userId)) {
                    friends.add(newFriend);
                  }
                });
              }
            },
          ),
        );
      },
    ).then((_) {
      // Cũng refresh dữ liệu khi đóng popup phòng hờ
      if (mounted) {
        _loadFriends();
        _loadPendingFriendRequestCount();
      }
    });
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
        showGameNotificationDialog(
          context,
          message: AppLocalizations.of(context).friendsLoadError,
          isSuccess: false,
        );
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
        showGameNotificationDialog(
          context,
          message: AppLocalizations.of(context).friendsSearchError,
          isSuccess: false,
        );
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
    showGameNotificationDialog(context, message: message, isSuccess: isSuccess);
  }

  Future<void> _sendRequest(FriendsResponse player) async {
    try {
      // Gọi API gửi kết bạn
      await context.read<FriendsRepository>().sendFriendRequest(player.userId);

      // Gọi thông báo thành công
      if (mounted) {
        _showGameNotification(
          AppLocalizations.of(context).friendsRequestSentTo(player.username),
          true,
        );
      }

      // Ẩn người dùng khỏi danh sách sau khi gửi
      setState(() {
        _searchResults.removeWhere((user) => user.userId == player.userId);
      });
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        String rawMessage = e.toString().replaceAll('Exception: ', '');
        String gameText = l10n.friendsRequestSendFailed;

        // Xử lý các câu báo lỗi
        if (rawMessage.contains("already sent")) {
          gameText = l10n.friendsRequestAlreadySent;
        } else if (rawMessage.contains("already friend")) {
          gameText = l10n.friendsAlreadyFriend;
        } else if (rawMessage.contains("not found")) {
          gameText = l10n.friendsPlayerNotFound;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.authCard;
    final textColor = isDark ? AppColors.darkForeground : AppColors.woodDeep;
    final l10n = AppLocalizations.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, bottomInset + 24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.wood,
            width: 2,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GameButtonLabel(
                l10n.friendsAddNew,
                fontSize: 18,
                color: textColor,
                outlineColor: isDark
                    ? AppColors.darkTextOutline
                    : AppColors.creamLight,
                outlineWidth: 3,
              ),
              IconButton(
                icon: const AppIcon(Icons.close, size: 28),
                constraints: const BoxConstraints.tightFor(
                  width: 40,
                  height: 40,
                ),
                padding: EdgeInsets.zero,
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
                    hintText: l10n.friendsPlayerNameHint,
                    filled: true,
                    fillColor: AppColors.creamLight.withOpacity(0.85),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppColors.wood,
                        width: 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppColors.wood,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppColors.woodDeep,
                        width: 2,
                      ),
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
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.buttonGreen,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.woodDeep,
                      width: 1.5,
                    ),
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
                      : AppIcon(
                          Icons.search,
                          color: AppColors.buttonText,
                          size: 17,
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Text(
            _searchController.text.trim().isEmpty
                ? l10n.friendsSuggestionsCount(_searchResults.length)
                : l10n.friendsSearchResultsCount(_searchResults.length),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),

          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [CircularProgressIndicator()],
                    ),
                  )
                : _searchResults.isEmpty
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(l10n.friendsNoAvailablePlayers),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final player = _searchResults[index];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? AppColors.darkCard
                                : AppColors.authCard,
                            borderRadius: BorderRadius.circular(
                              16,
                            ), // Thẻ bo tròn
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkCardBorder
                                  : AppColors.wood,
                              width: 2,
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
                                          errorBuilder: (_, __, ___) => AppIcon(
                                            Icons.pets,
                                            asset: AppAssets.iconFriendProfile,
                                            color: colorScheme.primary,
                                          ),
                                        )
                                      : AppIcon(
                                          Icons
                                              .pets, // Có thể đổi thành Icons.sports_esports hoặc Icons.directions_walk
                                          asset: AppAssets.iconFriendProfile,
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
                              FilledButton(
                                onPressed: () => _sendRequest(player),
                                style: FilledButton.styleFrom(
                                  backgroundColor: isDark
                                      ? AppColors.darkLife
                                      : AppColors.buttonGreen,
                                  foregroundColor: isDark
                                      ? AppColors.darkTextOutline
                                      : AppColors.buttonText,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 0,
                                  ),
                                  minimumSize: const Size(0, 36), // Thu gọn nút
                                  shape: const StadiumBorder(),
                                  side: BorderSide(
                                    color: isDark
                                        ? AppColors.darkBorder
                                        : AppColors.woodDeep,
                                    width: 1.5,
                                  ),
                                ),
                                child: GameButtonLabel(
                                  l10n.friendsAddShort,
                                  fontSize: 13,
                                  outlineWidth: 2.2,
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
  final void Function(FriendsResponse)? onFriendAccepted;

  const FriendRequestsBottomSheet({super.key, this.onFriendAccepted});

  @override
  State<FriendRequestsBottomSheet> createState() =>
      _FriendRequestsBottomSheetState();
}

class _FriendRequestsBottomSheetState extends State<FriendRequestsBottomSheet> {
  bool _isSentTab = false;
  List<FriendRequestResponse> _sentRequests = [];
  List<FriendRequestResponse> _receivedRequests = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSentRequests();
      _loadReceivedRequests();
    });
  }

  Future<void> _loadReceivedRequests() async {
    setState(() => _isLoading = true);
    try {
      final repo = context.read<FriendsRepository>();
      final results = await repo.getReceivedFriendRequests();

      // Lọc lấy những yêu cầu pending
      final pendingRequests = results
          .where((req) => req.statusCode.toLowerCase() == 'pending')
          .toList();

      if (!mounted) return;
      setState(() => _receivedRequests = pendingRequests);
    } catch (e) {
      if (!mounted) return;
      _showNotification("Không thể tải lời mời đã nhận.", false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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

      _showNotification(
        AppLocalizations.of(context).friendsRequestCanceled,
        true,
      );
    } catch (e) {
      if (!mounted) return;
      _showNotification(
        AppLocalizations.of(context).friendsRequestCancelFailed,
        false,
      );
    }
  }

  Future<void> _respondToRequest(
    FriendRequestResponse request,
    bool isAccepted,
  ) async {
    try {
      final repo = context.read<FriendsRepository>();
      await repo.respondToFriendRequest(request.requestId, isAccepted);

      if (!mounted) return;
      setState(() {
        // Xóa lời mời này khỏi danh sách đang hiển thị sau khi cập nhật thành công
        _receivedRequests = List.from(_receivedRequests)
          ..removeWhere((item) => item.requestId == request.requestId);
      });

      // Gọi callback để load lại danh sách bạn bè phía sau và truyền luôn dữ liệu người bạn (Optimistic UI)
      if (isAccepted && widget.onFriendAccepted != null) {
        widget.onFriendAccepted!(request.user);
      }

      _showNotification(
        isAccepted
            ? AppLocalizations.of(context).friendsRequestAccepted
            : AppLocalizations.of(context).friendsRequestDeclined,
        true,
      );
    } catch (e) {
      if (!mounted) return;
      _showNotification(
        AppLocalizations.of(context).friendsRequestActionFailed,
        false,
      );
    }
  }

  void _showNotification(String message, bool isSuccess) {
    showGameNotificationDialog(context, message: message, isSuccess: isSuccess);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.authCard;
    final textColor = isDark ? AppColors.darkForeground : AppColors.woodDeep;

    final currentList = _isSentTab ? _sentRequests : _receivedRequests;
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.wood,
            width: 2,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GameButtonLabel(
                l10n.friendsInbox,
                fontSize: 18,
                color: textColor,
                outlineColor: isDark
                    ? AppColors.darkTextOutline
                    : AppColors.creamLight,
                outlineWidth: 3,
              ),
              IconButton(
                icon: const AppIcon(Icons.close, size: 28),
                constraints: const BoxConstraints.tightFor(
                  width: 40,
                  height: 40,
                ),
                padding: EdgeInsets.zero,
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
                  label: Center(
                    child: Text(
                      l10n.friendsReceivedInvites,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  selected: !_isSentTab,
                  selectedColor: isDark
                      ? AppColors.darkPrimary
                      : AppColors.buttonGreen,
                  backgroundColor: isDark
                      ? AppColors.darkMuted
                      : AppColors.creamLight,
                  labelStyle: TextStyle(
                    color: !_isSentTab
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface,
                  ),
                  showCheckmark: false,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.wood,
                      width: 1.5,
                    ),
                  ),
                  onSelected: (val) {
                    if (_isSentTab) {
                      setState(() => _isSentTab = false);
                      _loadReceivedRequests();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),

              Expanded(
                child: ChoiceChip(
                  label: Center(
                    child: Text(
                      l10n.friendsSentInvites,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  selected: _isSentTab,
                  selectedColor: isDark
                      ? AppColors.darkPrimary
                      : AppColors.buttonGreen,
                  backgroundColor: isDark
                      ? AppColors.darkMuted
                      : AppColors.creamLight,
                  labelStyle: TextStyle(
                    color: _isSentTab
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface,
                  ),
                  showCheckmark: false,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.wood,
                      width: 1.5,
                    ),
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
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [CircularProgressIndicator()],
                    ),
                  )
                : currentList.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isSentTab
                              ? l10n.friendsNoSentInvites
                              : l10n.friendsNoReceivedInvites,
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    itemCount: currentList.length,
                    itemBuilder: (context, index) {
                      final req = currentList[index];
                      final targetUser = req.user;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          // Đồng bộ màu nền thẻ giống Thêm Bạn
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkCard
                              : AppColors.authCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.wood,
                            width: 2,
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
                                        errorBuilder: (_, __, ___) => AppIcon(
                                          Icons.pets,
                                          asset: AppAssets.iconFriendProfile,
                                          color: colorScheme.primary,
                                        ),
                                      )
                                    : AppIcon(
                                        Icons.pets,
                                        asset: AppAssets.iconFriendProfile,
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
                            if (_isSentTab)
                              OutlinedButton(
                                onPressed: () => _cancelRequest(req),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: AppColors.buttonSecondary,
                                  foregroundColor: AppColors.woodDeep,
                                  side: const BorderSide(
                                    color: AppColors.woodDeep,
                                    width: 1.8,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  minimumSize: const Size(0, 40),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  shape: const StadiumBorder(),
                                ),
                                child: Text(
                                  l10n.friendsCancel,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              )
                            else
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AssetOnlyIconButton(
                                    onPressed: () =>
                                        _respondToRequest(req, true),
                                    semanticLabel: l10n.pvpAccept,
                                    asset: AppAssets.iconAcceptFriend,
                                    buttonSize: 40,
                                    assetSize: 36,
                                  ),

                                  const SizedBox(width: 12),

                                  AssetOnlyIconButton(
                                    onPressed: () =>
                                        _respondToRequest(req, false),
                                    semanticLabel: l10n.pvpReject,
                                    asset: AppAssets.iconDeclineFriend,
                                    buttonSize: 40,
                                    assetSize: 36,
                                  ),
                                  const SizedBox(width: 8),
                                ],
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
