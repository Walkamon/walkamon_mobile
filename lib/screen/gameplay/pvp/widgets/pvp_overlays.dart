import 'package:flutter/material.dart';
import '../../../../data/models/pvp_models.dart';

class PvPMatchingOverlay extends StatelessWidget {
  const PvPMatchingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      alignment: Alignment.center,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                'Đang tìm đối thủ...',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PvPWaitingFriendOverlay extends StatelessWidget {
  final String opponentName;
  final VoidCallback onCancel;

  const PvPWaitingFriendOverlay({
    super.key,
    required this.opponentName,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      alignment: Alignment.center,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                'Đã gửi lời mời!',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium,
                  children: [
                    const TextSpan(text: 'Đang chờ '),
                    TextSpan(
                      text: opponentName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const TextSpan(text: ' phản hồi...'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: onCancel,
                child: const Text('Hủy yêu cầu'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PvPRoomCountdownOverlay extends StatelessWidget {
  final String opponentName;
  final int countdown;

  const PvPRoomCountdownOverlay({
    super.key,
    required this.opponentName,
    required this.countdown,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      alignment: Alignment.center,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.sports_kabaddi,
                  size: 48,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Đã kết nối!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium,
                  children: [
                    const TextSpan(text: 'Bạn sẽ đua với '),
                    TextSpan(
                      text: opponentName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                countdown > 0 ? '$countdown' : '',
                style: const TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'CHUẨN BỊ VÀO TRẬN',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PvPMatchSuccessOverlay extends StatelessWidget {
  const PvPMatchSuccessOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: Colors.black54,
      alignment: Alignment.center,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 48,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Ghép trận thành công!',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Đang vào cuộc đua. Đếm ngược sẽ bắt đầu ngay sau khi trận đấu sẵn sàng.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PvPFinishedOverlay extends StatelessWidget {
  final PvpMatchResultResponse? result;
  final bool isLoading;
  final String? currentUserId;
  final String opponentName;
  final VoidCallback onContinue;
  final Future<void> Function()? onClaimReward;
  final bool isClaiming;

  const PvPFinishedOverlay({
    super.key,
    required this.result,
    required this.isLoading,
    required this.currentUserId,
    required this.opponentName,
    required this.onContinue,
    this.onClaimReward,
    this.isClaiming = false,
  });

  Color? _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final normalized = hex.startsWith('#') ? hex.substring(1) : hex;
    if (normalized.length != 6 && normalized.length != 8) return null;
    final value = int.tryParse(normalized, radix: 16);
    if (value == null) return null;
    return Color(normalized.length == 6 ? (0xFF000000 | value) : value);
  }

  String _titleForResult(String? resultCode) {
    switch (resultCode) {
      case 'win':
        return 'Chiến thắng!';
      case 'draw':
        return 'Hòa!';
      case 'lose':
        return 'Thất bại';
      default:
        return 'Kết quả trận đấu';
    }
  }

  String _subtitleForResult(String? resultCode) {
    switch (resultCode) {
      case 'win':
        return opponentName.isEmpty
            ? 'Bạn đã thắng trận sprint!'
            : 'Bạn đã đánh bại $opponentName';
      case 'draw':
        return 'Hai bên ngang điểm';
      case 'lose':
        return 'Cố gắng thêm chút nữa nhé!';
      default:
        return 'Đang tải kết quả từ máy chủ...';
    }
  }

  String _formatMmrDelta(int delta) {
    if (delta > 0) return '+$delta';
    return '$delta';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resultCode = result?.resultCodeForUser(currentUserId);
    final isWin = resultCode == 'win';
    final isDraw = resultCode == 'draw';
    final rank = result?.rankAfter ?? result?.rankBefore;
    final rankColor =
        _parseHexColor(rank?.colorHex) ?? theme.colorScheme.primary;
    final canClaim =
        result != null &&
        result!.canClaimReward &&
        result!.claimedAt == null &&
        onClaimReward != null;

    return Container(
      color: Colors.black87,
      alignment: Alignment.center,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading && result == null) ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  Text(
                    'Đang tải kết quả...',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Đang chờ máy chủ chốt trận...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ] else if (result == null) ...[
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Chưa lấy được kết quả trận',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Trận đã kết thúc. Thử lại sau hoặc tiếp tục.',
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: (isWin
                              ? Colors.amber
                              : isDraw
                              ? Colors.blueGrey
                              : Colors.grey)
                          .withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isWin
                          ? Icons.emoji_events
                          : isDraw
                          ? Icons.handshake
                          : Icons.close,
                      size: 64,
                      color: isWin
                          ? Colors.amber
                          : isDraw
                          ? Colors.blueGrey
                          : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _titleForResult(resultCode),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _subtitleForResult(resultCode),
                    textAlign: TextAlign.center,
                  ),
                  if (result != null) ...[
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        if (result!.isRanked) ...[
                          _buildRewardCard(
                            context,
                            'MMR',
                            _formatMmrDelta(result!.mmrDelta),
                            Icons.trending_up,
                            result!.mmrDelta >= 0
                                ? Colors.amber
                                : theme.colorScheme.error,
                          ),
                          _buildRewardCard(
                            context,
                            'MMR hiện tại',
                            '${result!.mmrAfter}',
                            Icons.speed,
                            theme.colorScheme.primary,
                          ),
                        ],
                        if (rank != null)
                          _buildRewardCard(
                            context,
                            result!.tierChanged ? 'Rank mới' : 'Rank',
                            rank.displayName,
                            Icons.military_tech,
                            rankColor,
                          ),
                      ],
                    ),
                    if (result!.claimedAt != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Đã nhận thưởng',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ],
                const SizedBox(height: 32),
                if (canClaim) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isClaiming ? null : () => onClaimReward?.call(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: isClaiming
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Nhận thưởng',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: onContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Text(
                      'Tiếp tục',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRewardCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
