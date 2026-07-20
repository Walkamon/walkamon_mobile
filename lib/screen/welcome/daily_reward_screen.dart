import 'package:flutter/material.dart';
import 'package:walkamon_mobile/l10n/app_localizations.dart';
import '../../core/constants/app_assets.dart';
import '../auth/widgets/auth_style.dart';

class DailyRewardScreen extends StatelessWidget {
  const DailyRewardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuthGardenScaffold(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: AuthRoundIconButton(
                    icon: Icons.arrow_back_rounded,
                    semanticLabel: l10n.loginBack,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: AuthCard(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 84,
                              height: 84,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.72),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AuthStyle.gold.withValues(alpha: 0.42),
                                ),
                              ),
                              child: Image.asset(AppAssets.authLoginSteps),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.dailyRewardTitle,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: AuthStyle.forestDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.dailyRewardSubtitle,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AuthStyle.forest,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.dailyRewardDescription,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AuthStyle.forest.withValues(alpha: 0.78),
                                fontWeight: FontWeight.w600,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
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
}
