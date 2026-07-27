import 'package:flutter/material.dart';

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
    debugPrint('Overlay rebuild countdown: $countdown');
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
                countdown <= 0 ? 'GO' : '$countdown',
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

class PvPFinishedOverlay extends StatelessWidget {
  final bool isWin;
  final String opponentName;
  final VoidCallback onContinue;

  const PvPFinishedOverlay({
    super.key,
    required this.isWin,
    required this.opponentName,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: Colors.black87,
      alignment: Alignment.center,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isWin) ...[
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    size: 64,
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Chiến thắng!',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: theme.textTheme.bodyMedium,
                    children: [
                      const TextSpan(text: 'Mochi đã đánh bại '),
                      TextSpan(
                        text: opponentName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildRewardCard(
                      context,
                      'Thưởng',
                      '+50',
                      Icons.water_drop,
                      Colors.blue,
                    ),
                    const SizedBox(width: 16),
                    _buildRewardCard(
                      context,
                      'Gắn kết',
                      '+10',
                      Icons.favorite,
                      Colors.red,
                    ),
                  ],
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '#2',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Về nhì',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Cố gắng thêm chút nữa nhé!'),
              ],
              const SizedBox(height: 32),
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
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
