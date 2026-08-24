import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/network/api_client.dart';
import '../../data/datasources/remote/notification_datasource.dart';
import '../../data/models/notification_response.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/common/app_icon.dart';
import '../../widgets/common/asset_only_icon_button.dart';
import '../../widgets/common/game_button_label.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/common/game_notification_dialog.dart';
import '../../widgets/common/game_async_state.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final NotificationDatasource _datasource;
  List<NotificationItem> _notifications = [];
  bool _isLoading = true;
  bool _hasLoadError = false;

  @override
  void initState() {
    super.initState();
    _datasource = NotificationDatasourceImpl(ApiClient());
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasLoadError = false;
      });
    }
    try {
      final data = await _datasource.getNotifications(1, 20);
      if (!mounted) return;
      setState(() {
        _notifications = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasLoadError = true;
        _isLoading = false;
      });
    }
  }

  void _showGameToast(String message, {bool isError = false}) {
    showGameNotificationDialog(context, message: message, isSuccess: !isError);
  }

  Future<void> _deleteNotification(String id, int index) async {
    try {
      await _datasource.deleteNotification(id);
      if (mounted) {
        _showGameToast(AppLocalizations.of(context).notificationsDeleted);
      }
    } catch (e) {
      _fetchNotifications();
      if (mounted) {
        _showGameToast(
          AppLocalizations.of(context).notificationsDeleteFailed('$e'),
          isError: true,
        );
      }
    }
  }

  Future<void> _showNotificationDetail(NotificationItem item) async {
    if (!item.isRead) {
      setState(() {
        item.isRead = true;
      });
    }

    showDialog(
      context: context,
      barrierColor: Colors.black45,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 24,
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 420,
              maxHeight: MediaQuery.sizeOf(context).height * 0.78,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 32),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.authCard,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.wood,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.woodDeep.withValues(alpha: 0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: FutureBuilder<NotificationDetail>(
                future: _datasource.getNotificationDetail(item.notificationId),
                builder: (context, snapshot) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GameButtonLabel(
                        item.title,
                        fontSize: 21,
                        color: isDark
                            ? AppColors.darkForeground
                            : AppColors.woodDeep,
                        outlineColor: isDark
                            ? AppColors.darkTextOutline
                            : AppColors.creamLight,
                        outlineWidth: 3,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatTimeAgo(item.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkMutedForeground
                              : AppColors.outlineBrown,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const Padding(
                          padding: EdgeInsets.all(28),
                          child: CircularProgressIndicator(
                            color: AppColors.oliveDeep,
                          ),
                        )
                      else if (snapshot.hasError)
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            AppLocalizations.of(
                              context,
                            ).notificationsDetailError,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.darkForeground
                                  : AppColors.inkBrown,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      else if (snapshot.hasData)
                        Flexible(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                if (snapshot.data!.imageUrl != null &&
                                    snapshot.data!.imageUrl!.isNotEmpty) ...[
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(
                                      snapshot.data!.imageUrl!,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) =>
                                          const SizedBox.shrink(),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                ],
                                if (snapshot.data!.typeCode?.isNotEmpty == true)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 13,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.darkPrimary.withValues(
                                              alpha: 0.7,
                                            )
                                          : AppColors.leafLight.withValues(
                                              alpha: 0.5,
                                            ),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: AppColors.wood.withValues(
                                          alpha: 0.55,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      _translateTypeCode(
                                        snapshot.data!.typeCode,
                                      ),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: isDark
                                            ? AppColors.darkForeground
                                            : AppColors.oliveDeep,
                                      ),
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    4,
                                    2,
                                    4,
                                    12,
                                  ),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: Text(
                                      snapshot.data!.body,
                                      textAlign: TextAlign.left,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isDark
                                            ? AppColors.darkForeground
                                            : AppColors.inkBrown,
                                        fontWeight: FontWeight.w600,
                                        height: 1.55,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatTimeAgo(DateTime date) {
    final l10n = AppLocalizations.of(context);
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return l10n.notificationsTimeAgoDays(diff.inDays);
    if (diff.inHours > 0) return l10n.notificationsTimeAgoHours(diff.inHours);
    if (diff.inMinutes > 0) {
      return l10n.notificationsTimeAgoMinutes(diff.inMinutes);
    }
    return l10n.notificationsTimeAgoJustNow;
  }

  String _notificationIconKey(String? iconName, String? typeCode) {
    final normalizedIcon = iconName?.trim().toLowerCase() ?? '';
    final normalizedType = typeCode?.trim().toLowerCase() ?? '';
    if (_isKnownNotificationIconKey(normalizedIcon) || normalizedType.isEmpty) {
      return normalizedIcon;
    }
    return normalizedType;
  }

  bool _isKnownNotificationIconKey(String key) {
    return key.contains('maintenance') ||
        key.contains('patch') ||
        key.contains('news') ||
        key.contains('megaphone') ||
        key.contains('announcement') ||
        key.contains('gift') ||
        key.contains('reward') ||
        key.contains('claim') ||
        key.contains('sword') ||
        key.contains('battle') ||
        key.contains('pvp') ||
        key.contains('success') ||
        key.contains('confirmed') ||
        key.contains('error') ||
        key.contains('failed') ||
        key.contains('warning') ||
        key.contains('info') ||
        key.contains('footprint') ||
        key.contains('step_goal') ||
        key.contains('calendar') ||
        key.contains('event');
  }

  IconData _getNotificationIcon(String? iconName, [String? typeCode]) {
    switch (_notificationIconKey(iconName, typeCode)) {
      case 'megaphone':
        return Icons.campaign;
      case 'gift':
        return Icons.card_giftcard;
      case 'sword':
      case 'swords':
        return Icons.sports_martial_arts;
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'info':
        return Icons.info_outline;
      default:
        return Icons.notifications;
    }
  }

  String _getNotificationIconAsset(String? iconName, [String? typeCode]) {
    final key = _notificationIconKey(iconName, typeCode);
    if (key.contains('maintenance')) return AppAssets.notificationMaintenance;
    if (key.contains('patch')) return AppAssets.notificationPatchNotes;
    if (key.contains('news')) return AppAssets.notificationNews;
    if (key.contains('megaphone') || key.contains('announcement')) {
      return AppAssets.notificationAnnouncement;
    }
    if (key.contains('gift') ||
        key.contains('reward') ||
        key.contains('claim')) {
      return AppAssets.notificationRewardClaim;
    }
    if (key.contains('sword') ||
        key.contains('battle') ||
        key.contains('pvp')) {
      return AppAssets.iconAttack;
    }
    if (key.contains('success') || key.contains('confirmed')) {
      return AppAssets.notificationSuccess;
    }
    if (key.contains('error') || key.contains('failed')) {
      return AppAssets.notificationError;
    }
    if (key.contains('warning')) return AppAssets.notificationWarning;
    if (key.contains('info')) return AppAssets.notificationInfo;
    if (key.contains('footprint') || key.contains('step_goal')) {
      return AppAssets.iconStep;
    }
    if (key.contains('calendar') || key.contains('event')) {
      return AppAssets.notificationEvent;
    }
    return AppAssets.iconNotificationBell;
  }

  String _translateTypeCode(String? typeCode) {
    if (typeCode == null || typeCode.isEmpty) return '';
    switch (typeCode) {
      case 'daily_reward':
        return AppLocalizations.of(context).notificationsTypeDailyReward;
      case 'daily_step_goal_reminder':
        return AppLocalizations.of(
          context,
        ).notificationsTypeDailyStepGoalReminder;
      case 'streak_reward':
        return AppLocalizations.of(context).notificationsTypeStreakReward;
      case 'mission_complete':
        return AppLocalizations.of(context).notificationsTypeMissionComplete;
      case 'achievement_complete':
        return AppLocalizations.of(
          context,
        ).notificationsTypeAchievementComplete;
      case 'challenge_invite':
        return AppLocalizations.of(context).notificationsTypeChallengeInvite;
      case 'pvp_invite':
        return AppLocalizations.of(context).notificationsTypePvpInvite;
      case 'friend_request':
        return AppLocalizations.of(context).notificationsTypeFriendRequest;
      case 'friend_accepted':
        return AppLocalizations.of(context).notificationsTypeFriendAccepted;
      case 'friend_removed':
        return AppLocalizations.of(context).notificationsTypeFriendRemoved;
      case 'spirit_hungry':
        return AppLocalizations.of(context).notificationsTypeSpiritHungry;
      case 'spirit_ready_evolution':
        return AppLocalizations.of(
          context,
        ).notificationsTypeSpiritReadyEvolution;
      case 'spirit_energy_full':
        return AppLocalizations.of(context).notificationsTypeSpiritEnergyFull;
      case 'spirit_bond_low':
        return AppLocalizations.of(context).notificationsTypeSpiritBondLow;
      case 'spirit_level_up':
        return AppLocalizations.of(context).notificationsTypeSpiritLevelUp;
      case 'item_purchased':
        return AppLocalizations.of(context).notificationsTypeItemPurchased;
      case 'pvp_result':
        return AppLocalizations.of(context).notificationsTypePvpResult;
      case 'maintenance':
        return AppLocalizations.of(context).notificationsTypeMaintenance;
      case 'patch_notes':
        return AppLocalizations.of(context).notificationsTypePatchNotes;
      case 'news':
        return AppLocalizations.of(context).notificationsTypeNews;
      case 'event':
        return AppLocalizations.of(context).notificationsTypeEvent;
      case 'compensation':
        return AppLocalizations.of(context).notificationsTypeCompensation;
      case 'server_announcement':
        return AppLocalizations.of(context).notificationsTypeServerAnnouncement;
      default:
        return typeCode;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: AssetOnlyIconButton(
            icon: Icons.arrow_back,
            semanticLabel: MaterialLocalizations.of(context).backButtonTooltip,
            buttonSize: 40,
            assetSize: 36,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: GameButtonLabel(
          l10n.notificationsTitle,
          fontSize: 20,
          color: AppColors.woodDeep,
          outlineColor: AppColors.authCard,
          outlineWidth: 4,
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: GameLoadingIndicator(label: l10n.loading))
          : _hasLoadError
          ? GameAsyncStatePanel(
              message: l10n.notificationsLoadFailed,
              isError: true,
              onRetry: _fetchNotifications,
              retryLabel: l10n.retry,
            )
          : _notifications.isEmpty
          ? GameAsyncStatePanel(
              message: l10n.notificationsEmpty,
              onRetry: _fetchNotifications,
              retryLabel: l10n.retry,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final item = _notifications[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkNestedCard.withValues(
                            alpha: item.isRead ? 0.72 : 0.9,
                          )
                        : item.isRead
                        ? AppColors.authCard.withValues(alpha: 0.82)
                        : AppColors.authCard.withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkCardBorder.withValues(
                              alpha: item.isRead ? 0.55 : 0.95,
                            )
                          : item.isRead
                          ? AppColors.wood.withValues(alpha: 0.65)
                          : AppColors.oliveDeep,
                      width: item.isRead ? 1.5 : 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.woodDeep.withValues(alpha: 0.12),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => _showNotificationDetail(item),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Opacity(
                                  opacity: item.isRead ? 0.65 : 1,
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.darkMuted
                                          : AppColors.leafLight.withValues(
                                              alpha: 0.48,
                                            ),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isDark
                                            ? AppColors.darkBorder.withValues(
                                                alpha: 0.35,
                                              )
                                            : AppColors.wood.withValues(
                                                alpha: 0.55,
                                              ),
                                      ),
                                    ),
                                    child: AppIcon(
                                      _getNotificationIcon(item.typeCode),
                                      asset: _getNotificationIconAsset(
                                        item.typeCode,
                                      ),
                                      size: 34,
                                      color: isDark
                                          ? AppColors.darkForeground
                                          : item.isRead
                                          ? AppColors.outlineBrown
                                          : AppColors.oliveDeep,
                                    ),
                                  ),
                                ),
                                if (!item.isRead)
                                  const Positioned(
                                    top: -2,
                                    right: -2,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: AppColors.success,
                                        shape: BoxShape.circle,
                                      ),
                                      child: SizedBox(width: 11, height: 11),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: isDark
                                          ? AppColors.darkForeground
                                          : item.isRead
                                          ? AppColors.outlineBrown
                                          : AppColors.inkDark,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    item.shortBody,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.4,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? AppColors.darkForeground
                                          : item.isRead
                                          ? AppColors.outlineBrown
                                          : AppColors.inkBrown,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _formatTimeAgo(item.createdAt),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? AppColors.darkMutedForeground
                                          : AppColors.outlineBrown,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            IconButton(
                              tooltip: MaterialLocalizations.of(
                                context,
                              ).deleteButtonTooltip,
                              onPressed: () {
                                final deletedId = item.notificationId;
                                setState(() {
                                  _notifications.removeAt(index);
                                });
                                _deleteNotification(deletedId, index);
                              },
                              constraints: const BoxConstraints.tightFor(
                                width: 40,
                                height: 40,
                              ),
                              padding: EdgeInsets.zero,
                              icon: AppIcon(
                                Icons.delete_outline,
                                size: 26,
                                color: isDark
                                    ? AppColors.darkForeground
                                    : AppColors.woodDeep,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
