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
  String get fps60 => '60 FPS mode';

  @override
  String get fps60Hint => 'Smoother, uses more battery';

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
      'The Seed will evolve into different Lumina forms based on your walking habits.';

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
}
