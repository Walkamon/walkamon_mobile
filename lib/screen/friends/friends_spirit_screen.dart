import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

class _FriendSpiritScreenContentState extends State<_FriendSpiritScreenContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  String activeTab = "stats";

  // Sử dụng getter để tự động thay đổi màu theo Light/Dark Theme
  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get lifeColor => isDark ? AppColors.darkLife : AppColors.lightLife;
  Color get bondColor => isDark ? AppColors.darkBond : AppColors.lightBond;
  Color get energyColor => isDark ? AppColors.darkDew : AppColors.lightDew;
  Color get expColor => isDark ? AppColors.darkAccent : AppColors.lightAccent;
  Color get primaryColor => Theme.of(context).colorScheme.primary;
  Color get glowColor =>
      isDark ? AppColors.darkLuminaGlow : AppColors.lightLuminaGlow;
  Color get mutedColor => isDark ? AppColors.darkMuted : AppColors.lightMuted;
  Color get mutedFgColor =>
      isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground;
  Color get borderColor => Theme.of(context).colorScheme.outline;
  Color get cardColor => Theme.of(context).colorScheme.surface;
  Color get fgColor => Theme.of(context).colorScheme.onSurface;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

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
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
            onPressed: () => Navigator.of(context).pop(),
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
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              provider.errorMessage,
              style: const TextStyle(color: Colors.red, fontSize: 16),
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
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
            onPressed: () => Navigator.of(context).pop(),
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

            // Khu vực Tinh linh (Sprite) với hiệu ứng glow bám sát Figma
            Expanded(
              flex: 4,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Glow Effect ngay sau lưng pet
                  AnimatedBuilder(
                    animation: _glowController,
                    builder: (context, child) {
                      return Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: glowColor.withOpacity(
                                0.3 + (_glowController.value * 0.1),
                              ),
                              blurRadius: 80,
                              spreadRadius: 20,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  // Pet Image (Không có background card)
                  LuminaSprite(stageImage: spiritData.stageImage),
                ],
              ),
            ),

            // Khung chứa thông tin chi tiết (Dạng Bottom Card to)
            Expanded(
              flex: 6,
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
        InkWell(
          onTap: () => Navigator.of(context).pop(),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: mutedColor.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.arrow_back, size: 20, color: fgColor),
          ),
        ),
        Text(
          AppLocalizations.of(context).friendSpiritOfName(spiritData.userName),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: fgColor,
          ),
        ),
        const SizedBox(width: 40), // Cân bằng khoảng trống với nút back
      ],
    );
  }

  Widget _buildDetailsCard(
    BuildContext context,
    FriendSpiritResponse spiritData,
  ) {
    String displayName = spiritData.petNickName.isNotEmpty
        ? spiritData.petNickName
        : spiritData.petName;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(32),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tên & Badge Level
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: fgColor,
                    letterSpacing: -0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: expColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 14, color: expColor),
                    const SizedBox(width: 4),
                    Text(
                      AppLocalizations.of(
                        context,
                      ).friendSpiritLevel(spiritData.level),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: expColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Danh sách Tags
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                [
                      _localizedStageName(
                        spiritData.stageName,
                        AppLocalizations.of(context),
                      ),
                    ]
                    .map(
                      (tag) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: mutedColor.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: mutedFgColor,
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 24),

          // Thanh chuyển đổi Tab
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: mutedColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => activeTab = "stats"),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: activeTab == "stats"
                            ? isDark
                                  ? const Color(0xFF5A6A5E)
                                  : cardColor
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: activeTab == "stats" && !isDark
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        AppLocalizations.of(context).friendSpiritStatsTitle,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: activeTab == "stats" ? fgColor : mutedFgColor,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => activeTab = "evolution"),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: activeTab == "evolution"
                            ? isDark
                                  ? const Color(0xFF5A6A5E)
                                  : cardColor
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: activeTab == "evolution" && !isDark
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        AppLocalizations.of(context).friendSpiritEvolutionTitle,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: activeTab == "evolution"
                              ? fgColor
                              : mutedFgColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Nội dung Tab
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: activeTab == "stats"
                  ? _buildStatsTab(spiritData)
                  : _buildEvolutionTab(spiritData),
            ),
          ),
        ],
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
          ),
          const SizedBox(height: 16),
          _buildStatRow(
            AppLocalizations.of(context).friendSpiritBonding,
            Icons.auto_awesome,
            lifeColor, // Figma dùng màu xanh lá cho Gắn kết
            {'current': spiritData.currentBond, 'max': spiritData.maxBond},
          ),
          const SizedBox(height: 16),
          _buildStatRow(
            AppLocalizations.of(context).friendSpiritEnergy,
            Icons.bolt,
            energyColor,
            {'current': spiritData.currentEnergy, 'max': spiritData.maxEnergy},
          ),
          const SizedBox(height: 16),
          _buildStatRow(
            AppLocalizations.of(context).friendSpiritLifeForce,
            Icons.spa_outlined,
            bondColor,
            {
              'current': spiritData.currentLifeForce,
              'max': spiritData.maxLifeForce,
            },
          ),

          const SizedBox(height: 28),

          // THÀNH TÍCH NỔI BẬT UI
          Text(
            AppLocalizations.of(context).friendSpiritCurrentStage,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: mutedFgColor,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: mutedColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: expColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.star_rounded, color: expColor, size: 28),
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
                          color: fgColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context).friendSpiritRecently,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: mutedFgColor,
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
    Map<String, dynamic> statData,
  ) {
    double percent = (statData['max'] > 0)
        ? (statData['current'] / statData['max'])
        : 0;
    percent = percent.clamp(0.0, 1.0);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: mutedFgColor),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: mutedFgColor,
                  ),
                ),
              ],
            ),
            Text(
              "${statData['current']}/${statData['max']}",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: fgColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 6, // Thanh mỏng nhẹ bám sát thiết kế Figma
          width: double.infinity,
          decoration: BoxDecoration(
            color: mutedColor,
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: percent,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEvolutionTab(FriendSpiritResponse spiritData) {
    return SingleChildScrollView(
      key: const ValueKey("evolution"),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(
              context,
            ).friendSpiritEvolutionStages.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: mutedFgColor,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _buildDynamicEvolutionStages(spiritData),
          ),
          const SizedBox(height: 32),

          // Lịch sử tiến hóa
          Text(
            AppLocalizations.of(context).friendSpiritMilestones.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: mutedFgColor,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          _buildHistoryTimelineRow(
            AppLocalizations.of(
              context,
            ).friendSpiritReachLevel(spiritData.level),
            AppLocalizations.of(context).friendSpiritRecently,
            Icons.security,
            0.6,
          ),
          const SizedBox(height: 16),
          _buildHistoryTimelineRow(
            AppLocalizations.of(context).friendSpiritBeginJourney,
            AppLocalizations.of(context).friendSpiritInit,
            Icons.emoji_events,
            0.3,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildEvolutionNode(
    String label,
    bool isCompleted,
    Color color, {
    bool isActive = false,
  }) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isCompleted
                    ? (isActive ? color : color.withOpacity(0.15))
                    : mutedColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted
                      ? (isActive ? color.withOpacity(0.2) : color)
                      : borderColor,
                  width: isActive ? 4 : 2,
                  style: isCompleted ? BorderStyle.solid : BorderStyle.none,
                ),
                boxShadow: isActive
                    ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8)]
                    : null,
              ),
              alignment: Alignment.center,
              child: isCompleted && !isActive
                  ? Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                    )
                  : (isActive
                        ? Text(
                            label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          )
                        : Text(
                            label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: mutedFgColor,
                            ),
                          )),
            ),
            if (isCompleted && !isActive)
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    size: 8,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildConnectingLine(
    bool isCompleted,
    Color color, {
    double progress = 1.0,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(top: 18, left: 8, right: 8),
        height: 4,
        decoration: BoxDecoration(
          color: isCompleted ? color.withOpacity(0.3) : mutedColor,
          borderRadius: BorderRadius.circular(2),
        ),
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: progress,
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTimelineRow(
    String title,
    String date,
    IconData icon,
    double opacity, {
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
                  child: Icon(
                    icon,
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
                      color: fgColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: mutedFgColor,
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
    // Walkamon defined stages
    final stages = [
      {'name': 'Mầm', 'keyWord': 'Mầm'},
      {'name': 'Chồi', 'keyWord': 'Chồi'},
      {'name': 'Lá', 'keyWord': 'Lá'},
    ];

    int currentIndex = stages.indexWhere(
      (s) => spiritData.stageName.toLowerCase().contains(
        s['keyWord']!.toLowerCase(),
      ),
    );

    if (currentIndex == -1) currentIndex = 0;

    List<Widget> children = [];
    for (int i = 0; i < stages.length; i++) {
      bool isPastOrActive = i <= currentIndex;
      bool isActive = i == currentIndex;
      Color nodeColor = isPastOrActive ? primaryColor : mutedFgColor;

      children.add(
        _buildEvolutionNode(
          stages[i]['name']!,
          isPastOrActive,
          nodeColor,
          isActive: isActive,
        ),
      );

      if (i < stages.length - 1) {
        bool lineCompleted = i < currentIndex;
        double progress = 0.0;
        if (isActive && spiritData.maxExp > 0) {
          progress = (spiritData.currentExp / spiritData.maxExp).clamp(
            0.0,
            1.0,
          );
        }

        Color lineColor = (lineCompleted || isActive)
            ? primaryColor
            : mutedFgColor;
        children.add(
          _buildConnectingLine(lineCompleted, lineColor, progress: progress),
        );
      }
    }

    return children;
  }
}

class LuminaSprite extends StatelessWidget {
  final String stageImage;
  const LuminaSprite({Key? key, required this.stageImage}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color iconColor = isDark ? AppColors.darkLife : AppColors.lightLife;

    return SizedBox(
      width: 200,
      height: 200,
      // Không còn background thẻ, ảnh đứng tự do
      child: Center(
        child: stageImage.isNotEmpty
            ? Image.asset(stageImage, fit: BoxFit.contain)
            : Icon(Icons.emoji_nature_rounded, size: 100, color: iconColor),
      ),
    );
  }
}
