// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Walkamon';

  @override
  String get system => 'System';

  @override
  String get notificationsRemind => 'Reminder notifications';

  @override
  String get notificationsSubtitle =>
      'Get reminders for feeding and walking your pet';

  @override
  String get featuresSupport => 'Features & Support';

  @override
  String get language => 'Language';

  @override
  String get languageVi => 'Vietnamese';

  @override
  String get languageEn => 'English';

  @override
  String get sendFeedback => 'Send feedback & report bugs';

  @override
  String get accountSecurity => 'Account & Security';

  @override
  String get changePassword => 'Change password';

  @override
  String get logout => 'Log out';

  @override
  String get feedbackTitle => 'Send feedback';

  @override
  String get feedbackSuggestion => 'Suggestion';

  @override
  String get feedbackBug => 'Bug report';

  @override
  String get feedbackDetail => 'Details';

  @override
  String get feedbackHintSuggestion =>
      'Do you have any new ideas for the game?';

  @override
  String get feedbackHintBug => 'What issue did you encounter while playing?';

  @override
  String get feedbackSending => 'Sending...';

  @override
  String get feedbackSubmit => 'Submit';

  @override
  String get feedbackSuccess => 'Feedback sent successfully';

  @override
  String feedbackMinLength(int count) {
    return 'Description must be at least 20 characters. ($count/20)';
  }

  @override
  String get gameSettings => 'Game Settings';

  @override
  String get bgm => 'Background music (BGM)';

  @override
  String get sfx => 'Sound effects (SFX)';

  @override
  String get haptics => 'Touch feedback';

  @override
  String get hapticsSubtitle =>
      'Gentle vibration for care actions, rewards and races';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get navHome => 'Home';

  @override
  String get navShop => 'Shop';

  @override
  String get navBag => 'Bag';

  @override
  String get navQuest => 'Quest';

  @override
  String get navProfile => 'Profile';

  @override
  String get welcomeTagline => 'Walk & Grow Together';

  @override
  String get welcomeExplore => 'Explore Now';

  @override
  String get welcomeLogin => 'Login';

  @override
  String get welcomeRegister => 'Register';

  @override
  String get welcomeOr => 'OR';

  @override
  String get welcomeGoogleLogin => 'Continue with Google';

  @override
  String get googleLoginFailed => 'Google sign in failed';

  @override
  String get healthWarning =>
      'Playing for more than 180 minutes a day may harm your health';

  @override
  String get today => 'Today';

  @override
  String get todayStepsDesc => 'Steps you\'ve walked today';

  @override
  String get petActionBusy =>
      'Your pet is finishing another action. Please wait a moment.';

  @override
  String get petLifeForceFull => 'Your pet has reached its Life Force limit.';

  @override
  String get petFeedLimitReached =>
      'You have reached the feeding limit. Please come back later.';

  @override
  String get petFeedInsufficientDew =>
      'You do not have enough Dewdrops to feed your pet.';

  @override
  String get petFeedUnavailable =>
      'Unable to feed your pet right now. Please try again.';

  @override
  String get stepTrackingPermissionRequired =>
      'Allow activity recognition to record steps in the background.';

  @override
  String get stepTrackingPermissionAction => 'Allow access';

  @override
  String get stepTrackingPermissionSettings => 'Open settings';

  @override
  String get stepTrackingSensorUnavailable =>
      'Step sensors are unavailable on this device.';

  @override
  String get step => 'Steps';

  @override
  String get luminaStatus => 'LUMINA STATUS';

  @override
  String get energy => 'Energy';

  @override
  String get lifeForce => 'Life Force';

  @override
  String get bonding => 'Bonding';

  @override
  String levelShort(int level) {
    return 'Lv. $level';
  }

  @override
  String expProgress(int current, int max) {
    return 'EXP $current/$max';
  }

  @override
  String get homeNavCommunity => 'Community';

  @override
  String get homeNavPvp => 'PvP';

  @override
  String get homeNavInventory => 'Inventory';

  @override
  String get homeNavStore => 'Shop';

  @override
  String get loginBack => 'Go back';

  @override
  String get loginTagline => 'Every step, a little magic';

  @override
  String get loginWelcomeBack => 'Welcome back!';

  @override
  String get loginSubtitle => 'Continue your journey with your Lumina spirit.';

  @override
  String get loginEmailRequired => 'Email is required.';

  @override
  String get loginEmailInvalid => 'Invalid email format.';

  @override
  String get loginPasswordRequired => 'Password is required.';

  @override
  String get loginFailed => 'Login failed.';

  @override
  String get loginEmail => 'Email';

  @override
  String get loginPassword => 'Password';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get forgotPasswordTitle => 'Lost password?';

  @override
  String get forgotPasswordSubtitle =>
      'Enter your registered email and we will send an OTP to reset your password.';

  @override
  String get forgotPasswordResetSent =>
      'If the email exists, a password reset OTP has been sent.';

  @override
  String get forgotPasswordRequestFailed =>
      'Unable to send password reset request.';

  @override
  String get forgotPasswordSendSignal => 'Send signal';

  @override
  String get loginButton => 'Log in';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get registerNow => 'Sign up now';

  @override
  String get registerTitle => 'Plant your first seed';

  @override
  String get registerSubtitle =>
      'Sign the pact and begin your own magical journey';

  @override
  String get registerNameHint => 'Your name';

  @override
  String get registerPasswordMinLength =>
      'Password must contain at least 6 characters.';

  @override
  String get registerConfirmPassword => 'Confirm password';

  @override
  String get registerNameRequired => 'Name is required.';

  @override
  String get registerNameMinLength =>
      'Name must contain at least 2 characters.';

  @override
  String get registerConfirmPasswordRequired => 'Please confirm your password.';

  @override
  String get registerPasswordMismatch =>
      'Password confirmation does not match.';

  @override
  String get registerFailed => 'Registration failed. Please try again.';

  @override
  String get registerAgreeTerms => 'I have read and agree to ';

  @override
  String get privacyPolicy => 'Privacy policy and terms of use';

  @override
  String get registerButton => 'Start the pact';

  @override
  String get registerAlreadyAccount => 'Already signed the pact?';

  @override
  String get registerLoginHere => 'Log in here';

  @override
  String get changePasswordTitle => 'Change Password';

  @override
  String get changePasswordSubtitle =>
      'Update your password to keep your account secure.';

  @override
  String get changePasswordCurrentPassword => 'Current Password';

  @override
  String get changePasswordCurrentPasswordHint => 'Enter your current password';

  @override
  String get changePasswordCurrentPasswordRequired =>
      'Current password is required.';

  @override
  String get changePasswordNewPassword => 'New Password';

  @override
  String get changePasswordNewPasswordHint => 'Enter your new password';

  @override
  String get changePasswordNewPasswordRequired => 'New password is required.';

  @override
  String get changePasswordNewPasswordMinLength =>
      'New password must be at least 6 characters.';

  @override
  String get changePasswordConfirmPassword => 'Confirm New Password';

  @override
  String get changePasswordConfirmPasswordHint => 'Confirm your new password';

  @override
  String get changePasswordConfirmPasswordRequired =>
      'Please confirm your new password.';

  @override
  String get changePasswordConfirmPasswordMismatch => 'Passwords do not match.';

  @override
  String get changePasswordSave => 'Save Changes';

  @override
  String get changePasswordSuccessTitle => 'Password Changed Successfully!';

  @override
  String get changePasswordSuccessSubtitle =>
      'Your password has been updated securely. Please use your new password the next time you sign in.';

  @override
  String get changePasswordBackToSettings => 'Back to Settings';

  @override
  String get changePasswordFailed =>
      'Failed to change password. Please try again.';

  @override
  String get otpTitle => 'OTP';

  @override
  String get otpSubtitle => 'Enter the 6-digit OTP sent to your email';

  @override
  String get otpVerifyButton => 'Verify OTP';

  @override
  String get otpResendButton => 'Resend OTP';

  @override
  String get otpIncomplete => 'Please enter all 6 OTP digits.';

  @override
  String get otpDigitsOnly => 'OTP must contain digits only.';

  @override
  String get otpRequestCodeNotFound => 'OTP request code not found.';

  @override
  String get otpEmailNotFound => 'Email not found for resending OTP.';

  @override
  String get otpInvalid => 'Invalid OTP code.';

  @override
  String get otpVerifySuccess => 'OTP verified successfully!';

  @override
  String get otpResendSuccess => 'OTP has been resent successfully!';

  @override
  String get otpResendFailed => 'Failed to resend OTP.';

  @override
  String get seedContinue => 'Continue';

  @override
  String get seedTitle => 'Seed of Light';

  @override
  String get seedDescription =>
      'This is the beginning of your journey. The Seed of Light absorbs Life Force from your footsteps to grow.';

  @override
  String get seedEvolutionTitle => 'Evolution';

  @override
  String get seedEvolutionDescription =>
      'When the Seed of Light reaches its evolution level, you can choose one of three Spirit affinities as your companion.';

  @override
  String get seedPath1Name => 'Dawn Spirit';

  @override
  String get seedPath1Description => 'Flying Type • Morning Walks';

  @override
  String get seedPath2Name => 'Moonlight Spirit';

  @override
  String get seedPath2Description => 'Night Type • Evening Walks';

  @override
  String get seedPath3Name => 'Sunlight Spirit';

  @override
  String get seedPath3Description => 'Nature Type • Balanced Walking';

  @override
  String get privacyTitle => 'Terms of Service';

  @override
  String get privacySubtitle => 'Agreement with Walkamon';

  @override
  String get privacyIntroTitle => 'INTRODUCTION';

  @override
  String get privacyIntroContent => '...';

  @override
  String get privacyPart1 => 'PART 1';

  @override
  String get privacySection1Title => '1. Registration';

  @override
  String get privacySection1Content => '...';

  @override
  String get privacySection2Title => '2. Naming';

  @override
  String get privacySection2Content => '...';

  @override
  String get privacySection3Title => '3. Data Storage';

  @override
  String get privacySection3Content => '...';

  @override
  String get privacySection4Title => '4. Prohibited Conduct';

  @override
  String get privacySection4Content => '...';

  @override
  String get privacySection5Title => '5. Account Termination';

  @override
  String get privacySection5Content => '...';

  @override
  String get privacyPart2 => 'PART 2';

  @override
  String get privacySection6Title => '1. Content';

  @override
  String get privacySection6Content => '...';

  @override
  String get privacySection7Title => '2. Age Rating';

  @override
  String get privacySection7Content => '...';

  @override
  String get privacySection8Title => '3. Virtual Items';

  @override
  String get privacySection8Content => '...';

  @override
  String get privacySection9Title => '4. Copyright';

  @override
  String get privacySection9Content => '...';

  @override
  String get privacySection10Title => '5. Third-party Websites';

  @override
  String get privacySection10Content => '...';

  @override
  String get privacyContactTitle => 'CONTACT';

  @override
  String get privacyContactContent => '...';

  @override
  String get privacyLastUpdated => 'Last updated: June 25, 2026';

  @override
  String get privacyAgreeButton => 'I Understand & Agree';

  @override
  String get profileTitle => 'Profile';

  @override
  String get loading => 'Loading...';

  @override
  String get traveler => 'Traveler';

  @override
  String get managementStats => 'Management & Stats';

  @override
  String get accountInfo => 'Account information';

  @override
  String get setStepGoal => 'Set step goal';

  @override
  String get streak => 'Daily streak';

  @override
  String get activityStats => 'Activity stats';

  @override
  String get achievements => 'Achievements';

  @override
  String get achievementVault => 'Achievement Vault';

  @override
  String get achievementsLoadFailed => 'Failed to load achievements';

  @override
  String achievementsCollected(int count) {
    return 'Collected $count badges';
  }

  @override
  String get achievementsUnlockedTab => 'Claimed';

  @override
  String get achievementsLockedTab => 'Unclaimed';

  @override
  String achievementClaimSuccess(int amount) {
    return 'Reward claimed: +$amount';
  }

  @override
  String get achievementClaimFailed =>
      'Could not claim the reward. Please try again.';

  @override
  String get achievementsCurrentProgress => 'Current progress';

  @override
  String achievementsLockedDetail(String description, int reward) {
    return '$description.\nReward: $reward Dewdrops';
  }

  @override
  String achievementsUnlockedAt(String date) {
    return 'Unlocked at: $date';
  }

  @override
  String achievementsUnlockedDetail(String description) {
    return '$description. Keep the momentum going to unlock more achievements!';
  }

  @override
  String get achievementsKeepTrying => 'Keep trying';

  @override
  String get achievementsCollection => 'Collection';

  @override
  String get achievementsGoals => 'Goals';

  @override
  String achievementsLockedCount(int count) {
    return '$count badges are waiting to be discovered';
  }

  @override
  String get retry => 'Retry';

  @override
  String get characterNotFound => 'Character information not found.';

  @override
  String get notUpdated => 'Not updated';

  @override
  String get dateOfBirth => 'Date of birth';

  @override
  String get gender => 'Gender';

  @override
  String get joinDate => 'Join date';

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get genderOther => 'Other';

  @override
  String get dailyLoginNoData => 'No daily login data available.';

  @override
  String get dailyLoginTitle => 'Daily Check-in';

  @override
  String get dailyLoginRewardTitle => 'Daily Gift';

  @override
  String get dailyLoginRewardSubtitle =>
      'Log in every day to receive amazing rewards.\nDon’t miss day 7!';

  @override
  String get dailyLoginAlreadyClaimed => 'You already claimed your gift today!';

  @override
  String get dailyLoginSuccessTitle => 'Success!';

  @override
  String dailyLoginSuccessMessage(int day) {
    return 'Congratulations! You have successfully claimed your reward for day $day!';
  }

  @override
  String dailyLoginSuccessReward(int amount) {
    return 'Reward: +$amount Dewdrops';
  }

  @override
  String dailyLoginSuccessBalance(int balance) {
    return 'Current balance: $balance Dewdrops';
  }

  @override
  String get dailyLoginSuccessAction => 'Awesome';

  @override
  String get dailyLoginClaimedToday => 'Claimed Today';

  @override
  String get dailyLoginClaimNow => 'Claim Reward Now';

  @override
  String get dailyLoginNoRewardData => 'No reward data yet';

  @override
  String dayLabel(int day) {
    return 'DAY $day';
  }

  @override
  String rewardCount(int count) {
    return 'x$count';
  }

  @override
  String get errorPrefix => 'Error';

  @override
  String get friendsLoadError => 'Failed to load friends list';

  @override
  String get friendsRemoveTitle => 'Remove friend';

  @override
  String friendsRemoveConfirm(String name) {
    return 'Are you sure you want to remove $name from your friends list?';
  }

  @override
  String get friendsCancel => 'Cancel';

  @override
  String get friendsRemove => 'Remove';

  @override
  String get friendsRequest => 'Requests';

  @override
  String get friendsAdd => 'Add Friend';

  @override
  String get friendsSearchHint => 'Search friends...';

  @override
  String get friendsEmptyTitle => 'No teammates yet!';

  @override
  String get friendsEmptySubtitle =>
      'Tap \'Add Friend\' to start your journey.';

  @override
  String get friendsNoResult => 'No matching friend found.';

  @override
  String friendsRemoveSuccess(String name) {
    return 'You unfriended $name!';
  }

  @override
  String get friendsRemoveFailure =>
      'Failed to remove friend. Please try again!';

  @override
  String get pvpTitle => 'PvP Arena';

  @override
  String get pvpComingSoonTitle => 'PvP mode is under development!';

  @override
  String get pvpComingSoonDescription =>
      'Challenge the strength of Lumina against rivals.';

  @override
  String get inventoryLoadError => 'Could not load inventory.';

  @override
  String get inventoryNoItems => 'No items available.';

  @override
  String get inventoryNoEffect => 'No effect';

  @override
  String inventoryUsed(String name) {
    return 'Used: $name';
  }

  @override
  String inventoryUseFailed(String message) {
    return 'Use failed: $message';
  }

  @override
  String inventoryUseError(String message) {
    return 'Error while using item: $message';
  }

  @override
  String get inventoryCommunity => 'Community';

  @override
  String get inventoryPvp => 'PvP';

  @override
  String get inventoryBag => 'Inventory';

  @override
  String get inventoryStore => 'Shop';

  @override
  String get inventoryHome => 'Home';

  @override
  String get leaderboardTitle => 'Leaderboard';

  @override
  String leaderboardYourRank(int rank) {
    return 'Your rank: #$rank';
  }

  @override
  String get leaderboardToday => 'Today';

  @override
  String get leaderboardThisWeek => 'This week';

  @override
  String get leaderboardThisMonth => 'This month';

  @override
  String get leaderboardSteps => 'Steps';

  @override
  String get leaderboardLevel => 'Level';

  @override
  String get leaderboardYou => 'You';

  @override
  String get leaderboardUserDefault => 'User';

  @override
  String get leaderboardCouldNotLoad => 'Could not load leaderboard';

  @override
  String get leaderboardCouldNotConnect => 'Could not connect to the server';

  @override
  String get missionsDefaultDescription =>
      'Complete the mission to receive a reward.';

  @override
  String get missionsChallengeDescription =>
      'Complete the challenge to receive a reward.';

  @override
  String get missionsLoadError => 'Could not load missions.';

  @override
  String missionsClaimSuccess(int amount) {
    return 'Reward claimed successfully: +$amount';
  }

  @override
  String missionsClaimFailed(String message) {
    return 'Could not claim reward: $message';
  }

  @override
  String get missionsChallengeExists =>
      'You already have a challenge. Please finish or cancel it first!';

  @override
  String get missionsChallengeCanceled => 'Challenge canceled.';

  @override
  String get missionsChallengeCreated => 'New challenge received!';

  @override
  String missionsCancelFailed(String message) {
    return 'Could not cancel challenge: $message';
  }

  @override
  String get missionsDailyTitle => 'Daily missions';

  @override
  String get missionsOverallTitle => 'Overall missions';

  @override
  String get missionsDailyEmpty => 'No daily missions.';

  @override
  String get missionsOverallEmpty => 'No overall missions.';

  @override
  String get missionsRandomChallenge => 'Random Challenge';

  @override
  String missionsCancelRemaining(int remaining, int limit) {
    return 'Cancels left: $remaining/$limit';
  }

  @override
  String get missionsNoActiveChallenge =>
      'There are currently no active challenges.';

  @override
  String get missionsNewChallenge => 'Take a new challenge';

  @override
  String get missionsTitle => 'Missions';

  @override
  String get missionsTabMission => 'Mission';

  @override
  String get missionsTabChallenge => 'Challenge';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsEmpty => 'No notifications yet.';

  @override
  String get notificationsLoadFailed => 'Could not load notifications.';

  @override
  String get streakLoadFailed => 'Could not load your streak.';

  @override
  String get notificationsDeleted => 'Notification deleted';

  @override
  String notificationsDeleteFailed(String message) {
    return 'Delete failed: $message';
  }

  @override
  String get notificationsDetailError =>
      'An error occurred while loading the content.';

  @override
  String notificationsTimeAgoDays(int count) {
    return '$count days ago';
  }

  @override
  String notificationsTimeAgoHours(int count) {
    return '$count hours ago';
  }

  @override
  String notificationsTimeAgoMinutes(int count) {
    return '$count minutes ago';
  }

  @override
  String get notificationsTimeAgoJustNow => 'Just now';

  @override
  String get notificationsTypeDailyReward => 'Daily login reward';

  @override
  String get notificationsTypeDailyStepGoalReminder =>
      'Daily activity reminder';

  @override
  String get notificationsTypeStreakReward => 'Streak reward';

  @override
  String get notificationsTypeMissionComplete => 'Mission complete';

  @override
  String get notificationsTypeAchievementComplete => 'Achievement complete';

  @override
  String get notificationsTypeChallengeInvite => 'Challenge invitation';

  @override
  String get notificationsTypePvpInvite => 'PvP invitation';

  @override
  String get notificationsTypeFriendRequest => 'Friend request';

  @override
  String get notificationsTypeFriendAccepted => 'Friend request accepted';

  @override
  String get notificationsTypeFriendRemoved => 'Friend removed';

  @override
  String get notificationsTypeSpiritHungry => 'Lumina is hungry';

  @override
  String get notificationsTypeSpiritReadyEvolution => 'Ready to evolve';

  @override
  String get notificationsTypeSpiritEnergyFull => 'Energy full';

  @override
  String get notificationsTypeSpiritBondLow => 'Life force low';

  @override
  String get notificationsTypeSpiritLevelUp => 'Level up';

  @override
  String get notificationsTypeItemPurchased => 'Item purchased successfully';

  @override
  String get notificationsTypePvpResult => 'PvP result';

  @override
  String get notificationsTypeMaintenance => 'Maintenance notice';

  @override
  String get notificationsTypePatchNotes => 'Patch notes';

  @override
  String get notificationsTypeNews => 'News';

  @override
  String get notificationsTypeEvent => 'Event';

  @override
  String get notificationsTypeCompensation => 'Compensation reward';

  @override
  String get notificationsTypeServerAnnouncement => 'Server announcement';

  @override
  String get profileEditTitle => 'Edit Profile';

  @override
  String get profileEditDisplayName => 'Display name';

  @override
  String get profileEditDisplayNameHint => 'Enter your name';

  @override
  String get profileEditEmailLabel => 'Email (Cannot be changed)';

  @override
  String get profileEditEmailHint => 'Enter email';

  @override
  String get profileEditGenderLabel => 'Gender';

  @override
  String get profileEditBirthLabel => 'Date of birth';

  @override
  String get profileEditBioLabel => 'Bio';

  @override
  String get profileEditBioHint => 'A little about you...';

  @override
  String get profileEditSaveLoading => 'Saving...';

  @override
  String get profileEditSave => 'Save Changes';

  @override
  String get profileEditSuccessMessage =>
      'Your profile information has been updated successfully!';

  @override
  String get profileEditFailureMessage => 'Update failed. Please check again.';

  @override
  String get profileEditRequiredName => 'Cannot be empty';

  @override
  String get profileEditConfirm => 'Confirm';

  @override
  String get profileEditDefaultName => 'Traveler';

  @override
  String get profileEditDefaultBio => 'Enjoying the Walkamon journey!';

  @override
  String get activityStatsTitle => 'Activity';

  @override
  String get activityStatsStats => 'Statistics';

  @override
  String get activityStatsHistory => 'History';

  @override
  String get activityStatsDaily => 'Day';

  @override
  String get activityStatsWeekly => 'Week';

  @override
  String get activityStatsMonthly => 'Month';

  @override
  String get activityStatsTotalSteps => 'Total steps';

  @override
  String get activityStatsDistance => 'Distance';

  @override
  String get activityStatsNoChartData => 'No chart data yet';

  @override
  String get activityStatsNoHistory => 'No activity history yet';

  @override
  String get activityStatsGoalReached => 'GOAL REACHED';

  @override
  String get activityStatsStepsUnit => 'steps';

  @override
  String get activityStatsStepsPerDay => 'steps/day';

  @override
  String get activityStatsSuffixKm => 'km';

  @override
  String get activityStatsTodayTitle => 'Today\'s activity';

  @override
  String get activityStatsWeekTitle => 'This week\'s activity';

  @override
  String get activityStatsMonthTitle => 'Month activity';

  @override
  String get activityStatsTotal => 'Total';

  @override
  String get activityStatsAverage => 'Average';

  @override
  String activityStatsWeekBucket(int week) {
    return 'Week $week';
  }

  @override
  String get streakTitle => 'Daily Login Streak';

  @override
  String get streakDays => 'days';

  @override
  String get streakEncouragement =>
      'You’re doing great! Keep it up to receive exciting rewards.';

  @override
  String get streakThirtyDays => '30-day streak';

  @override
  String get streakRecord => 'Streak record';

  @override
  String get streakCurrent => 'Current streak';

  @override
  String get shopTitle => 'Shop';

  @override
  String get shopCurrency => 'Dewdrops';

  @override
  String get shopNoItems => 'No shop items available.';

  @override
  String get shopBuy => 'Buy';

  @override
  String shopBuySuccess(String name) {
    return 'Purchased successfully: $name';
  }

  @override
  String shopBuyFailed(String message) {
    return 'Purchase failed: $message';
  }

  @override
  String shopBuyError(String message) {
    return 'Error while buying: $message';
  }

  @override
  String get shopType => 'Type';

  @override
  String get shopPrice => 'Price';

  @override
  String get shopDescription => 'Description';

  @override
  String get socialTitle => 'Community';

  @override
  String get socialFriends => 'Friends';

  @override
  String get socialLeaderboard => 'Leaderboard';

  @override
  String get dailyRewardTitle => 'Daily Check-in';

  @override
  String get dailyRewardSubtitle => 'Daily check-in is being developed!';

  @override
  String get dailyRewardDescription =>
      'Log in every day to receive magical dew drops.';

  @override
  String get namePetTitle => 'Name your Lumina';

  @override
  String get namePetDescription =>
      'Choose a meaningful name for your companion.';

  @override
  String get namePetHint => 'Enter a Lumina name...';

  @override
  String get namePetComplete => 'Complete';

  @override
  String get namePetCreateFailed =>
      'Could not create your starter pet. Please try again.';

  @override
  String get seedTitleScreen => 'Seed of Light';

  @override
  String get seedDescriptionScreen =>
      'This is the beginning of your journey. The Seed of Light absorbs Life Force from your footsteps to grow.';

  @override
  String get storySkip => 'Skip';

  @override
  String get storyBack => 'Back';

  @override
  String get storyContinue => 'Continue';

  @override
  String get storyExplore => 'Explore';

  @override
  String get close => 'Close';

  @override
  String get processing => 'Processing...';

  @override
  String get profileEditFailureTitle => 'Failed';

  @override
  String get missionsClaim => 'CLAIM';

  @override
  String get missionsClaimed => 'CLAIMED';

  @override
  String get inventoryNoDescription => 'No description yet.';

  @override
  String get inventoryUse => 'Use';

  @override
  String friendsListCount(int count) {
    return 'LIST ($count)';
  }

  @override
  String get friendsSearchError => 'Search failed';

  @override
  String get friendsAddNew => 'Add New Friend';

  @override
  String get friendsPlayerNameHint => 'Enter player name...';

  @override
  String friendsSuggestionsCount(int count) {
    return 'FRIEND SUGGESTIONS ($count)';
  }

  @override
  String friendsSearchResultsCount(int count) {
    return 'SEARCH RESULTS ($count)';
  }

  @override
  String get friendsNoAvailablePlayers => 'No available players';

  @override
  String get friendsAddShort => 'Add';

  @override
  String get friendsInbox => 'Friend Mailbox';

  @override
  String get friendsReceivedInvites => 'Received invites';

  @override
  String get friendsSentInvites => 'Sent';

  @override
  String get friendsNoSentInvites => 'You have not sent any invites recently.';

  @override
  String get friendsNoReceivedInvites => 'No friend invites.';

  @override
  String get stepGoalTitle => 'Step goal';

  @override
  String get stepGoalCustomTitle => 'Custom goal';

  @override
  String get stepGoalInputHint => 'Enter steps...';

  @override
  String get stepGoalSuggestions => 'GOAL SUGGESTIONS';

  @override
  String get stepGoalTodayProgress => 'TODAY\'S PROGRESS';

  @override
  String get stepGoalMinError => 'Goal must be greater than 500 steps.';

  @override
  String get stepGoalMaxError => 'Goal cannot exceed 100,000 steps.';

  @override
  String get stepGoalGreaterThanCurrent =>
      'New goal must be greater than the current goal.';

  @override
  String get stepGoalInvalidNumber => 'Enter a valid step count.';

  @override
  String stepGoalSaved(String steps) {
    return 'Saved goal of $steps steps.';
  }

  @override
  String stepGoalClaimSuccess(String amount) {
    return 'Reward claimed successfully: +$amount Dewdrops.';
  }

  @override
  String stepGoalOutOfSteps(String steps) {
    return ' / $steps steps';
  }

  @override
  String stepGoalRemaining(String steps) {
    return '$steps steps left';
  }

  @override
  String get stepGoalNotSet => 'No goal set';

  @override
  String get stepGoalChoosePrompt =>
      'Choose a goal below to start tracking today\'s progress.';

  @override
  String get stepGoalCompletedMessage =>
      'Great job! You completed today\'s goal.';

  @override
  String get stepGoalActiveMessage =>
      'Set a realistic goal and gradually increase it to keep your active streak going.';

  @override
  String get stepGoalStreakTitle => 'Goal streak';

  @override
  String get stepGoalStreakSubtitle =>
      'Complete goals to grow your wallet reward.';

  @override
  String get stepGoalLongest => 'Longest';

  @override
  String get stepGoalClaiming => 'Claiming';

  @override
  String get stepGoalCustomShort => 'Custom';

  @override
  String spiritDetailTitle(String name) {
    return '$name Details';
  }

  @override
  String spiritLevel(int level) {
    return 'Level $level';
  }

  @override
  String get spiritRecoveryPotion => 'Recovery Potion';

  @override
  String spiritBondBonus(int amount) {
    return '+$amount Bonding';
  }

  @override
  String spiritEnergyBonus(int amount) {
    return '+$amount Energy';
  }

  @override
  String get spiritPlantType => 'Plant Type';

  @override
  String get spiritStatsTab => 'Stats';

  @override
  String get spiritEvolutionTab => 'Evolution';

  @override
  String get spiritLifeForceExp => 'Life Force (EXP)';

  @override
  String get spiritSupportItems => 'Support Items';

  @override
  String get spiritTapLumina => 'Tap Lumina';

  @override
  String get spiritTapSuccess => 'Tapped Lumina successfully';

  @override
  String get spiritFeed => 'Feed';

  @override
  String get spiritFeedSuccess => 'Fed Lumina successfully';

  @override
  String get spiritEvolutionStages => 'Evolution Stages';

  @override
  String get spiritStageSeed => 'Seed';

  @override
  String get spiritStageSprout => 'Sprout';

  @override
  String get spiritStageLeaf => 'Leaf';

  @override
  String spiritCurrentRequirement(int level, int bonding) {
    return 'Current requirements: Lv $level - Bond $bonding';
  }

  @override
  String spiritCurrentStage(String stage, int level) {
    return 'Current stage: $stage • Lv $level';
  }

  @override
  String get spiritHistoryNoEvolution => 'No evolution history yet.';

  @override
  String spiritHistoryDateLevel(String date, int level) {
    return '$date • Lv $level';
  }

  @override
  String spiritHistoryLevel(int level) {
    return 'Lv $level';
  }

  @override
  String spiritConditionTargetLevel(int level) {
    return 'Reach Lv $level';
  }

  @override
  String get spiritEvolutionPreview => 'Evolution Preview';

  @override
  String get spiritChooseEvolutionBranch => 'Choose evolution branch';

  @override
  String spiritRequiredLevel(int level) {
    return 'Required level: $level';
  }

  @override
  String get spiritReady => 'Ready';

  @override
  String get spiritEvolutionHistory => 'Evolution History';

  @override
  String get spiritHistoryHatched => 'Hatched successfully';

  @override
  String get spiritHistorySprout => 'Evolved into Sprout Form';

  @override
  String get spiritHistoryLeaf => 'Evolved into Leaf Form';

  @override
  String get spiritEvolutionConditions => 'Evolution Conditions';

  @override
  String get spiritReachLevel15 => 'Reach Level 15';

  @override
  String get spiritBondRequirement => 'Bonding requirement met';

  @override
  String get spiritMet => 'Met';

  @override
  String get spiritEvolveNow => 'Evolve Now';

  @override
  String get spiritMaxEvolution =>
      'Lumina has reached the current maximum evolution form!';

  @override
  String get spiritEvolving => 'Evolving...';

  @override
  String get storySlide1 =>
      'You discover an old space exploration device. Inside is a Seed of Light...';

  @override
  String get storySlide2 =>
      '...a small Lumina from a planet that lost its gravity.';

  @override
  String get storySlide3 =>
      'To survive and grow, Lumina absorbs Life Force from human footsteps.';

  @override
  String get storySlide4 =>
      'Lumina does not need you to fight. It only wants to walk beside you and see the real world.';

  @override
  String get profileEditGenderMale => 'Male';

  @override
  String get profileEditGenderFemale => 'Female';

  @override
  String get profileEditGenderOther => 'Other';

  @override
  String friendsRequestSentTo(String name) {
    return 'Sent an invite to $name!';
  }

  @override
  String get friendsRequestSendFailed =>
      'Could not send the invite. Please try again later.';

  @override
  String get friendsRequestAlreadySent =>
      'You already sent this player an invite!';

  @override
  String get friendsRequestCanceled => 'Friend invite withdrawn.';

  @override
  String get friendsRequestCancelFailed =>
      'Could not withdraw the invite. Please try again.';

  @override
  String get friendsRequestAccepted => 'Friend invite accepted!';

  @override
  String get friendsRequestDeclined => 'Friend invite declined.';

  @override
  String get friendsRequestActionFailed =>
      'That action could not be completed. Please try again.';

  @override
  String get friendsAlreadyFriend => 'You are already friends!';

  @override
  String get friendsPlayerNotFound => 'Could not find this player.';

  @override
  String get friendProfileTitle => 'Traveler Profile';

  @override
  String get friendProfileTraveler => 'Traveler';

  @override
  String get friendProfileUnknownPlayer => 'Unknown player';

  @override
  String get friendProfileCompanion => 'Companion Spirit';

  @override
  String get friendProfileStats => 'Stats';

  @override
  String get friendProfileAchievements => 'Featured Achievements';

  @override
  String friendProfileSpiritName(String name) {
    return 'Spirit: $name';
  }

  @override
  String get friendProfileViewStats => 'View Stats';

  @override
  String friendProfileSpiritMeta(String type, int level) {
    return '$type - Level $level';
  }

  @override
  String get friendProfileNoSpirit => 'No spirit yet';

  @override
  String get friendProfileSpiritTypeUnknown => 'Unknown Type';

  @override
  String get friendProfileTotalSteps => 'Total steps';

  @override
  String get friendProfileStreak => 'Streak';

  @override
  String get friendProfileEnergy => 'Energy';

  @override
  String get friendProfileBond => 'Bond';

  @override
  String get friendProfileLifeForce => 'Life Force';

  @override
  String get friendProfileExp => 'EXP';

  @override
  String get friendProfileUnavailable => '--';

  @override
  String get friendProfileAchievementsUnavailable =>
      'Achievements data is not available yet.';

  @override
  String get friendProfileLoadFailed => 'Could not load this player profile.';

  @override
  String get friendProfileRequestSentTitle => 'Invite sent!';

  @override
  String friendProfileRequestSentMessage(String name) {
    return 'Your friend invite has been sent to $name. Keep walking together!';
  }

  @override
  String get friendProfileGreat => 'Great';

  @override
  String get friendSpiritTitle => 'Spirit Stats';

  @override
  String get feedbackWaitBeforeRetry => 'Please wait before sending again.';

  @override
  String get feedbackSendFailed =>
      'Failed to send feedback. Please try again later.';

  @override
  String get friendSpiritNoData => 'No friend spirit data.';

  @override
  String friendSpiritOfName(String userName) {
    return '$userName\'s Spirit';
  }

  @override
  String friendSpiritLevel(int level) {
    return 'Level $level';
  }

  @override
  String get friendSpiritStatsTitle => 'Stats';

  @override
  String get friendSpiritEvolutionTitle => 'Evolution';

  @override
  String get friendSpiritExp => 'Experience (EXP)';

  @override
  String get friendSpiritLifeForce => 'Life Force (Life Force)';

  @override
  String get friendSpiritBonding => 'Bonding (Bond)';

  @override
  String get friendSpiritEnergy => 'Energy (Energy)';

  @override
  String get friendSpiritCurrentStage => 'CURRENT STAGE';

  @override
  String get friendSpiritCurrentProperty => 'Current energy attribute recorded';

  @override
  String get friendSpiritEvolutionStages => 'EVOLUTION STAGES';

  @override
  String get friendSpiritMilestones => 'MILESTONES HISTORY';

  @override
  String friendSpiritReachLevel(int level) {
    return 'Reach Level $level';
  }

  @override
  String get friendSpiritRecently => 'Recently';

  @override
  String get friendSpiritBeginJourney => 'Started Walkamon Journey';

  @override
  String get friendSpiritInit => 'Initialized';

  @override
  String get friendSpiritStageSeedling => 'Seedling';

  @override
  String get friendSpiritStageSprout => 'Sprout';

  @override
  String get friendSpiritStageLeaf => 'Leaf';

  @override
  String get pvpInvites => 'Invites';

  @override
  String get pvpHistory => 'History';

  @override
  String get pvpTodayStepsLabel => 'Today\'s steps:';

  @override
  String get pvpSpiritAffinityLabel => 'Spirit affinity:';

  @override
  String get pvpEnergyLabel => 'Energy:';

  @override
  String get pvpBondLabel => 'Bond:';

  @override
  String pvpEnergyRequired(int amount) {
    return 'PvP requires at least $amount energy.';
  }

  @override
  String get petDataLoadError =>
      'Unable to load the latest spirit stats. Please try again.';

  @override
  String get pvpSearchingOpponent => 'Searching for an opponent...';

  @override
  String get pvpCancelSearch => 'Cancel search';

  @override
  String get pvpConnecting => 'Connecting...';

  @override
  String get pvpPreparing => 'Preparing...';

  @override
  String get pvpFindRandomMatch => 'Find random match';

  @override
  String get pvpChallengeFriend => 'Challenge a friend';

  @override
  String get pvpAffinityWarmSun => 'Warm Sun';

  @override
  String get pvpAffinityDawn => 'Dawn';

  @override
  String get pvpAffinityMoonlight => 'Moonlight';

  @override
  String get pvpAffinitySprout => 'Sprout';

  @override
  String get pvpAffinityUnknown => 'Unknown affinity';

  @override
  String get pvpExitMatchTitle => 'Leave match?';

  @override
  String get pvpExitMatchMessage =>
      'Leaving now will count as a DEFEAT and your opponent will win.';

  @override
  String get pvpStayInMatch => 'Stay';

  @override
  String get pvpExitAndForfeit => 'Leave & forfeit';

  @override
  String get pvpNoticeTitle => 'Notice';

  @override
  String get pvpInviteDeclined => 'The player declined your invitation.';

  @override
  String get pvpChallengeInvitesTitle => 'Challenge invites';

  @override
  String get pvpNoInvitations => 'No invitations';

  @override
  String get pvpStatusOffline => 'Offline';

  @override
  String get pvpStatusBusy => 'Busy';

  @override
  String get pvpStatusOnline => 'Online';

  @override
  String get pvpOpponent => 'Opponent';

  @override
  String get pvpSenderInAnotherMatch => 'The sender is in another match';

  @override
  String get pvpSenderOffline => 'The sender has gone offline';

  @override
  String get pvpAccept => 'Accept';

  @override
  String get pvpReject => 'Reject';

  @override
  String get pvpMatchTypeRanked => 'Ranked';

  @override
  String get pvpMatchTypeFriendly => 'Friendly';

  @override
  String get pvpMatchTypeEvent => 'Event';

  @override
  String get pvpMatchTypeOther => 'Other';

  @override
  String get pvpMatchSourceBot => 'Bot';

  @override
  String get pvpMatchSourceMatchmaking => 'Matchmaking';

  @override
  String get pvpMatchSourceInvite => 'Invite';

  @override
  String get pvpMatchSourceOther => 'Other source';

  @override
  String get pvpMatchHistoryTitle => 'Match history';

  @override
  String get pvpRefresh => 'Refresh';

  @override
  String get pvpFilterAll => 'All';

  @override
  String get pvpFilterAllResults => 'All results';

  @override
  String get pvpFilterWins => 'Wins';

  @override
  String get pvpFilterLosses => 'Losses';

  @override
  String get pvpNoMatches => 'No matches yet';

  @override
  String get pvpHistoryVictory => 'VICTORY';

  @override
  String get pvpHistoryCancelled => 'CANCELLED';

  @override
  String get pvpHistoryDefeat => 'DEFEAT';

  @override
  String get pvpHistoryDraw => 'DRAW';

  @override
  String get pvpHistoryResultUnknown => 'UNKNOWN';

  @override
  String get pvpPreviousPage => 'Previous page';

  @override
  String pvpPageOf(int page, int totalPages) {
    return 'Page $page / $totalPages';
  }

  @override
  String get pvpNextPage => 'Next page';

  @override
  String get pvpChallengeFriendsTitle => 'Challenge Friends';

  @override
  String get pvpOnlineSection => 'ONLINE';

  @override
  String get pvpNoOnlineFriends => 'No friends are online';

  @override
  String get pvpOfflineSection => 'OFFLINE';

  @override
  String get pvpNoOfflineFriends => 'No offline friends';

  @override
  String get pvpFriendBusy => 'Friend is busy';

  @override
  String get pvpChallengeAction => 'Challenge';

  @override
  String get pvpInviteSent => 'Invitation sent!';

  @override
  String pvpWaitingForFriend(String opponentName) {
    return 'Waiting for $opponentName to respond...';
  }

  @override
  String get pvpCancelRequest => 'Cancel request';

  @override
  String get pvpConnected => 'Connected!';

  @override
  String pvpRaceAgainst(String opponentName) {
    return 'You will race against $opponentName';
  }

  @override
  String get pvpPrepareForMatch => 'GET READY';

  @override
  String get pvpMatchSuccess => 'Match found!';

  @override
  String get pvpEnteringRace =>
      'Entering the race. The countdown will begin as soon as the match is ready.';

  @override
  String get pvpResultVictoryTitle => 'Victory!';

  @override
  String get pvpResultDrawTitle => 'Draw!';

  @override
  String get pvpResultDefeatTitle => 'Defeat';

  @override
  String get pvpResultTitle => 'Match result';

  @override
  String get pvpResultWinGeneric => 'You won the sprint!';

  @override
  String pvpResultBeatOpponent(String opponentName) {
    return 'You defeated $opponentName';
  }

  @override
  String get pvpResultScoresTied => 'Both sides finished with the same score';

  @override
  String get pvpResultForfeitGeneric => 'You left the match and forfeited.';

  @override
  String pvpResultForfeitOpponentWon(String opponentName) {
    return 'You left the match. $opponentName won.';
  }

  @override
  String get pvpResultTryAgain => 'Keep going—you\'ve almost got it!';

  @override
  String get pvpResultLoadingServer => 'Loading the result from the server...';

  @override
  String get pvpLoadingResult => 'Loading result...';

  @override
  String get pvpWaitingServerFinalize =>
      'Waiting for the server to finalize the match...';

  @override
  String get pvpResultUnavailableTitle => 'Match result unavailable';

  @override
  String get pvpResultUnavailableMessage =>
      'The match has ended. Try again later or continue.';

  @override
  String get pvpMmr => 'MMR';

  @override
  String get pvpCurrentMmr => 'Current MMR';

  @override
  String get pvpNewRank => 'New rank';

  @override
  String get pvpRank => 'Rank';

  @override
  String get pvpRewardClaimed => 'Reward claimed';

  @override
  String get pvpRewardsReceived => 'REWARDS RECEIVED';

  @override
  String pvpCoinReward(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+$count Dewdrops',
      one: '+1 Dewdrop',
    );
    return '$_temp0';
  }

  @override
  String pvpItemReward(int quantity) {
    String _temp0 = intl.Intl.pluralLogic(
      quantity,
      locale: localeName,
      other: 'x$quantity items',
      one: 'x1 item',
    );
    return '$_temp0';
  }

  @override
  String get pvpClaimReward => 'Claim reward';

  @override
  String get pvpContinue => 'Continue';

  @override
  String get pvpYou => 'You';

  @override
  String get pvpSprintMode => 'SPRINT';

  @override
  String pvpRaceProgress(int percent) {
    return 'Race progress: $percent%';
  }

  @override
  String pvpRaceTimeRemaining(int seconds) {
    return '${seconds}s left';
  }

  @override
  String get pvpRaceSegmentStart => 'Start';

  @override
  String get pvpRaceSegmentTrail => 'Forest trail';

  @override
  String get pvpRaceSegmentFinish => 'Finish';

  @override
  String get pvpRaceGo => 'GO!';

  @override
  String get pvpCloseRace => 'Leave race';

  @override
  String get pvpItemOnlyDuringRace =>
      'Items can only be used while the race is running';

  @override
  String get pvpItemSlotUnavailable => 'This item slot is no longer available';

  @override
  String get pvpItemUseFailed => 'Unable to use this item';

  @override
  String get pvpItemBlocked => 'The shield blocked the effect';

  @override
  String get pvpItemCleansed => 'Negative effects were cleansed';

  @override
  String get pvpItemUsed => 'Item used';

  @override
  String get pvpMatchStatusWaiting => 'Waiting';

  @override
  String get pvpMatchStatusCountdown => 'Countdown';

  @override
  String get pvpMatchStatusRunning => 'Running';

  @override
  String get pvpMatchStatusSettling => 'Finalizing';

  @override
  String get pvpMatchStatusFinished => 'Finished';

  @override
  String get pvpMatchStatusCancelled => 'Cancelled';

  @override
  String get pvpTierMamDong => 'Bronze Sprout';

  @override
  String get pvpTierLaBac => 'Silver Leaf';

  @override
  String get pvpTierNuVang => 'Golden Bud';

  @override
  String get pvpTierHoaLam => 'Indigo Flower';

  @override
  String get pvpTierTrangTim => 'Purple Moon';

  @override
  String get pvpTierTinhLinhCauVong => 'Rainbow Spirit';

  @override
  String get pvpTierUnknown => 'Unknown rank';

  @override
  String get tutorialSettingsTitle => 'Guides';

  @override
  String get tutorialReplayHome => 'Replay Home guide';

  @override
  String get tutorialReplayPvp => 'Replay PvP guide';

  @override
  String get tutorialReplayStarted => 'The guide is ready to replay.';

  @override
  String get tutorialSkip => 'Skip guide';

  @override
  String get tutorialNext => 'Next';

  @override
  String get tutorialGotIt => 'Got it';

  @override
  String tutorialStepLabel(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get tutorialHomePetTitle => 'Say hello';

  @override
  String get tutorialHomePetBody =>
      'Tap your Lumina to greet it and build your bond.';

  @override
  String get tutorialHomeFeedTitle => 'Care for your Lumina';

  @override
  String get tutorialHomeFeedBody =>
      'Tap the Dew Drop to try feeding. Even when your pet is full, the game will explain why.';

  @override
  String get tutorialHomeStatsTitle => 'Read its needs';

  @override
  String get tutorialHomeStatsBody =>
      'Energy powers activities, Life Force shows wellbeing, and Bond grows as you care for your Lumina.';

  @override
  String get tutorialHomeStepsTitle => 'Your real steps matter';

  @override
  String get tutorialHomeStepsBody =>
      'Open Steps to see today\'s progress and fix activity permission when needed.';

  @override
  String get tutorialHomeMissionsTitle => 'A gentle next goal';

  @override
  String get tutorialHomeMissionsBody =>
      'Open Missions to find small daily goals and rewards.';

  @override
  String get tutorialPvpLobbyTitle => 'Before the race';

  @override
  String get tutorialPvpLobbyBody =>
      'Check your pet, Energy and Bond here. A race costs Energy; Friendly races do not grant ranked rewards.';

  @override
  String get tutorialPvpMatchTitle => 'Choose an opponent';

  @override
  String get tutorialPvpMatchBody =>
      'Use random matchmaking or challenge a friend. You can cancel safely while searching.';

  @override
  String get tutorialPvpRaceTitle => 'A 30-second journey';

  @override
  String get tutorialPvpRaceBody =>
      'Your pet runs automatically. The route and live progress show how close both racers are to the finish.';

  @override
  String get tutorialPvpItemsTitle => 'Optional race items';

  @override
  String get tutorialPvpItemsBody =>
      'Items are optional. Tap an available slot for an effect; an empty loadout never blocks the race.';

  @override
  String get tutorialPvpItemsEmptyBody =>
      'Your loadout is empty. That is okay—your pet still races normally and no item is required.';

  @override
  String get tutorialPvpFinishTitle => 'The finish moment';

  @override
  String get tutorialPvpFinishBody =>
      'After crossing the line, your pet stops and reacts to winning or losing before the result card appears.';

  @override
  String get tutorialPvpResultTitle => 'The finish tells the story';

  @override
  String get tutorialPvpResultBody =>
      'After the finish reaction, compare the final scores. Ranked rewards appear only when the server grants them.';

  @override
  String get pvpRaceCountdownReady => 'Ready';

  @override
  String get pvpRaceCountdownSet => 'Set';

  @override
  String get pvpRaceCountdownGo => 'Go!';

  @override
  String get pvpLoadoutTitle => 'Race items';

  @override
  String get pvpLoadoutSubtitle => 'Choose up to two items for your next race';

  @override
  String pvpLoadoutSummary(int equipped, int limit) {
    return 'Items $equipped/$limit';
  }

  @override
  String pvpLoadoutSlot(int slot) {
    return 'Slot $slot';
  }

  @override
  String get pvpLoadoutEmptySlot => 'Tap an item to equip';

  @override
  String get pvpLoadoutChooseReplacement =>
      'Choose the slot you want to replace';

  @override
  String get pvpLoadoutAvailableTitle => 'Available items';

  @override
  String pvpLoadoutQuantity(int quantity) {
    return 'Owned: $quantity';
  }

  @override
  String get pvpLoadoutSave => 'Save loadout';

  @override
  String get pvpLoadoutSaved => 'Loadout saved';

  @override
  String get pvpLoadoutDiscardTitle => 'Discard changes?';

  @override
  String get pvpLoadoutDiscardBody => 'Your item choices have not been saved.';

  @override
  String get pvpLoadoutDiscard => 'Discard';

  @override
  String get pvpLoadoutKeepEditing => 'Keep editing';

  @override
  String get pvpLoadoutNoItems => 'You do not own a PvP item yet.';

  @override
  String get pvpLoadoutGoToShop => 'Visit shop';

  @override
  String get pvpLoadoutLocked => 'Loadout is locked after matchmaking starts';

  @override
  String get pvpItemHasteName => 'Haste Nectar';

  @override
  String get pvpItemHasteDescription =>
      'Boosts your Lumina\'s speed for a short time.';

  @override
  String get pvpItemSlowName => 'Slow Mist';

  @override
  String get pvpItemSlowDescription => 'Slows the opponent for a short time.';

  @override
  String get pvpItemCleanseName => 'Cleansing Dew';

  @override
  String get pvpItemCleanseDescription =>
      'Removes negative speed effects from your Lumina.';

  @override
  String get pvpItemShieldName => 'Shield Acorn';

  @override
  String get pvpItemShieldDescription => 'Blocks the next harmful item effect.';

  @override
  String get pvpItemTargetSelf => 'Target: you';

  @override
  String get pvpItemTargetOpponent => 'Target: opponent';

  @override
  String pvpItemDurationSeconds(num seconds) {
    return 'Duration: ${seconds}s';
  }

  @override
  String get apiErrorBadRequest =>
      'Please check the information and try again.';

  @override
  String get apiErrorUnauthorized =>
      'Your session has expired. Please sign in again.';

  @override
  String get apiErrorForbidden => 'You do not have permission to do that.';

  @override
  String get apiErrorNotFound => 'The requested content could not be found.';

  @override
  String get apiErrorConflict => 'The data changed. Refresh and try again.';

  @override
  String get apiErrorTooManyRequests =>
      'Too many requests. Please wait a moment.';

  @override
  String get apiErrorInternal =>
      'The server is having trouble. Please try again later.';

  @override
  String get apiErrorNetworkUnavailable =>
      'No network connection. Check your connection and try again.';

  @override
  String get apiErrorRequestTimeout =>
      'The request took too long. Please try again.';

  @override
  String get apiErrorUnexpectedResponse =>
      'Something went wrong. Please try again.';

  @override
  String get apiErrorValidationFailed =>
      'Some information is invalid. Please check it again.';

  @override
  String get apiErrorAccountNotActive => 'This account has not been activated.';

  @override
  String get apiErrorPvpInvalidSlot => 'Only two PvP item slots are available.';

  @override
  String get apiErrorPvpDuplicateItem =>
      'Each PvP item can only occupy one slot.';

  @override
  String get apiErrorPvpInvalidItem => 'This item cannot be used in PvP.';

  @override
  String get apiErrorPvpItemNotOwned => 'You no longer own this item.';

  @override
  String get apiErrorPvpLoadoutLocked =>
      'You cannot change items after matchmaking starts.';

  @override
  String get apiErrorPvpActionInvalid =>
      'That PvP item action is invalid. Please try again.';

  @override
  String get apiErrorPvpMatchNotFound =>
      'This PvP match is no longer available.';

  @override
  String get apiErrorPvpNotParticipant =>
      'You are not a participant in this PvP match.';

  @override
  String get apiErrorPvpMatchNotRunning =>
      'Items can only be used while the race is running.';

  @override
  String get apiErrorPvpSlotNotFound =>
      'This item slot is not available in the current race.';

  @override
  String get apiErrorPvpItemAlreadyUsed => 'This item has already been used.';

  @override
  String get apiErrorPvpItemUnavailable =>
      'This item is no longer in your inventory.';

  @override
  String get apiErrorPvpEffectConflict =>
      'That effect cannot be applied right now.';

  @override
  String get apiErrorPvpBotUnavailable =>
      'No suitable opponent is available right now.';

  @override
  String apiErrorPvpInsufficientEnergy(int requiredEnergy) {
    return 'At least $requiredEnergy energy is required to play PvP.';
  }

  @override
  String get apiErrorPvpReadyTimeout =>
      'The match was cancelled because a player was not ready in time.';

  @override
  String get apiErrorPvpMatchmakingFailed =>
      'Matchmaking could not start. Please try again.';

  @override
  String get apiErrorAuthEmailExists => 'This email is already registered.';

  @override
  String get apiErrorAuthUsernameExists => 'This username is already in use.';

  @override
  String get apiErrorAuthIdentityExists =>
      'This email or username is already registered.';

  @override
  String get apiErrorAuthOtpRequestInvalid =>
      'This OTP request is no longer valid.';

  @override
  String get apiErrorAuthOtpExpired =>
      'This OTP has expired. Request a new one.';

  @override
  String get apiErrorAuthOtpInvalid => 'The OTP is incorrect.';

  @override
  String get apiErrorAuthResetInvalid =>
      'This password reset request has expired.';

  @override
  String get apiErrorAuthAccountLocked => 'This account is locked.';

  @override
  String get apiErrorAuthCurrentPassword =>
      'The current password is incorrect.';

  @override
  String get apiErrorAuthGoogleInvalid =>
      'Google sign-in could not be verified.';

  @override
  String get apiErrorAuthGoogleUnverified =>
      'The Google email has not been verified.';

  @override
  String get apiErrorUserNotFound => 'This player could not be found.';

  @override
  String get apiErrorProfileNotFound =>
      'This player profile could not be found.';

  @override
  String get apiErrorPetNotFound => 'Your Lumina could not be found.';

  @override
  String get apiErrorPetAlreadyExists => 'You already have a Lumina.';

  @override
  String get apiErrorPetBondFull => 'Your Lumina\'s Bond is already full.';

  @override
  String get apiErrorPetTapLimit => 'You have reached today\'s greeting limit.';

  @override
  String get apiErrorPetLifeForceFull =>
      'Your Lumina\'s Life Force is already full.';

  @override
  String get apiErrorPetFeedLimit => 'You have reached today\'s feeding limit.';

  @override
  String get apiErrorPetFinalStage =>
      'Your Lumina is already at its final stage.';

  @override
  String get apiErrorMissionNotFound => 'This mission is no longer available.';

  @override
  String get apiErrorMissionNotCompleted =>
      'Complete the mission before claiming its reward.';

  @override
  String get apiErrorMissionCancelled => 'This mission has been cancelled.';

  @override
  String get apiErrorAchievementNotFound =>
      'This achievement is no longer available.';

  @override
  String get apiErrorAchievementNotCompleted =>
      'This achievement has not been completed yet.';

  @override
  String get apiErrorRewardAlreadyClaimed =>
      'This reward has already been claimed.';

  @override
  String get apiErrorShopQuantity => 'Choose a valid purchase quantity.';

  @override
  String get apiErrorWalletBalance => 'You do not have enough Dewdrops.';

  @override
  String get apiErrorItemNotFound => 'This item is no longer available.';

  @override
  String get apiErrorFriendSelf =>
      'You cannot send a friend request to yourself.';

  @override
  String get apiErrorNotificationNotFound =>
      'This notification is no longer available.';

  @override
  String apiErrorFeedbackCooldown(int hours) {
    return 'You can send feedback once every $hours hours.';
  }
}
