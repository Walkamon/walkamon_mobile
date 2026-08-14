import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:walkamon_mobile/core/constants/app_assets.dart';
import 'package:walkamon_mobile/widgets/common/app_icon.dart';
import 'package:walkamon_mobile/widgets/common/game_back_button.dart';
import 'package:walkamon_mobile/widgets/common/game_button_label.dart';
import 'package:walkamon_mobile/widgets/pet_runtime/pet_runtime_preview.dart';

import '../../core/network/api_client.dart';
import '../../data/datasources/remote/friend_spirit_datasource.dart';
import '../../data/repositories/friend_spirit_repository.dart';
import '../../providers/friend_spirit_provider.dart';
import '../../data/models/friend_spirit_response.dart';
import 'package:walkamon_mobile/l10n/app_localizations.dart';

import 'package:walkamon_mobile/core/theme/app_colors.dart';

class FriendSpiritScreen extends StatelessWidget {
  final String userId;

  const FriendSpiritScreen({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FriendSpiritProvider(
        FriendSpiritRepository(
          remoteDatasource: FriendSpiritDatasource(ApiClient()),
        ),
      )..fetchFriendSpirit(userId),
      child: _FriendSpiritScreenContent(userId: userId),
    );
  }
}

class _FriendSpiritScreenContent extends StatefulWidget {
  final String userId;

  const _FriendSpiritScreenContent({Key? key, required this.userId})
    : super(key: key);

  @override
  State<_FriendSpiritScreenContent> createState() =>
      _FriendSpiritScreenContentState();
}

class _FriendSpiritScreenContentState
    extends State<_FriendSpiritScreenContent> {
  String activeTab = "stats";

  // Sử dụng getter để tự động thay đổi màu theo Light/Dark Theme
  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get lifeColor => isDark ? AppColors.darkLife : AppColors.lightLife;
  Color get bondColor => isDark ? AppColors.darkBond : AppColors.lightBond;
  Color get energyColor => isDark ? AppColors.darkDew : AppColors.lightDew;
  Color get expColor => isDark ? AppColors.darkAccent : AppColors.lightAccent;
  Color get primaryColor =>
      isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
  Color get mutedColor => isDark ? AppColors.darkMuted : AppColors.lightMuted;
  Color get mutedFgColor =>
      isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground;
  Color get borderColor =>
      isDark ? AppColors.darkBorder : AppColors.lightBorder;
  Color get cardColor => isDark ? AppColors.darkCard : AppColors.authCard;
  Color get fgColor =>
      isDark ? AppColors.darkForeground : AppColors.lightForeground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<FriendSpiritProvider>();

    if (provider.isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 64,
          leadingWidth: 68,
          leading: Padding(
            padding: const EdgeInsets.only(left: 20, top: 8, bottom: 8),
            child: GameBackButton(
              semanticLabel: MaterialLocalizations.of(
                context,
              ).backButtonTooltip,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (provider.errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 64,
          leadingWidth: 68,
          leading: Padding(
            padding: const EdgeInsets.only(left: 20, top: 8, bottom: 8),
            child: GameBackButton(
              semanticLabel: MaterialLocalizations.of(
                context,
              ).backButtonTooltip,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              provider.errorMessage,
              style: TextStyle(
                color: isDark ? AppColors.darkForeground : AppColors.danger,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final spiritData = provider.friendSpirit;
    if (spiritData == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 64,
          leadingWidth: 68,
          leading: Padding(
            padding: const EdgeInsets.only(left: 20, top: 8, bottom: 8),
            child: GameBackButton(
              semanticLabel: MaterialLocalizations.of(
                context,
              ).backButtonTooltip,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        body: Center(
          child: Text(AppLocalizations.of(context).friendSpiritNoData),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 8.0,
              ),
              child: _buildHeader(context, spiritData),
            ),

            // Pet đứng tự do, đồng bộ với màn chi tiết Spirit của người dùng.
            Expanded(
              flex: 3,
              child: Center(
                child: LuminaSprite(stageImage: spiritData.stageImage),
              ),
            ),
            // Khung chứa thông tin chi tiết (Dạng Bottom Card to)
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _buildDetailsCard(context, spiritData),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, FriendSpiritResponse spiritData) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GameBackButton(
          semanticLabel: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => Navigator.of(context).pop(),
        ),
        GameButtonLabel(
          AppLocalizations.of(context).friendSpiritOfName(spiritData.userName),
          fontSize: 17,
          color: isDark ? AppColors.darkForeground : AppColors.woodDeep,
          outlineColor: isDark ? AppColors.darkTextOutline : AppColors.authCard,
          outlineWidth: 4,
        ),
        const SizedBox(width: GameBackButton.buttonSize),
      ],
    );
  }

  Widget _buildDetailsCard(
    BuildContext context,
    FriendSpiritResponse spiritData,
  ) {
    final l10n = AppLocalizations.of(context);
    final displayName = spiritData.petNickName.isNotEmpty
        ? spiritData.petNickName
        : spiritData.petName;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkCard.withValues(alpha: 0.96)
            : AppColors.authCard.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.wood,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.woodDeep.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: GameButtonLabel(
                    displayName,
                    fontSize: 19,
                    color: isDark
                        ? AppColors.darkForeground
                        : AppColors.woodDeep,
                    outlineColor: isDark
                        ? AppColors.darkTextOutline
                        : AppColors.creamLight,
                    outlineWidth: 3,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkPrimary.withValues(alpha: 0.82)
                      : AppColors.leafLight.withValues(alpha: 0.62),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AppColors.wood.withValues(alpha: 0.65),
                  ),
                ),
                child: Text(
                  l10n.friendSpiritLevel(spiritData.level),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.darkForeground
                        : AppColors.oliveDeep,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkMuted
                      : AppColors.creamLight.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AppColors.wood.withValues(alpha: 0.65),
                    width: 1.2,
                  ),
                ),
                child: Text(
                  _localizedStageName(spiritData.stageName, l10n),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.darkForeground
                        : AppColors.inkBrown,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkMuted
                  : AppColors.authCard.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.wood,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildFriendTab(
                    label: l10n.friendSpiritStatsTitle,
                    active: activeTab == 'stats',
                    onTap: () => setState(() => activeTab = 'stats'),
                  ),
                ),
                Expanded(
                  child: _buildFriendTab(
                    label: l10n.friendSpiritEvolutionTitle,
                    active: activeTab == 'evolution',
                    onTap: () => setState(() => activeTab = 'evolution'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: activeTab == 'stats'
                  ? _buildStatsTab(spiritData)
                  : _buildEvolutionTab(spiritData),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendTab({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: active
          ? (isDark ? AppColors.woodLight : AppColors.buttonGreen)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: active
                  ? (isDark ? AppColors.darkBorder : AppColors.woodDeep)
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: active
              ? GameButtonLabel(
                  label,
                  fontSize: 13,
                  color: isDark
                      ? AppColors.darkForeground
                      : AppColors.buttonText,
                  outlineColor: isDark
                      ? AppColors.darkTextOutline
                      : AppColors.woodDeep,
                  outlineWidth: 2.5,
                )
              : Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.darkForeground
                        : AppColors.woodDeep,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildStatsTab(FriendSpiritResponse spiritData) {
    return SingleChildScrollView(
      key: const ValueKey("stats"),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Các thanh chỉ số không còn nằm trong card riêng lẻ
          _buildStatRow(
            AppLocalizations.of(
              context,
            ).friendSpiritExp, // Thay thế cho Sinh Mệnh Lực (EXP) trong Figma
            Icons.favorite_border_rounded,
            expColor,
            {'current': spiritData.currentExp, 'max': spiritData.maxExp},
            asset: AppAssets.iconLevelUp,
          ),
          const SizedBox(height: 7),
          _buildStatRow(
            AppLocalizations.of(context).friendSpiritBonding,
            Icons.auto_awesome,
            lifeColor, // Figma dùng màu xanh lá cho Gắn kết
            {'current': spiritData.currentBond, 'max': spiritData.maxBond},
            asset: AppAssets.iconBond,
          ),
          const SizedBox(height: 7),
          _buildStatRow(
            AppLocalizations.of(context).friendSpiritEnergy,
            Icons.bolt,
            energyColor,
            {'current': spiritData.currentEnergy, 'max': spiritData.maxEnergy},
            asset: AppAssets.iconEnergy,
          ),
          const SizedBox(height: 7),
          _buildStatRow(
            AppLocalizations.of(context).friendSpiritLifeForce,
            Icons.spa_outlined,
            bondColor,
            {
              'current': spiritData.currentLifeForce,
              'max': spiritData.maxLifeForce,
            },
            asset: AppAssets.iconLifeForce,
          ),

          const SizedBox(height: 12),

          // THÀNH TÍCH NỔI BẬT UI
          Text(
            AppLocalizations.of(context).friendSpiritCurrentStage,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkForeground : AppColors.inkBrown,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkCard.withValues(alpha: 0.96)
                  : AppColors.authCard.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.wood.withValues(alpha: 0.7),
                width: 1.4,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkMuted
                        : AppColors.creamLight.withValues(alpha: 0.78),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.wood.withValues(alpha: 0.65),
                      width: 1.2,
                    ),
                  ),
                  child: PetRuntimePreview(
                    assetReference: spiritData.stageImage,
                    compact: true,
                    height: 56,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${_localizedStageName(spiritData.stageName, AppLocalizations.of(context))} (${AppLocalizations.of(context).friendSpiritLevel(spiritData.level)})",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.darkForeground
                              : AppColors.inkDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context).friendSpiritRecently,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.darkMutedForeground
                              : AppColors.inkBrown,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(
    String label,
    IconData icon,
    Color color,
    Map<String, dynamic> statData, {
    String? asset,
  }) {
    final current = (statData['current'] as num?)?.toInt() ?? 0;
    final maximum = (statData['max'] as num?)?.toInt() ?? 0;
    final safeMaximum = maximum <= 0 ? 1 : maximum;
    final progress = (current / safeMaximum).clamp(0.0, 1.0);

    return Row(
      children: [
        SizedBox(
          width: 96,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkForeground : AppColors.inkBrown,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 28,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  right: 12,
                  child: Container(
                    height: 17,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkMuted
                          : AppColors.creamLight,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.woodDeep,
                        width: 1.5,
                      ),
                    ),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: progress),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) => Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: value,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  right: 12,
                  child: Center(
                    child: Text(
                      '$current/$maximum',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: isDark
                            ? AppColors.darkForeground
                            : AppColors.inkDark,
                        height: 1,
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  right: -2,
                  child: CustomPaint(
                    size: Size(29, 29),
                    painter: _FriendProgressLeafPainter(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEvolutionTab(FriendSpiritResponse spiritData) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      key: const ValueKey('evolution'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkCard.withValues(alpha: 0.96)
              : AppColors.authCard.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.wood,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.friendSpiritEvolutionStages.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: isDark ? AppColors.darkForeground : AppColors.inkBrown,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildDynamicEvolutionStages(spiritData),
            ),
            const SizedBox(height: 22),
            Divider(
              color: isDark ? AppColors.darkBorder : AppColors.wood,
              height: 1,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.friendSpiritMilestones.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: isDark ? AppColors.darkForeground : AppColors.inkBrown,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 12),
            _buildHistoryTimelineRow(
              l10n.friendSpiritReachLevel(spiritData.level),
              l10n.friendSpiritRecently,
              Icons.security,
              0.6,
              asset: AppAssets.iconLevelUp,
            ),
            const SizedBox(height: 7),
            _buildHistoryTimelineRow(
              l10n.friendSpiritBeginJourney,
              l10n.friendSpiritInit,
              Icons.emoji_events,
              0.3,
              asset: AppAssets.iconAchievement,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTimelineRow(
    String title,
    String date,
    IconData icon,
    double opacity, {
    String? asset,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 24,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                if (!isLast)
                  Positioned(
                    top: 24,
                    bottom: -16,
                    child: Container(width: 2, color: mutedColor),
                  ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(opacity),
                    shape: BoxShape.circle,
                    border: Border.all(color: cardColor, width: 3),
                  ),
                  child: AppIcon(
                    icon,
                    asset: asset,
                    size: 10,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.darkForeground
                          : AppColors.inkDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.darkMutedForeground
                          : AppColors.inkBrown,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _localizedStageName(String backendStageName, AppLocalizations l10n) {
    final normalized = backendStageName.toLowerCase().trim();
    // Map backend Vietnamese stage names → localized keys
    if (normalized.contains('m\u1ea7m')) return l10n.friendSpiritStageSeedling;
    if (normalized.contains('ch\u1ed3i')) return l10n.friendSpiritStageSprout;
    if (normalized.contains('l\u00e1')) return l10n.friendSpiritStageLeaf;
    // Fallback: return raw name as-is (future stages not yet mapped)
    return backendStageName;
  }

  List<Widget> _buildDynamicEvolutionStages(FriendSpiritResponse spiritData) {
    final l10n = AppLocalizations.of(context);
    final reference = parsePetRuntimeAssetReference(spiritData.stageImage);
    final affinity =
        reference?.affinityCode ?? _inferAffinity(spiritData.stageName);
    final currentIndex = affinity == 'sprout'
        ? 0
        : (reference?.stageNo ?? 1) >= 2
        ? 2
        : 1;
    final nodes = [
      (label: l10n.friendSpiritStageSeedling, affinity: 'sprout', stage: 0),
      (
        label: l10n.friendSpiritStageSprout,
        affinity: affinity == 'sprout' ? 'warm_sun' : affinity,
        stage: 1,
      ),
      (
        label: l10n.friendSpiritStageLeaf,
        affinity: affinity == 'sprout' ? 'warm_sun' : affinity,
        stage: 2,
      ),
    ];

    final children = <Widget>[];
    for (var index = 0; index < nodes.length; index++) {
      final node = nodes[index];
      children.add(
        Expanded(
          child: _buildEvolutionPetNode(
            label: node.label,
            affinity: node.affinity,
            stageNo: node.stage,
            completed: index <= currentIndex,
            active: index == currentIndex,
          ),
        ),
      );
      if (index < nodes.length - 1) {
        children.add(
          Container(
            width: 22,
            height: 3,
            margin: const EdgeInsets.only(top: 32),
            decoration: BoxDecoration(
              color: index < currentIndex
                  ? (isDark ? AppColors.darkBorder : AppColors.buttonGreen)
                  : (isDark
                        ? AppColors.darkMutedForeground
                        : AppColors.wood.withValues(alpha: 0.35)),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }
    }
    return children;
  }

  Widget _buildEvolutionPetNode({
    required String label,
    required String affinity,
    required int stageNo,
    required bool completed,
    required bool active,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 66,
          height: 66,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: active
                ? (isDark
                      ? AppColors.darkPrimary
                      : AppColors.leafLight.withValues(alpha: 0.72))
                : (isDark
                      ? AppColors.darkMuted
                      : AppColors.creamLight.withValues(alpha: 0.86)),
            shape: BoxShape.circle,
            border: Border.all(
              color: active
                  ? (isDark ? AppColors.darkBorder : AppColors.woodDeep)
                  : (isDark ? AppColors.darkBorder : AppColors.wood),
              width: active ? 2.2 : 1.2,
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.woodDeep.withValues(alpha: 0.16),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Opacity(
            opacity: completed ? 1 : 0.5,
            child: PetRuntimePreview(
              affinityCode: affinity,
              stageNo: stageNo,
              animationType: 'idle',
              compact: true,
              height: 58,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: active ? FontWeight.w900 : FontWeight.w700,
            color: active
                ? (isDark ? AppColors.darkForeground : AppColors.oliveDeep)
                : (isDark ? AppColors.darkMutedForeground : AppColors.inkBrown),
          ),
        ),
      ],
    );
  }

  String _inferAffinity(String stageName) {
    final normalized = stageName.toLowerCase();
    if (normalized.contains('bình minh') || normalized.contains('dawn')) {
      return 'dawn';
    }
    if (normalized.contains('ánh trăng') || normalized.contains('moon')) {
      return 'moonlight';
    }
    if (normalized.contains('nắng') || normalized.contains('warm')) {
      return 'warm_sun';
    }
    return 'sprout';
  }
}

class _FriendProgressLeafPainter extends CustomPainter {
  const _FriendProgressLeafPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final leaf = Path()
      ..moveTo(size.width * 0.13, size.height * 0.76)
      ..cubicTo(
        size.width * 0.18,
        size.height * 0.20,
        size.width * 0.68,
        size.height * 0.04,
        size.width * 0.90,
        size.height * 0.10,
      )
      ..cubicTo(
        size.width * 0.95,
        size.height * 0.46,
        size.width * 0.76,
        size.height * 0.85,
        size.width * 0.13,
        size.height * 0.76,
      )
      ..close();
    canvas.drawPath(leaf, Paint()..color = AppColors.leafBright);
    canvas.drawPath(
      leaf,
      Paint()
        ..color = AppColors.oliveDeep
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawLine(
      Offset(size.width * 0.13, size.height * 0.76),
      Offset(size.width * 0.78, size.height * 0.23),
      Paint()
        ..color = AppColors.oliveDeep
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LuminaSprite extends StatelessWidget {
  final String stageImage;
  const LuminaSprite({Key? key, required this.stageImage}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final imagePath = stageImage.trim();
    final imageScheme = Uri.tryParse(imagePath)?.scheme.toLowerCase();
    final isRuntimeReference = imageScheme == 'asset';
    final isNetworkImage = imageScheme == 'http' || imageScheme == 'https';
    final fallback = const AppIcon(
      Icons.emoji_nature_rounded,
      asset: AppAssets.iconSpiritNav,
      size: 112,
      color: AppColors.leafShadow,
    );

    return SizedBox(
      width: 230,
      height: 210,
      child: Center(
        child: isRuntimeReference
            ? PetRuntimePreview(
                assetReference: imagePath,
                compact: true,
                height: 178,
              )
            : imagePath.isNotEmpty
            ? (isNetworkImage
                  ? Image.network(
                      imagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => fallback,
                    )
                  : Image.asset(
                      imagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => fallback,
                    ))
            : fallback,
      ),
    );
  }
}
