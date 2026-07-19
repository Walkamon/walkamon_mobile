import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Walkamon'**
  String get appTitle;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @notificationsRemind.
  ///
  /// In en, this message translates to:
  /// **'Reminder notifications'**
  String get notificationsRemind;

  /// No description provided for @notificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get reminders for feeding and walking your pet'**
  String get notificationsSubtitle;

  /// No description provided for @featuresSupport.
  ///
  /// In en, this message translates to:
  /// **'Features & Support'**
  String get featuresSupport;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageVi.
  ///
  /// In en, this message translates to:
  /// **'Vietnamese'**
  String get languageVi;

  /// No description provided for @languageEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEn;

  /// No description provided for @sendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send feedback & report bugs'**
  String get sendFeedback;

  /// No description provided for @accountSecurity.
  ///
  /// In en, this message translates to:
  /// **'Account & Security'**
  String get accountSecurity;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @feedbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get feedbackTitle;

  /// No description provided for @feedbackSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Suggestion'**
  String get feedbackSuggestion;

  /// No description provided for @feedbackBug.
  ///
  /// In en, this message translates to:
  /// **'Bug report'**
  String get feedbackBug;

  /// No description provided for @feedbackDetail.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get feedbackDetail;

  /// No description provided for @feedbackHintSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Do you have any new ideas for the game?'**
  String get feedbackHintSuggestion;

  /// No description provided for @feedbackHintBug.
  ///
  /// In en, this message translates to:
  /// **'What issue did you encounter while playing?'**
  String get feedbackHintBug;

  /// No description provided for @feedbackSending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get feedbackSending;

  /// No description provided for @feedbackSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get feedbackSubmit;

  /// No description provided for @feedbackSuccess.
  ///
  /// In en, this message translates to:
  /// **'Feedback sent successfully'**
  String get feedbackSuccess;

  /// No description provided for @feedbackMinLength.
  ///
  /// In en, this message translates to:
  /// **'Description must be at least 20 characters. ({count}/20)'**
  String feedbackMinLength(int count);

  /// No description provided for @gameSettings.
  ///
  /// In en, this message translates to:
  /// **'Game Settings'**
  String get gameSettings;

  /// No description provided for @bgm.
  ///
  /// In en, this message translates to:
  /// **'Background music (BGM)'**
  String get bgm;

  /// No description provided for @sfx.
  ///
  /// In en, this message translates to:
  /// **'Sound effects (SFX)'**
  String get sfx;

  /// No description provided for @fps60.
  ///
  /// In en, this message translates to:
  /// **'60 FPS mode'**
  String get fps60;

  /// No description provided for @fps60Hint.
  ///
  /// In en, this message translates to:
  /// **'Smoother, uses more battery'**
  String get fps60Hint;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkMode;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navShop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get navShop;

  /// No description provided for @navBag.
  ///
  /// In en, this message translates to:
  /// **'Bag'**
  String get navBag;

  /// No description provided for @navQuest.
  ///
  /// In en, this message translates to:
  /// **'Quest'**
  String get navQuest;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @welcomeTagline.
  ///
  /// In en, this message translates to:
  /// **'Walk & Grow Together'**
  String get welcomeTagline;

  /// No description provided for @welcomeExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore Now'**
  String get welcomeExplore;

  /// No description provided for @welcomeLogin.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get welcomeLogin;

  /// No description provided for @welcomeRegister.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get welcomeRegister;

  /// No description provided for @welcomeOr.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get welcomeOr;

  /// No description provided for @welcomeGoogleLogin.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get welcomeGoogleLogin;

  /// No description provided for @googleLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign in failed'**
  String get googleLoginFailed;

  /// No description provided for @healthWarning.
  ///
  /// In en, this message translates to:
  /// **'Playing for more than 180 minutes a day may harm your health'**
  String get healthWarning;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @todayStepsDesc.
  ///
  /// In en, this message translates to:
  /// **'Steps you\'ve walked today'**
  String get todayStepsDesc;

  /// No description provided for @step.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get step;

  /// No description provided for @luminaStatus.
  ///
  /// In en, this message translates to:
  /// **'LUMINA STATUS'**
  String get luminaStatus;

  /// No description provided for @energy.
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get energy;

  /// No description provided for @lifeForce.
  ///
  /// In en, this message translates to:
  /// **'Life Force'**
  String get lifeForce;

  /// No description provided for @bonding.
  ///
  /// In en, this message translates to:
  /// **'Bonding'**
  String get bonding;

  /// No description provided for @levelShort.
  ///
  /// In en, this message translates to:
  /// **'Lv. {level}'**
  String levelShort(int level);

  /// No description provided for @expProgress.
  ///
  /// In en, this message translates to:
  /// **'EXP {current}/{max}'**
  String expProgress(int current, int max);

  /// No description provided for @homeNavCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get homeNavCommunity;

  /// No description provided for @homeNavPvp.
  ///
  /// In en, this message translates to:
  /// **'PvP'**
  String get homeNavPvp;

  /// No description provided for @homeNavInventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get homeNavInventory;

  /// No description provided for @homeNavStore.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get homeNavStore;

  /// No description provided for @loginBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get loginBack;

  /// No description provided for @loginTagline.
  ///
  /// In en, this message translates to:
  /// **'Every step, a little magic'**
  String get loginTagline;

  /// No description provided for @loginWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back!'**
  String get loginWelcomeBack;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Continue your journey with your Lumina spirit.'**
  String get loginSubtitle;

  /// No description provided for @loginEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required.'**
  String get loginEmailRequired;

  /// No description provided for @loginEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid email format.'**
  String get loginEmailInvalid;

  /// No description provided for @loginPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required.'**
  String get loginPasswordRequired;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed.'**
  String get loginFailed;

  /// No description provided for @loginEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get loginEmail;

  /// No description provided for @loginPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPassword;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Lost password?'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your registered email and we will send an OTP to reset your password.'**
  String get forgotPasswordSubtitle;

  /// No description provided for @forgotPasswordResetSent.
  ///
  /// In en, this message translates to:
  /// **'If the email exists, a password reset OTP has been sent.'**
  String get forgotPasswordResetSent;

  /// No description provided for @forgotPasswordRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to send password reset request.'**
  String get forgotPasswordRequestFailed;

  /// No description provided for @forgotPasswordSendSignal.
  ///
  /// In en, this message translates to:
  /// **'Send signal'**
  String get forgotPasswordSendSignal;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get loginButton;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccount;

  /// No description provided for @registerNow.
  ///
  /// In en, this message translates to:
  /// **'Sign up now'**
  String get registerNow;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Plant your first seed'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign the pact and begin your own magical journey'**
  String get registerSubtitle;

  /// No description provided for @registerNameHint.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get registerNameHint;

  /// No description provided for @registerPasswordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least 6 characters.'**
  String get registerPasswordMinLength;

  /// No description provided for @registerConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get registerConfirmPassword;

  /// No description provided for @registerNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required.'**
  String get registerNameRequired;

  /// No description provided for @registerNameMinLength.
  ///
  /// In en, this message translates to:
  /// **'Name must contain at least 2 characters.'**
  String get registerNameMinLength;

  /// No description provided for @registerConfirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password.'**
  String get registerConfirmPasswordRequired;

  /// No description provided for @registerPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Password confirmation does not match.'**
  String get registerPasswordMismatch;

  /// No description provided for @registerFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed. Please try again.'**
  String get registerFailed;

  /// No description provided for @registerAgreeTerms.
  ///
  /// In en, this message translates to:
  /// **'I have read and agree to '**
  String get registerAgreeTerms;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy and terms of use'**
  String get privacyPolicy;

  /// No description provided for @registerButton.
  ///
  /// In en, this message translates to:
  /// **'Start the pact'**
  String get registerButton;

  /// No description provided for @registerAlreadyAccount.
  ///
  /// In en, this message translates to:
  /// **'Already signed the pact?'**
  String get registerAlreadyAccount;

  /// No description provided for @registerLoginHere.
  ///
  /// In en, this message translates to:
  /// **'Log in here'**
  String get registerLoginHere;

  /// No description provided for @changePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePasswordTitle;

  /// No description provided for @changePasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your password to keep your account secure.'**
  String get changePasswordSubtitle;

  /// No description provided for @changePasswordCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get changePasswordCurrentPassword;

  /// No description provided for @changePasswordCurrentPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password'**
  String get changePasswordCurrentPasswordHint;

  /// No description provided for @changePasswordCurrentPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Current password is required.'**
  String get changePasswordCurrentPasswordRequired;

  /// No description provided for @changePasswordNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get changePasswordNewPassword;

  /// No description provided for @changePasswordNewPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your new password'**
  String get changePasswordNewPasswordHint;

  /// No description provided for @changePasswordNewPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'New password is required.'**
  String get changePasswordNewPasswordRequired;

  /// No description provided for @changePasswordNewPasswordMinLength.
  ///
  /// In en, this message translates to:
  /// **'New password must be at least 6 characters.'**
  String get changePasswordNewPasswordMinLength;

  /// No description provided for @changePasswordConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get changePasswordConfirmPassword;

  /// No description provided for @changePasswordConfirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Confirm your new password'**
  String get changePasswordConfirmPasswordHint;

  /// No description provided for @changePasswordConfirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your new password.'**
  String get changePasswordConfirmPasswordRequired;

  /// No description provided for @changePasswordConfirmPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get changePasswordConfirmPasswordMismatch;

  /// No description provided for @changePasswordSave.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get changePasswordSave;

  /// No description provided for @changePasswordSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Password Changed Successfully!'**
  String get changePasswordSuccessTitle;

  /// No description provided for @changePasswordSuccessSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your password has been updated securely. Please use your new password the next time you sign in.'**
  String get changePasswordSuccessSubtitle;

  /// No description provided for @changePasswordBackToSettings.
  ///
  /// In en, this message translates to:
  /// **'Back to Settings'**
  String get changePasswordBackToSettings;

  /// No description provided for @changePasswordFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to change password. Please try again.'**
  String get changePasswordFailed;

  /// No description provided for @otpTitle.
  ///
  /// In en, this message translates to:
  /// **'OTP'**
  String get otpTitle;

  /// No description provided for @otpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit OTP sent to your email'**
  String get otpSubtitle;

  /// No description provided for @otpVerifyButton.
  ///
  /// In en, this message translates to:
  /// **'Verify OTP'**
  String get otpVerifyButton;

  /// No description provided for @otpResendButton.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get otpResendButton;

  /// No description provided for @otpIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Please enter all 6 OTP digits.'**
  String get otpIncomplete;

  /// No description provided for @otpDigitsOnly.
  ///
  /// In en, this message translates to:
  /// **'OTP must contain digits only.'**
  String get otpDigitsOnly;

  /// No description provided for @otpRequestCodeNotFound.
  ///
  /// In en, this message translates to:
  /// **'OTP request code not found.'**
  String get otpRequestCodeNotFound;

  /// No description provided for @otpEmailNotFound.
  ///
  /// In en, this message translates to:
  /// **'Email not found for resending OTP.'**
  String get otpEmailNotFound;

  /// No description provided for @otpInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid OTP code.'**
  String get otpInvalid;

  /// No description provided for @otpVerifySuccess.
  ///
  /// In en, this message translates to:
  /// **'OTP verified successfully!'**
  String get otpVerifySuccess;

  /// No description provided for @otpResendSuccess.
  ///
  /// In en, this message translates to:
  /// **'OTP has been resent successfully!'**
  String get otpResendSuccess;

  /// No description provided for @otpResendFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to resend OTP.'**
  String get otpResendFailed;

  /// No description provided for @seedContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get seedContinue;

  /// No description provided for @seedTitle.
  ///
  /// In en, this message translates to:
  /// **'Seed of Light'**
  String get seedTitle;

  /// No description provided for @seedDescription.
  ///
  /// In en, this message translates to:
  /// **'This is the beginning of your journey. The Seed of Light absorbs Life Force from your footsteps to grow.'**
  String get seedDescription;

  /// No description provided for @seedEvolutionTitle.
  ///
  /// In en, this message translates to:
  /// **'Evolution'**
  String get seedEvolutionTitle;

  /// No description provided for @seedEvolutionDescription.
  ///
  /// In en, this message translates to:
  /// **'The Seed will evolve into different Lumina forms based on your walking habits.'**
  String get seedEvolutionDescription;

  /// No description provided for @seedPath1Name.
  ///
  /// In en, this message translates to:
  /// **'Dawn Spirit'**
  String get seedPath1Name;

  /// No description provided for @seedPath1Description.
  ///
  /// In en, this message translates to:
  /// **'Flying Type • Morning Walks'**
  String get seedPath1Description;

  /// No description provided for @seedPath2Name.
  ///
  /// In en, this message translates to:
  /// **'Moonlight Spirit'**
  String get seedPath2Name;

  /// No description provided for @seedPath2Description.
  ///
  /// In en, this message translates to:
  /// **'Night Type • Evening Walks'**
  String get seedPath2Description;

  /// No description provided for @seedPath3Name.
  ///
  /// In en, this message translates to:
  /// **'Sunlight Spirit'**
  String get seedPath3Name;

  /// No description provided for @seedPath3Description.
  ///
  /// In en, this message translates to:
  /// **'Nature Type • Balanced Walking'**
  String get seedPath3Description;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get privacyTitle;

  /// No description provided for @privacySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Agreement with Walkamon'**
  String get privacySubtitle;

  /// No description provided for @privacyIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'INTRODUCTION'**
  String get privacyIntroTitle;

  /// No description provided for @privacyIntroContent.
  ///
  /// In en, this message translates to:
  /// **'...'**
  String get privacyIntroContent;

  /// No description provided for @privacyPart1.
  ///
  /// In en, this message translates to:
  /// **'PART 1'**
  String get privacyPart1;

  /// No description provided for @privacySection1Title.
  ///
  /// In en, this message translates to:
  /// **'1. Registration'**
  String get privacySection1Title;

  /// No description provided for @privacySection1Content.
  ///
  /// In en, this message translates to:
  /// **'...'**
  String get privacySection1Content;

  /// No description provided for @privacySection2Title.
  ///
  /// In en, this message translates to:
  /// **'2. Naming'**
  String get privacySection2Title;

  /// No description provided for @privacySection2Content.
  ///
  /// In en, this message translates to:
  /// **'...'**
  String get privacySection2Content;

  /// No description provided for @privacySection3Title.
  ///
  /// In en, this message translates to:
  /// **'3. Data Storage'**
  String get privacySection3Title;

  /// No description provided for @privacySection3Content.
  ///
  /// In en, this message translates to:
  /// **'...'**
  String get privacySection3Content;

  /// No description provided for @privacySection4Title.
  ///
  /// In en, this message translates to:
  /// **'4. Prohibited Conduct'**
  String get privacySection4Title;

  /// No description provided for @privacySection4Content.
  ///
  /// In en, this message translates to:
  /// **'...'**
  String get privacySection4Content;

  /// No description provided for @privacySection5Title.
  ///
  /// In en, this message translates to:
  /// **'5. Account Termination'**
  String get privacySection5Title;

  /// No description provided for @privacySection5Content.
  ///
  /// In en, this message translates to:
  /// **'...'**
  String get privacySection5Content;

  /// No description provided for @privacyPart2.
  ///
  /// In en, this message translates to:
  /// **'PART 2'**
  String get privacyPart2;

  /// No description provided for @privacySection6Title.
  ///
  /// In en, this message translates to:
  /// **'1. Content'**
  String get privacySection6Title;

  /// No description provided for @privacySection6Content.
  ///
  /// In en, this message translates to:
  /// **'...'**
  String get privacySection6Content;

  /// No description provided for @privacySection7Title.
  ///
  /// In en, this message translates to:
  /// **'2. Age Rating'**
  String get privacySection7Title;

  /// No description provided for @privacySection7Content.
  ///
  /// In en, this message translates to:
  /// **'...'**
  String get privacySection7Content;

  /// No description provided for @privacySection8Title.
  ///
  /// In en, this message translates to:
  /// **'3. Virtual Items'**
  String get privacySection8Title;

  /// No description provided for @privacySection8Content.
  ///
  /// In en, this message translates to:
  /// **'...'**
  String get privacySection8Content;

  /// No description provided for @privacySection9Title.
  ///
  /// In en, this message translates to:
  /// **'4. Copyright'**
  String get privacySection9Title;

  /// No description provided for @privacySection9Content.
  ///
  /// In en, this message translates to:
  /// **'...'**
  String get privacySection9Content;

  /// No description provided for @privacySection10Title.
  ///
  /// In en, this message translates to:
  /// **'5. Third-party Websites'**
  String get privacySection10Title;

  /// No description provided for @privacySection10Content.
  ///
  /// In en, this message translates to:
  /// **'...'**
  String get privacySection10Content;

  /// No description provided for @privacyContactTitle.
  ///
  /// In en, this message translates to:
  /// **'CONTACT'**
  String get privacyContactTitle;

  /// No description provided for @privacyContactContent.
  ///
  /// In en, this message translates to:
  /// **'...'**
  String get privacyContactContent;

  /// No description provided for @privacyLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated: June 25, 2026'**
  String get privacyLastUpdated;

  /// No description provided for @privacyAgreeButton.
  ///
  /// In en, this message translates to:
  /// **'I Understand & Agree'**
  String get privacyAgreeButton;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @traveler.
  ///
  /// In en, this message translates to:
  /// **'Traveler'**
  String get traveler;

  /// No description provided for @managementStats.
  ///
  /// In en, this message translates to:
  /// **'Management & Stats'**
  String get managementStats;

  /// No description provided for @accountInfo.
  ///
  /// In en, this message translates to:
  /// **'Account information'**
  String get accountInfo;

  /// No description provided for @setStepGoal.
  ///
  /// In en, this message translates to:
  /// **'Set step goal'**
  String get setStepGoal;

  /// No description provided for @streak.
  ///
  /// In en, this message translates to:
  /// **'Daily streak'**
  String get streak;

  /// No description provided for @activityStats.
  ///
  /// In en, this message translates to:
  /// **'Activity stats'**
  String get activityStats;

  /// No description provided for @achievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievements;

  /// No description provided for @achievementVault.
  ///
  /// In en, this message translates to:
  /// **'Achievement Vault'**
  String get achievementVault;

  /// No description provided for @achievementsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load achievements'**
  String get achievementsLoadFailed;

  /// No description provided for @achievementsCollected.
  ///
  /// In en, this message translates to:
  /// **'Collected {count} badges'**
  String achievementsCollected(int count);

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @characterNotFound.
  ///
  /// In en, this message translates to:
  /// **'Character information not found.'**
  String get characterNotFound;

  /// No description provided for @notUpdated.
  ///
  /// In en, this message translates to:
  /// **'Not updated'**
  String get notUpdated;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get dateOfBirth;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @joinDate.
  ///
  /// In en, this message translates to:
  /// **'Join date'**
  String get joinDate;

  /// No description provided for @genderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get genderFemale;

  /// No description provided for @genderOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get genderOther;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
