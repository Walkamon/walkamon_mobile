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

  /// No description provided for @achievementsUnlockedTab.
  ///
  /// In en, this message translates to:
  /// **'Claimed'**
  String get achievementsUnlockedTab;

  /// No description provided for @achievementsLockedTab.
  ///
  /// In en, this message translates to:
  /// **'Unclaimed'**
  String get achievementsLockedTab;

  /// No description provided for @achievementsCurrentProgress.
  ///
  /// In en, this message translates to:
  /// **'Current progress'**
  String get achievementsCurrentProgress;

  /// No description provided for @achievementsLockedDetail.
  ///
  /// In en, this message translates to:
  /// **'{description}.\nReward: {reward} Dewdrops'**
  String achievementsLockedDetail(String description, int reward);

  /// No description provided for @achievementsUnlockedAt.
  ///
  /// In en, this message translates to:
  /// **'Unlocked at: {date}'**
  String achievementsUnlockedAt(String date);

  /// No description provided for @achievementsUnlockedDetail.
  ///
  /// In en, this message translates to:
  /// **'{description}. Keep the momentum going to unlock more achievements!'**
  String achievementsUnlockedDetail(String description);

  /// No description provided for @achievementsKeepTrying.
  ///
  /// In en, this message translates to:
  /// **'Keep trying'**
  String get achievementsKeepTrying;

  /// No description provided for @achievementsCollection.
  ///
  /// In en, this message translates to:
  /// **'Collection'**
  String get achievementsCollection;

  /// No description provided for @achievementsGoals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get achievementsGoals;

  /// No description provided for @achievementsLockedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} badges are waiting to be discovered'**
  String achievementsLockedCount(int count);

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

  /// No description provided for @dailyLoginNoData.
  ///
  /// In en, this message translates to:
  /// **'No daily login data available.'**
  String get dailyLoginNoData;

  /// No description provided for @dailyLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Check-in'**
  String get dailyLoginTitle;

  /// No description provided for @dailyLoginRewardTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Gift'**
  String get dailyLoginRewardTitle;

  /// No description provided for @dailyLoginRewardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log in every day to receive amazing rewards.\nDon’t miss day 7!'**
  String get dailyLoginRewardSubtitle;

  /// No description provided for @dailyLoginAlreadyClaimed.
  ///
  /// In en, this message translates to:
  /// **'You already claimed your gift today!'**
  String get dailyLoginAlreadyClaimed;

  /// No description provided for @dailyLoginSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Success!'**
  String get dailyLoginSuccessTitle;

  /// No description provided for @dailyLoginSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Congratulations! You have successfully claimed your reward for day {day}!'**
  String dailyLoginSuccessMessage(int day);

  /// No description provided for @dailyLoginSuccessReward.
  ///
  /// In en, this message translates to:
  /// **'Reward: +{amount} Dewdrops'**
  String dailyLoginSuccessReward(int amount);

  /// No description provided for @dailyLoginSuccessBalance.
  ///
  /// In en, this message translates to:
  /// **'Current balance: {balance} Dewdrops'**
  String dailyLoginSuccessBalance(int balance);

  /// No description provided for @dailyLoginSuccessAction.
  ///
  /// In en, this message translates to:
  /// **'Awesome'**
  String get dailyLoginSuccessAction;

  /// No description provided for @dailyLoginClaimedToday.
  ///
  /// In en, this message translates to:
  /// **'Claimed Today'**
  String get dailyLoginClaimedToday;

  /// No description provided for @dailyLoginClaimNow.
  ///
  /// In en, this message translates to:
  /// **'Claim Reward Now'**
  String get dailyLoginClaimNow;

  /// No description provided for @dailyLoginNoRewardData.
  ///
  /// In en, this message translates to:
  /// **'No reward data yet'**
  String get dailyLoginNoRewardData;

  /// No description provided for @dayLabel.
  ///
  /// In en, this message translates to:
  /// **'DAY {day}'**
  String dayLabel(int day);

  /// No description provided for @rewardCount.
  ///
  /// In en, this message translates to:
  /// **'x{count}'**
  String rewardCount(int count);

  /// No description provided for @errorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorPrefix;

  /// No description provided for @friendsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load friends list'**
  String get friendsLoadError;

  /// No description provided for @friendsRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove friend'**
  String get friendsRemoveTitle;

  /// No description provided for @friendsRemoveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove {name} from your friends list?'**
  String friendsRemoveConfirm(String name);

  /// No description provided for @friendsCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get friendsCancel;

  /// No description provided for @friendsRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get friendsRemove;

  /// No description provided for @friendsRequest.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get friendsRequest;

  /// No description provided for @friendsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add Friend'**
  String get friendsAdd;

  /// No description provided for @friendsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search friends...'**
  String get friendsSearchHint;

  /// No description provided for @friendsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No teammates yet!'**
  String get friendsEmptyTitle;

  /// No description provided for @friendsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap \'Add Friend\' to start your journey.'**
  String get friendsEmptySubtitle;

  /// No description provided for @friendsNoResult.
  ///
  /// In en, this message translates to:
  /// **'No matching friend found.'**
  String get friendsNoResult;

  /// No description provided for @friendsRemoveSuccess.
  ///
  /// In en, this message translates to:
  /// **'You unfriended {name}!'**
  String friendsRemoveSuccess(String name);

  /// No description provided for @friendsRemoveFailure.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove friend. Please try again!'**
  String get friendsRemoveFailure;

  /// No description provided for @pvpTitle.
  ///
  /// In en, this message translates to:
  /// **'PvP Arena'**
  String get pvpTitle;

  /// No description provided for @pvpComingSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'PvP mode is under development!'**
  String get pvpComingSoonTitle;

  /// No description provided for @pvpComingSoonDescription.
  ///
  /// In en, this message translates to:
  /// **'Challenge the strength of Lumina against rivals.'**
  String get pvpComingSoonDescription;

  /// No description provided for @inventoryLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load inventory.'**
  String get inventoryLoadError;

  /// No description provided for @inventoryNoItems.
  ///
  /// In en, this message translates to:
  /// **'No items available.'**
  String get inventoryNoItems;

  /// No description provided for @inventoryNoEffect.
  ///
  /// In en, this message translates to:
  /// **'No effect'**
  String get inventoryNoEffect;

  /// No description provided for @inventoryUsed.
  ///
  /// In en, this message translates to:
  /// **'Used: {name}'**
  String inventoryUsed(String name);

  /// No description provided for @inventoryUseFailed.
  ///
  /// In en, this message translates to:
  /// **'Use failed: {message}'**
  String inventoryUseFailed(String message);

  /// No description provided for @inventoryUseError.
  ///
  /// In en, this message translates to:
  /// **'Error while using item: {message}'**
  String inventoryUseError(String message);

  /// No description provided for @inventoryCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get inventoryCommunity;

  /// No description provided for @inventoryPvp.
  ///
  /// In en, this message translates to:
  /// **'PvP'**
  String get inventoryPvp;

  /// No description provided for @inventoryBag.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventoryBag;

  /// No description provided for @inventoryStore.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get inventoryStore;

  /// No description provided for @inventoryHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get inventoryHome;

  /// No description provided for @leaderboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboardTitle;

  /// No description provided for @leaderboardYourRank.
  ///
  /// In en, this message translates to:
  /// **'Your rank: #{rank}'**
  String leaderboardYourRank(int rank);

  /// No description provided for @leaderboardToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get leaderboardToday;

  /// No description provided for @leaderboardThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get leaderboardThisWeek;

  /// No description provided for @leaderboardThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get leaderboardThisMonth;

  /// No description provided for @leaderboardSteps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get leaderboardSteps;

  /// No description provided for @leaderboardLevel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get leaderboardLevel;

  /// No description provided for @leaderboardYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get leaderboardYou;

  /// No description provided for @leaderboardUserDefault.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get leaderboardUserDefault;

  /// No description provided for @leaderboardCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load leaderboard'**
  String get leaderboardCouldNotLoad;

  /// No description provided for @leaderboardCouldNotConnect.
  ///
  /// In en, this message translates to:
  /// **'Could not connect to the server'**
  String get leaderboardCouldNotConnect;

  /// No description provided for @missionsDefaultDescription.
  ///
  /// In en, this message translates to:
  /// **'Complete the mission to receive a reward.'**
  String get missionsDefaultDescription;

  /// No description provided for @missionsChallengeDescription.
  ///
  /// In en, this message translates to:
  /// **'Complete the challenge to receive a reward.'**
  String get missionsChallengeDescription;

  /// No description provided for @missionsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load missions.'**
  String get missionsLoadError;

  /// No description provided for @missionsClaimSuccess.
  ///
  /// In en, this message translates to:
  /// **'Reward claimed successfully: +{amount}'**
  String missionsClaimSuccess(int amount);

  /// No description provided for @missionsClaimFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not claim reward: {message}'**
  String missionsClaimFailed(String message);

  /// No description provided for @missionsChallengeExists.
  ///
  /// In en, this message translates to:
  /// **'You already have a challenge. Please finish or cancel it first!'**
  String get missionsChallengeExists;

  /// No description provided for @missionsChallengeCanceled.
  ///
  /// In en, this message translates to:
  /// **'Challenge canceled.'**
  String get missionsChallengeCanceled;

  /// No description provided for @missionsChallengeCreated.
  ///
  /// In en, this message translates to:
  /// **'New challenge received!'**
  String get missionsChallengeCreated;

  /// No description provided for @missionsCancelFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not cancel challenge: {message}'**
  String missionsCancelFailed(String message);

  /// No description provided for @missionsDailyTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily missions'**
  String get missionsDailyTitle;

  /// No description provided for @missionsOverallTitle.
  ///
  /// In en, this message translates to:
  /// **'Overall missions'**
  String get missionsOverallTitle;

  /// No description provided for @missionsDailyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No daily missions.'**
  String get missionsDailyEmpty;

  /// No description provided for @missionsOverallEmpty.
  ///
  /// In en, this message translates to:
  /// **'No overall missions.'**
  String get missionsOverallEmpty;

  /// No description provided for @missionsRandomChallenge.
  ///
  /// In en, this message translates to:
  /// **'Random Challenge'**
  String get missionsRandomChallenge;

  /// No description provided for @missionsCancelRemaining.
  ///
  /// In en, this message translates to:
  /// **'Cancels left: {remaining}/{limit}'**
  String missionsCancelRemaining(int remaining, int limit);

  /// No description provided for @missionsNoActiveChallenge.
  ///
  /// In en, this message translates to:
  /// **'There are currently no active challenges.'**
  String get missionsNoActiveChallenge;

  /// No description provided for @missionsNewChallenge.
  ///
  /// In en, this message translates to:
  /// **'Take a new challenge'**
  String get missionsNewChallenge;

  /// No description provided for @missionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Missions'**
  String get missionsTitle;

  /// No description provided for @missionsTabMission.
  ///
  /// In en, this message translates to:
  /// **'Mission'**
  String get missionsTabMission;

  /// No description provided for @missionsTabChallenge.
  ///
  /// In en, this message translates to:
  /// **'Challenge'**
  String get missionsTabChallenge;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet.'**
  String get notificationsEmpty;

  /// No description provided for @notificationsDeleted.
  ///
  /// In en, this message translates to:
  /// **'Notification deleted'**
  String get notificationsDeleted;

  /// No description provided for @notificationsDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed: {message}'**
  String notificationsDeleteFailed(String message);

  /// No description provided for @notificationsDetailError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while loading the content.'**
  String get notificationsDetailError;

  /// No description provided for @notificationsTimeAgoDays.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String notificationsTimeAgoDays(int count);

  /// No description provided for @notificationsTimeAgoHours.
  ///
  /// In en, this message translates to:
  /// **'{count} hours ago'**
  String notificationsTimeAgoHours(int count);

  /// No description provided for @notificationsTimeAgoMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count} minutes ago'**
  String notificationsTimeAgoMinutes(int count);

  /// No description provided for @notificationsTimeAgoJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get notificationsTimeAgoJustNow;

  /// No description provided for @notificationsTypeDailyReward.
  ///
  /// In en, this message translates to:
  /// **'Daily login reward'**
  String get notificationsTypeDailyReward;

  /// No description provided for @notificationsTypeStreakReward.
  ///
  /// In en, this message translates to:
  /// **'Streak reward'**
  String get notificationsTypeStreakReward;

  /// No description provided for @notificationsTypeMissionComplete.
  ///
  /// In en, this message translates to:
  /// **'Mission complete'**
  String get notificationsTypeMissionComplete;

  /// No description provided for @notificationsTypeAchievementComplete.
  ///
  /// In en, this message translates to:
  /// **'Achievement complete'**
  String get notificationsTypeAchievementComplete;

  /// No description provided for @notificationsTypeChallengeInvite.
  ///
  /// In en, this message translates to:
  /// **'Challenge invitation'**
  String get notificationsTypeChallengeInvite;

  /// No description provided for @notificationsTypePvpInvite.
  ///
  /// In en, this message translates to:
  /// **'PvP invitation'**
  String get notificationsTypePvpInvite;

  /// No description provided for @notificationsTypeFriendRequest.
  ///
  /// In en, this message translates to:
  /// **'Friend request'**
  String get notificationsTypeFriendRequest;

  /// No description provided for @notificationsTypeFriendAccepted.
  ///
  /// In en, this message translates to:
  /// **'Friend request accepted'**
  String get notificationsTypeFriendAccepted;

  /// No description provided for @notificationsTypeFriendRemoved.
  ///
  /// In en, this message translates to:
  /// **'Friend removed'**
  String get notificationsTypeFriendRemoved;

  /// No description provided for @notificationsTypeSpiritHungry.
  ///
  /// In en, this message translates to:
  /// **'Lumina is hungry'**
  String get notificationsTypeSpiritHungry;

  /// No description provided for @notificationsTypeSpiritReadyEvolution.
  ///
  /// In en, this message translates to:
  /// **'Ready to evolve'**
  String get notificationsTypeSpiritReadyEvolution;

  /// No description provided for @notificationsTypeSpiritEnergyFull.
  ///
  /// In en, this message translates to:
  /// **'Energy full'**
  String get notificationsTypeSpiritEnergyFull;

  /// No description provided for @notificationsTypeSpiritBondLow.
  ///
  /// In en, this message translates to:
  /// **'Life force low'**
  String get notificationsTypeSpiritBondLow;

  /// No description provided for @notificationsTypeSpiritLevelUp.
  ///
  /// In en, this message translates to:
  /// **'Level up'**
  String get notificationsTypeSpiritLevelUp;

  /// No description provided for @notificationsTypeItemPurchased.
  ///
  /// In en, this message translates to:
  /// **'Item purchased successfully'**
  String get notificationsTypeItemPurchased;

  /// No description provided for @notificationsTypePvpResult.
  ///
  /// In en, this message translates to:
  /// **'PvP result'**
  String get notificationsTypePvpResult;

  /// No description provided for @notificationsTypeMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance notice'**
  String get notificationsTypeMaintenance;

  /// No description provided for @notificationsTypePatchNotes.
  ///
  /// In en, this message translates to:
  /// **'Patch notes'**
  String get notificationsTypePatchNotes;

  /// No description provided for @notificationsTypeNews.
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get notificationsTypeNews;

  /// No description provided for @notificationsTypeEvent.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get notificationsTypeEvent;

  /// No description provided for @notificationsTypeCompensation.
  ///
  /// In en, this message translates to:
  /// **'Compensation reward'**
  String get notificationsTypeCompensation;

  /// No description provided for @notificationsTypeServerAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'Server announcement'**
  String get notificationsTypeServerAnnouncement;

  /// No description provided for @profileEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get profileEditTitle;

  /// No description provided for @profileEditDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get profileEditDisplayName;

  /// No description provided for @profileEditDisplayNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get profileEditDisplayNameHint;

  /// No description provided for @profileEditEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email (Cannot be changed)'**
  String get profileEditEmailLabel;

  /// No description provided for @profileEditEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter email'**
  String get profileEditEmailHint;

  /// No description provided for @profileEditGenderLabel.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get profileEditGenderLabel;

  /// No description provided for @profileEditBirthLabel.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get profileEditBirthLabel;

  /// No description provided for @profileEditBioLabel.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get profileEditBioLabel;

  /// No description provided for @profileEditBioHint.
  ///
  /// In en, this message translates to:
  /// **'A little about you...'**
  String get profileEditBioHint;

  /// No description provided for @profileEditSaveLoading.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get profileEditSaveLoading;

  /// No description provided for @profileEditSave.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get profileEditSave;

  /// No description provided for @profileEditSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Your profile information has been updated successfully!'**
  String get profileEditSuccessMessage;

  /// No description provided for @profileEditFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'Update failed. Please check again.'**
  String get profileEditFailureMessage;

  /// No description provided for @profileEditRequiredName.
  ///
  /// In en, this message translates to:
  /// **'Cannot be empty'**
  String get profileEditRequiredName;

  /// No description provided for @profileEditConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get profileEditConfirm;

  /// No description provided for @profileEditDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Traveler'**
  String get profileEditDefaultName;

  /// No description provided for @profileEditDefaultBio.
  ///
  /// In en, this message translates to:
  /// **'Enjoying the Walkamon journey!'**
  String get profileEditDefaultBio;

  /// No description provided for @activityStatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activityStatsTitle;

  /// No description provided for @activityStatsStats.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get activityStatsStats;

  /// No description provided for @activityStatsHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get activityStatsHistory;

  /// No description provided for @activityStatsDaily.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get activityStatsDaily;

  /// No description provided for @activityStatsWeekly.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get activityStatsWeekly;

  /// No description provided for @activityStatsMonthly.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get activityStatsMonthly;

  /// No description provided for @activityStatsTotalSteps.
  ///
  /// In en, this message translates to:
  /// **'Total steps'**
  String get activityStatsTotalSteps;

  /// No description provided for @activityStatsDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get activityStatsDistance;

  /// No description provided for @activityStatsNoChartData.
  ///
  /// In en, this message translates to:
  /// **'No chart data yet'**
  String get activityStatsNoChartData;

  /// No description provided for @activityStatsNoHistory.
  ///
  /// In en, this message translates to:
  /// **'No activity history yet'**
  String get activityStatsNoHistory;

  /// No description provided for @activityStatsGoalReached.
  ///
  /// In en, this message translates to:
  /// **'GOAL REACHED'**
  String get activityStatsGoalReached;

  /// No description provided for @activityStatsStepsUnit.
  ///
  /// In en, this message translates to:
  /// **'steps'**
  String get activityStatsStepsUnit;

  /// No description provided for @activityStatsStepsPerDay.
  ///
  /// In en, this message translates to:
  /// **'steps/day'**
  String get activityStatsStepsPerDay;

  /// No description provided for @activityStatsSuffixKm.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get activityStatsSuffixKm;

  /// No description provided for @activityStatsTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s activity'**
  String get activityStatsTodayTitle;

  /// No description provided for @activityStatsWeekTitle.
  ///
  /// In en, this message translates to:
  /// **'This week\'s activity'**
  String get activityStatsWeekTitle;

  /// No description provided for @activityStatsMonthTitle.
  ///
  /// In en, this message translates to:
  /// **'This month\'s activity'**
  String get activityStatsMonthTitle;

  /// No description provided for @activityStatsTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get activityStatsTotal;

  /// No description provided for @activityStatsAverage.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get activityStatsAverage;

  /// No description provided for @activityStatsWeekBucket.
  ///
  /// In en, this message translates to:
  /// **'Week {week}'**
  String activityStatsWeekBucket(int week);

  /// No description provided for @streakTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Login Streak'**
  String get streakTitle;

  /// No description provided for @streakDays.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get streakDays;

  /// No description provided for @streakEncouragement.
  ///
  /// In en, this message translates to:
  /// **'You’re doing great! Keep it up to receive exciting rewards.'**
  String get streakEncouragement;

  /// No description provided for @streakThirtyDays.
  ///
  /// In en, this message translates to:
  /// **'30-day streak'**
  String get streakThirtyDays;

  /// No description provided for @streakRecord.
  ///
  /// In en, this message translates to:
  /// **'Streak record'**
  String get streakRecord;

  /// No description provided for @streakCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current streak'**
  String get streakCurrent;

  /// No description provided for @shopTitle.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get shopTitle;

  /// No description provided for @shopCurrency.
  ///
  /// In en, this message translates to:
  /// **'Dewdrops'**
  String get shopCurrency;

  /// No description provided for @shopNoItems.
  ///
  /// In en, this message translates to:
  /// **'No shop items available.'**
  String get shopNoItems;

  /// No description provided for @shopBuy.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get shopBuy;

  /// No description provided for @shopBuySuccess.
  ///
  /// In en, this message translates to:
  /// **'Purchased successfully: {name}'**
  String shopBuySuccess(String name);

  /// No description provided for @shopBuyFailed.
  ///
  /// In en, this message translates to:
  /// **'Purchase failed: {message}'**
  String shopBuyFailed(String message);

  /// No description provided for @shopBuyError.
  ///
  /// In en, this message translates to:
  /// **'Error while buying: {message}'**
  String shopBuyError(String message);

  /// No description provided for @shopType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get shopType;

  /// No description provided for @shopPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get shopPrice;

  /// No description provided for @shopDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get shopDescription;

  /// No description provided for @socialTitle.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get socialTitle;

  /// No description provided for @socialFriends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get socialFriends;

  /// No description provided for @socialLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get socialLeaderboard;

  /// No description provided for @dailyRewardTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Check-in'**
  String get dailyRewardTitle;

  /// No description provided for @dailyRewardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Daily check-in is being developed!'**
  String get dailyRewardSubtitle;

  /// No description provided for @dailyRewardDescription.
  ///
  /// In en, this message translates to:
  /// **'Log in every day to receive magical dew drops.'**
  String get dailyRewardDescription;

  /// No description provided for @namePetTitle.
  ///
  /// In en, this message translates to:
  /// **'Name your Lumina'**
  String get namePetTitle;

  /// No description provided for @namePetDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose a meaningful name for your companion.'**
  String get namePetDescription;

  /// No description provided for @namePetHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a Lumina name...'**
  String get namePetHint;

  /// No description provided for @namePetComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get namePetComplete;

  /// No description provided for @namePetCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not create your starter pet. Please try again.'**
  String get namePetCreateFailed;

  /// No description provided for @seedTitleScreen.
  ///
  /// In en, this message translates to:
  /// **'Seed of Light'**
  String get seedTitleScreen;

  /// No description provided for @seedDescriptionScreen.
  ///
  /// In en, this message translates to:
  /// **'This is the beginning of your journey. The Seed of Light absorbs Life Force from your footsteps to grow.'**
  String get seedDescriptionScreen;

  /// No description provided for @storySkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get storySkip;

  /// No description provided for @storyBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get storyBack;

  /// No description provided for @storyContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get storyContinue;

  /// No description provided for @storyExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get storyExplore;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// No description provided for @profileEditFailureTitle.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get profileEditFailureTitle;

  /// No description provided for @missionsClaim.
  ///
  /// In en, this message translates to:
  /// **'CLAIM'**
  String get missionsClaim;

  /// No description provided for @missionsClaimed.
  ///
  /// In en, this message translates to:
  /// **'CLAIMED'**
  String get missionsClaimed;

  /// No description provided for @inventoryNoDescription.
  ///
  /// In en, this message translates to:
  /// **'No description yet.'**
  String get inventoryNoDescription;

  /// No description provided for @inventoryUse.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get inventoryUse;

  /// No description provided for @friendsListCount.
  ///
  /// In en, this message translates to:
  /// **'LIST ({count})'**
  String friendsListCount(int count);

  /// No description provided for @friendsSearchError.
  ///
  /// In en, this message translates to:
  /// **'Search failed'**
  String get friendsSearchError;

  /// No description provided for @friendsAddNew.
  ///
  /// In en, this message translates to:
  /// **'Add New Friend'**
  String get friendsAddNew;

  /// No description provided for @friendsPlayerNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter player name...'**
  String get friendsPlayerNameHint;

  /// No description provided for @friendsSuggestionsCount.
  ///
  /// In en, this message translates to:
  /// **'FRIEND SUGGESTIONS ({count})'**
  String friendsSuggestionsCount(int count);

  /// No description provided for @friendsSearchResultsCount.
  ///
  /// In en, this message translates to:
  /// **'SEARCH RESULTS ({count})'**
  String friendsSearchResultsCount(int count);

  /// No description provided for @friendsNoAvailablePlayers.
  ///
  /// In en, this message translates to:
  /// **'No available players'**
  String get friendsNoAvailablePlayers;

  /// No description provided for @friendsAddShort.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get friendsAddShort;

  /// No description provided for @friendsInbox.
  ///
  /// In en, this message translates to:
  /// **'Friend Mailbox'**
  String get friendsInbox;

  /// No description provided for @friendsReceivedInvites.
  ///
  /// In en, this message translates to:
  /// **'Received invites'**
  String get friendsReceivedInvites;

  /// No description provided for @friendsSentInvites.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get friendsSentInvites;

  /// No description provided for @friendsNoSentInvites.
  ///
  /// In en, this message translates to:
  /// **'You have not sent any invites recently.'**
  String get friendsNoSentInvites;

  /// No description provided for @friendsNoReceivedInvites.
  ///
  /// In en, this message translates to:
  /// **'No friend invites.'**
  String get friendsNoReceivedInvites;

  /// No description provided for @stepGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'Step goal'**
  String get stepGoalTitle;

  /// No description provided for @stepGoalCustomTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom goal'**
  String get stepGoalCustomTitle;

  /// No description provided for @stepGoalInputHint.
  ///
  /// In en, this message translates to:
  /// **'Enter steps...'**
  String get stepGoalInputHint;

  /// No description provided for @stepGoalSuggestions.
  ///
  /// In en, this message translates to:
  /// **'GOAL SUGGESTIONS'**
  String get stepGoalSuggestions;

  /// No description provided for @stepGoalTodayProgress.
  ///
  /// In en, this message translates to:
  /// **'TODAY\'S PROGRESS'**
  String get stepGoalTodayProgress;

  /// No description provided for @stepGoalMinError.
  ///
  /// In en, this message translates to:
  /// **'Goal must be greater than 500 steps.'**
  String get stepGoalMinError;

  /// No description provided for @stepGoalMaxError.
  ///
  /// In en, this message translates to:
  /// **'Goal cannot exceed 100,000 steps.'**
  String get stepGoalMaxError;

  /// No description provided for @stepGoalGreaterThanCurrent.
  ///
  /// In en, this message translates to:
  /// **'New goal must be greater than the current goal.'**
  String get stepGoalGreaterThanCurrent;

  /// No description provided for @stepGoalInvalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid step count.'**
  String get stepGoalInvalidNumber;

  /// No description provided for @stepGoalSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved goal of {steps} steps.'**
  String stepGoalSaved(String steps);

  /// No description provided for @stepGoalClaimSuccess.
  ///
  /// In en, this message translates to:
  /// **'Reward claimed successfully: +{amount} Dewdrops.'**
  String stepGoalClaimSuccess(String amount);

  /// No description provided for @stepGoalOutOfSteps.
  ///
  /// In en, this message translates to:
  /// **' / {steps} steps'**
  String stepGoalOutOfSteps(String steps);

  /// No description provided for @stepGoalRemaining.
  ///
  /// In en, this message translates to:
  /// **'{steps} steps left'**
  String stepGoalRemaining(String steps);

  /// No description provided for @stepGoalNotSet.
  ///
  /// In en, this message translates to:
  /// **'No goal set'**
  String get stepGoalNotSet;

  /// No description provided for @stepGoalChoosePrompt.
  ///
  /// In en, this message translates to:
  /// **'Choose a goal below to start tracking today\'s progress.'**
  String get stepGoalChoosePrompt;

  /// No description provided for @stepGoalCompletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Great job! You completed today\'s goal.'**
  String get stepGoalCompletedMessage;

  /// No description provided for @stepGoalActiveMessage.
  ///
  /// In en, this message translates to:
  /// **'Set a realistic goal and gradually increase it to keep your active streak going.'**
  String get stepGoalActiveMessage;

  /// No description provided for @stepGoalStreakTitle.
  ///
  /// In en, this message translates to:
  /// **'Goal streak'**
  String get stepGoalStreakTitle;

  /// No description provided for @stepGoalStreakSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Complete goals to grow your wallet reward.'**
  String get stepGoalStreakSubtitle;

  /// No description provided for @stepGoalLongest.
  ///
  /// In en, this message translates to:
  /// **'Longest'**
  String get stepGoalLongest;

  /// No description provided for @stepGoalClaiming.
  ///
  /// In en, this message translates to:
  /// **'Claiming'**
  String get stepGoalClaiming;

  /// No description provided for @stepGoalCustomShort.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get stepGoalCustomShort;

  /// No description provided for @spiritDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} Details'**
  String spiritDetailTitle(String name);

  /// No description provided for @spiritLevel.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String spiritLevel(int level);

  /// No description provided for @spiritRecoveryPotion.
  ///
  /// In en, this message translates to:
  /// **'Recovery Potion'**
  String get spiritRecoveryPotion;

  /// No description provided for @spiritBondBonus.
  ///
  /// In en, this message translates to:
  /// **'+{amount} Bonding'**
  String spiritBondBonus(int amount);

  /// No description provided for @spiritEnergyBonus.
  ///
  /// In en, this message translates to:
  /// **'+{amount} Energy'**
  String spiritEnergyBonus(int amount);

  /// No description provided for @spiritPlantType.
  ///
  /// In en, this message translates to:
  /// **'Plant Type'**
  String get spiritPlantType;

  /// No description provided for @spiritStatsTab.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get spiritStatsTab;

  /// No description provided for @spiritEvolutionTab.
  ///
  /// In en, this message translates to:
  /// **'Evolution'**
  String get spiritEvolutionTab;

  /// No description provided for @spiritLifeForceExp.
  ///
  /// In en, this message translates to:
  /// **'Life Force (EXP)'**
  String get spiritLifeForceExp;

  /// No description provided for @spiritSupportItems.
  ///
  /// In en, this message translates to:
  /// **'Support Items'**
  String get spiritSupportItems;

  /// No description provided for @spiritTapLumina.
  ///
  /// In en, this message translates to:
  /// **'Tap Lumina'**
  String get spiritTapLumina;

  /// No description provided for @spiritTapSuccess.
  ///
  /// In en, this message translates to:
  /// **'Tapped Lumina successfully'**
  String get spiritTapSuccess;

  /// No description provided for @spiritFeed.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get spiritFeed;

  /// No description provided for @spiritFeedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Fed Lumina successfully'**
  String get spiritFeedSuccess;

  /// No description provided for @spiritEvolutionStages.
  ///
  /// In en, this message translates to:
  /// **'Evolution Stages'**
  String get spiritEvolutionStages;

  /// No description provided for @spiritStageSeed.
  ///
  /// In en, this message translates to:
  /// **'Seed'**
  String get spiritStageSeed;

  /// No description provided for @spiritStageSprout.
  ///
  /// In en, this message translates to:
  /// **'Sprout'**
  String get spiritStageSprout;

  /// No description provided for @spiritStageLeaf.
  ///
  /// In en, this message translates to:
  /// **'Leaf'**
  String get spiritStageLeaf;

  /// No description provided for @spiritCurrentRequirement.
  ///
  /// In en, this message translates to:
  /// **'Current requirements: Lv {level} - Bond {bonding}'**
  String spiritCurrentRequirement(int level, int bonding);

  /// No description provided for @spiritCurrentStage.
  ///
  /// In en, this message translates to:
  /// **'Current stage: {stage} • Lv {level}'**
  String spiritCurrentStage(String stage, int level);

  /// No description provided for @spiritHistoryNoEvolution.
  ///
  /// In en, this message translates to:
  /// **'No evolution history yet.'**
  String get spiritHistoryNoEvolution;

  /// No description provided for @spiritHistoryDateLevel.
  ///
  /// In en, this message translates to:
  /// **'{date} • Lv {level}'**
  String spiritHistoryDateLevel(String date, int level);

  /// No description provided for @spiritHistoryLevel.
  ///
  /// In en, this message translates to:
  /// **'Lv {level}'**
  String spiritHistoryLevel(int level);

  /// No description provided for @spiritConditionTargetLevel.
  ///
  /// In en, this message translates to:
  /// **'Reach Lv {level}'**
  String spiritConditionTargetLevel(int level);

  /// No description provided for @spiritEvolutionPreview.
  ///
  /// In en, this message translates to:
  /// **'Evolution Preview'**
  String get spiritEvolutionPreview;

  /// No description provided for @spiritChooseEvolutionBranch.
  ///
  /// In en, this message translates to:
  /// **'Choose evolution branch'**
  String get spiritChooseEvolutionBranch;

  /// No description provided for @spiritRequiredLevel.
  ///
  /// In en, this message translates to:
  /// **'Required level: {level}'**
  String spiritRequiredLevel(int level);

  /// No description provided for @spiritReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get spiritReady;

  /// No description provided for @spiritEvolutionHistory.
  ///
  /// In en, this message translates to:
  /// **'Evolution History'**
  String get spiritEvolutionHistory;

  /// No description provided for @spiritHistoryHatched.
  ///
  /// In en, this message translates to:
  /// **'Hatched successfully'**
  String get spiritHistoryHatched;

  /// No description provided for @spiritHistorySprout.
  ///
  /// In en, this message translates to:
  /// **'Evolved into Sprout Form'**
  String get spiritHistorySprout;

  /// No description provided for @spiritHistoryLeaf.
  ///
  /// In en, this message translates to:
  /// **'Evolved into Leaf Form'**
  String get spiritHistoryLeaf;

  /// No description provided for @spiritEvolutionConditions.
  ///
  /// In en, this message translates to:
  /// **'Evolution Conditions'**
  String get spiritEvolutionConditions;

  /// No description provided for @spiritReachLevel15.
  ///
  /// In en, this message translates to:
  /// **'Reach Level 15'**
  String get spiritReachLevel15;

  /// No description provided for @spiritBondRequirement.
  ///
  /// In en, this message translates to:
  /// **'Bonding requirement met'**
  String get spiritBondRequirement;

  /// No description provided for @spiritMet.
  ///
  /// In en, this message translates to:
  /// **'Met'**
  String get spiritMet;

  /// No description provided for @spiritEvolveNow.
  ///
  /// In en, this message translates to:
  /// **'Evolve Now'**
  String get spiritEvolveNow;

  /// No description provided for @spiritMaxEvolution.
  ///
  /// In en, this message translates to:
  /// **'Lumina has reached the current maximum evolution form!'**
  String get spiritMaxEvolution;

  /// No description provided for @spiritEvolving.
  ///
  /// In en, this message translates to:
  /// **'Evolving...'**
  String get spiritEvolving;

  /// No description provided for @storySlide1.
  ///
  /// In en, this message translates to:
  /// **'You discover an old space exploration device. Inside is a Seed of Light...'**
  String get storySlide1;

  /// No description provided for @storySlide2.
  ///
  /// In en, this message translates to:
  /// **'...a small Lumina from a planet that lost its gravity.'**
  String get storySlide2;

  /// No description provided for @storySlide3.
  ///
  /// In en, this message translates to:
  /// **'To survive and grow, Lumina absorbs Life Force from human footsteps.'**
  String get storySlide3;

  /// No description provided for @storySlide4.
  ///
  /// In en, this message translates to:
  /// **'Lumina does not need you to fight. It only wants to walk beside you and see the real world.'**
  String get storySlide4;

  /// No description provided for @profileEditGenderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get profileEditGenderMale;

  /// No description provided for @profileEditGenderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get profileEditGenderFemale;

  /// No description provided for @profileEditGenderOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get profileEditGenderOther;

  /// No description provided for @friendsRequestSentTo.
  ///
  /// In en, this message translates to:
  /// **'Sent an invite to {name}!'**
  String friendsRequestSentTo(String name);

  /// No description provided for @friendsRequestSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send the invite. Please try again later.'**
  String get friendsRequestSendFailed;

  /// No description provided for @friendsRequestAlreadySent.
  ///
  /// In en, this message translates to:
  /// **'You already sent this player an invite!'**
  String get friendsRequestAlreadySent;

  /// No description provided for @friendsAlreadyFriend.
  ///
  /// In en, this message translates to:
  /// **'You are already friends!'**
  String get friendsAlreadyFriend;

  /// No description provided for @friendsPlayerNotFound.
  ///
  /// In en, this message translates to:
  /// **'Could not find this player.'**
  String get friendsPlayerNotFound;

  /// No description provided for @friendProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Traveler Profile'**
  String get friendProfileTitle;

  /// No description provided for @friendProfileTraveler.
  ///
  /// In en, this message translates to:
  /// **'Traveler'**
  String get friendProfileTraveler;

  /// No description provided for @friendProfileUnknownPlayer.
  ///
  /// In en, this message translates to:
  /// **'Unknown player'**
  String get friendProfileUnknownPlayer;

  /// No description provided for @friendProfileCompanion.
  ///
  /// In en, this message translates to:
  /// **'Companion Spirit'**
  String get friendProfileCompanion;

  /// No description provided for @friendProfileStats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get friendProfileStats;

  /// No description provided for @friendProfileAchievements.
  ///
  /// In en, this message translates to:
  /// **'Featured Achievements'**
  String get friendProfileAchievements;

  /// No description provided for @friendProfileSpiritName.
  ///
  /// In en, this message translates to:
  /// **'Spirit: {name}'**
  String friendProfileSpiritName(String name);

  /// No description provided for @friendProfileViewStats.
  ///
  /// In en, this message translates to:
  /// **'View Stats'**
  String get friendProfileViewStats;

  /// No description provided for @friendProfileSpiritMeta.
  ///
  /// In en, this message translates to:
  /// **'{type} - Level {level}'**
  String friendProfileSpiritMeta(String type, int level);

  /// No description provided for @friendProfileNoSpirit.
  ///
  /// In en, this message translates to:
  /// **'No spirit yet'**
  String get friendProfileNoSpirit;

  /// No description provided for @friendProfileSpiritTypeUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown Type'**
  String get friendProfileSpiritTypeUnknown;

  /// No description provided for @friendProfileTotalSteps.
  ///
  /// In en, this message translates to:
  /// **'Total steps'**
  String get friendProfileTotalSteps;

  /// No description provided for @friendProfileStreak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get friendProfileStreak;

  /// No description provided for @friendProfileEnergy.
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get friendProfileEnergy;

  /// No description provided for @friendProfileBond.
  ///
  /// In en, this message translates to:
  /// **'Bond'**
  String get friendProfileBond;

  /// No description provided for @friendProfileLifeForce.
  ///
  /// In en, this message translates to:
  /// **'Life Force'**
  String get friendProfileLifeForce;

  /// No description provided for @friendProfileExp.
  ///
  /// In en, this message translates to:
  /// **'EXP'**
  String get friendProfileExp;

  /// No description provided for @friendProfileUnavailable.
  ///
  /// In en, this message translates to:
  /// **'--'**
  String get friendProfileUnavailable;

  /// No description provided for @friendProfileAchievementsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Achievements data is not available yet.'**
  String get friendProfileAchievementsUnavailable;

  /// No description provided for @friendProfileLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load this player profile.'**
  String get friendProfileLoadFailed;

  /// No description provided for @friendProfileRequestSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite sent!'**
  String get friendProfileRequestSentTitle;

  /// No description provided for @friendProfileRequestSentMessage.
  ///
  /// In en, this message translates to:
  /// **'Your friend invite has been sent to {name}. Keep walking together!'**
  String friendProfileRequestSentMessage(String name);

  /// No description provided for @friendProfileGreat.
  ///
  /// In en, this message translates to:
  /// **'Great'**
  String get friendProfileGreat;

  /// No description provided for @friendSpiritTitle.
  ///
  /// In en, this message translates to:
  /// **'Spirit Stats'**
  String get friendSpiritTitle;

  /// No description provided for @feedbackWaitBeforeRetry.
  ///
  /// In en, this message translates to:
  /// **'Please wait before sending again.'**
  String get feedbackWaitBeforeRetry;

  /// No description provided for @feedbackSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send feedback. Please try again later.'**
  String get feedbackSendFailed;

  /// No description provided for @friendSpiritNoData.
  ///
  /// In en, this message translates to:
  /// **'No friend spirit data.'**
  String get friendSpiritNoData;

  /// No description provided for @friendSpiritOfName.
  ///
  /// In en, this message translates to:
  /// **'{userName}\'s Spirit'**
  String friendSpiritOfName(String userName);

  /// No description provided for @friendSpiritLevel.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String friendSpiritLevel(int level);

  /// No description provided for @friendSpiritStatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get friendSpiritStatsTitle;

  /// No description provided for @friendSpiritEvolutionTitle.
  ///
  /// In en, this message translates to:
  /// **'Evolution'**
  String get friendSpiritEvolutionTitle;

  /// No description provided for @friendSpiritExp.
  ///
  /// In en, this message translates to:
  /// **'Experience (EXP)'**
  String get friendSpiritExp;

  /// No description provided for @friendSpiritLifeForce.
  ///
  /// In en, this message translates to:
  /// **'Life Force (Life Force)'**
  String get friendSpiritLifeForce;

  /// No description provided for @friendSpiritBonding.
  ///
  /// In en, this message translates to:
  /// **'Bonding (Bond)'**
  String get friendSpiritBonding;

  /// No description provided for @friendSpiritEnergy.
  ///
  /// In en, this message translates to:
  /// **'Energy (Energy)'**
  String get friendSpiritEnergy;

  /// No description provided for @friendSpiritCurrentStage.
  ///
  /// In en, this message translates to:
  /// **'CURRENT STAGE'**
  String get friendSpiritCurrentStage;

  /// No description provided for @friendSpiritCurrentProperty.
  ///
  /// In en, this message translates to:
  /// **'Current energy attribute recorded'**
  String get friendSpiritCurrentProperty;

  /// No description provided for @friendSpiritEvolutionStages.
  ///
  /// In en, this message translates to:
  /// **'EVOLUTION STAGES'**
  String get friendSpiritEvolutionStages;

  /// No description provided for @friendSpiritMilestones.
  ///
  /// In en, this message translates to:
  /// **'MILESTONES HISTORY'**
  String get friendSpiritMilestones;

  /// No description provided for @friendSpiritReachLevel.
  ///
  /// In en, this message translates to:
  /// **'Reach Level {level}'**
  String friendSpiritReachLevel(int level);

  /// No description provided for @friendSpiritRecently.
  ///
  /// In en, this message translates to:
  /// **'Recently'**
  String get friendSpiritRecently;

  /// No description provided for @friendSpiritBeginJourney.
  ///
  /// In en, this message translates to:
  /// **'Started Walkamon Journey'**
  String get friendSpiritBeginJourney;

  /// No description provided for @friendSpiritInit.
  ///
  /// In en, this message translates to:
  /// **'Initialized'**
  String get friendSpiritInit;

  /// No description provided for @friendSpiritStageSeedling.
  ///
  /// In en, this message translates to:
  /// **'Seedling'**
  String get friendSpiritStageSeedling;

  /// No description provided for @friendSpiritStageSprout.
  ///
  /// In en, this message translates to:
  /// **'Sprout'**
  String get friendSpiritStageSprout;

  /// No description provided for @friendSpiritStageLeaf.
  ///
  /// In en, this message translates to:
  /// **'Leaf'**
  String get friendSpiritStageLeaf;

  /// No description provided for @pvpInvites.
  ///
  /// In en, this message translates to:
  /// **'Invites'**
  String get pvpInvites;

  /// No description provided for @pvpHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get pvpHistory;

  /// No description provided for @pvpTodayStepsLabel.
  ///
  /// In en, this message translates to:
  /// **'Today\'s steps:'**
  String get pvpTodayStepsLabel;

  /// No description provided for @pvpSpiritAffinityLabel.
  ///
  /// In en, this message translates to:
  /// **'Spirit affinity:'**
  String get pvpSpiritAffinityLabel;

  /// No description provided for @pvpEnergyLabel.
  ///
  /// In en, this message translates to:
  /// **'Energy:'**
  String get pvpEnergyLabel;

  /// No description provided for @pvpBondLabel.
  ///
  /// In en, this message translates to:
  /// **'Bond:'**
  String get pvpBondLabel;

  /// No description provided for @pvpSearchingOpponent.
  ///
  /// In en, this message translates to:
  /// **'Searching for an opponent...'**
  String get pvpSearchingOpponent;

  /// No description provided for @pvpCancelSearch.
  ///
  /// In en, this message translates to:
  /// **'Cancel search'**
  String get pvpCancelSearch;

  /// No description provided for @pvpConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get pvpConnecting;

  /// No description provided for @pvpPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing...'**
  String get pvpPreparing;

  /// No description provided for @pvpFindRandomMatch.
  ///
  /// In en, this message translates to:
  /// **'Find random match'**
  String get pvpFindRandomMatch;

  /// No description provided for @pvpChallengeFriend.
  ///
  /// In en, this message translates to:
  /// **'Challenge a friend'**
  String get pvpChallengeFriend;

  /// No description provided for @pvpAffinityWarmSun.
  ///
  /// In en, this message translates to:
  /// **'Warm Sun'**
  String get pvpAffinityWarmSun;

  /// No description provided for @pvpAffinityDawn.
  ///
  /// In en, this message translates to:
  /// **'Dawn'**
  String get pvpAffinityDawn;

  /// No description provided for @pvpAffinityMoonlight.
  ///
  /// In en, this message translates to:
  /// **'Moonlight'**
  String get pvpAffinityMoonlight;

  /// No description provided for @pvpAffinitySprout.
  ///
  /// In en, this message translates to:
  /// **'Sprout'**
  String get pvpAffinitySprout;

  /// No description provided for @pvpAffinityUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown affinity'**
  String get pvpAffinityUnknown;

  /// No description provided for @pvpExitMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave match?'**
  String get pvpExitMatchTitle;

  /// No description provided for @pvpExitMatchMessage.
  ///
  /// In en, this message translates to:
  /// **'Leaving now will count as a DEFEAT and your opponent will win.'**
  String get pvpExitMatchMessage;

  /// No description provided for @pvpStayInMatch.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get pvpStayInMatch;

  /// No description provided for @pvpExitAndForfeit.
  ///
  /// In en, this message translates to:
  /// **'Leave & forfeit'**
  String get pvpExitAndForfeit;

  /// No description provided for @pvpNoticeTitle.
  ///
  /// In en, this message translates to:
  /// **'Notice'**
  String get pvpNoticeTitle;

  /// No description provided for @pvpInviteDeclined.
  ///
  /// In en, this message translates to:
  /// **'The player declined your invitation.'**
  String get pvpInviteDeclined;

  /// No description provided for @pvpChallengeInvitesTitle.
  ///
  /// In en, this message translates to:
  /// **'Challenge invites'**
  String get pvpChallengeInvitesTitle;

  /// No description provided for @pvpNoInvitations.
  ///
  /// In en, this message translates to:
  /// **'No invitations'**
  String get pvpNoInvitations;

  /// No description provided for @pvpStatusOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get pvpStatusOffline;

  /// No description provided for @pvpStatusBusy.
  ///
  /// In en, this message translates to:
  /// **'Busy'**
  String get pvpStatusBusy;

  /// No description provided for @pvpStatusOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get pvpStatusOnline;

  /// No description provided for @pvpOpponent.
  ///
  /// In en, this message translates to:
  /// **'Opponent'**
  String get pvpOpponent;

  /// No description provided for @pvpSenderInAnotherMatch.
  ///
  /// In en, this message translates to:
  /// **'The sender is in another match'**
  String get pvpSenderInAnotherMatch;

  /// No description provided for @pvpSenderOffline.
  ///
  /// In en, this message translates to:
  /// **'The sender has gone offline'**
  String get pvpSenderOffline;

  /// No description provided for @pvpAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get pvpAccept;

  /// No description provided for @pvpReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get pvpReject;

  /// No description provided for @pvpMatchTypeRanked.
  ///
  /// In en, this message translates to:
  /// **'Ranked'**
  String get pvpMatchTypeRanked;

  /// No description provided for @pvpMatchTypeFriendly.
  ///
  /// In en, this message translates to:
  /// **'Friendly'**
  String get pvpMatchTypeFriendly;

  /// No description provided for @pvpMatchTypeEvent.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get pvpMatchTypeEvent;

  /// No description provided for @pvpMatchTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get pvpMatchTypeOther;

  /// No description provided for @pvpMatchSourceBot.
  ///
  /// In en, this message translates to:
  /// **'Bot'**
  String get pvpMatchSourceBot;

  /// No description provided for @pvpMatchSourceMatchmaking.
  ///
  /// In en, this message translates to:
  /// **'Matchmaking'**
  String get pvpMatchSourceMatchmaking;

  /// No description provided for @pvpMatchSourceInvite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get pvpMatchSourceInvite;

  /// No description provided for @pvpMatchSourceOther.
  ///
  /// In en, this message translates to:
  /// **'Other source'**
  String get pvpMatchSourceOther;

  /// No description provided for @pvpMatchHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Match history'**
  String get pvpMatchHistoryTitle;

  /// No description provided for @pvpRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get pvpRefresh;

  /// No description provided for @pvpFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get pvpFilterAll;

  /// No description provided for @pvpFilterAllResults.
  ///
  /// In en, this message translates to:
  /// **'All results'**
  String get pvpFilterAllResults;

  /// No description provided for @pvpFilterWins.
  ///
  /// In en, this message translates to:
  /// **'Wins'**
  String get pvpFilterWins;

  /// No description provided for @pvpFilterLosses.
  ///
  /// In en, this message translates to:
  /// **'Losses'**
  String get pvpFilterLosses;

  /// No description provided for @pvpNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches yet'**
  String get pvpNoMatches;

  /// No description provided for @pvpHistoryVictory.
  ///
  /// In en, this message translates to:
  /// **'VICTORY'**
  String get pvpHistoryVictory;

  /// No description provided for @pvpHistoryCancelled.
  ///
  /// In en, this message translates to:
  /// **'CANCELLED'**
  String get pvpHistoryCancelled;

  /// No description provided for @pvpHistoryDefeat.
  ///
  /// In en, this message translates to:
  /// **'DEFEAT'**
  String get pvpHistoryDefeat;

  /// No description provided for @pvpHistoryDraw.
  ///
  /// In en, this message translates to:
  /// **'DRAW'**
  String get pvpHistoryDraw;

  /// No description provided for @pvpHistoryResultUnknown.
  ///
  /// In en, this message translates to:
  /// **'UNKNOWN'**
  String get pvpHistoryResultUnknown;

  /// No description provided for @pvpPreviousPage.
  ///
  /// In en, this message translates to:
  /// **'Previous page'**
  String get pvpPreviousPage;

  /// No description provided for @pvpPageOf.
  ///
  /// In en, this message translates to:
  /// **'Page {page} / {totalPages}'**
  String pvpPageOf(int page, int totalPages);

  /// No description provided for @pvpNextPage.
  ///
  /// In en, this message translates to:
  /// **'Next page'**
  String get pvpNextPage;

  /// No description provided for @pvpChallengeFriendsTitle.
  ///
  /// In en, this message translates to:
  /// **'Challenge Friends'**
  String get pvpChallengeFriendsTitle;

  /// No description provided for @pvpOnlineSection.
  ///
  /// In en, this message translates to:
  /// **'ONLINE'**
  String get pvpOnlineSection;

  /// No description provided for @pvpNoOnlineFriends.
  ///
  /// In en, this message translates to:
  /// **'No friends are online'**
  String get pvpNoOnlineFriends;

  /// No description provided for @pvpOfflineSection.
  ///
  /// In en, this message translates to:
  /// **'OFFLINE'**
  String get pvpOfflineSection;

  /// No description provided for @pvpNoOfflineFriends.
  ///
  /// In en, this message translates to:
  /// **'No offline friends'**
  String get pvpNoOfflineFriends;

  /// No description provided for @pvpFriendBusy.
  ///
  /// In en, this message translates to:
  /// **'Friend is busy'**
  String get pvpFriendBusy;

  /// No description provided for @pvpChallengeAction.
  ///
  /// In en, this message translates to:
  /// **'Challenge'**
  String get pvpChallengeAction;

  /// No description provided for @pvpInviteSent.
  ///
  /// In en, this message translates to:
  /// **'Invitation sent!'**
  String get pvpInviteSent;

  /// No description provided for @pvpWaitingForFriend.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {opponentName} to respond...'**
  String pvpWaitingForFriend(String opponentName);

  /// No description provided for @pvpCancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Cancel request'**
  String get pvpCancelRequest;

  /// No description provided for @pvpConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected!'**
  String get pvpConnected;

  /// No description provided for @pvpRaceAgainst.
  ///
  /// In en, this message translates to:
  /// **'You will race against {opponentName}'**
  String pvpRaceAgainst(String opponentName);

  /// No description provided for @pvpPrepareForMatch.
  ///
  /// In en, this message translates to:
  /// **'GET READY'**
  String get pvpPrepareForMatch;

  /// No description provided for @pvpMatchSuccess.
  ///
  /// In en, this message translates to:
  /// **'Match found!'**
  String get pvpMatchSuccess;

  /// No description provided for @pvpEnteringRace.
  ///
  /// In en, this message translates to:
  /// **'Entering the race. The countdown will begin as soon as the match is ready.'**
  String get pvpEnteringRace;

  /// No description provided for @pvpResultVictoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Victory!'**
  String get pvpResultVictoryTitle;

  /// No description provided for @pvpResultDrawTitle.
  ///
  /// In en, this message translates to:
  /// **'Draw!'**
  String get pvpResultDrawTitle;

  /// No description provided for @pvpResultDefeatTitle.
  ///
  /// In en, this message translates to:
  /// **'Defeat'**
  String get pvpResultDefeatTitle;

  /// No description provided for @pvpResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Match result'**
  String get pvpResultTitle;

  /// No description provided for @pvpResultWinGeneric.
  ///
  /// In en, this message translates to:
  /// **'You won the sprint!'**
  String get pvpResultWinGeneric;

  /// No description provided for @pvpResultBeatOpponent.
  ///
  /// In en, this message translates to:
  /// **'You defeated {opponentName}'**
  String pvpResultBeatOpponent(String opponentName);

  /// No description provided for @pvpResultScoresTied.
  ///
  /// In en, this message translates to:
  /// **'Both sides finished with the same score'**
  String get pvpResultScoresTied;

  /// No description provided for @pvpResultForfeitGeneric.
  ///
  /// In en, this message translates to:
  /// **'You left the match and forfeited.'**
  String get pvpResultForfeitGeneric;

  /// No description provided for @pvpResultForfeitOpponentWon.
  ///
  /// In en, this message translates to:
  /// **'You left the match. {opponentName} won.'**
  String pvpResultForfeitOpponentWon(String opponentName);

  /// No description provided for @pvpResultTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Keep going—you\'ve almost got it!'**
  String get pvpResultTryAgain;

  /// No description provided for @pvpResultLoadingServer.
  ///
  /// In en, this message translates to:
  /// **'Loading the result from the server...'**
  String get pvpResultLoadingServer;

  /// No description provided for @pvpLoadingResult.
  ///
  /// In en, this message translates to:
  /// **'Loading result...'**
  String get pvpLoadingResult;

  /// No description provided for @pvpWaitingServerFinalize.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the server to finalize the match...'**
  String get pvpWaitingServerFinalize;

  /// No description provided for @pvpResultUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Match result unavailable'**
  String get pvpResultUnavailableTitle;

  /// No description provided for @pvpResultUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'The match has ended. Try again later or continue.'**
  String get pvpResultUnavailableMessage;

  /// No description provided for @pvpMmr.
  ///
  /// In en, this message translates to:
  /// **'MMR'**
  String get pvpMmr;

  /// No description provided for @pvpCurrentMmr.
  ///
  /// In en, this message translates to:
  /// **'Current MMR'**
  String get pvpCurrentMmr;

  /// No description provided for @pvpNewRank.
  ///
  /// In en, this message translates to:
  /// **'New rank'**
  String get pvpNewRank;

  /// No description provided for @pvpRank.
  ///
  /// In en, this message translates to:
  /// **'Rank'**
  String get pvpRank;

  /// No description provided for @pvpRewardClaimed.
  ///
  /// In en, this message translates to:
  /// **'Reward claimed'**
  String get pvpRewardClaimed;

  /// No description provided for @pvpRewardsReceived.
  ///
  /// In en, this message translates to:
  /// **'REWARDS RECEIVED'**
  String get pvpRewardsReceived;

  /// No description provided for @pvpCoinReward.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1 {+1 Dewdrop} other {+{count} Dewdrops}}'**
  String pvpCoinReward(int count);

  /// No description provided for @pvpItemReward.
  ///
  /// In en, this message translates to:
  /// **'{quantity, plural, =1 {x1 item} other {x{quantity} items}}'**
  String pvpItemReward(int quantity);

  /// No description provided for @pvpClaimReward.
  ///
  /// In en, this message translates to:
  /// **'Claim reward'**
  String get pvpClaimReward;

  /// No description provided for @pvpContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get pvpContinue;

  /// No description provided for @pvpYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get pvpYou;

  /// No description provided for @pvpSprintMode.
  ///
  /// In en, this message translates to:
  /// **'SPRINT'**
  String get pvpSprintMode;

  /// No description provided for @pvpRaceProgress.
  ///
  /// In en, this message translates to:
  /// **'Race progress: {percent}%'**
  String pvpRaceProgress(int percent);

  /// No description provided for @pvpRaceGo.
  ///
  /// In en, this message translates to:
  /// **'GO!'**
  String get pvpRaceGo;

  /// No description provided for @pvpCloseRace.
  ///
  /// In en, this message translates to:
  /// **'Leave race'**
  String get pvpCloseRace;

  /// No description provided for @pvpMatchStatusWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get pvpMatchStatusWaiting;

  /// No description provided for @pvpMatchStatusCountdown.
  ///
  /// In en, this message translates to:
  /// **'Countdown'**
  String get pvpMatchStatusCountdown;

  /// No description provided for @pvpMatchStatusRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get pvpMatchStatusRunning;

  /// No description provided for @pvpMatchStatusSettling.
  ///
  /// In en, this message translates to:
  /// **'Finalizing'**
  String get pvpMatchStatusSettling;

  /// No description provided for @pvpMatchStatusFinished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get pvpMatchStatusFinished;

  /// No description provided for @pvpMatchStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get pvpMatchStatusCancelled;

  /// No description provided for @pvpTierMamDong.
  ///
  /// In en, this message translates to:
  /// **'Bronze Sprout'**
  String get pvpTierMamDong;

  /// No description provided for @pvpTierLaBac.
  ///
  /// In en, this message translates to:
  /// **'Silver Leaf'**
  String get pvpTierLaBac;

  /// No description provided for @pvpTierNuVang.
  ///
  /// In en, this message translates to:
  /// **'Golden Bud'**
  String get pvpTierNuVang;

  /// No description provided for @pvpTierHoaLam.
  ///
  /// In en, this message translates to:
  /// **'Indigo Flower'**
  String get pvpTierHoaLam;

  /// No description provided for @pvpTierTrangTim.
  ///
  /// In en, this message translates to:
  /// **'Purple Moon'**
  String get pvpTierTrangTim;

  /// No description provided for @pvpTierTinhLinhCauVong.
  ///
  /// In en, this message translates to:
  /// **'Rainbow Spirit'**
  String get pvpTierTinhLinhCauVong;

  /// No description provided for @pvpTierUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown rank'**
  String get pvpTierUnknown;
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
