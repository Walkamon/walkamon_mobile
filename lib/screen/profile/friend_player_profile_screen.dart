import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:walkamon_mobile/widgets/common/app_icon.dart';

import '../../core/constants/app_assets.dart';
import '../../core/network/api_client.dart';
import '../../data/datasources/remote/friend_profile_datasource.dart';
import '../../data/models/friend_profile_response.dart';
import '../../data/repositories/friend_profile_repository.dart';
import '../../data/repositories/friends_repository.dart';
import '../../l10n/app_localizations.dart';

class FriendPlayerProfileArguments {
  final String userId;
  final String? initialName;
  final String? initialAvatarUrl;

  const FriendPlayerProfileArguments({
    required this.userId,
    this.initialName,
    this.initialAvatarUrl,
  });
}

class FriendPlayerProfileScreen extends StatefulWidget {
  final String userId;
  final String? initialName;
  final String? initialAvatarUrl;

  const FriendPlayerProfileScreen({
    super.key,
    required this.userId,
    this.initialName,
    this.initialAvatarUrl,
  });

  @override
  State<FriendPlayerProfileScreen> createState() =>
      _FriendPlayerProfileScreenState();
}

class _FriendPlayerProfileScreenState extends State<FriendPlayerProfileScreen> {
  late final FriendProfileRepository _repository;
  late Future<FriendPlayerProfile> _profileFuture;
  bool _requestSent = false;
  bool _isSendingRequest = false;

  @override
  void initState() {
    super.initState();
    _repository = FriendProfileRepository(
      FriendProfileDatasource(ApiClient()),
    );
    _profileFuture = _repository.getFriendPlayerProfile(widget.userId);
  }

  Future<void> _refresh() async {
    setState(() {
      _profileFuture = _repository.getFriendPlayerProfile(widget.userId);
    });
    await _profileFuture;
  }

  Future<void> _sendFriendRequest(String name) async {
    if (_requestSent || _isSendingRequest) return;

    setState(() => _isSendingRequest = true);
    try {
      await context.read<FriendsRepository>().sendFriendRequest(widget.userId);
      if (!mounted) return;
      setState(() => _requestSent = true);
      _showRequestDialog(name);
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      final message = e.toString().toLowerCase();
      var gameText = l10n.friendsRequestSendFailed;
      if (message.contains('already sent')) {
        gameText = l10n.friendsRequestAlreadySent;
      } else if (message.contains('already friends') ||
          message.contains('already friend')) {
        gameText = l10n.friendsAlreadyFriend;
      } else if (message.contains('not found')) {
        gameText = l10n.friendsPlayerNotFound;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(gameText),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSendingRequest = false);
    }
  }

  void _showRequestDialog(String name) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.25),
                  ),
                ),
                child: AppIcon(
                  Icons.check_rounded,
                  color: theme.colorScheme.primary,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.friendProfileRequestSentTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.friendProfileRequestSentMessage(name),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    l10n.friendProfileGreat,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: FutureBuilder<FriendPlayerProfile>(
            future: _profileFuture,
            builder: (context, snapshot) {
              final data = snapshot.data;
              final name = _displayName(data, l10n);

              return Column(
                children: [
                  Row(
                    children: [
                      _CircleIconButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: () => Navigator.maybePop(context),
                      ),
                      Expanded(
                        child: Text(
                          l10n.friendProfileTitle,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      _CircleIconButton(
                        icon: _requestSent
                            ? Icons.check_rounded
                            : Icons.person_add_alt_1_rounded,
                        isActive: _requestSent,
                        isLoading: _isSendingRequest,
                        onTap: () => _sendFriendRequest(name),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Expanded(
                    child: snapshot.connectionState == ConnectionState.waiting
                        ? const Center(child: CircularProgressIndicator())
                        : snapshot.hasError
                            ? _ErrorState(onRetry: _refresh)
                            : RefreshIndicator(
                                onRefresh: _refresh,
                                child: ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding:
                                      const EdgeInsets.only(bottom: 28),
                                  children: [
                                    _ProfileCard(
                                      profile: data?.profile,
                                      fallbackName: widget.initialName,
                                      fallbackAvatarUrl:
                                          widget.initialAvatarUrl,
                                    ),
                                    const SizedBox(height: 22),
                                    _SectionTitle(
                                      title: l10n.friendProfileCompanion,
                                    ),
                                    const SizedBox(height: 8),
                                    _SpiritCard(
                                      spirit: data?.spirit,
                                      userId: widget.userId,
                                    ),
                                    const SizedBox(height: 22),
                                    _SectionTitle(
                                      title: l10n.friendProfileStats,
                                    ),
                                    const SizedBox(height: 8),
                                    _StatsGrid(spirit: data?.spirit),
                                    const SizedBox(height: 22),
                                    _SectionTitle(
                                      title: l10n.friendProfileAchievements,
                                    ),
                                    const SizedBox(height: 8),
                                    const _AchievementsCard(),
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
  }

  String _displayName(FriendPlayerProfile? data, AppLocalizations l10n) {
    final apiName = data?.displayName.trim() ?? '';
    if (apiName.isNotEmpty) return apiName;
    final initialName = widget.initialName?.trim() ?? '';
    if (initialName.isNotEmpty) return initialName;
    return l10n.friendProfileUnknownPlayer;
  }
}

class FriendSpiritScreen extends StatefulWidget {
  final String userId;

  const FriendSpiritScreen({super.key, required this.userId});

  @override
  State<FriendSpiritScreen> createState() => _FriendSpiritScreenState();
}

class _FriendSpiritScreenState extends State<FriendSpiritScreen> {
  late final FriendProfileRepository _repository;
  late Future<FriendSpiritResponse> _spiritFuture;

  @override
  void initState() {
    super.initState();
    _repository = FriendProfileRepository(
      FriendProfileDatasource(ApiClient()),
    );
    _spiritFuture = _repository.getFriendSpirit(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            children: [
              Row(
                children: [
                  _CircleIconButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.maybePop(context),
                  ),
                  Expanded(
                    child: Text(
                      l10n.friendSpiritTitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: 18),
              Expanded(
                child: FutureBuilder<FriendSpiritResponse>(
                  future: _spiritFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError || !snapshot.hasData) {
                      return _ErrorState(
                        onRetry: () async {
                          setState(() {
                            _spiritFuture =
                                _repository.getFriendSpirit(widget.userId);
                          });
                          await _spiritFuture;
                        },
                      );
                    }

                    final spirit = snapshot.data!;
                    return ListView(
                      children: [
                        _SpiritHero(spirit: spirit),
                        const SizedBox(height: 18),
                        _SpiritMetricBar(
                          icon: Icons.bolt_rounded,
                          label: l10n.friendProfileEnergy,
                          color: Colors.orange,
                          current: spirit.currentEnergy,
                          max: spirit.maxEnergy,
                        ),
                        _SpiritMetricBar(
                          icon: Icons.favorite_rounded,
                          label: l10n.friendProfileBond,
                          color: Colors.pink,
                          current: spirit.currentBond,
                          max: spirit.maxBond,
                        ),
                        _SpiritMetricBar(
                          icon: Icons.auto_awesome_rounded,
                          asset: AppAssets.iconLifeForce,
                          label: l10n.friendProfileLifeForce,
                          color: Colors.teal,
                          current: spirit.currentLifeForce,
                          max: spirit.maxLifeForce,
                        ),
                        _SpiritMetricBar(
                          icon: Icons.trending_up_rounded,
                          label: l10n.friendProfileExp,
                          color: theme.colorScheme.primary,
                          current: spirit.currentExp,
                          max: spirit.maxExp,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final FriendProfileResponse? profile;
  final String? fallbackName;
  final String? fallbackAvatarUrl;

  const _ProfileCard({
    this.profile,
    this.fallbackName,
    this.fallbackAvatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final name = _firstNotEmpty([
      profile?.username,
      fallbackName,
      l10n.friendProfileUnknownPlayer,
    ]);
    final avatarUrl = _firstNotEmpty([profile?.avatarUrl, fallbackAvatarUrl]);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.surface.withOpacity(0.7),
                width: 4,
              ),
              image: avatarUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(avatarUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: avatarUrl.isEmpty
                ? Text(
                    name.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.friendProfileTraveler,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if ((profile?.bio.trim().isNotEmpty ?? false)) ...[
            const SizedBox(height: 12),
            Text(
              profile!.bio,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SpiritCard extends StatelessWidget {
  final FriendSpiritResponse? spirit;
  final String userId;

  const _SpiritCard({required this.spirit, required this.userId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final petName = _firstNotEmpty([
      spirit?.petNickName,
      spirit?.petName,
      l10n.friendProfileNoSpirit,
    ]);
    final type = _firstNotEmpty([
      spirit != null ? _localizedStageName(spirit!.stageName, l10n) : null,
      l10n.friendProfileSpiritTypeUnknown,
    ]);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: spirit == null
            ? null
            : () => Navigator.pushNamed(
                  context,
                  '/spirit/friend',
                  arguments: userId,
                ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              _SpiritThumb(imageUrl: spirit?.stageImage),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Text(
                          l10n.friendProfileSpiritName(petName),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withOpacity(0.6),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant,
                            ),
                          ),
                          child: Text(
                            l10n.friendProfileViewStats,
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.friendProfileSpiritMeta(
                        type,
                        spirit?.level ?? 0,
                      ),
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              AppIcon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.55),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final FriendSpiritResponse? spirit;

  const _StatsGrid({this.spirit});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.35,
      children: [
        _StatCard(
          icon: Icons.directions_walk_rounded,
          asset: AppAssets.iconProfileSteps,
          iconColor: Colors.indigo,
          label: l10n.friendProfileTotalSteps,
          value: l10n.friendProfileUnavailable,
        ),
        _StatCard(
          icon: Icons.local_fire_department_rounded,
          asset: AppAssets.iconStreak,
          iconColor: Colors.orange,
          label: l10n.friendProfileStreak,
          value: l10n.friendProfileUnavailable,
        ),
        _StatCard(
          icon: Icons.bolt_rounded,
          iconColor: Colors.amber,
          label: l10n.friendProfileEnergy,
          value: _formatRatio(spirit?.currentEnergy, spirit?.maxEnergy),
        ),
        _StatCard(
          icon: Icons.favorite_rounded,
          iconColor: Colors.pink,
          label: l10n.friendProfileBond,
          value: _formatRatio(spirit?.currentBond, spirit?.maxBond),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String? asset;
  final Color iconColor;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    this.asset,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.14),
              shape: BoxShape.circle,
            ),
            child: AppIcon(
              icon,
              asset: asset,
              color: iconColor,
              size: 19,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AchievementsCard extends StatelessWidget {
  const _AchievementsCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.14),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.amber.withOpacity(0.2)),
            ),
            child: const AppIcon(Icons.emoji_events_rounded, color: Colors.amber),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.friendProfileAchievementsUnavailable,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpiritHero extends StatelessWidget {
  final FriendSpiritResponse spirit;

  const _SpiritHero({required this.spirit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final name = _firstNotEmpty([spirit.petNickName, spirit.petName]);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          _SpiritThumb(imageUrl: spirit.stageImage, size: 132),
          const SizedBox(height: 14),
          Text(
            name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.friendProfileSpiritMeta(_localizedStageName(spirit.stageName, l10n), spirit.level),
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpiritMetricBar extends StatelessWidget {
  final IconData icon;
  final String? asset;
  final String label;
  final Color color;
  final int current;
  final int max;

  const _SpiritMetricBar({
    required this.icon,
    this.asset,
    required this.label,
    required this.color,
    required this.current,
    required this.max,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final safeMax = max <= 0 ? 1 : max;
    final progress = (current / safeMax).clamp(0.0, 1.0);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Row(
            children: [
              AppIcon(icon, asset: asset, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                '$current/$max',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: color.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpiritThumb extends StatelessWidget {
  final String? imageUrl;
  final double size;

  const _SpiritThumb({this.imageUrl, this.size = 56});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = imageUrl?.trim() ?? '';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.14),
        borderRadius: BorderRadius.circular(size >= 100 ? 32 : 16),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
        image: url.isNotEmpty
            ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)
            : null,
      ),
      child: url.isEmpty
          ? AppIcon(
              Icons.auto_awesome_rounded,
              asset: AppAssets.iconSpiritNav,
              color: theme.colorScheme.primary,
              size: size * 0.45,
            )
          : null,
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;
  final bool isLoading;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.isActive = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: isLoading ? null : onTap,
        child: Ink(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.surface.withOpacity(0.85),
            shape: BoxShape.circle,
            border: Border.all(
              color:
                  isActive ? Colors.transparent : theme.colorScheme.outlineVariant,
            ),
          ),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.primary,
                    ),
                  )
                : AppIcon(
                    icon,
                    size: 20,
                    color: isActive
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(
            Icons.warning_amber_rounded,
            color: theme.colorScheme.error,
            size: 42,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.friendProfileLoadFailed,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const AppIcon(Icons.refresh_rounded, size: 18),
            label: Text(l10n.retry),
          ),
        ],
      ),
    );
  }
}

String _firstNotEmpty(List<String?> values) {
  for (final value in values) {
    final text = value?.trim() ?? '';
    if (text.isNotEmpty) return text;
  }
  return '';
}

String _formatRatio(int? current, int? max) {
  if (current == null && max == null) return '-';
  return '${current ?? 0}/${max ?? 0}';
}

String _localizedStageName(String backendStageName, AppLocalizations l10n) {
  final normalized = backendStageName.toLowerCase().trim();
  if (normalized.contains('m\u1ea7m')) return l10n.friendSpiritStageSeedling;
  if (normalized.contains('ch\u1ed3i')) return l10n.friendSpiritStageSprout;
  if (normalized.contains('l\u00e1')) return l10n.friendSpiritStageLeaf;
  return backendStageName;
}
