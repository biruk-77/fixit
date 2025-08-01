// lib/services/app_string.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart'; // You WILL need to create this provider file

// --- Abstract Class for All Strings ---
// Defines the contract for all localizations
abstract class AppStrings {
  Locale get locale;

  String get appName;
  // --- General ---
  String get appTitle;
  String get highContrastTooltip;
  String get specifyInDescription;
  String get switchedToClientView;
  String get currency;
  String get availability;
  String get workerDetailPrice;
  String get workerDetailRequestQuote;
  String get viewImageButton;
  String get workerDetailDistanceUnknown;
  String get workerDetailHireButton;
  String get back;
  String get workerDetailDistance;
  String get workerDetailHireDialogContent;
  String distanceMeters(String meters);
  String distanceKilometers(String km);
  String hireWorker(String name);
  String get switchedToWorkerView;
  String get switchToWorkerViewTooltip;
  String get switchToClientViewTooltip;
  String get becomeWorkerTooltip;
  String get darkModeTooltip;
  String get languageToggleTooltip;
  Map<String, List<String>> get jobCategoriesAndSkills;
  String get errorInitializationFailed;
  String get errorCouldNotSavePrefs;
  // Inside your abstract class AppStrings { ... }

  String get viewButton;
  String get carouselViewTooltip;
  String get gridViewTooltip;
  String get distanceLabel;
  String get locationTitle;
  String get mapNotAvailable;
  String get mapErrorConnectivity;
  String get estimatedEtaLabel;
  String get viewOnMapButton;
  String get snackbarFailedToLaunchMap;
  String availableSlotsForDate(String date); // This is a method, not a getter
  String get noSlotsAvailable;
  String get bookSlotButton;
  String get selectTimeSlotButton;
  String get noInternetConnection;
  String get locationPermissionDenied;
  String get errorFetchingLocation;
  String get couldNotLoadVideo;
  String get videoLoadFailed;
  String get cannotPlayVideoNoInternet;
  String get reviewJobPaymentPrerequisite;
  String get performanceOverviewTitle;
  String get failedToMakeCall;
  String
      get submitReviewButton; // Ensure this is also present if missing from your abstract
  String get errorConnectivityCheck;
  String get errorActionFailed;
  String get errorCouldNotLaunchUrl;
  String get errorCouldNotLaunchDialer;
  String get successPrefsSaved;
  String get successSubscription;
  String get connectionRestored;
  String get noInternet;
  String get retryButton;
  String get errorGeneric;
  String get loading;
  String get generalCancel;
  String get generalLogout;
  String get clear;
  String get ok;
  String get notAvailable;
  String get notSet;

  // --- HomeScreen ---
  String helloUser(String userName);
  String get findExpertsTitle;
  String get yourJobFeedTitle;
  String get navHome;
  String get navPostJob;
  String get navProfile;
  String get navHistory;
  String get navFeed;
  String get navMyJobs;
  String get navSetup;
  String get appBarHome;
  String get appBarPostNewJob;
  String get appBarMyProfile;
  String get appBarJobHistory;
  String get appBarJobFeed;
  String get appBarMyJobs;
  String get appBarProfileSetup;
  String get themeTooltipLight;
  String get themeTooltipDark;
  String get searchHintProfessionals;
  String get searchHintJobs;
  String get featuredPros;
  String get featuredJobs;
  String get emptyStateProfessionals;
  String get emptyStateJobs;
  String get emptyStateDetails;
  String get refreshButton;
  String get fabPostJob;
  String get fabMyProfile;
  String get fabPostJobTooltip;
  String get fabMyProfileTooltip;
  String get filterOptionsTitle;
  String get filterCategory;
  String get filterLocation;
  String get workerDetailTabOverview;
  String get workerDetailTabAbout;
  String get filterJobStatus;
  String get filterResetButton;
  String get filterApplyButton;
  String get filtersResetSuccess;
  String workerCardJobsDone(int count);
  String workerCardYearsExp(int years);
  String get workerCardHire;
  String get jobCardView;
  String get jobStatusOpen;
  String get jobStatusAssigned;
  String get jobStatusCompleted;
  String get jobStatusUnknown;
  String get jobDateN_A;
  String get generalN_A;
  String get jobUntitled;
  String get jobNoDescription;
  String jobBudgetETB(String amount);
  String get timeAgoJustNow;
  String timeAgoMinute(int minutes);
  String timeAgoHour(int hours);
  String timeAgoDay(int days);
  String timeAgoWeek(int weeks);
  String timeAgoMonth(int months);
  String timeAgoYear(int years);

  // --- WorkerDetail Screen ---
  String workerDetailAbout(String name);
  String get workerDetailSkills;
  String get workerDetailAvailability;
  String workerDetailReviews(int count);
  String get workerDetailLeaveReview;
  String get workerDetailHireNow;
  String get workerDetailWorking;
  String get workerDetailCall;
  String get workerDetailSubmitReview;
  String get workerDetailShareProfileTooltip;
  String get workerDetailAddFavoriteTooltip;
  String get workerDetailRemoveFavoriteTooltip;
  String get workerDetailAvailable;
  String get workerDetailBooked;
  String get workerDetailSelectTime;
  String get workerDetailCancel;
  String get workerDetailAnonymous;
  String get emailNotVerifiedYet;
  String get errorCheckingVerification;
  String get errorResendingEmail;
  String get verificationScreenTitle;
  String get verificationScreenInfo;
  String get checkingStatusButton;
  String get signOutButton;
  String get resendingButton;
  String get resendEmailButton;
  String get checkVerificationButton;
  String get emailVerifiedSuccess;
  String get emailVerificationSent;
  String get workerDetailWriteReviewHint;
  String workerDetailReviewLengthCounter(int currentLength, int maxLength);
  String get workerDetailNoReviews;
  String get workerDetailNoSkills;
  String get workerDetailNoAbout;
  String get workerDetailShowAll;
  String get workerDetailShowLess;
  String get workermoneyempty;
  String get workerDetailTabDetails;
  String get workerDetailTabPortfolio;
  String get workerDetailTabReviews;
  String get workerCardRating;
  String get workerCardJobsDoneShort;
  String get workerCardYearsExpShort;
  String get workerDetailHireDialogQuick;
  String get workerDetailHireDialogQuickSub;
  String get workerDetailHireDialogFull;
  String get workerDetailHireDialogFullSub;
  String get workerDetailVideoIntro;
  String get workerDetailGallery;
  String get workerDetailCertifications;
  String get workerDetailRatingBreakdown;
  String get workerDetailNoGallery;
  String get workerDetailNoCerts;
  String get generalClose;
  String workerDetailShareMessage(
      String workerName, String profession, String phone);

  // --- Notifications ---
  String get notificationTitle;

  // --- Snackbars ---
  String get snackErrorLoading;
  String get snackErrorSubmitting;
  String get snackErrorGeneric;
  String get snackSuccessReviewSubmitted;
  String get snackPleaseLogin;
  String get snackFavoriteAdded;
  String get snackFavoriteRemoved;
  String get snackPhoneNumberCopied;
  String get snackPhoneNumberNotAvailable;
  String get snackErrorCheckFavorites;
  String get snackErrorUpdateFavorites;
  String get snackErrorContactInfo;
  String get snackErrorLoadingProfile;
  String get snackReviewMissing;
  String get snackWorkerNotFound;
  String get createJobSnackbarErrorWorker;
  String get createJobSnackbarErrorUpload;
  String get createJobSnackbarErrorUploadPartial;
  String get createJobSnackbarErrorForm;
  String get createJobSnackbarSuccess;
  String get createJobSnackbarError;
  String createJobSnackbarFileSelected(int count);
  String get createJobSnackbarFileCancelled;
  String get createJobSnackbarErrorPick;
  String get snackErrorCameraNotAvailable;
  String get snackErrorCameraPermission;
  String get snackErrorGalleryPermission;
  String get snackErrorReadFile;
  String get snackSkippingUnknownType;
  String get errorUserNotLoggedIn;
  String get googleSignInCancelled;
  String get googleSignInAccountExists;

  //---- profile ---
  String get profileNotFound;
  String get profileDataUnavailable;
  String get profileEditAvatarHint;
  String get snackSuccessProfileUpdated;
  String get profileStatsTitleWorker;
  String get profileStatsTitleClient;
  String get profileStatJobsCompleted;
  String get profileStatRating;
  String get profileStatExperience;
  String get profileStatReviews;
  String get profileStatJobsPosted;
  String get profileNeedProfileForHistory;
  String get profileJobHistoryTitle;
  String get viewAllButton;
  String get profileNoJobHistory;
  String get workerNameLabel;
  String get profileSettingsTitle;
  String get settingsNotificationsTitle;
  String get settingsNotificationsSubtitle;
  String get settingsPaymentTitle;
  String get settingsPaymentSubtitle;
  String get settingsPrivacyTitle;
  String get settingsPrivacySubtitle;
  String get settingsAccountTitle;
  String get settingsAccountSubtitle;
  String get settingsHelpTitle;
  String get settingsHelpSubtitle;
  String get settingsNotificationsContent;
  String get settingsPaymentContent;
  String get settingsPrivacyContent;
  String get settingsAccountContent;
  String get settingsHelpContent;
  String get profileEditButton;
  String get dialogEditClientContent;
  String get dialogFeatureUnderDevelopment;

  // --- Dialogs ---
  String get phoneDialogTitle;
  String get phoneDialogCopy;
  String get phoneDialogClose;

  // --- Job Detail Screen ---
  String get jobDetailAppBarTitle;
  String get jobDetailLoading;
  String get jobDetailErrorLoading;
  String get jobDetailStatusLabel;
  String get jobDetailBudgetLabel;
  String get jobDetailLocationLabel;
  String get jobDetailPostedDateLabel;
  String get jobDetailScheduledDateLabel;
  String get jobDetailDescriptionLabel;
  String get jobDetailAttachmentsLabel;
  String get jobDetailNoAttachments;
  String get jobDetailAssignedWorkerLabel;
  String get jobDetailNoWorkerAssigned;
  String get jobDetailViewWorkerProfile;
  String get jobDetailApplicantsLabel;
  String get jobDetailNoApplicantsYet;
  String get jobDetailViewApplicantsButton;
  String get jobDetailActionApply;
  String get jobDetailActionApplying;
  String get jobDetailActionApplied;
  String get jobDetailActionCancelApplication;
  String get jobDetailActionMarkComplete;
  String get jobDetailActionContactClient;
  String get jobDetailActionPayNow;
  String get jobDetailActionMessageWorker;
  String get jobDetailActionLeaveReview;
  String get jobDetailActionPostSimilar;
  String get jobDetailActionShare;
  String get jobDetailDeleteConfirmTitle;
  String get jobDetailDeleteConfirmContent;
  String get jobDetailDeleteConfirmKeep;
  String get jobDetailDeleteConfirmDelete;
  String get jobDetailErrorAssigningWorker;
  String get jobDetailSuccessWorkerAssigned;
  String get jobDetailErrorApplying;
  String get jobDetailSuccessApplied;
  String get jobDetailErrorDeleting;
  String get jobDetailSuccessDeleted;
  String get jobDetailErrorMarkingComplete;
  String get jobDetailSuccessMarkedComplete;
  String get jobDetailFeatureComingSoon;
  String get jobDetailApplicantHireButton;
  String get clientNameLabel;

  // --- Create Job Screen ---
  String get createJobCategoryLabel;
  String get createJobErrorCategory;
  String get createJobErrorSkill;
  String get attachOptionGallery;
  String get attachOptionCamera;
  String get attachOptionFile;
  String get attachOptionCancel;
  String get attachTitle;
  String get createJobCategoryHint;
  String get createJobSkillLabel;
  String get createJobSkillHint;
  String get createJobCalendarTitle;
  String get createJobCalendarCancel;
  String get createJobAppBarTitle;
  String get createJobSelectedWorkerSectionTitle;
  String get createJobDetailsSectionTitle;
  String get createJobOptionalSectionTitle;
  String get createJobTitleLabel;
  String get createJobTitleHint;
  String get createJobTitleError;
  String get createJobDescLabel;
  String get createJobDescHint;
  String get createJobDescErrorEmpty;
  String get createJobDescErrorShort;
  String get createJobBudgetLabel;
  String get createJobBudgetHint;
  String get createJobBudgetErrorEmpty;
  String get createJobBudgetErrorNaN;
  String get createJobBudgetErrorPositive;
  String get createJobLocationLabel;
  String get createJobLocationHint;
  String get createJobLocationError;
  String get createJobScheduleLabelOptional;
  String createJobScheduleLabelSet(String date);
  String get createJobScheduleSub;
  String get createJobAttachmentsLabelOptional;
  String get createJobAttachmentsSubAdd;
  String createJobAttachmentsSubCount(int count);
  String get createJobUrgentLabel;
  String get createJobUrgentSub;
  String get createJobButtonPosting;
  String get createJobButtonPost;
  String get registerErrorProfessionRequired;
  String get errorPasswordShort;

  // --- Job Dashboard Screen ---
  String get dashboardTitleDefault;
  String get dashboardTitleWorker;
  String get dashboardTitleClient;
  String get tabWorkerAssigned;
  String get tabWorkerApplied;
  String get tabWorkerActive;
  String get tabClientPosted;
  String get tabClientApplications;
  String get tabClientRequests;
  String get filterAll;
  String get filterOpen;
  String get filterPending;
  String get filterAssigned;
  String get filterAccepted;
  String get filterInProgress;
  String get filterStartedWorking;
  String get filterCompleted;
  String get filterCancelled;
  String get filterRejected;
  String get filterClosed;
  String get emptyStateWorkerAssigned;
  String get emptyStateWorkerApplied;
  String get emptyStateWorkerActive;
  String get emptyStateClientPosted;
  String get emptyStateClientApplications;
  String get emptyStateClientRequests;
  String get emptyStateJobsFilteredTitle;
  String get emptyStateJobsFilteredSubtitle;
  String get emptyStateGeneralSubtitle;
  String get noApplicantsSubtitle;
  String get buttonAccept;
  String get buttonStartWork;
  String get buttonComplete;
  String get buttonViewApplicants;
  String get buttonChatClient;
  String get buttonChatWorker;
  String get buttonPayWorker;
  String get buttonCancelJob;
  String get viewProfileButton;
  String get viewAllApplicantsButton;
  String get buttonChat;
  String get jobAcceptedSuccess;
  String get jobAcceptedError;
  String get jobStartedSuccess;
  String get jobStartedError;
  String get applicantLoadError;
  String applicantsForJob(String jobTitle);
  String get applicantNotFound;
  String workerCardDistanceAway(String km);
  String get skillsLabel;
  String get distanceInKm;
  String get aboutLabel;
  String get priceRangeLabel;
  String get experienceLabel;
  String get phoneLabel;
  String get timelinePending;
  String get timelineInProgress;
  String get timelineCompleted;
  String jobsCompleted(int count);
  String yearsExperience(int years);
  String applicantCount(int count);
  String formatTimeAgo(DateTime date);

  // --- Login Screen ---
  String get loginTitle;
  String get loginWelcome;
  String get loginEmailLabel;
  String get loginEmailHint;
  String get loginPasswordLabel;
  String get loginPasswordHint;
  String get loginRememberMe;
  String get loginForgotPassword;
  String get loginButton;
  String get loginNoAccount;
  String get loginSignUpLink;
  String get loginErrorUserNotFound;
  String get loginErrorWrongPassword;
  String get loginErrorInvalidEmail;
  String get loginErrorUserDisabled;
  String get loginErrorTooManyRequests;
  String get loginErrorUnknown;
  String get loginWithGoogle;
  String get loginErrorGoogleSignIn;

  // --- Register Screen ---
  String get registerTitle;
  String get registerSubtitle;
  String get registerUserTypePrompt;
  String get registerUserTypeClient;
  String get registerUserTypeWorker;
  String get registerProfessionLabel;
  String get registerProfessionHint;
  String get registerFullNameLabel;
  String get registerFullNameHint;
  String get registerPhoneLabel;
  String get registerPhoneHint;
  String get registerConfirmPasswordLabel;
  String get registerConfirmPasswordHint;
  String get registerButton;
  String get registerHaveAccount;
  String get registerSignInLink;
  String get registerErrorPasswordMismatch;
  String get registerErrorWeakPassword;
  String get registerErrorEmailInUse;
  String get verificationScreenHeader;
  String get registerErrorInvalidEmailRegister;
  String get registerErrorUnknown;
  String get registerWithGoogle;
  String get registerSuccess;
  String get registerNavigateToSetup;
  String get registerNavigateToHome;

  // --- Forgot Password Screen (if needed) ---
  String get forgotPasswordTitle;
  String get forgotPasswordInstructions;
  String get forgotPasswordButton;
  String get forgotPasswordSuccess;
  String get forgotPasswordError;

  // --- Helper Methods (To be implemented in subclasses) ---
  String getStatusName(String key);
  IconData? getFilterIcon(String key);
  String getFilterName(String key);
  IconData? getEmptyStateIcon(String key);
  String errorFieldRequired(String fieldName);
  String getUserTypeDisplayName(String key);

  // --- Payment Screen (Added from your implementation) ---
  String get paymentScreenTitle;
  String get paymentMethods;
  String get paymentAddMethod;
  String get paymentNoMethod;

  // --- NEWLY ADDED based on errors for Job Dashboard ---
  String errorLoadingData(String errorDetails);
  String errorLoadingJobs(String errorDetails);
  String get jobCancelledSuccess;
  String errorCancellingJob(String errorDetails);
  String get applicationAcceptedSuccess;
  String errorAcceptingApplication(String errorDetails);
  String errorAcceptingJob(String errorDetails);
  String errorStartingWork(String errorDetails);
  String get jobCompletedSuccess;
  String errorCompletingJob(String errorDetails);
  String get jobStatusPending;
  String get jobStatusActive;
  String get jobStatusInProgress;
  String get jobStatusCancelled;
  String get jobStatusRejected;
  String get jobStatusClosed;
  String get jobStatusStartedWorking;
  String get myWorkDashboard;
  String get myJobsDashboard;
  String get assignedJobsTab;
  String get myApplicationsTab;
  String get activeWorkTab;
  String get myPostedJobsTab;
  String get applicationsTab;
  String get myRequestsTab;
  String assignedJobsCount(int count);
  String get noAssignedJobsTitle;
  String get noAssignedJobsSubtitle;
  String jobsCount(int count);
  String get noApplicationsYetTitle;
  String get noApplicationsYetSubtitleWorker;
  String activeJobsCount(int count);
  String get noActiveWorkTitle;
  String get noActiveWorkSubtitle;
  String get noPostedJobsTitle;
  String get noPostedJobsSubtitle;
  String get noApplicationsYetSubtitleClient;
  String get noJobRequestsTitle;
  String get noJobRequestsSubtitle;
  String postedTimeAgo(String timeAgo);
  String applicantsCount(int count);
  String get waitingForWorkerToAccept;
  String get yourWorkIsPending;
  String get payButton;
  String get viewDetailsButton;
  String get acceptButton;
  String get startButton;
  String get completeButton;
  String get manageButton;
  String get postAJobButton;
  String jobApplicationsScreenTitle(String jobTitle);

  // Strings used in JobDashboardScreen directly
  String get myWorkDashboardText;
  String get myJobsDashboardText;
  String get assignedJobsText;
  String get myApplicationsText;
  String get activeWorkText;
  String get myPostedJobsText;
  String get applicationsText;
  String get myRequestsText;
  String get allText;
  String get openText;
  String get pendingText;
  String get acceptedText;
  String get completedText;
  String get closedText;
  String get cancelledText;
  String get rejectedText;
  String get inProgressText;
  String get jobText;
  String get jobsText;
  String get assignedJobText;
  String get assignedJobsPluralText;
  String get activeJobText;
  String get activeJobsPluralText;
  String get postedText;
  String get agoText;
  String get applicantText;
  String get applicantsText;
  String get noApplicantsText;
  String get waitingForWorkerToAcceptText;
  String get yourWorkingIsOnPendingText;
  String get payText;
  String get viewDetailsText;
  String get rateText;
  String get manageText;
  String get postAJobText;
  String get noAssignedJobsYetText;
  String get whenJobsAreAssignedToYouText;
  String get noApplicationsYetText;
  String get jobsYouApplyForWillAppearHereText;
  String get noActiveWorkText;
  String get yourActiveJobsWillAppearHereText;
  String get noPostedJobsYetText;
  String get tapThePlusButtonToPostYourFirstJobText;
  String get noJobRequestsText;
  String get yourPersonalJobRequestsWillAppearHereText;
  String get aboutText;
  String get skillsText;
  String get viewProfileText;
  String get acceptText;
  String get declineText;
  String get applicantsForText;
  String get couldNotLoadApplicantText;
  String get moreApplicantsText;
  String get jobCancelledSuccessfullyText;
  String get applicationAcceptedSuccessfullyText;
  String get jobAcceptedSuccessfullyText;
  String get jobMarkedAsCompletedSuccessfullyText;
  String get workStartedSuccessfullyText;
  String get applicationDeclinedSuccessfullyText;
  String get loadingText;
  String get professionalSetupTitle;
  String get professionalSetupSubtitle;
  String get professionalSetupSaveAll;
  String get professionalSetupSaving;

  // SnackBar Messages
  String get professionalSetupErrorNotLoggedIn;
  String professionalSetupErrorLoading(String error);
  String get professionalSetupErrorFormValidation;
  String get professionalSetupInfoUploadingMedia;
  String get professionalSetupInfoSavingData;
  String get professionalSetupSuccess;
  String professionalSetupErrorSaving(String error);
  String get professionalSetupErrorLocationDisabled;
  String get professionalSetupErrorLocationDenied;
  String get professionalSetupErrorLocationPermanentlyDenied;
  String professionalSetupErrorGettingLocation(String error);
  String get professionalSetupErrorMaxImages;

  // Wide Layout Navigation
  String get professionalSetupNavHeader;
  String get professionalSetupNavBasic;
  String get professionalSetupNavExpertise;
  String get professionalSetupNavLocation;
  String get professionalSetupNavShowcase;
  String get professionalSetupNavRates;

  // Profile Strength Indicator
  String get professionalSetupStrengthTitle;
  String get professionalSetupStrengthIncomplete;
  String get professionalSetupStrengthGood;
  String get professionalSetupStrengthExcellent;

  // Section: Basic Info
  String get professionalSetupBasicTitle;
  String get professionalSetupBasicSubtitle;
  String get professionalSetupLabelName;
  String get professionalSetupHintName;
  String get professionalSetupLabelProfession;
  String get professionalSetupHintProfession;
  String get professionalSetupLabelPhone;
  String get professionalSetupHintPhone;
  String professionalSetupValidatorRequired(String label);

  // Section: Expertise
  String get professionalSetupExpertiseTitle;
  String get professionalSetupExpertiseSubtitle;
  String get professionalSetupLabelExperience;
  String get professionalSetupHintExperience;
  String get professionalSetupLabelBio;
  String get professionalSetupHintBio;

  // Section: Skills
  String get professionalSetupSkillsDialogTitle;
  String get professionalSetupSkillsDialogSubtitle;
  String get professionalSetupSkillsDialogCancel;
  String get professionalSetupSkillsDialogConfirm;
  String get professionalSetupSkillsEmptyButton;
  String get professionalSetupSkillsEditButton;
  String get professionalSetupSkillsSelectedTitle;

  // Section: Location
  String get professionalSetupLocationTitle;
  String get professionalSetupLocationSubtitle;
  String get professionalSetupLabelCity;
  String get professionalSetupHintCity;
  String get professionalSetupTooltipGetLocation;
  String get professionalSetupServiceRadiusTitle;
  String get professionalSetupServiceRadiusSubtitle;

  // Section: Showcase
  String get professionalSetupShowcaseTitle;
  String get professionalSetupShowcaseSubtitle;
  String get professionalSetupVideoTitle;
  String get professionalSetupVideoEmptyButton;
  String get professionalSetupGalleryTitle;
  String get professionalSetupCertificationsTitle;
  String get professionalSetupImageEmptyButton;

  // Section: Operations
  String get professionalSetupOperationsTitle;
  String get professionalSetupOperationsSubtitle;
  String get professionalSetupPricingTitle;
  String get professionalSetupLabelRate;
  String get professionalSetupAvailabilityTitle;
  String get professionalSetupAvailabilityTo;
}

// ===========================================================
//                  English Implementation
// ===========================================================
class AppStringsEn implements AppStrings {
  @override
  Locale get locale => const Locale('en');

  // --- General ---
  @override
  String get appName => " WORKS";
  @override
  String get appTitle => "FixIt";
  @override
  String get specifyInDescription => 'Specify in Description';
  @override
  String get highContrastTooltip => "High Contrast Mode";
  @override
  String get darkModeTooltip => "Toggle Dark Mode";
  @override
  String get languageToggleTooltip => "Switch Language";

  @override
  Map<String, List<String>> get jobCategoriesAndSkills => {
        'Plumbing': [
          'Leak Repair',
          'Pipe Installation',
          'Drain Cleaning',
          'Faucet Fix',
          'Toilet Repair',
          'Water Heater'
        ],
        'Electrical': [
          'Wiring',
          'Outlet Repair',
          'Lighting Installation',
          'Circuit Breaker',
          'Fan Installation',
          'Appliance Repair'
        ],
        'Cleaning': [
          'Home Cleaning',
          'Office Cleaning',
          'Deep Cleaning',
          'Window Washing',
          'Carpet Cleaning'
        ],
        'Painting': [
          'Interior Painting',
          'Exterior Painting',
          'Wall Preparation',
          'Furniture Painting'
        ],
        'Carpentry': [
          'Furniture Assembly',
          'Door Repair',
          'Shelf Installation',
          'Wood Repair'
        ],
        'Gardening': ['Lawn Mowing', 'Planting', 'Weeding', 'Tree Trimming'],
        'Moving': ['Loading/Unloading', 'Packing', 'Furniture Moving'],
        'Handyman': [
          'General Repairs',
          'Mounting TV',
          'Picture Hanging',
          'Minor Fixes'
        ],
        'Other': ['Specify in Description']
      };
  @override
  String get errorInitializationFailed => "Initialization failed";
  @override
  String get errorCouldNotSavePrefs => "Could not save preferences";
  @override
  String get errorConnectivityCheck => "Could not check connectivity";
  @override
  String get errorActionFailed => "Action failed. Please try again.";
  @override
  String get errorCouldNotLaunchUrl => "Could not launch URL.";
  @override
  String get errorCouldNotLaunchDialer => "Could not launch dialer.";
  @override
  String get successPrefsSaved => "Preference saved.";
  @override
  String get switchedToClientView => "Switched to Client View";
  @override
  String get switchedToWorkerView => "Switched to Worker View";
  @override
  String get switchToWorkerViewTooltip => "Switch to Worker View";
  @override
  String get switchToClientViewTooltip => "Switch to Client View";
  @override
  String get becomeWorkerTooltip => "Set up Professional Profile";
  @override
  String get successSubscription => "Thank you for subscribing!";
  @override
  String get connectionRestored => "Internet connection restored.";
  @override
  String get noInternet => "No internet connection.";
  @override
  String get retryButton => "Retry";
  @override
  String get errorGeneric => "An error occurred. Please try again.";
  @override
  String get distanceInKm => "meter";
  @override
  String get loading => "Loading...";
  @override
  String get generalCancel => "Cancel";
  @override
  String get generalLogout => "Logout";
  @override
  String get emailVerificationSent => "Verification email sent.";
  @override
  String get currency => "ETB";
  @override
  String workerDetailShareMessage(
          String workerName, String profession, String phone) =>
      'Check out this professional on FixIt: $workerName ($profession). Contact: $phone';
  @override
  String get emailVerifiedSuccess => "Email successfully verified!";
  @override
  String get emailNotVerifiedYet => "Email not verified yet.";
  @override
  String get errorCheckingVerification => "Error checking verification status.";
  @override
  String get verificationScreenTitle => "Email Verification";
  @override
  String get verificationScreenHeader => "Verify Your Email";
  @override
  String get verificationScreenInfo =>
      "Please verify your email to continue registration.";
  @override
  String get checkingStatusButton => "Checking...";
  @override
  String get checkVerificationButton => "Check Verification";
  @override
  String get resendingButton => "Resending...";
  @override
  String get resendEmailButton => "Resend Email";
  @override
  String get signOutButton => "Sign Out";
  @override
  String get errorResendingEmail => "Error resending verification email.";
  @override
  String get clear => 'Clear';
  @override
  String get ok => 'OK';
  @override
  String get notAvailable => "N/A";
  @override
  String get notSet => "Not Set";
  @override
  String get generalClose => "Close";

  // --- HomeScreen ---
  @override
  String helloUser(String userName) => "Hello, $userName!";
  @override
  String get findExpertsTitle => "Find Experts";
  @override
  String get yourJobFeedTitle => "Your Job Feed";
  @override
  String get navHome => "Home";
  @override
  String get navPostJob => "Post Job";
  @override
  String get navProfile => "Profile";
  @override
  String get navHistory => "History";
  @override
  String get navFeed => "Feed";
  @override
  String get navMyJobs => "My Jobs";
  @override
  String get navSetup => "Setup";
  @override
  String get appBarHome => "Home";
  @override
  String get appBarPostNewJob => "Post New Job";
  @override
  String get appBarMyProfile => "My Profile";
  @override
  String get appBarJobHistory => "Job History";
  @override
  String get appBarJobFeed => "Job Feed";
  @override
  String get appBarMyJobs => "My Jobs";
  @override
  String get appBarProfileSetup => "Profile Setup";
  @override
  String get themeTooltipLight => "Switch to Light Mode";
  @override
  String get themeTooltipDark => "Switch to Dark Mode";
  @override
  String get searchHintProfessionals => "Search Professionals, Skills...";
  @override
  String get searchHintJobs => "Search Jobs, Keywords...";
  @override
  String get featuredPros => "⭐ Top Rated Pros";
  @override
  String get featuredJobs => "🚀 Recent Open Jobs";
  @override
  String get emptyStateProfessionals => "No Professionals Found";
  @override
  String get emptyStateJobs => "No Jobs Match Your Criteria";
  @override
  String get emptyStateDetails =>
      "Try adjusting your search terms or clearing the filters.";
  @override
  String get refreshButton => "Refresh";
  @override
  String get fabPostJob => "Post New Job";
  @override
  String get fabMyProfile => "My Profile";
  @override
  String get fabPostJobTooltip => "Create a new job posting";
  @override
  String get fabMyProfileTooltip => "View or edit your professional profile";
  @override
  String get filterOptionsTitle => "Filter Options";
  @override
  String get filterCategory => "Category / Profession";
  @override
  String get filterLocation => "Location";
  @override
  String get filterJobStatus => "Job Status";
  @override
  String get filterResetButton => "Reset";
  @override
  String get filterApplyButton => "Apply Filters";
  @override
  String get filtersResetSuccess => "Filters reset";
  @override
  String workerCardJobsDone(int count) => "$count Jobs Done";
  @override
  String workerCardYearsExp(int years) => "$years yrs Exp";
  @override
  String get workerCardHire => "Hire";
  @override
  String get jobCardView => "View Details";
  @override
  String get jobStatusOpen => "Open";
  @override
  String get jobStatusAssigned => "Assigned";
  @override
  String get jobStatusCompleted => "Completed";
  @override
  String get jobStatusUnknown => "Unknown";
  @override
  String get jobDateN_A => "Date N/A";
  @override
  String get generalN_A => "N/A";
  @override
  String get jobUntitled => "Untitled Job";
  @override
  String get jobNoDescription => "No description provided.";
  @override
  String jobBudgetETB(String amount) => "$amount ETB";
  @override
  String get timeAgoJustNow => "Just now";
  @override
  String timeAgoMinute(int minutes) => "${minutes}m ago";
  @override
  String timeAgoHour(int hours) => "${hours}h ago";
  @override
  String timeAgoDay(int days) => "${days}d ago";
  @override
  String timeAgoWeek(int weeks) => "${weeks}w ago";
  @override
  String timeAgoMonth(int months) => "${months}mo ago";
  @override
  String timeAgoYear(int years) => "${years}y ago";

  // --- WorkerDetail Screen ---
  @override
  String workerDetailAbout(String name) => "About $name";
  @override
  String get workerDetailSkills => "Skills";
  @override
  String get workerDetailAvailability => "Availability";
  @override
  String workerDetailReviews(int count) => "Reviews ($count)";
  @override
  String get workerDetailLeaveReview => "Leave a Review";
  @override
  String get workerDetailHireNow => "Hire Now";
  @override
  String get workerDetailWorking => "Working";
  @override
  String get workerDetailPrice => "Starts From";
  @override
  String get workerDetailRequestQuote => "Request a Quote";
  @override
  String get workerDetailDistanceUnknown => 'Distance unknown';
  @override
  String get workerDetailHireButton => 'Hire Worker';
  @override
  String get back => 'Back';
  @override
  String get workerDetailDistance => 'Distance';
  @override
  String get workerDetailHireDialogContent =>
      "Choose the best way to hire this professional.";
  @override
  String distanceMeters(String meters) => '$meters m';
  @override
  String distanceKilometers(String km) => '$km km';
  @override
  String hireWorker(String name) => 'Hire $name';
  @override
  String get workerDetailCall => "Call";
  @override
  String get workerDetailSubmitReview => "Submit Review";
  @override
  String get workerDetailShareProfileTooltip => "Share Profile";
  @override
  String get workerDetailAddFavoriteTooltip => "Add Favorite";
  @override
  String get workerDetailRemoveFavoriteTooltip => "Remove Favorite";
  @override
  String get workerDetailAvailable => "Available";
  @override
  String get workerDetailBooked => "Booked";
  @override
  String get workerDetailSelectTime => "Select Time Slot";
  @override
  String get workerDetailCancel => "Cancel";
  @override
  String get workerDetailAnonymous => "Anonymous";
  @override
  String get profileNotFound => "Profile not found.";
  @override
  String get profileDataUnavailable => "Profile data unavailable.";
  @override
  String get profileEditAvatarHint => "Tap to edit profile avatar";
  @override
  String get snackSuccessProfileUpdated => "Profile updated successfully!";
  @override
  String get profileStatsTitleWorker => "Profile Stats";
  @override
  String get profileStatsTitleClient => "Profile Stats";
  @override
  String get profileStatJobsCompleted => "Jobs Completed";
  @override
  String get profileStatRating => "Rating";
  @override
  String get profileStatExperience => "Experience";
  @override
  String get profileStatReviews => "Reviews";
  @override
  String get profileStatJobsPosted => "Jobs Posted";
  @override
  String get profileNeedProfileForHistory =>
      "You need a profile for job history.";
  @override
  String get profileJobHistoryTitle => "Job History";
  @override
  String get viewAllButton => "View All";
  @override
  String get profileNoJobHistory => "No job history found.";
  @override
  String get workerNameLabel => "Worker Name";
  @override
  String get profileSettingsTitle => "Settings";
  @override
  String get settingsNotificationsTitle => "Notifications";
  @override
  String get settingsNotificationsSubtitle => "Notifications settings";
  @override
  String get settingsPaymentTitle => "Payment";
  @override
  String get settingsPaymentSubtitle => "Payment settings";
  @override
  String get settingsPrivacyTitle => "Privacy";
  @override
  String get settingsPrivacySubtitle => "Privacy settings";
  @override
  String get settingsAccountTitle => "Account";
  @override
  String get settingsAccountSubtitle => "Account settings";
  @override
  String get availability => "Available";
  @override
  String get settingsHelpTitle => "Help";
  @override
  String get settingsHelpSubtitle => "Help and support";
  @override
  String get settingsNotificationsContent => "Notifications content";
  @override
  String get settingsPaymentContent => "Payment content";
  @override
  String get settingsPrivacyContent => "Privacy content";
  @override
  String get settingsAccountContent => "Account content";
  @override
  String get settingsHelpContent => "Help content";
  @override
  String get profileEditButton => "Edit Profile";
  @override
  String get dialogEditClientContent => "Edit client content";
  @override
  String get dialogFeatureUnderDevelopment => "Feature under development";
  @override
  String get workerDetailWriteReviewHint => "Share your experience...";
  @override
  String workerDetailReviewLengthCounter(int currentLength, int maxLength) =>
      "$currentLength/$maxLength";
  @override
  String get workerDetailNoReviews => "No reviews yet.";
  @override
  String get workerDetailNoSkills => "No skills listed.";
  @override
  String get workerDetailNoAbout => "No details provided.";
  @override
  String get workerDetailShowAll => "Show All";
  @override
  String get workerDetailShowLess => "Show Less";
  @override
  String get workermoneyempty => "Not set";
  @override
  String get workerDetailTabDetails => "Details";
  @override
  String get workerDetailTabPortfolio => "Portfolio";
  @override
  String get workerDetailTabReviews => "Reviews";
  @override
  String get workerCardRating => "Rating";
  @override
  String get workerCardJobsDoneShort => "Jobs Done";
  @override
  String get workerCardYearsExpShort => "Years Exp";
  @override
  String get workerDetailHireDialogQuick => "Quick Job Request";
  @override
  String get workerDetailHireDialogQuickSub =>
      "For simple, straightforward tasks.";
  @override
  String get workerDetailHireDialogFull => "Full Job Form";
  @override
  String get workerDetailHireDialogFullSub =>
      "For detailed jobs with specific requirements.";
  @override
  String get workerDetailVideoIntro => "Video Introduction";
  @override
  String get workerDetailGallery => "Work Gallery";
  @override
  String get workerDetailCertifications => "Licenses & Certifications";
  @override
  String get workerDetailRatingBreakdown => "Rating Breakdown";
  @override
  String get workerDetailNoGallery =>
      "No gallery images have been uploaded yet.";
  @override
  String get workerDetailNoCerts => "No certifications have been uploaded yet.";

  // --- Notifications ---
  @override
  String get notificationTitle => "Notifications";

  // --- Snackbars ---
  @override
  String get snackErrorLoading => "Error loading data.";
  @override
  String get snackErrorSubmitting => "Failed to submit.";
  @override
  String get snackErrorGeneric => "An error occurred. Please try again.";
  @override
  String get snackSuccessReviewSubmitted => "Review submitted successfully!";
  @override
  String get snackPleaseLogin => "Please log in to continue.";
  @override
  String get snackFavoriteAdded => "Added to favorites!";
  @override
  String get snackFavoriteRemoved => "Removed from favorites";
  @override
  String get snackPhoneNumberCopied => "Phone number copied!";
  @override
  String get snackPhoneNumberNotAvailable => "Phone number not available.";
  @override
  String get snackErrorCheckFavorites => "Error checking favorites.";
  @override
  String get snackErrorUpdateFavorites => "Could not update favorites.";
  @override
  String get snackErrorContactInfo => "Error getting contact info.";
  @override
  String get snackErrorLoadingProfile => "Error loading your profile.";
  @override
  String get snackReviewMissing => "Please provide both a rating and comment.";
  @override
  String get snackWorkerNotFound => "Worker profile not found.";
  @override
  String get createJobSnackbarErrorWorker =>
      'Error loading worker details. Please try again.';
  @override
  String get createJobSnackbarErrorUpload =>
      'Error uploading attachments. Please try again.';
  @override
  String get createJobSnackbarErrorUploadPartial =>
      'Some attachments failed to upload.';
  @override
  String get createJobSnackbarErrorForm => 'Please fix the errors in the form.';
  @override
  String get createJobSnackbarSuccess => 'Job posted successfully!';
  @override
  String get createJobSnackbarError =>
      'Failed to create job. Please try again.';
  @override
  String createJobSnackbarFileSelected(int count) => '$count file(s) selected.';
  @override
  String get createJobSnackbarFileCancelled => 'File selection cancelled.';
  @override
  String get createJobSnackbarErrorPick =>
      'Error picking files. Please try again.';
  @override
  String get snackErrorCameraNotAvailable =>
      'Camera not available on this device.';
  @override
  String get snackErrorCameraPermission =>
      'Camera permission denied. Please enable it in settings.';
  @override
  String get snackErrorGalleryPermission =>
      'Gallery permission denied. Please enable it in settings.';
  @override
  String get snackErrorReadFile => 'Failed to read file data.';
  @override
  String get snackSkippingUnknownType => 'Skipping unknown file type.';
  @override
  String get errorUserNotLoggedIn => "User not logged in.";
  @override
  String get googleSignInCancelled => "Google Sign-In cancelled.";
  @override
  String get googleSignInAccountExists =>
      "Account exists with different credentials. Try logging in differently.";

  // --- Dialogs ---
  @override
  String get phoneDialogTitle => "Contact Number";
  @override
  String get phoneDialogCopy => "Copy Number";
  @override
  String get phoneDialogClose => "Close";

  // --- Job Detail Screen ---
  @override
  String get jobDetailAppBarTitle => "Job Details";
  @override
  String get jobDetailLoading => "Loading Job Details...";
  @override
  String get jobDetailErrorLoading => "Error loading job details.";
  @override
  String get jobDetailStatusLabel => "Status";
  @override
  String get jobDetailBudgetLabel => "Budget";
  @override
  String get jobDetailLocationLabel => "Location";
  @override
  String get jobDetailPostedDateLabel => "Posted On";
  @override
  String get jobDetailScheduledDateLabel => "Scheduled For";
  @override
  String get jobDetailDescriptionLabel => "Description";
  @override
  String get jobDetailAttachmentsLabel => "Attachments";
  @override
  String get jobDetailNoAttachments => "No attachments provided.";
  @override
  String get jobDetailAssignedWorkerLabel => "Assigned Professional";
  @override
  String get jobDetailNoWorkerAssigned => "No professional assigned yet.";
  @override
  String get jobDetailViewWorkerProfile => "View Profile";
  @override
  String get jobDetailApplicantsLabel => "Applicants";
  @override
  String get jobDetailNoApplicantsYet => "No applications received yet.";
  @override
  String get jobDetailViewApplicantsButton => "View Applicants";
  @override
  String get jobDetailActionApply => "Apply for This Job";
  @override
  String get jobDetailActionApplying => "Applying...";
  @override
  String get jobDetailActionApplied => "Application Submitted";
  @override
  String get jobDetailActionCancelApplication => "Cancel Application";
  @override
  String get jobDetailActionMarkComplete => "Mark as Completed";
  @override
  String get jobDetailActionContactClient => "Contact Client";
  @override
  String get jobDetailActionPayNow => "Proceed to Payment";
  @override
  String get jobDetailActionMessageWorker => "Message Professional";
  @override
  String get jobDetailActionLeaveReview => "Leave a Review";
  @override
  String get jobDetailActionPostSimilar => "Post Similar Job";
  @override
  String get jobDetailActionShare => "Share This Job";
  @override
  String get jobDetailDeleteConfirmTitle => "Delete Job";
  @override
  String get jobDetailDeleteConfirmContent =>
      "Are you sure you want to permanently delete this job posting?";
  @override
  String get jobDetailDeleteConfirmKeep => "Keep Job";
  @override
  String get jobDetailDeleteConfirmDelete => "Delete";
  @override
  String get jobDetailErrorAssigningWorker => "Error assigning worker.";
  @override
  String get jobDetailSuccessWorkerAssigned => "Worker assigned successfully!";
  @override
  String get jobDetailErrorApplying => "Error submitting application.";
  @override
  String get jobDetailSuccessApplied => "Application submitted successfully!";
  @override
  String get jobDetailErrorDeleting => "Error deleting job.";
  @override
  String get jobDetailSuccessDeleted => "Job deleted successfully.";
  @override
  String get jobDetailErrorMarkingComplete => "Error marking job as complete.";
  @override
  String get jobDetailSuccessMarkedComplete => "Job marked as complete!";
  @override
  String get jobDetailFeatureComingSoon => "Feature coming soon!";
  @override
  String get jobDetailApplicantHireButton => "Hire";
  @override
  String get clientNameLabel => "Client";

  // --- Payment Screen (Added from your implementation) ---
  @override
  String get paymentScreenTitle => "Manage Payment Methods";
  @override
  String get paymentMethods => "Payment Methods";
  @override
  String get paymentAddMethod => "Add Method";
  @override
  String get paymentNoMethod => "No payment method";

  // --- Create Job Screen ---
  @override
  String get createJobCategoryLabel => 'Category';
  @override
  String get createJobCategoryHint => 'Select job category';
  @override
  String get createJobErrorCategory => 'Please select a category.';
  @override
  String get createJobSkillLabel => 'Specific Skill / Task';
  @override
  String get createJobSkillHint => 'Select required skill';
  @override
  String get createJobErrorSkill => 'Please select a skill/task.';
  @override
  String get attachOptionGallery => 'Choose from Gallery';
  @override
  String get attachOptionCamera => 'Take Photo';
  @override
  String get attachOptionFile => 'Browse Files';
  @override
  String get attachOptionCancel => 'Cancel';
  @override
  String get attachTitle => 'Add Attachment';
  @override
  String get createJobCalendarTitle => 'Select Job Date';
  @override
  String get createJobCalendarCancel => 'Cancel';
  @override
  String get createJobAppBarTitle => 'Create New Job';
  @override
  String get createJobSelectedWorkerSectionTitle => 'Selected Worker';
  @override
  String get createJobDetailsSectionTitle => 'Job Details';
  @override
  String get createJobOptionalSectionTitle => 'Optional Details';
  @override
  String get createJobTitleLabel => 'Job Title';
  @override
  String get createJobTitleHint => 'e.g., Fix leaky faucet';
  @override
  String get createJobTitleError => 'Please enter a job title.';
  @override
  String get createJobDescLabel => 'Description';
  @override
  String get createJobDescHint =>
      'Provide details about the job... (min 20 chars)';
  @override
  String get createJobDescErrorEmpty => 'Please enter a description.';
  @override
  String get createJobDescErrorShort =>
      'Description must be at least 20 characters long.';
  @override
  String get createJobBudgetLabel => 'Budget (ETB)';
  @override
  String get createJobBudgetHint => 'e.g., 500';
  @override
  String get createJobBudgetErrorEmpty => 'Please enter a budget amount.';
  @override
  String get createJobBudgetErrorNaN =>
      'Please enter a valid number for the budget.';
  @override
  String get createJobBudgetErrorPositive =>
      'Budget must be a positive amount.';
  @override
  String get createJobLocationLabel => 'Location';
  @override
  String get createJobLocationHint => 'e.g., Bole, Addis Ababa';
  @override
  String get createJobLocationError => 'Please enter the job location.';
  @override
  String get createJobScheduleLabelOptional => 'Schedule Date (Optional)';
  @override
  String createJobScheduleLabelSet(String date) => 'Scheduled for: $date';
  @override
  String get createJobScheduleSub => 'Tap to select a preferred date';
  @override
  String get createJobAttachmentsLabelOptional => 'Attachments (Optional)';
  @override
  String get createJobAttachmentsSubAdd => 'Tap to add photos or documents';
  @override
  String createJobAttachmentsSubCount(int count) => '$count file(s) attached';
  @override
  String get createJobUrgentLabel => 'Mark as Urgent';
  @override
  String get createJobUrgentSub => 'Urgent jobs may get quicker responses';
  @override
  String get createJobButtonPosting => 'POSTING...';
  @override
  String get createJobButtonPost => 'POST JOB';
  @override
  String get registerErrorProfessionRequired => "Please enter your profession.";
  @override
  String get errorPasswordShort => "Password must be at least 6 characters.";

  // --- Job Dashboard Screen ---
  @override
  String get dashboardTitleDefault => "Dashboard";
  @override
  String get dashboardTitleWorker => "My Work Dashboard"; // Used by AppBar
  @override
  String get dashboardTitleClient => "My Jobs Dashboard"; // Used by AppBar
  @override
  String get tabWorkerAssigned => "ASSIGNED TO ME";
  @override
  String get tabWorkerApplied => "MY APPLICATIONS";
  @override
  String get tabWorkerActive => "ACTIVE/DONE";
  @override
  String get tabClientPosted => "MY POSTINGS";
  @override
  String get tabClientApplications => "APPLICANTS";
  @override
  String get tabClientRequests => "MY REQUESTS";
  @override
  String get filterAll => "All";
  @override
  String get filterOpen => "Open";
  @override
  String get filterPending => "Pending";
  @override
  String get filterAssigned => "Assigned";
  @override
  String get filterAccepted => "Accepted";
  @override
  String get filterInProgress => "In Progress";
  @override
  String get filterStartedWorking => "Working";

  @override
  String get filterCompleted => "Completed";
  @override
  String get filterCancelled => "Cancelled";
  @override
  String get filterRejected => "Rejected";
  @override
  String get filterClosed => "Closed";
  @override
  String get viewImageButton => "VIEW";
  @override
  String get emptyStateWorkerAssigned => "No Jobs Assigned Yet";
  @override
  String get emptyStateWorkerApplied => "You Haven't Applied to Any Jobs";
  @override
  String get emptyStateWorkerActive => "No Active or Completed Work Yet";
  @override
  String get emptyStateClientPosted => "You Haven't Posted Any Jobs";
  @override
  String get emptyStateClientApplications => "No Applications Received Yet";
  @override
  String get emptyStateClientRequests =>
      "You Haven't Requested Any Jobs Directly";
  @override
  String get emptyStateJobsFilteredTitle => "No Jobs Match Filter";
  @override
  String get emptyStateJobsFilteredSubtitle =>
      "Try adjusting the status filter above.";
  @override
  String get workerDetailTabOverview => "Overview";
  @override
  String get workerDetailTabAbout => "About the Worker";
  @override
  String get emptyStateGeneralSubtitle => "Check back later or refresh.";
  @override
  String get noApplicantsSubtitle =>
      "When workers apply, they will show up here.";
  @override
  String get buttonAccept => "Accept"; // Generic button
  @override
  String get buttonStartWork => "Start Work"; // Generic button
  @override
  String get buttonComplete => "Complete"; // Generic button
  @override
  String get buttonViewApplicants => "View Applicants";
  @override
  String get buttonChatClient => "Chat Client";
  @override
  String get buttonChatWorker => "Chat Worker";
  @override
  String get buttonPayWorker => "Pay Worker";
  @override
  String get buttonCancelJob => "Cancel Job";
  @override
  String get viewProfileButton => "View Profile";
  @override
  String get viewAllApplicantsButton => "View All";
  @override
  String get buttonChat => "Chat";
  @override
  String get jobAcceptedSuccess => "Job accepted successfully!";
  @override
  String get jobAcceptedError => "Failed to accept job.";
  @override
  String get jobStartedSuccess => "Work started!";
  @override
  String get jobStartedError => "Failed to update status to 'started'.";
  @override
  String get applicantLoadError => "Error loading applicants.";
  @override
  String applicantsForJob(String jobTitle) => "Applicants for: $jobTitle";
  @override
  String get applicantNotFound => "Applicant not found";
  @override
  String get skillsLabel => "Skills:";
  @override
  String get aboutLabel => "About:";
  @override
  String get priceRangeLabel => "Price Range";
  @override
  String get experienceLabel => "Experience";
  @override
  String get phoneLabel => "Phone";
  @override
  String get timelinePending => "Pending";
  @override
  String get timelineInProgress => "In Progress";
  @override
  String get timelineCompleted => "Completed";

  // --- Professional Setup/Edit Screen Strings ---
  @override
  String get professionalSetupTitle => "Edit Profile";
  @override
  String get professionalSetupSubtitle =>
      "A complete profile attracts more clients.";
  @override
  String get professionalSetupSaveAll => "Save All";
  @override
  String get professionalSetupSaving => "Saving...";

  // SnackBar Messages
  @override
  String get professionalSetupErrorNotLoggedIn => "Error: Not logged in.";
  @override
  String professionalSetupErrorLoading(String error) =>
      "Error loading profile: $error";
  @override
  String get professionalSetupErrorFormValidation =>
      "Please correct the errors before saving.";
  @override
  String get professionalSetupInfoUploadingMedia =>
      "Uploading media, please wait...";
  @override
  String get professionalSetupInfoSavingData => "Saving profile data...";
  @override
  String get professionalSetupSuccess => "Profile saved successfully!";
  @override
  String professionalSetupErrorSaving(String error) =>
      "Failed to save profile: $error";
  @override
  String get professionalSetupErrorLocationDisabled =>
      "Location services are disabled.";
  @override
  String get professionalSetupErrorLocationDenied =>
      "Location permissions are denied.";
  @override
  String get professionalSetupErrorLocationPermanentlyDenied =>
      "Location permissions are permanently denied.";
  @override
  String professionalSetupErrorGettingLocation(String error) =>
      "Failed to get location: $error";
  @override
  String get professionalSetupErrorMaxImages => "Maximum 6 images allowed.";

  // Wide Layout Navigation
  @override
  String get professionalSetupNavHeader => "Profile Sections";
  @override
  String get professionalSetupNavBasic => "Basic Info";
  @override
  String get professionalSetupNavExpertise => "Expertise & Skills";
  @override
  String get professionalSetupNavLocation => "Location & Radius";
  @override
  String get professionalSetupNavShowcase => "Portfolio Showcase";
  @override
  String get professionalSetupNavRates => "Rates & Availability";

  // Profile Strength Indicator
  @override
  String get professionalSetupStrengthTitle => "Profile Strength";
  @override
  String get professionalSetupStrengthIncomplete =>
      "Your profile is incomplete. Add more details to appear in more searches.";
  @override
  String get professionalSetupStrengthGood =>
      "Looking good! A few more details will make your profile stand out.";
  @override
  String get professionalSetupStrengthExcellent =>
      "Excellent! Your profile is complete and ready to attract clients.";

  // Section: Basic Info
  @override
  String get professionalSetupBasicTitle => "Basic Information";
  @override
  String get professionalSetupBasicSubtitle =>
      "This is the first thing clients see. Make a great impression.";
  @override
  String get professionalSetupLabelName => "Full Name";
  @override
  String get professionalSetupHintName => "e.g., Abebe Bikila";
  @override
  String get professionalSetupLabelProfession => "Primary Profession";
  @override
  String get professionalSetupHintProfession => "e.g., Master Electrician";
  @override
  String get professionalSetupLabelPhone => "Public Contact Number";
  @override
  String get professionalSetupHintPhone => "+251 9...";
  @override
  String professionalSetupValidatorRequired(String label) =>
      "$label is required.";

  // Section: Expertise
  @override
  String get professionalSetupExpertiseTitle => "Your Expertise";
  @override
  String get professionalSetupExpertiseSubtitle =>
      "Detail your experience and the skills you offer.";
  @override
  String get professionalSetupLabelExperience =>
      "Years of Professional Experience";
  @override
  String get professionalSetupHintExperience => "e.g., 5";
  @override
  String get professionalSetupLabelBio => "Professional Bio";
  @override
  String get professionalSetupHintBio =>
      "Describe yourself, your work ethic, and what makes your service unique. (A detailed bio increases engagement!)";

  // Section: Skills
  @override
  String get professionalSetupSkillsDialogTitle => "Select Your Skills";
  @override
  String get professionalSetupSkillsDialogSubtitle =>
      "Choose all skills that apply to your expertise.";
  @override
  String get professionalSetupSkillsDialogCancel => "Cancel";
  @override
  String get professionalSetupSkillsDialogConfirm => "Confirm Skills";
  @override
  String get professionalSetupSkillsEmptyButton => "Select your skills";
  @override
  String get professionalSetupSkillsEditButton => "Add/Edit";
  @override
  String get professionalSetupSkillsSelectedTitle => "Selected Skills";

  // Section: Location
  @override
  String get professionalSetupLocationTitle => "Service Area";
  @override
  String get professionalSetupLocationSubtitle =>
      "Define your primary location and how far you're willing to travel for jobs.";
  @override
  String get professionalSetupLabelCity => "Primary City or Town";
  @override
  String get professionalSetupHintCity => "e.g., Addis Ababa, Ethiopia";
  @override
  String get professionalSetupTooltipGetLocation => "Get Current Location";
  @override
  String get professionalSetupServiceRadiusTitle => "Service Radius";
  @override
  String get professionalSetupServiceRadiusSubtitle =>
      "How far you're willing to travel from your location for jobs.";

  // Section: Showcase
  @override
  String get professionalSetupShowcaseTitle => "Media Showcase";
  @override
  String get professionalSetupShowcaseSubtitle =>
      "Build trust with a personal video and photos of your work.";
  @override
  String get professionalSetupVideoTitle => "Video Introduction";
  @override
  String get professionalSetupVideoEmptyButton => "Add Video Introduction";
  @override
  String get professionalSetupGalleryTitle => "Work Gallery (Max 6)";
  @override
  String get professionalSetupCertificationsTitle =>
      "Certifications & Licenses (Max 6)";
  @override
  String get professionalSetupImageEmptyButton => "Add Image";

  // Section: Operations
  @override
  String get professionalSetupOperationsTitle => "Business Operations";
  @override
  String get professionalSetupOperationsSubtitle =>
      "Set your hourly rate and weekly working schedule.";
  @override
  String get professionalSetupPricingTitle => "Pricing";
  @override
  String get professionalSetupLabelRate => "Base Rate (per hour, in ETB)";
  @override
  String get professionalSetupAvailabilityTitle => "Weekly Availability";
  @override
  String get professionalSetupAvailabilityTo => "to";
  // --- Login Screen ---
  @override
  String get loginTitle => "Welcome Back!";
  @override
  String get loginWelcome => "Log in to continue";
  @override
  String get loginEmailLabel => "Email";
  @override
  String get loginEmailHint => "Enter your email";
  @override
  String get loginPasswordLabel => "Password";
  @override
  String get loginPasswordHint => "Enter your password";
  @override
  String get loginRememberMe => "Remember Me";
  @override
  String get loginForgotPassword => "Forgot Password?";
  @override
  String get loginButton => "LOG IN";
  @override
  String get loginNoAccount => "Don't have an account? ";
  @override
  String get loginSignUpLink => "Sign Up";
  @override
  String get loginErrorUserNotFound => "No user found for that email.";
  @override
  String get loginErrorWrongPassword => "Wrong password provided.";
  @override
  String get loginErrorInvalidEmail => "The email address is badly formatted.";
  @override
  String get loginErrorUserDisabled => "This user account has been disabled.";
  @override
  String get loginErrorTooManyRequests =>
      "Too many login attempts. Please try again later.";
  @override
  String get loginErrorUnknown =>
      "Login failed. Please check your credentials.";
  @override
  String get jobsLabel => "jobs";
  @override
  String get workerDetailIntroVideo => "Introduction Video";
  @override
  String get loginWithGoogle => "Sign in with Google";
  @override
  String get loginErrorGoogleSignIn =>
      "Google Sign-In failed. Please try again.";

  // --- Register Screen ---
  @override
  String get registerTitle => "Create Account";
  @override
  String get registerSubtitle =>
      "Join our community of clients and professionals";
  @override
  String get registerUserTypePrompt => "I am a:";
  @override
  String get registerUserTypeClient => "Client (Hiring)";
  @override
  String get registerUserTypeWorker => "Professional (Worker)";
  @override
  String get registerProfessionLabel => "Your Profession";
  @override
  String get registerProfessionHint => "e.g., Plumber, Electrician";
  @override
  String get registerFullNameLabel => "Full Name";
  @override
  String get registerFullNameHint => "Enter your full name";
  @override
  String get registerPhoneLabel => "Phone Number";
  @override
  String get registerPhoneHint => "Enter your phone number";
  @override
  String get registerConfirmPasswordLabel => "Confirm Password";
  @override
  String get registerConfirmPasswordHint => "Re-enter your password";
  @override
  String get registerButton => "CREATE ACCOUNT";
  @override
  String get registerHaveAccount => "Already have an account? ";
  @override
  String get registerSignInLink => "Sign In";
  @override
  String get registerErrorPasswordMismatch => "Passwords do not match.";
  @override
  String get registerErrorWeakPassword => "The password provided is too weak.";
  @override
  String get registerErrorEmailInUse =>
      "An account already exists for that email.";
  @override
  String get registerErrorInvalidEmailRegister =>
      "The email address is badly formatted.";
  @override
  String get registerErrorUnknown => "Registration failed. Please try again.";
  @override
  String get registerWithGoogle => "Sign up with Google";
  @override
  String get registerSuccess => "Registration successful!";
  @override
  String get registerNavigateToSetup => "Navigating to professional setup...";
  @override
  String get registerNavigateToHome => "Navigating to home...";

  // --- Forgot Password Screen ---
  @override
  String get forgotPasswordTitle => "Reset Password";
  @override
  String get forgotPasswordInstructions =>
      "Enter your email address below and we'll send you a link to reset your password.";
  @override
  String get forgotPasswordButton => "Send Reset Link";
  @override
  String get forgotPasswordSuccess =>
      "Password reset email sent! Please check your inbox.";
  @override
  String get forgotPasswordError =>
      "Error sending reset email. Please check the address and try again.";
  @override
  String get myWorkDashboardText => "My Work Dashboard";
  @override
  String get myJobsDashboardText => "My Jobs Dashboard";
  @override
  String get assignedJobsText => "ASSIGNED JOBS";
  @override
  String get myApplicationsText => "MY APPLICATIONS";
  @override
  String get activeWorkText => "ACTIVE WORK";
  @override
  String get myPostedJobsText => "MY POSTED JOBS";
  @override
  String get applicationsText => "APPLICATIONS";
  @override
  String get myRequestsText => "MY REQUESTS";
  @override
  String get allText => "All";
  @override
  String get openText => "Open";
  @override
  String get pendingText => "Pending";
  @override
  String get acceptedText => "Accepted";
  @override
  String get completedText => "Completed";
  @override
  String get closedText => "Closed";
  @override
  String get cancelledText => "Cancelled";
  @override
  String get rejectedText => "Rejected";
  @override
  String get inProgressText => "In Progress";
  @override
  String get jobText => "job";
  @override
  String get jobsText => "jobs";
  @override
  String get assignedJobText => "assigned job";
  @override
  String get assignedJobsPluralText => "assigned jobs";
  @override
  String get activeJobText => "active job";
  @override
  String get activeJobsPluralText => "active jobs";
  @override
  String get postedText => "Posted";
  @override
  String get agoText => "ago";
  @override
  String get applicantText => "Applicant";
  @override
  String get applicantsText => "Applicants";
  @override
  String get noApplicantsText => "No applicants";
  @override
  String get waitingForWorkerToAcceptText => "Waiting for worker to accept";
  @override
  String get yourWorkingIsOnPendingText => "your working is on pending";
  @override
  String get payText => "Pay";
  @override
  String get viewDetailsText => "View Details";
  @override
  String get rateText => "Rate";
  @override
  String get manageText => "Manage";
  @override
  String get postAJobText => "Post a Job";
  @override
  String get noAssignedJobsYetText => "No assigned jobs yet";
  @override
  String get whenJobsAreAssignedToYouText =>
      "When jobs are assigned to you, they will appear here";
  @override
  String get noApplicationsYetText => "No applications yet";
  @override
  String get jobsYouApplyForWillAppearHereText =>
      "Jobs you apply for will appear here";
  @override
  String get noActiveWorkText => "No active work";
  @override
  String get yourActiveJobsWillAppearHereText =>
      "Your active jobs will appear here";
  @override
  String get noPostedJobsYetText => "No posted jobs yet";
  @override
  String get tapThePlusButtonToPostYourFirstJobText =>
      "Tap the + button to post your first job";
  @override
  String get noJobRequestsText => "No job requests";
  @override
  String get yourPersonalJobRequestsWillAppearHereText =>
      "Your personal job requests will appear here";
  @override
  String get aboutText => "About";
  @override
  String get skillsText => "Skills";
  @override
  String get viewProfileText => "View Profile";
  @override
  String get acceptText => "Accept";
  @override
  String get declineText => "Decline";
  @override
  String get applicantsForText => "Applicants for";
  @override
  String get couldNotLoadApplicantText => "Could not load applicant";
  @override
  String get moreApplicantsText => "more applicants";

  // --- Helper Method Implementations ---
  @override
  String getStatusName(String key) {
    switch (key.toLowerCase()) {
      case 'open':
        return filterOpen;
      case 'pending':
        return filterPending;
      case 'assigned':
        return filterAssigned;
      case 'accepted':
        return filterAccepted;
      case 'in_progress':
        return filterInProgress;
      case 'started working':
        return filterStartedWorking;
      case 'completed':
        return filterCompleted;
      case 'cancelled':
        return filterCancelled;
      case 'rejected':
        return filterRejected;
      case 'closed':
        return filterClosed;
      default:
        return key.toUpperCase();
    }
  }

  @override
  IconData? getFilterIcon(String key) {
    switch (key.toLowerCase()) {
      case 'all':
        return Icons.list_alt_rounded;
      case 'open':
        return Icons.lock_open_rounded;
      case 'pending':
        return Icons.pending_actions_rounded;
      case 'assigned':
        return Icons.assignment_ind_outlined;
      case 'accepted':
        return Icons.check_circle_outline_rounded;
      case 'in_progress':
        return Icons.construction_rounded;
      case 'started working':
        return Icons.play_circle_outline_rounded;
      case 'completed':
        return Icons.task_alt_rounded;
      case 'cancelled':
        return Icons.cancel_outlined;
      case 'rejected':
        return Icons.thumb_down_alt_outlined;
      case 'closed':
        return Icons.lock_outline_rounded;
      default:
        return null;
    }
  }

  @override
  String getFilterName(String key) => getStatusName(key);
  @override
  IconData? getEmptyStateIcon(String key) {
    if (key == emptyStateWorkerAssigned) return Icons.assignment_late_outlined;
    if (key == emptyStateWorkerApplied) {
      return Icons.playlist_add_check_circle_outlined;
    }
    if (key == emptyStateWorkerActive) return Icons.construction_rounded;
    if (key == emptyStateClientPosted) return Icons.post_add_rounded;
    if (key == emptyStateClientApplications) return Icons.people_alt_outlined;
    if (key == emptyStateClientRequests) return Icons.request_page_outlined;
    return Icons.search_off_rounded;
  }

  @override
  String yearsExperience(int years) =>
      "$years year${years == 1 ? '' : 's'} Exp";
  @override
  String applicantCount(int count) =>
      "$count Applicant${count == 1 ? '' : 's'}";
  @override
  String jobsCompleted(int count) => "$count Jobs Done";
  @override
  String formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inSeconds < 60) return timeAgoJustNow;
    if (difference.inMinutes < 60) return timeAgoMinute(difference.inMinutes);
    if (difference.inHours < 24) return timeAgoHour(difference.inHours);
    if (difference.inDays < 7) return timeAgoDay(difference.inDays);
    if (difference.inDays < 30) {
      return timeAgoWeek((difference.inDays / 7).floor());
    }
    if (difference.inDays < 365) {
      return timeAgoMonth((difference.inDays / 30).floor());
    }
    return timeAgoYear((difference.inDays / 365).floor());
  }

  @override
  String errorFieldRequired(String fieldName) => "Please enter $fieldName.";
  @override
  String getUserTypeDisplayName(String key) {
    switch (key) {
      case 'registerUserTypeClient':
        return registerUserTypeClient;
      case 'registerUserTypeWorker':
        return registerUserTypeWorker;
      default:
        return key;
    }
  }

  // --- NEWLY ADDED based on errors for Job Dashboard ---
  @override
  String errorLoadingData(String errorDetails) =>
      "Error loading data: $errorDetails";
  @override
  String get jobCancelledSuccessfullyText => "Job cancelled successfully.";

  @override
  String get applicationAcceptedSuccessfullyText =>
      "Application accepted successfully.";

  @override
  String get jobAcceptedSuccessfullyText => "Job accepted successfully.";

  @override
  String get jobMarkedAsCompletedSuccessfullyText =>
      "Job marked as completed successfully.";

  @override
  String get workStartedSuccessfullyText => "Work started successfully.";

  @override
  String get applicationDeclinedSuccessfullyText =>
      "Application declined successfully.";

  @override
  String get loadingText => "Loading...";
  @override
  String errorLoadingJobs(String errorDetails) =>
      "Error loading jobs: $errorDetails";
  @override
  String get jobCancelledSuccess => "Job cancelled successfully.";
  @override
  String errorCancellingJob(String errorDetails) =>
      "Error cancelling job: $errorDetails";
  @override
  String get applicationAcceptedSuccess => "Application accepted successfully.";
  @override
  String errorAcceptingApplication(String errorDetails) =>
      "Error accepting application: $errorDetails";
  @override
  String errorAcceptingJob(String errorDetails) =>
      "Error accepting job: $errorDetails";
  @override
  String errorStartingWork(String errorDetails) =>
      "Error starting work: $errorDetails";
  @override
  String get jobCompletedSuccess => "Job completed successfully.";
  @override
  String errorCompletingJob(String errorDetails) =>
      "Error completing job: $errorDetails";
  @override
  String get jobStatusPending => "Pending";
  @override
  String get jobStatusActive => "Active";
  @override
  String get jobStatusInProgress => "In Progress";
  @override
  String get jobStatusCancelled => "Cancelled";
  @override
  String get jobStatusRejected => "Rejected";
  @override
  String get jobStatusClosed => "Closed";
  @override
  String get jobStatusStartedWorking => "Started Working";
  @override
  String get myWorkDashboard => "My Work Dashboard";
  // Inside your class AppStringsEn implements AppStrings { ... }

  @override
  String get viewButton => "View";
  @override
  String get carouselViewTooltip => "Carousel View";
  @override
  String get gridViewTooltip => "Grid View";
  @override
  String get distanceLabel => "Distance";
  @override
  String get locationTitle => "Location";
  @override
  String get mapNotAvailable => "Map not available";
  @override
  String get mapErrorConnectivity => "Check internet or API key";
  @override
  String get estimatedEtaLabel => "Estimated ETA";
  @override
  String get viewOnMapButton => "View on Map";
  @override
  String get snackbarFailedToLaunchMap => "Failed to launch map";
  @override
  String availableSlotsForDate(String date) => "Available Slots for $date";
  @override
  String get noSlotsAvailable => "No slots available";
  @override
  String get bookSlotButton => "Book Slot";
  @override
  String get selectTimeSlotButton => "Select a Time Slot";
  @override
  String get noInternetConnection => "No internet connection.";
  @override
  String get locationPermissionDenied => "Location permission denied.";
  @override
  String get errorFetchingLocation => "Error fetching location.";
  @override
  String get couldNotLoadVideo => "Could not load video.";
  @override
  String get videoLoadFailed => "Video load failed.";
  @override
  String get cannotPlayVideoNoInternet => "Cannot play video without internet.";
  @override
  String get reviewJobPaymentPrerequisite =>
      "You need to complete at least one\njob and one payment to submit a review.";
  @override
  String get performanceOverviewTitle => "Performance Overview";
  @override
  String get failedToMakeCall => "Failed to make call.";
  @override
  String get submitReviewButton => "Submit Review"; // Ensure this is present
  @override
  String get myJobsDashboard => "My Jobs Dashboard";
  @override
  String get assignedJobsTab => "Assigned"; // Tab title
  @override
  String get myApplicationsTab => "My Applications"; // Tab title
  @override
  String get activeWorkTab => "Active Work"; // Tab title
  @override
  String get myPostedJobsTab => "Posted"; // Tab title
  @override
  String get applicationsTab => "Applications"; // Tab title for client
  @override
  String get myRequestsTab => "Requests"; // Tab title
  @override
  String assignedJobsCount(int count) =>
      "$count Job${count == 1 ? '' : 's'} Assigned";
  @override
  String get noAssignedJobsTitle => "No Jobs Assigned Yet";
  @override
  String get noAssignedJobsSubtitle =>
      "When jobs are assigned to you, they'll appear here.";
  @override
  String jobsCount(int count) => "$count Job${count == 1 ? '' : 's'}";
  @override
  String get noApplicationsYetTitle => "No Applications Yet";
  @override
  String get noApplicationsYetSubtitleWorker =>
      "Your applications for jobs will be shown here.";
  @override
  String activeJobsCount(int count) =>
      "$count Active Job${count == 1 ? '' : 's'}";
  @override
  String get noActiveWorkTitle => "No Active Work";
  @override
  String get noActiveWorkSubtitle =>
      "Jobs you've accepted and are working on will appear here.";
  @override
  String get noPostedJobsTitle => "You Haven't Posted Any Jobs";
  @override
  String get noPostedJobsSubtitle =>
      "Post a job to find skilled professionals.";
  @override
  String get noApplicationsYetSubtitleClient =>
      "When professionals apply to your jobs, they'll show up here.";
  @override
  String workerCardDistanceAway(String km) => '$km km away';
  @override
  String get noJobRequestsTitle => "No Job Requests Made";
  @override
  String get noJobRequestsSubtitle =>
      "Jobs you've directly requested from professionals will be listed here.";
  @override
  String postedTimeAgo(String timeAgo) => "Posted $timeAgo";
  @override
  String applicantsCount(int count) =>
      "$count Applicant${count == 1 ? '' : 's'}";
  @override
  String get waitingForWorkerToAccept => "Waiting for you to accept/decline.";
  @override
  String get yourWorkIsPending => "Your action is pending for this job.";
  @override
  String get payButton => "Pay Now";
  @override
  String get viewDetailsButton => "View Details";
  @override
  String get acceptButton => "Accept";
  @override
  String get startButton => "Start Work";
  @override
  String get completeButton => "Mark Complete";
  @override
  String get manageButton => "Manage";
  @override
  String get postAJobButton => "Post a Job";
  @override
  String jobApplicationsScreenTitle(String jobTitle) =>
      "Applicants for: $jobTitle";
}

// ===========================================================
//                 Amharic Implementation
// ===========================================================
class AppStringsAm implements AppStrings {
  @override
  Locale get locale => const Locale('am');

  // --- Implement ALL abstract members ---

  @override
  String get appName => "ስራ";
  @override
  String get appTitle => "FixIt"; // Translate as needed
  @override
  String get specifyInDescription => 'በመግለጫው ውስጥ ይግለጹ';
  @override
  String get highContrastTooltip => "ከፍተኛ ንፅፅር";
  @override
  String get darkModeTooltip => "ጨለማ ሁናቴ";
  @override
  String get languageToggleTooltip => "ቋንቋ ቀይር";
  @override
  Map<String, List<String>> get jobCategoriesAndSkills => {
        'የቧንቧ ስራ': [
          'የውሃ ጠብታ ጥገና',
          'የቧንቧ ዝርጋታ',
          'የፍሳሽ ማጽዳት',
          'የውሃ ቧንቧ ጥገና',
          'የሽንት ቤት ጥገና',
          'የውሃ ማሞቂያ'
        ],
        'የኤሌክትሪክ ስራ': [
          'የሽቦ ዝርጋታ',
          'የሶኬት ጥገና',
          'የመብራት ተከላ',
          'ሰርኪዩት ብሬከር',
          'የማራገቢያ ተከላ',
          'የቤት እቃ ጥገና'
        ],
        'ጽዳት': ['የቤት ጽዳት', 'የቢሮ ጽዳት', 'ጥልቅ ጽዳት', 'የመስኮት ጽዳት', 'ምንጣፍ ጽዳት'],
        'ቀለም ቅብ': ['የቤት ውስጥ ቀለም', 'የውጭ ቀለም', 'የግድግዳ ዝግጅት', 'የቤት እቃ ቀለም'],
        'የእንጨት ስራ': ['የቤት እቃ ገጣጠም', 'የበር ጥገና', 'የመደርደሪያ ተከላ', 'የእንጨት ጥገና'],
        'አትክልተኝነት': ['የሣር ማጨድ', 'መትከል', 'አረም መንቀል', 'የዛፍ ቅርንጫፍ መቁረጥ'],
        'ዕቃ ማጓጓዝ': ['መጫን/ማውረድ', 'ማሸግ', 'የቤት ዕቃ ማንቀሳቀስ'],
        'የእጅ ባለሙያ': ['አጠቃላይ ጥገና', 'ቴሌቪዥን መስቀል', 'ፎቶ መስቀል', 'ጥቃቅን ጥገናዎች'],
        'ሌላ': ['በመግለጫው ውስጥ ይግለጹ']
      };
  @override
  String get errorInitializationFailed => "ማስጀመር አልተሳካም";
  @override
  String get profileNotFound => "ፕሮፋይል አልተገኘም";
  @override
  String get profileDataUnavailable => "ፕሮፋይል መረጃ አልተገኘም";
  @override
  String get profileEditAvatarHint => "አቫታር ቀይር";
  @override
  String get snackSuccessProfileUpdated => "ፕሮፋይል በተሳካ ሁኔታ ተሻሽሏል!";
  @override
  String get profileStatsTitleWorker => "የባለሙያ ስታትስቲክስ";
  @override
  String get profileStatsTitleClient => "የደንበኛ ስታትስቲክስ";
  @override
  String get profileStatJobsCompleted => "የተጠናቀቁ ስራዎች";
  @override
  String get profileStatRating => "ደረጃ";
  @override
  String get profileStatExperience => "ልምድ";
  @override
  String get profileStatReviews => "ግምገማዎች";
  @override
  String get profileStatJobsPosted => "የተለጠፉ ስራዎች";
  @override
  String get profileNeedProfileForHistory => "ለስራ ታሪክ ፕሮፋይል ያስፈልጋል";
  @override
  String get profileJobHistoryTitle => "የስራ ታሪክ";
  @override
  String get viewAllButton => "ሁሉንም ይመልከቱ";
  @override
  String get profileNoJobHistory => "የስራ ታሪክ የለም";
  @override
  String get workerNameLabel => "የባለሙያ ስም";
  @override
  String get profileSettingsTitle => "ቅንብሮች";
  @override
  String get settingsNotificationsTitle => "ማሳወቂያዎች";
  @override
  String get settingsNotificationsSubtitle => "የማሳወቂያ ቅንብሮች";
  @override
  String get settingsPaymentTitle => "ክፍያ";
  @override
  String get settingsPaymentSubtitle => "የክፍያ ቅንብሮች";
  @override
  String get settingsPrivacyTitle => "ግላዊነት";
  @override
  String get settingsPrivacySubtitle => "የግላዊነት ቅንብሮች";
  @override
  String get settingsAccountTitle => "አካውንት";
  @override
  String get settingsAccountSubtitle => "የአካውንት ቅንብሮች";
  @override
  String get switchedToClientView => "ወደ ደንበኛ እይታ ተቀይሯል";
  @override
  String get switchedToWorkerView => "ወደ ባለሙያ እይታ ተቀይሯል";
  @override
  String get switchToWorkerViewTooltip => "ወደ ባለሙያ እይታ ቀይር";
  @override
  String get switchToClientViewTooltip => "ወደ ደንበኛ እይታ ቀይር";
  @override
  String get becomeWorkerTooltip => "የባለሙያ መገለጫ አዋቅር";
  @override
  String get settingsHelpTitle => "እገዛ";
  @override
  String get settingsHelpSubtitle => "እገዛ እና ድጋፍ";
  @override
  String get settingsNotificationsContent => "የማሳወቂያ ይዘት";
  @override
  String get settingsPaymentContent => "የክፍያ ይዘት";
  @override
  String get settingsPrivacyContent => "የግላዊነት ይዘት";
  @override
  String get settingsAccountContent => "የአካውንት ይዘት";
  @override
  String get settingsHelpContent => "የእገዛ ይዘት";
  @override
  String get profileEditButton => "መገለጫ አርትዕ";
  @override
  String get dialogEditClientContent => "የደንበኛ መረጃ አርትዕ";
  @override
  String get dialogFeatureUnderDevelopment => "ይህ አገልግሎት በልማት ላይ ነው";
  @override
  String get errorCouldNotSavePrefs => "ምርጫዎችን ማስቀመጥ አልተቻለም";
  @override
  String get errorConnectivityCheck => "ግንኙነትን ማረጋገጥ አልተቻለም";
  @override
  String get errorActionFailed => "እርምጃው አልተሳካም። እባክዎ እንደገና ይሞክሩ.";
  @override
  String get errorCouldNotLaunchUrl => "ዩአርኤል መክፈት አልተቻለም።";
  @override
  String get errorCouldNotLaunchDialer => "መደወያ መክፈት አልተቻለም።";
  @override
  String get successPrefsSaved => "ምርጫ ተቀምጧል።";
  @override
  String get successSubscription => "ስለተመዘገቡ እናመሰግናለን!";
  @override
  String get connectionRestored => "የበይነመረብ ግንኙነት ተመልሷል።";
  @override
  String get noInternet => "የበይነመረብ ግንኙነት የለም።";
  @override
  String get retryButton => "እንደገና ሞክር";
  @override
  String get errorGeneric => "ስህተት ተከስቷል። እባክዎ እንደገና ይሞክሩ።";
  @override
  String get loading => "በመጫን ላይ...";
  @override
  String get generalCancel => "ይቅር";
  @override
  String get generalLogout => "ውጣ";

  @override
  String get emailVerificationSent => 'የማረጋገጫ ኢሜል ተልኳል።';
  @override
  String get emailVerifiedSuccess => 'ኢሜል በተሳካ ሁኔታ ተረጋግጧል!';
  @override
  String get emailNotVerifiedYet => 'ኢሜል ገና አልተረጋገጠም።';
  @override
  String get errorCheckingVerification => 'የማረጋገጫ ሁኔታን በማጣራት ላይ ስህተት።';
  @override
  String get errorResendingEmail => 'የማረጋገጫ ኢሜል እንደገና በመላክ ላይ ስህተት።';
  @override
  String get verificationScreenTitle => 'የኢሜል ማረጋገጫ';
  @override
  String get verificationScreenHeader => 'ኢሜልዎን ያረጋግጡ';
  @override
  String get verificationScreenInfo => 'ምዝገባውን ለመቀጠል እባክዎ ኢሜልዎን ያረጋግጡ።';
  @override
  String get checkingStatusButton => 'ሁኔታን በማጣራት ላይ...';
  @override
  String get checkVerificationButton => 'ማረጋገጫን አረጋግጥ';
  @override
  String get resendingButton => 'እንደገና በመላክ ላይ...';
  @override
  String get resendEmailButton => 'ኢሜል እንደገና ላክ';
  @override
  String get signOutButton => 'ውጣ';

  @override
  String get clear => 'አጥፋ';
  @override
  String get ok => 'እሺ';
  @override
  String get notAvailable => "የለም";
  @override
  String get availability => "አለ";
  @override
  String get notSet => "አልተቀመጠም";

  // HomeScreen
  @override
  String helloUser(String userName) => "ሰላም, $userName!";
  @override
  String get findExpertsTitle => "ባለሙያ ያግኙ";
  @override
  String get yourJobFeedTitle => "የእርስዎ የስራ ዝርዝር";
  @override
  String get navHome => "መነሻ";
  @override
  String get navPostJob => "ስራ ለጥፍ";
  @override
  String get navProfile => "መገለጫ";
  @override
  String get navHistory => "ታሪክ";
  @override
  String get navFeed => "ዝርዝር";
  @override
  String get navMyJobs => "የእኔ ስራዎች";
  @override
  String get navSetup => "ማዋቀር";
  @override
  String get appBarHome => "መነሻ";
  @override
  String get appBarPostNewJob => "አዲስ ስራ ለጥፍ";
  @override
  String get appBarMyProfile => "የእኔ መገለጫ";
  @override
  String get appBarJobHistory => "የስራ ታሪክ";
  @override
  String get appBarJobFeed => "የስራ ዝርዝር";
  @override
  String get appBarMyJobs => "የእኔ ስራዎች";
  @override
  String get appBarProfileSetup => "የመገለጫ ማዋቀር";
  @override
  String get themeTooltipLight => "ወደ ቀላል ገጽታ ቀይር";
  @override
  String get themeTooltipDark => "ወደ ጨለማ ገጽታ ቀይር";
  @override
  String get searchHintProfessionals => "ባለሙያዎችን፣ ክህሎቶችን ፈልግ...";
  @override
  String get searchHintJobs => "ስራዎችን፣ ቁልፍ ቃላትን ፈልግ...";
  @override
  String get featuredPros => "⭐ ከፍተኛ ደረጃ የተሰጣቸው ባለሙያዎች";
  @override
  String get featuredJobs => "🚀 የቅርብ ጊዜ ክፍት ስራዎች";
  @override
  String get emptyStateProfessionals => "ምንም ባለሙያዎች አልተገኙም";
  @override
  String get emptyStateJobs => "መስፈርትዎን የሚያሟላ ስራ የለም";
  @override
  String get emptyStateDetails => "የፍለጋ ቃላትዎን ለማስተካከል ወይም ማጣሪያዎችን ለማጽዳት ይሞክሩ።";
  @override
  String get refreshButton => "አድስ";
  @override
  String get fabPostJob => "አዲስ ስራ ለጥፍ";
  @override
  String get fabMyProfile => "የእኔ መገለጫ";
  @override
  String get fabPostJobTooltip => "አዲስ የስራ ማስታወቂያ ፍጠር";
  @override
  String get fabMyProfileTooltip => "የሙያ መገለጫዎን ይመልከቱ ወይም ያርትዑ";
  @override
  String get filterOptionsTitle => "የማጣሪያ አማራጮች";
  @override
  String get filterCategory => "ምድብ / ሙያ";
  @override
  String get filterLocation => "ቦታ";
  @override
  String get viewImageButton => "ይህን ስነብታ አስተያይ";
  @override
  String get filterJobStatus => "የስራ ሁኔታ";
  @override
  String get filterResetButton => "ዳግም አስጀምር";
  @override
  String get filterApplyButton => "ማጣሪያዎችን ተግብር";
  @override
  String get filtersResetSuccess => "ማጣሪያዎች ዳግም ተጀምረዋል";
  @override
  String workerCardJobsDone(int count) => "$count ስራዎች ተጠናቀዋል";
  @override
  String workerCardYearsExp(int years) => "$years ዓመት ልምድ";
  @override
  String get workerCardHire => "ቀጥር";
  @override
  String get jobCardView => "ዝርዝር እይ";
  @override
  String get jobStatusOpen => "ክፍት";
  @override
  String get jobStatusAssigned => "የተመደበ";
  @override
  String get jobStatusCompleted => "የተጠናቀቀ";
  @override
  String get jobStatusUnknown => "ያልታወቀ";
  @override
  String get jobDateN_A => "ቀን የለም";
  @override
  String get generalN_A => "የለም";
  @override
  String get jobUntitled => "ርዕስ አልባ ስራ";
  @override
  String get jobNoDescription => "መግለጫ አልተሰጠም።";
  @override
  String jobBudgetETB(String amount) => "$amount ብር";
  @override
  String get timeAgoJustNow => "አሁን";
  @override
  String timeAgoMinute(int minutes) => "ከ$minutes ደቂቃ በፊት";
  @override
  String timeAgoHour(int hours) => "ከ$hours ሰዓት በፊት";
  @override
  String timeAgoDay(int days) => "ከ$days ቀን በፊት";
  @override
  String timeAgoWeek(int weeks) => "ከ$weeks ሳምንት በፊት";
  @override
  String timeAgoMonth(int months) => "ከ$months ወር በፊት";
  @override
  String timeAgoYear(int years) => "ከ$years ዓመት በፊት";

  // WorkerDetail Screen
  @override
  String workerDetailAbout(String name) => "ስለ $name";
  @override
  String get workerDetailSkills => "ክህሎቶች";
  @override
  String get workerDetailAvailability => "ዝግጁነት";
  @override
  String workerDetailReviews(int count) => "ግምገማዎች ($count)";
  @override
  String get workerDetailLeaveReview => "ግምገማዎን ይተዉ";
  @override
  String get workerDetailHireNow => "አሁን ቀጥር";
  @override
  String get workerDetailWorking => "በስራ ላይ";
  @override
  String get workerDetailCall => "ደውል";
  @override
  String get workerDetailSubmitReview => "ግምገማ አስገባ";
  @override
  String get workerDetailShareProfileTooltip => "መገለጫ አጋራ";
  @override
  String get workerDetailAddFavoriteTooltip => "ወደ ተወዳጆች ጨምር";
  @override
  String get workerDetailRemoveFavoriteTooltip => "ከተወዳጆች አስወግድ";
  @override
  String get workerDetailAvailable => "ዝግጁ";
  @override
  String get workerDetailBooked => "ተይዟል";
  @override
  String get workerDetailSelectTime => "የጊዜ ሰሌዳ ምረጥ";
  @override
  String get workerDetailCancel => "ሰርዝ";
  @override
  String get workerDetailAnonymous => "ስም አልባ";
  @override
  String get workerDetailWriteReviewHint => "ተሞክሮዎን ያካፍሉ...";
  @override
  String workerDetailReviewLengthCounter(int currentLength, int maxLength) =>
      "$currentLength/$maxLength";
  @override
  String get workerDetailNoReviews => "እስካሁን ምንም ግምገማዎች የሉም።";
  @override
  String get workerDetailNoSkills => "ምንም ክህሎቶች አልተዘረዘሩም።";
  @override
  String get workerDetailNoAbout => "ምንም ዝርዝሮች አልተሰጡም።";
  @override
  String get workerDetailShowAll => "ሁሉንም አሳይ";
  @override
  String get workerDetailShowLess => "ትንሽ አሳይ";
  @override
  String get workermoneyempty => "አልተቀመጠም";
  @override
  String get workerDetailPrice => "ዋጋ ከ";
  @override
  String get workerDetailRequestQuote => "ዋጋ ይጠይቁ";
  @override
  String get workerDetailDistanceUnknown => 'ርቀት ያልታወቀ';
  @override
  String get workerDetailHireButton => 'ሰራተኛን አቅርብ';
  @override
  String get back => 'ተመለስ';
  @override
  String get workerDetailDistance => 'ርቀት';
  @override
  String get workerDetailHireDialogContent => "ይህንን ባለሙያ ለመቅጠር ምርጥ መንገድ ይምረጡ።";
  @override
  String distanceMeters(String meters) => '$meters ሜትር';
  @override
  String distanceKilometers(String km) => '$km ኪሎ ሜትር';
  @override
  String hireWorker(String name) => '$name ን ቅጥር';
  @override
  String get workerDetailTabDetails => "ዝርዝሮች";
  @override
  String get workerDetailTabPortfolio => "ፖርትፎሊዮ";
  @override
  String get workerDetailTabReviews => "ግምገማዎች";
  @override
  String get workerCardRating => "ደረጃ";
  @override
  String get workerCardJobsDoneShort => "የተሰሩ ስራዎች";
  @override
  String get workerCardYearsExpShort => "ዓመት ልምድ";
  @override
  String get workerDetailHireDialogQuick => "ፈጣን የስራ ጥያቄ";
  @override
  String get workerDetailHireDialogQuickSub => "ለቀላል እና ቀጥተኛ ስራዎች።";
  @override
  String get workerDetailHireDialogFull => "ሙሉ የስራ ቅጽ";
  @override
  String get workerDetailHireDialogFullSub => "ለዝርዝር ስራዎች እና የተወሰኑ መስፈርቶች።";
  @override
  String get workerDetailVideoIntro => "የቪዲዮ መግቢያ";
  @override
  String get workerDetailGallery => "የስራ ጋለሪ";
  @override
  String get workerDetailCertifications => "ፈቃዶች እና ምስክር ወረቀቶች";
  @override
  String get workerDetailRatingBreakdown => "የደረጃ ዝርዝር";
  @override
  String get workerDetailNoGallery => "ምንም የጋለሪ ምስሎች እስካሁን አልተጫኑም።";
  @override
  String get workerDetailNoCerts => "ምንም ምስክር ወረቀቶች እስካሁን አልተጫኑም።";
  @override
  String get generalClose => "ዝጋ";
  @override
  String get currency => "ብር";
  @override
  String workerDetailShareMessage(
          String workerName, String profession, String phone) =>
      'ይህን ባለሙያ በFixIt ይመልከቱ: $workerName ($profession). ያግኙ: $phone';

  // Notifications
  @override
  String get notificationTitle => "ማሳወቂያዎች";

  // Snackbars
  @override
  String get snackErrorLoading => "መረጃን በመጫን ላይ ስህተት።";
  @override
  String get snackErrorSubmitting => "ማስገባት አልተሳካም።";
  @override
  String get snackErrorGeneric => "ስህተት ተከስቷል። እባክዎ እንደገና ይሞክሩ።";
  @override
  String get snackSuccessReviewSubmitted => "ግምገማ በተሳካ ሁኔታ ገብቷል!";
  @override
  String get snackPleaseLogin => "እባክዎ ይህን ድርጊት ለመፈጸም ይግቡ።";
  @override
  String get snackFavoriteAdded => "ወደ ተወዳጆች ታክሏል!";
  @override
  String get snackFavoriteRemoved => "ከተወዳጆች ተወግዷል";
  @override
  String get snackPhoneNumberCopied => "ስልክ ቁጥር ተቀድቷል!";
  @override
  String get snackPhoneNumberNotAvailable => "ስልክ ቁጥር የለም።";
  @override
  String get snackErrorCheckFavorites => "ተወዳጆችን በማጣራት ላይ ስህተት።";
  @override
  String get snackErrorUpdateFavorites => "ተወዳጆችን ማዘመን አልተቻለም።";
  @override
  String get snackErrorContactInfo => "የመገኛ መረጃ በማምጣት ላይ ስህተት።";
  @override
  String get snackErrorLoadingProfile => "የእርስዎን መገለጫ በመጫን ላይ ስህተት።";
  @override
  String get snackReviewMissing => "እባክዎ ደረጃ እና አስተያየት ይስጡ።";
  @override
  String get snackWorkerNotFound => "የሰራተኛ መገለጫ አልተገኘም።";
  @override
  String get createJobSnackbarErrorWorker =>
      'የሰራተኛውን ዝርዝር በመጫን ላይ ስህተት ተፈጥሯል። እባክዎ እንደገና ይሞክሩ።';
  @override
  String get createJobSnackbarErrorUpload =>
      'ሰነዶችን በመጫን ላይ ስህተት ተፈጥሯል። እባክዎ እንደገና ይሞክሩ።';
  @override
  String get createJobSnackbarErrorUploadPartial => 'አንዳንድ ሰነዶች መጫን አልተሳካም።';
  @override
  String get createJobSnackbarErrorForm => 'እባክዎ በፎርሙ ላይ ያሉትን ስህተቶች ያስተካክሉ።';
  @override
  String get createJobSnackbarSuccess => 'ስራው በተሳካ ሁኔታ ተለጥፏል!';
  @override
  String get createJobSnackbarError => 'ስራውን መፍጠር አልተሳካም። እባክዎ እንደገና ይሞክሩ።';
  @override
  String get distanceInKm => "ሜትር";
  @override
  String createJobSnackbarFileSelected(int count) => '$count ፋይል(ሎች) ተመርጠዋል።';
  @override
  String get createJobSnackbarFileCancelled => 'ፋይል መምረጥ ተሰርዟል።';
  @override
  String get createJobSnackbarErrorPick =>
      'ፋይሎችን በመምረጥ ላይ ስህተት ተፈጥሯል። እባክዎ እንደገና ይሞክሩ።';
  @override
  String get snackErrorCameraNotAvailable => 'በዚህ መሣሪያ ላይ ካሜራ አይገኝም።';
  @override
  String get snackErrorCameraPermission =>
      'የካሜራ ፈቃድ ተከልክሏል። እባክዎ በቅንብሮች ውስጥ አንቁት።';
  @override
  String get snackErrorGalleryPermission =>
      'የጋለሪ ፈቃድ ተከልክሏል። እባክዎ በቅንብሮች ውስጥ አንቁት።';
  @override
  String get snackErrorReadFile => 'የፋይል መረጃ ማንበብ አልተቻለም።';
  @override
  String get snackSkippingUnknownType => 'ያልታወቀ የፋይል አይነት በመዝለል ላይ።';
  @override
  String get errorUserNotLoggedIn => "ተጠቃሚ አልገባም።";
  @override
  String get googleSignInCancelled => "በGoogle መግባት ተሰርዟል።";
  @override
  String get googleSignInAccountExists => "አካውንቱ በተለየ የመግቢያ መንገድ አስቀድሞ አለ።";

  // Dialogs
  @override
  String get phoneDialogTitle => "የመገኛ ስልክ ቁጥር";
  @override
  String get phoneDialogCopy => "ቁጥር ቅዳ";
  @override
  String get phoneDialogClose => "ዝጋ";
  @override
  String get jobsLabel => "ስራዎች"; // Or your correct Amharic translation
  @override
  String get workerDetailIntroVideo => "መግቢያ ቪዲዮ";

  // Job Detail Screen
  @override
  String get jobDetailAppBarTitle => "የስራ ዝርዝሮች";
  @override
  String get jobDetailLoading => "የስራ ዝርዝሮችን በመጫን ላይ...";
  @override
  String get jobDetailErrorLoading => "የስራ ዝርዝሮችን በመጫን ላይ ስህተት።";
  @override
  String get jobDetailStatusLabel => "ሁኔታ";
  @override
  String get jobDetailBudgetLabel => "በጀት";
  @override
  String get jobDetailLocationLabel => "ቦታ";
  @override
  String get jobDetailPostedDateLabel => "የተለጠፈበት ቀን";
  @override
  String get jobDetailScheduledDateLabel => "የታቀደለት ቀን";
  @override
  String get jobDetailDescriptionLabel => "מግለጫ";
  @override
  String get jobDetailAttachmentsLabel => "ተያያዥ ፋይሎች";
  @override
  String get jobDetailNoAttachments => "ምንም ተያያዥ ፋይሎች አልተሰጡም።";
  @override
  String get jobDetailAssignedWorkerLabel => "የተመደበ ባለሙያ";
  @override
  String get jobDetailNoWorkerAssigned => "እስካሁን ምንም ባለሙያ አልተመደበም።";
  @override
  String get jobDetailViewWorkerProfile => "መገለጫ ይመልከቱ";
  @override
  String get jobDetailApplicantsLabel => "አመልካቾች";
  @override
  String get jobDetailNoApplicantsYet => "እስካሁን ምንም ማመልከቻዎች አልተገኙም።";
  @override
  String get jobDetailViewApplicantsButton => "አመልካቾችን ይመልከቱ";
  @override
  String get jobDetailActionApply => "ለዚህ ስራ ያመልክቱ";
  @override
  String get jobDetailActionApplying => "በማመልከት ላይ...";
  @override
  String get jobDetailActionApplied => "ማመልከቻ ገብቷል";
  @override
  String get jobDetailActionCancelApplication => "ማመልከቻ ሰርዝ";
  @override
  String get jobDetailActionMarkComplete => "እንደተጠናቀቀ ምልክት አድርግ";
  @override
  String get jobDetailActionContactClient => "ደንበኛን ያግኙ";
  @override
  String get jobDetailActionPayNow => "ወደ ክፍያ ይቀጥሉ";
  @override
  String get jobDetailActionMessageWorker => "ባለሙያውን ያግኙ";
  @override
  String get jobDetailActionLeaveReview => "ግምገማ ይተዉ";
  @override
  String get jobDetailActionPostSimilar => "ተመሳሳይ ስራ ለጥፍ";
  @override
  String get jobDetailActionShare => "ይህንን ስራ አጋራ";
  @override
  String get jobDetailDeleteConfirmTitle => "ስራ ሰርዝ";
  @override
  String get jobDetailDeleteConfirmContent =>
      "ይህንን የስራ ማስታወቂያ እስከመጨረሻው መሰረዝ እንደሚፈልጉ እርግጠኛ ነዎት?";
  @override
  String get jobDetailDeleteConfirmKeep => "ስራውን አቆይ";
  @override
  String get jobDetailDeleteConfirmDelete => "ሰርዝ";
  @override
  String get jobDetailErrorAssigningWorker => "ሰራተኛን በመመደብ ላይ ስህተት።";
  @override
  String get jobDetailSuccessWorkerAssigned => "ሰራተኛ በተሳካ ሁኔታ ተመድቧል!";
  @override
  String get jobDetailErrorApplying => "ማመልከቻን በማስገባት ላይ ስህተት።";
  @override
  String get jobDetailSuccessApplied => "ማመልከቻ በተሳካ ሁኔታ ገብቷል!";
  @override
  String get jobDetailErrorDeleting => "ስራን በመሰረዝ ላይ ስህተት።";
  @override
  String get jobDetailSuccessDeleted => "ስራ በተሳካ ሁኔታ ተሰርዟል።";
  @override
  String get jobDetailErrorMarkingComplete =>
      "ስራን እንደተጠናቀቀ ምልክት በማድረግ ላይ ስህተት።";
  @override
  String get jobDetailSuccessMarkedComplete => "ስራ እንደተጠናቀቀ ምልክት ተደርጓል!";
  @override
  String get jobDetailFeatureComingSoon => "ይህ አገልግሎት በቅርቡ ይመጣል!";
  @override
  String get jobDetailApplicantHireButton => "ቀጥር";
  @override
  String get clientNameLabel => "ደንበኛ";

  // --- Payment Screen ---
  @override
  String get paymentScreenTitle => "የክፍያ ስልቶችን አደራጅ";
  @override
  String get paymentMethods => "የክፍያ ስልቶች";
  @override
  String get paymentAddMethod => "ስልት ጨምር";
  @override
  String get paymentNoMethod => "የክፍያ ስልት የለም";

  // Create Job Screen
  @override
  String get createJobCategoryLabel => 'የስራ አይነት (ምድብ)';
  @override
  String get createJobCategoryHint => 'የስራውን አይነት ይምረጡ';
  @override
  String get createJobErrorCategory => 'እባክዎ የስራውን አይነት ይምረጡ።';
  @override
  String get createJobSkillLabel => 'የሚፈለግ ክህሎት / ተግባር';
  @override
  String get createJobSkillHint => 'የሚፈለገውን ክህሎት ይምረጡ';
  @override
  String get createJobErrorSkill => 'እባክዎ የሚፈለገውን ክህሎት/ተግባር ይምረጡ።';
  @override
  String get attachOptionGallery => 'ከጋለሪ ይምረጡ';
  @override
  String get attachOptionCamera => 'ፎቶ አንሳ';
  @override
  String get attachOptionFile => 'ፋይል ምረጥ';
  @override
  String get attachOptionCancel => 'ይቅር';
  @override
  String get attachTitle => 'አባሪ ጨምር';
  @override
  String get createJobCalendarTitle => 'የስራ ቀን ይምረጡ';
  @override
  String get createJobCalendarCancel => 'ይቅር';
  @override
  String get createJobAppBarTitle => 'አዲስ ስራ ይፍጠሩ';
  @override
  String get createJobSelectedWorkerSectionTitle => 'የተመረጠ ሰራተኛ';
  @override
  String get createJobDetailsSectionTitle => 'የስራ ዝርዝሮች';
  @override
  String get createJobOptionalSectionTitle => 'ተጨማሪ ዝርዝሮች (አማራጭ)';
  @override
  String get createJobTitleLabel => 'የስራ ርዕስ';
  @override
  String get createJobTitleHint => 'ለምሳሌ፦ የቧንቧ ውሃ ጠብታ ማስተካከል';
  @override
  String get createJobTitleError => 'እባክዎ የስራ ርዕስ ያስገቡ።';
  @override
  String get createJobDescLabel => 'መግለጫ';
  @override
  String get createJobDescHint => 'ስለ ስራው ዝርዝር መረጃ ያቅርቡ... (ቢያንስ 20 ቁምፊዎች)';
  @override
  String get createJobDescErrorEmpty => 'እባክዎ መግለጫ ያስገቡ።';
  @override
  String get createJobDescErrorShort => 'መግለጫው ቢያንስ 20 ቁምፊዎች ሊኖረው ይገባል።';
  @override
  String get createJobBudgetLabel => 'በጀት (ብር)';
  @override
  String get createJobBudgetHint => 'ለምሳሌ፦ 500';
  @override
  String get createJobBudgetErrorEmpty => 'እባክዎ የበጀት መጠን ያስገቡ።';
  @override
  String get createJobBudgetErrorNaN => 'እባክዎ ትክክለኛ ቁጥር ለበጀት ያስገቡ።';
  @override
  String get createJobBudgetErrorPositive => 'በጀቱ ከዜሮ በላይ መሆን አለበት።';
  @override
  String get createJobLocationLabel => 'ቦታ';
  @override
  String get createJobLocationHint => 'ለምሳሌ፦ ቦሌ, አዲስ አበባ';
  @override
  String get createJobLocationError => 'እባክዎ የስራውን ቦታ ያስገቡ።';
  @override
  String get createJobScheduleLabelOptional => 'የጊዜ ሰሌዳ ቀን (አማራጭ)';
  @override
  String createJobScheduleLabelSet(String date) => 'የተያዘለት ቀን፦ $date';
  @override
  String get createJobScheduleSub => 'የሚመርጡትን ቀን ለመምረጥ ይንኩ';
  @override
  String get createJobAttachmentsLabelOptional => 'ሰነዶች (አማራጭ)';
  @override
  String get createJobAttachmentsSubAdd => 'ፎቶዎችን ወይም ሰነዶችን ለማከል ይንኩ';
  // Inside your class AppStringsAm implements AppStrings { ... }

  @override
  String get viewButton => "ይመልከቱ";
  @override
  String get carouselViewTooltip => "ካሮሰል እይታ";
  @override
  String get gridViewTooltip => "ፍርግርግ እይታ";
  @override
  String get distanceLabel => "ርቀት";
  @override
  String get locationTitle => "ቦታ";
  @override
  String get mapNotAvailable => "ካርታ የለም";
  @override
  String get mapErrorConnectivity => "ኢንተርኔት ወይም API ቁልፍ ያረጋግጡ";
  @override
  String get estimatedEtaLabel => "ግምታዊ የመድረሻ ጊዜ";
  @override
  String get viewOnMapButton => "ካርታ ላይ ይመልከቱ";
  @override
  String get snackbarFailedToLaunchMap => "ካርታ ለመክፈት አልተቻለም";
  @override
  String availableSlotsForDate(String date) => "የሚገኙ ክፍተቶች ለ $date";
  @override
  String get noSlotsAvailable => "ምንም የጊዜ ክፍተት የለም";
  @override
  String get bookSlotButton => "የጊዜ ክፍተት ያስይዙ";
  @override
  String get selectTimeSlotButton => "የጊዜ ክፍተት ይምረጡ";
  @override
  String get noInternetConnection => "የበይነመረብ ግንኙነት የለም።";
  @override
  String get locationPermissionDenied => "የቦታ ፈቃድ ተከልክሏል።";
  @override
  String get errorFetchingLocation => "ቦታ ሲመዘግብ ስህተት ተፈጠረ።";
  @override
  String get couldNotLoadVideo => "ቪዲዮውን መጫን አልተቻለም።";
  @override
  String get videoLoadFailed => "ቪዲዮ መጫን አልተሳካም።";
  @override
  String get cannotPlayVideoNoInternet => "ያለ ኢንተርኔት ቪዲዮ ማጫወት አይቻልም።";
  @override
  String get reviewJobPaymentPrerequisite =>
      "ግምገማ ለማስገባት ቢያንስ አንድ ስራ እና አንድ ክፍያ ማጠናቀቅ አለብዎት።";
  @override
  String get performanceOverviewTitle => "የአፈጻጸም አጠቃላይ እይታ";
  @override
  String get failedToMakeCall => "ጥሪ ለማድረግ አልተቻለም።";
  @override
  String get submitReviewButton => "ግምገማ አስገባ"; // Ensure this is present
  @override
  String createJobAttachmentsSubCount(int count) => '$count ፋይል(ሎች) ተያይዘዋል።';
  @override
  String get createJobUrgentLabel => 'እንደ አስቸኳይ ምልክት ያድርጉ';
  @override
  String get createJobUrgentSub => 'አስቸኳይ ስራዎች ፈጣን ምላሽ ሊያገኙ ይችላሉ';
  @override
  String get createJobButtonPosting => 'እየለጠፈ ነው...';
  @override
  String get createJobButtonPost => 'ስራውን ለጥፍ';
  @override
  String get registerErrorProfessionRequired => "እባክዎ ሙያዎን ያስገቡ።";
  @override
  String get errorPasswordShort => "የይለፍ ቃል ቢያንስ 6 ቁምፊዎች መሆን አለበት።";

  // Job Dashboard Screen
  @override
  String get dashboardTitleDefault => "ዳሽቦርድ";
  @override
  String get dashboardTitleWorker => "የእኔ የስራ ዳሽቦርድ";
  @override
  String get dashboardTitleClient => "የእኔ የስራዎች ዳሽቦርድ";
  @override
  String get tabWorkerAssigned => "ለኔ የተመደቡ";
  @override
  String get tabWorkerApplied => "የእኔ ማመልከቻዎች";
  @override
  String get tabWorkerActive => "በሂደት/ተጠናቋል";
  @override
  String get tabClientPosted => "የለጠፍኳቸው";
  @override
  String get tabClientApplications => "አመልካቾች";
  @override
  String get tabClientRequests => "ጥያቄዎቼ";
  @override
  String get filterAll => "ሁሉም";
  @override
  String get filterOpen => "ክፍት";
  @override
  String get filterPending => "በመጠባበቅ ላይ";
  @override
  String get filterAssigned => "የተመደበ";
  @override
  String get filterAccepted => "ተቀባይነት ያለው";
  @override
  String get filterInProgress => "በሂደት ላይ";
  @override
  String get filterStartedWorking => "በስራ ላይ";
  @override
  String get filterCompleted => "የተጠናቀቀ";
  @override
  String get filterCancelled => "የተሰረዘ";
  @override
  String get filterRejected => "ውድቅ የተደረገ";
  @override
  String get filterClosed => "የተዘጋ";
  @override
  String get emptyStateWorkerAssigned => "እስካሁን የተመደበልዎት ስራ የለም";
  @override
  String get emptyStateWorkerApplied => "እስካሁን ላוםንም ስራ አላመለከቱም";
  @override
  String get emptyStateWorkerActive => "በሂደት ላይ ያለ ወይም የተጠናቀቀ ስራ የለም";
  @override
  String get emptyStateClientPosted => "እስካሁን ምንም ስራ አልለጠፉም";
  @override
  String get emptyStateClientApplications => "እስካሁን ምንም ማመልከቻ አልደረሰዎትም";
  @override
  String get emptyStateClientRequests => "በቀጥታ የጠየቁት ስራ የለም";
  @override
  String get emptyStateJobsFilteredTitle => "ማጣሪያውን የሚያሟላ ስራ የለም";
  @override
  String get emptyStateJobsFilteredSubtitle =>
      "ከላይ ያለውን የሁኔታ ማጣሪያ ለማስተካከል ይሞክሩ።";
  @override
  String get emptyStateGeneralSubtitle => "በኋላ ተመልሰው ይሞክሩ ወይም ያድሱ።";
  @override
  String get noApplicantsSubtitle => "ሰራተኞች ሲያመለክቱ እዚህ ይታያሉ።";
  @override
  String get buttonAccept => "ተቀበል";
  @override
  String get buttonStartWork => "ስራ ጀምር";
  @override
  String get buttonComplete => "አጠናቅ";
  @override
  String get buttonViewApplicants => "አመልካቾችን እይ";
  @override
  String get buttonChatClient => "ደንበኛ አውራ";
  @override
  String get buttonChatWorker => "ሰራተኛ አውራ";
  @override
  String get buttonPayWorker => "ለሰራተኛ ክፈል";
  @override
  String get buttonCancelJob => "ስራ ሰርዝ";
  @override
  String get viewProfileButton => "መገለጫ እይ";
  @override
  String get viewAllApplicantsButton => "ሁሉንም እይ";
  @override
  String get buttonChat => "አውራ";
  @override
  String get jobAcceptedSuccess => "ስራው በተሳካ ሁኔታ ተቀባይነት አግኝቷል!";
  @override
  String get jobAcceptedError => "ስራውን መቀበል አልተቻለም።";
  @override
  String get jobStartedSuccess => "ስራ ተጀምሯል!";
  @override
  String get jobStartedError => "ሁኔታውን ወደ 'ተጀምሯል' ማዘመን አልተቻለም።";
  @override
  String get applicantLoadError => "አመልካቾችን በመጫን ላይ ስህተት።";
  @override
  String applicantsForJob(String jobTitle) => "ለ '$jobTitle' አመልካቾች";
  @override
  String get applicantNotFound => "አመልካች አልተገኘም";
  @override
  String get skillsLabel => "ክህሎቶች:";
  @override
  String get aboutLabel => "ስለ:";
  @override
  String get priceRangeLabel => "የዋጋ ክልል";
  @override
  String get experienceLabel => "ልምድ";
  @override
  String get phoneLabel => "ስልክ";
  @override
  String get timelinePending => "በመጠባበቅ ላይ";
  @override
  String get timelineInProgress => "በሂደት ላይ";
  @override
  String get timelineCompleted => "ተጠናቋል";

  // --- Login Screen ---
  @override
  String get loginTitle => "እንኳን ደህና መጡ!";
  @override
  String get loginWelcome => "ለመቀጠል ይግቡ";
  @override
  String get loginEmailLabel => "ኢሜል";
  @override
  String get loginEmailHint => "ኢሜልዎን ያስገቡ";
  @override
  String get loginPasswordLabel => "የይለፍ ቃል";
  @override
  String get loginPasswordHint => "የይለፍ ቃልዎን ያስገቡ";
  @override
  String get loginRememberMe => "አስታውሰኝ";
  @override
  String get loginForgotPassword => "የይለፍ ቃል ረስተዋል?";
  @override
  String get loginButton => "ግባ";
  @override
  String get loginNoAccount => "አካውንት የለዎትም? ";
  @override
  String get loginSignUpLink => "ይመዝገቡ";
  @override
  String get loginErrorUserNotFound => "ለዚህ ኢሜል ምንም ተጠቃሚ አልተገኘም።";
  @override
  String get loginErrorWrongPassword => "የተሳሳተ የይለፍ ቃል አስገብተዋል።";
  @override
  String get loginErrorInvalidEmail => "የኢሜል አድራሻው ቅርጸት ልክ አይደለም።";
  @override
  String get loginErrorUserDisabled => "ይህ የተጠቃሚ መለያ ታግዷል።";
  @override
  String get loginErrorTooManyRequests =>
      "በጣም ብዙ የመግባት ሙከራዎች። እባክዎ ቆይተው እንደገና ይሞክሩ።";
  @override
  String get loginErrorUnknown => "መግባት አልተሳካም። እባክዎ መረጃዎን ያረጋግጡ።";
  @override
  String get loginWithGoogle => "በGoogle ይግቡ";
  @override
  String get loginErrorGoogleSignIn => "በGoogle መግባት አልተሳካም። እባክዎ እንደገና ይሞክሩ።";

  // --- Register Screen ---
  @override
  String get registerTitle => "አካውንት ፍጠር";
  @override
  String get registerSubtitle => "የደንበኞች እና ባለሙያዎች ማህበረሰባችንን ይቀላቀሉ";
  @override
  String get registerUserTypePrompt => "እኔ:";
  @override
  String get registerUserTypeClient => "ደንበኛ (ቀጣሪ)";
  @override
  String get registerUserTypeWorker => "ባለሙያ (ሰራተኛ)";
  @override
  String get registerProfessionLabel => "የእርስዎ ሙያ";
  @override
  String get registerProfessionHint => "ለምሳሌ፦ የቧንቧ ሰራተኛ፣ ኤሌክትሪሻን";
  @override
  String get registerFullNameLabel => "ሙሉ ስም";
  @override
  String get registerFullNameHint => "ሙሉ ስምዎን ያስገቡ";
  @override
  String get registerPhoneLabel => "ስልክ ቁጥር";
  @override
  String get registerPhoneHint => "ስልክ ቁጥርዎን ያስገቡ";
  @override
  String get registerConfirmPasswordLabel => "የይለፍ ቃል አረጋግጥ";
  @override
  String get registerConfirmPasswordHint => "የይለፍ ቃልዎን እንደገና ያስገቡ";
  @override
  String get registerButton => "አካውንት ፍጠር";
  @override
  String get registerHaveAccount => "አካውንት አለዎት? ";
  @override
  String get registerSignInLink => "ይግቡ";
  @override
  String get registerErrorPasswordMismatch => "የይለፍ ቃሎች አይዛመዱም።";
  @override
  String get registerErrorWeakPassword => "የቀረበው የይለፍ ቃል በጣም ደካማ ነው።";
  @override
  String get registerErrorEmailInUse => "ለዚህ ኢሜል አካውንት አስቀድሞ አለ።";
  @override
  String get registerErrorInvalidEmailRegister => "የኢሜል አድራሻው ቅርጸት ልክ አይደለም።";
  @override
  String get registerErrorUnknown => "ምዝገባ አልተሳካም። እባክዎ እንደገና ይሞክሩ።";
  @override
  String get registerWithGoogle => "በGoogle ይመዝገቡ";
  @override
  String get registerSuccess => "ምዝገባው ተሳክቷል!";
  @override
  String get registerNavigateToSetup => "ወደ ባለሙያ ማዋቀሪያ በመሄድ ላይ...";
  @override
  String get registerNavigateToHome => "ወደ መነሻ በመሄድ ላይ...";

  // --- Forgot Password Screen ---
  @override
  String get forgotPasswordTitle => "የይለፍ ቃል ዳግም አስጀምር";
  @override
  String get forgotPasswordInstructions =>
      "የኢሜል አድራሻዎን ከታች ያስገቡ እና የይለፍ ቃልዎን ዳግም ለማስጀመር ሊንክ እንልክልዎታለን።";
  @override
  String get forgotPasswordButton => "የዳግም ማስጀመሪያ ሊንክ ላክ";
  @override
  String get forgotPasswordSuccess =>
      "የይለፍ ቃል ዳግም ማስጀመሪያ ኢሜል ተልኳል! እባክዎ የገቢ መልዕክት ሳጥንዎን ያረጋግጡ።";
  @override
  String get forgotPasswordError =>
      "የዳግም ማስጀመሪያ ኢሜል በመላክ ላይ ስህተት። እባክዎ አድራሻውን ያረጋግጡና እንደገና ይሞክሩ።";
  @override
  String get jobCancelledSuccessfullyText => "ስራው ተሰርዟል።";

  @override
  String get applicationAcceptedSuccessfullyText => "መተግበሪያው ተቀብሏል።";

  @override
  String get jobAcceptedSuccessfullyText => "ስራው ተቀብሏል።";

  @override
  String get jobMarkedAsCompletedSuccessfullyText => "ስራው ተጠናቅቋል።";

  @override
  String get workStartedSuccessfullyText => "ስራው ተጀምሯል።";

  @override
  String get applicationDeclinedSuccessfullyText => "መተግበሪያው ተቀናጀ።";

  @override
  String get loadingText => "በመጫን ላይ...";
  // --- Helper Method Implementations ---
  @override
  String getStatusName(String key) {
    switch (key.toLowerCase()) {
      case 'open':
        return filterOpen;
      case 'pending':
        return filterPending;
      case 'assigned':
        return filterAssigned;
      case 'accepted':
        return filterAccepted;
      case 'in_progress':
        return filterInProgress;
      case 'started working':
        return filterStartedWorking;
      case 'completed':
        return filterCompleted;
      case 'cancelled':
        return filterCancelled;
      case 'rejected':
        return filterRejected;
      case 'closed':
        return filterClosed;
      default:
        return key.toUpperCase();
    }
  }

  @override
  IconData? getFilterIcon(String key) {
    switch (key.toLowerCase()) {
      case 'all':
        return Icons.list_alt_rounded;
      case 'open':
        return Icons.lock_open_rounded;
      case 'pending':
        return Icons.pending_actions_rounded;
      case 'assigned':
        return Icons.assignment_ind_outlined;
      case 'accepted':
        return Icons.check_circle_outline_rounded;
      case 'in_progress':
        return Icons.construction_rounded;
      case 'started working':
        return Icons.play_circle_outline_rounded;
      case 'completed':
        return Icons.task_alt_rounded;
      case 'cancelled':
        return Icons.cancel_outlined;
      case 'rejected':
        return Icons.thumb_down_alt_outlined;
      case 'closed':
        return Icons.lock_outline_rounded;
      default:
        return null;
    }
  }

  @override
  String getFilterName(String key) => getStatusName(key);
  @override
  IconData? getEmptyStateIcon(String key) {
    if (key == emptyStateWorkerAssigned) return Icons.assignment_late_outlined;
    if (key == emptyStateWorkerApplied) {
      return Icons.playlist_add_check_circle_outlined;
    }
    if (key == emptyStateWorkerActive) return Icons.construction_rounded;
    if (key == emptyStateClientPosted) return Icons.post_add_rounded;
    if (key == emptyStateClientApplications) return Icons.people_alt_outlined;
    if (key == emptyStateClientRequests) return Icons.request_page_outlined;
    return Icons.search_off_rounded;
  }

  @override
  String yearsExperience(int years) => "$years ዓመት ልምድ";
  @override
  String applicantCount(int count) => "$count አመልካች${count == 1 ? '' : 'ዎች'}";
  @override
  String jobsCompleted(int count) => "$count ስራዎች ተጠናቀዋል";
  @override
  String formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inSeconds < 60) return timeAgoJustNow;
    if (difference.inMinutes < 60) return timeAgoMinute(difference.inMinutes);
    if (difference.inHours < 24) return timeAgoHour(difference.inHours);
    if (difference.inDays < 7) return timeAgoDay(difference.inDays);
    if (difference.inDays < 30) {
      return timeAgoWeek((difference.inDays / 7).floor());
    }
    if (difference.inDays < 365) {
      return timeAgoMonth((difference.inDays / 30).floor());
    }
    return timeAgoYear((difference.inDays / 365).floor());
  }

  @override
  String errorFieldRequired(String fieldName) => "እባክዎ $fieldName ያስገቡ።";
  @override
  String getUserTypeDisplayName(String key) {
    switch (key) {
      case 'registerUserTypeClient':
        return registerUserTypeClient;
      case 'registerUserTypeWorker':
        return registerUserTypeWorker;
      default:
        return key;
    }
  }

  // --- NEWLY ADDED based on errors for Job Dashboard ---
  @override
  String errorLoadingData(String errorDetails) =>
      "መረጃ በመጫን ላይ ስህተት፡ $errorDetails";
  @override
  String errorLoadingJobs(String errorDetails) =>
      "ስራዎችን በመጫን ላይ ስህተት፡ $errorDetails";
  @override
  String get jobCancelledSuccess => "ስራው በተሳካ ሁኔታ ተሰርዟል።";
  @override
  String errorCancellingJob(String errorDetails) =>
      "ስራን በመሰረዝ ላይ ስህተት፡ $errorDetails";
  @override
  String get applicationAcceptedSuccess => "ማመልከቻ በተሳካ ሁኔታ ተቀባይነት አግኝቷል።";
  @override
  String errorAcceptingApplication(String errorDetails) =>
      "ማመልከቻን በመቀበል ላይ ስህተት፡ $errorDetails";
  @override
  String errorAcceptingJob(String errorDetails) =>
      "ስራን በመቀበል ላይ ስህተት፡ $errorDetails";
  @override
  String errorStartingWork(String errorDetails) =>
      "ስራን በመጀመር ላይ ስህተት፡ $errorDetails";
  @override
  String get jobCompletedSuccess => "ስራው በተሳካ ሁኔታ ተጠናቋል።";
  @override
  String errorCompletingJob(String errorDetails) =>
      "ስራን በማጠናቀቅ ላይ ስህተት፡ $errorDetails";
  @override
  String get jobStatusPending => "በመጠባበቅ ላይ";
  @override
  String get jobStatusActive => "በሂደት ላይ"; // Or "ገባሪ"
  @override
  String get jobStatusInProgress => "በሂደት ላይ";
  @override
  String get jobStatusCancelled => "የተሰረዘ";
  @override
  String get jobStatusRejected => "ውድቅ የተደረገ";
  @override
  String get jobStatusClosed => "የተዘጋ";
  @override
  String get jobStatusStartedWorking => "ስራ ተጀምሯል";
  @override
  String get myWorkDashboard => "የእኔ የስራ ዳሽቦርድ";
  @override
  String get myJobsDashboard => "የእኔ ስራዎች ዳሽቦርድ";
  @override
  String get assignedJobsTab => "የተመደቡ"; // Tab title
  @override
  String get myApplicationsTab => "ማመልከቻዎቼ"; // Tab title
  @override
  String get activeWorkTab => "በሂደት ያሉ"; // Tab title
  @override
  String get myPostedJobsTab => "የለጠፍኳቸው"; // Tab title
  @override
  String get applicationsTab => "ማመልከቻዎች"; // Tab title for client
  @override
  String get myRequestsTab => "ጥያቄዎቼ"; // Tab title
  @override
  String assignedJobsCount(int count) =>
      "$count የተመደቡ ስራ${count == 1 ? '' : 'ዎች'}";
  @override
  String get noAssignedJobsTitle => "እስካሁን የተመደበ ስራ የለም";
  @override
  String get noAssignedJobsSubtitle => "ስራዎች ሲመደቡልዎት እዚህ ያገኟቸዋል።";
  @override
  String jobsCount(int count) => "$count ስራ${count == 1 ? '' : 'ዎች'}";
  @override
  String get noApplicationsYetTitle => "እስካሁን ምንም ማመልከቻ የለም";
  @override
  String get noApplicationsYetSubtitleWorker => "ለስራዎች ያመለከቱት እዚህ ይታያል።";
  @override
  String activeJobsCount(int count) =>
      "$count በሂደት ላይ ያለ ስራ${count == 1 ? '' : 'ዎች'}";
  @override
  String get noActiveWorkTitle => "በሂደት ላይ ያለ ስራ የለም";
  @override
  String get noActiveWorkSubtitle => "ተቀብለው እየሰሯቸው ያሉ ስራዎች እዚህ ይታያሉ።";
  @override
  String get noPostedJobsTitle => "እስካሁን የለጠፉት ስራ የለም";
  @override
  String get noPostedJobsSubtitle => "ባለሙያዎችን ለማግኘት ስራ ይለጥፉ።";
  @override
  String get noApplicationsYetSubtitleClient =>
      "ባለሙያዎች ለስራዎ ሲያመለክቱ እዚህ ያገኟቸዋል።";
  @override
  String get noJobRequestsTitle => "እስካሁን የተጠየቀ ስራ የለም";
  @override
  String get workerDetailTabOverview => "አጠቃላይ መግለጫ";
  @override
  String workerDetailTabAbout = "ስለ ሰራተኛው";

  @override
  String get noJobRequestsSubtitle => "በቀጥታ ከባለሙያዎች የጠየቋቸው ስራዎች እዚህ ይዘረዘራሉ።";
  @override
  String workerCardDistanceAway(String km) => 'ከዚህ $km ኪ.ሜ ይርቃል';
  @override
  String postedTimeAgo(String timeAgo) => "የተለጠፈው $timeAgo";
  @override
  String applicantsCount(int count) => "$count አመልካች${count == 1 ? '' : 'ዎች'}";
  @override
  String get waitingForWorkerToAccept => "እርስዎ እንዲቀበሉ/ውድቅ እንዲያደርጉ በመጠበቅ ላይ።";
  @override
  String get yourWorkIsPending => "ለዚህ ስራ የእርስዎ እርምጃ በመጠበቅ ላይ ነው።";
  @override
  String get payButton => "አሁን ክፈል";
  @override
  String get viewDetailsButton => "ዝርዝሮችን እይ";
  @override
  String get acceptButton => "ተቀበል";
  @override
  String get startButton => "ስራ ጀምር";
  @override
  String get completeButton => "እንደተጠናቀቀ ምልክት አድርግ";
  @override
  String get manageButton => "አደራጅ";
  @override
  String get postAJobButton => "ስራ ለጥፍ";
  @override
  String jobApplicationsScreenTitle(String jobTitle) => "ለ '$jobTitle' አመልካቾች";
  @override
  String get myWorkDashboardText => "የእኔ የስራ ዳሽቦርድ";
  @override
  String get myJobsDashboardText => "የእኔ ስራዎች ዳሽቦርድ";
  @override
  String get assignedJobsText => "የተሰጡኝ ስራዎች";
  @override
  String get myApplicationsText => "የእኔ ማመልከቻዎች";
  @override
  String get activeWorkText => "በሂደት ላይ ያሉ ስራዎች";
  @override
  String get myPostedJobsText => "የእኔ የተለጠፉ ስራዎች";
  @override
  String get applicationsText => "ማመልከቻዎች";
  @override
  String get myRequestsText => "የእኔ ጥያቄዎች";
  @override
  String get allText => "ሁሉም";
  @override
  String get openText => "ክፍት";
  @override
  String get pendingText => "በመጠባበቅ ላይ";
  @override
  String get acceptedText => "ተቀባይነት አግኝቷል";
  @override
  String get completedText => "ተጠናቋል";
  @override
  String get closedText => "ተዘግቷል";
  @override
  String get cancelledText => "ተሰርዟል";
  @override
  String get rejectedText => "ውድቅ ተደርጓል";
  @override
  String get inProgressText => "በሂደት ላይ";
  @override
  String get jobText => "ስራ";
  @override
  String get jobsText => "ስራዎች";
  @override
  String get assignedJobText => "የተሰጠ ስራ";
  @override
  String get assignedJobsPluralText => "የተሰጡ ስራዎች";
  @override
  String get activeJobText => "በሂደት ላይ ያለ ስራ";
  @override
  String get activeJobsPluralText => "በሂደት ላይ ያሉ ስራዎች";
  @override
  String get postedText => "የተለጠፈው";
  @override
  String get agoText => "በፊት";
  @override
  String get applicantText => "አመልካች";
  @override
  String get applicantsText => "አመልካቾች";
  @override
  String get noApplicantsText => "ምንም አመልካች የለም";
  @override
  String get waitingForWorkerToAcceptText => "ሰራተኛው እንዲቀበል በመጠባበቅ ላይ";
  @override
  String get yourWorkingIsOnPendingText => "ስራዎ በመጠባበቅ ላይ ነው";
  @override
  String get payText => "ክፈል";
  @override
  String get viewDetailsText => "ዝርዝሮችን ይመልከቱ";
  @override
  String get rateText => "ደረጃ ይስጡ";
  @override
  String get manageText => "አስተዳድር";
  @override
  String get postAJobText => "ስራ ይለጥፉ";
  @override
  String get noAssignedJobsYetText => "እስካሁን የተሰጠ ስራ የለም";
  @override
  String get whenJobsAreAssignedToYouText => "ስራዎች ሲሰጡዎት እዚህ ይታያሉ፡፡";
  @override
  String get noApplicationsYetText => "እስካሁን ምንም ማመልከቻ የለም";
  @override
  String get jobsYouApplyForWillAppearHereText => "ለሚያመለክቷቸው ስራዎች እዚህ ይታያሉ፡፡";
  @override
  String get noActiveWorkText => "በሂደት ላይ ያለ ስራ የለም";
  @override
  String get yourActiveJobsWillAppearHereText => "በሂደት ላይ ያሉ ስራዎችዎ እዚህ ይታያሉ፡፡";
  @override
  String get noPostedJobsYetText => "እስካሁን የተለጠፈ ስራ የለም";
  @override
  String get tapThePlusButtonToPostYourFirstJobText =>
      "የመጀመሪያ ስራዎን ለመለጠፍ + ቁልፉን ይጫኑ፡፡";
  @override
  String get noJobRequestsText => "ምንም የስራ ጥያቄ የለም";
  @override
  String get yourPersonalJobRequestsWillAppearHereText =>
      "የግል የስራ ጥያቄዎችዎ እዚህ ይታያሉ፡፡";
  @override
  String get aboutText => "ስለ";
  @override
  String get skillsText => "ችሎታዎች";
  @override
  String get viewProfileText => "መገለጫ ይመልከቱ";
  @override
  String get acceptText => "ተቀበል";
  @override
  String get declineText => "እምቢ በል";
  @override
  String get applicantsForText => "አመልካቾች ለ";
  @override
  String get couldNotLoadApplicantText => "አመልካች መጫን አልተቻለም";
  @override
  String get moreApplicantsText => "ተጨማሪ አመልካቾች";
  @override
  String get professionalSetupTitle => "መገለጫ ያርትዑ";
  @override
  String get professionalSetupSubtitle => "የተሟላ መገለጫ ብዙ ደንበኞችን ይስባል።";
  @override
  String get professionalSetupSaveAll => "ሁሉንም አስቀምጥ";
  @override
  String get professionalSetupSaving => "እያስቀመጠ ነው...";

  // SnackBar Messages
  @override
  String get professionalSetupErrorNotLoggedIn => "ስህተት፡ አልገቡም።";
  @override
  String professionalSetupErrorLoading(String error) =>
      "መገለጫ መጫን አልተቻለም፡ $error";
  @override
  String get professionalSetupErrorFormValidation =>
      "ከማስቀመጥዎ በፊት እባክዎ ስህተቶቹን ያስተካክሉ።";
  @override
  String get professionalSetupInfoUploadingMedia =>
      "ሚዲያ እየሰቀለ ነው፣ እባክዎ ይጠብቁ...";
  @override
  String get professionalSetupInfoSavingData => "የመገለጫ መረጃ በማስቀመጥ ላይ...";
  @override
  String get professionalSetupSuccess => "መገለጫ በተሳካ ሁኔታ ተቀምጧል!";
  @override
  String professionalSetupErrorSaving(String error) =>
      "መገለጫ ማስቀመጥ አልተሳካም፦ $error";
  @override
  String get professionalSetupErrorLocationDisabled => "የአካባቢ አገልግሎቶች ጠፍተዋል።";
  @override
  String get professionalSetupErrorLocationDenied => "የአካባቢ ፈቃዶች ተከልክለዋል።";
  @override
  String get professionalSetupErrorLocationPermanentlyDenied =>
      "የአካባቢ ፈቃዶች በቋሚነት ተከልክለዋል።";
  @override
  String professionalSetupErrorGettingLocation(String error) =>
      "አካባቢን ማግኘት አልተቻለም፦ $error";
  @override
  String get professionalSetupErrorMaxImages => "ቢበዛ 6 ምስሎችን ብቻ ማስገባት ይችላሉ።";

  // Wide Layout Navigation
  @override
  String get professionalSetupNavHeader => "የመገለጫ ክፍሎች";
  @override
  String get professionalSetupNavBasic => "መሰረታዊ መረጃ";
  @override
  String get professionalSetupNavExpertise => "ሙያ እና ችሎታ";
  @override
  String get professionalSetupNavLocation => "አካባቢ እና ራዲየስ";
  @override
  String get professionalSetupNavShowcase => "የስራ ማሳያ";
  @override
  String get professionalSetupNavRates => "ዋጋ እና ሰዓት";

  // Profile Strength Indicator
  @override
  String get professionalSetupStrengthTitle => "የመገለጫ ጥንካሬ";
  @override
  String get professionalSetupStrengthIncomplete =>
      "መገለጫዎ አልተጠናቀቀም። ለበለጠ ፍለጋ ተጨማሪ ዝርዝሮችን ያክሉ።";
  @override
  String get professionalSetupStrengthGood =>
      "ጥሩ ይመስላል! ጥቂት ተጨማሪ ዝርዝሮች መገለጫዎን ጎልቶ እንዲወጣ ያደርጉታል።";
  @override
  String get professionalSetupStrengthExcellent =>
      "በጣም ጥሩ! መገለጫዎ የተሟላ እና ደንበኞችን ለመሳብ ዝግጁ ነው።";

  // Section: Basic Info
  @override
  String get professionalSetupBasicTitle => "መሰረታዊ መረጃ";
  @override
  String get professionalSetupBasicSubtitle =>
      "ደንበኞች መጀመሪያ የሚያዩት ይህንን ነው። ጥሩ ስሜት ይፍጠሩ።";
  @override
  String get professionalSetupLabelName => "ሙሉ ስም";
  @override
  String get professionalSetupHintName => "ለምሳሌ፦ አበበ ቢቂላ";
  @override
  String get professionalSetupLabelProfession => "ዋና ሙያ";
  @override
  String get professionalSetupHintProfession => "ለምሳሌ፦ ማስተር ኤሌክትሪሺያን";
  @override
  String get professionalSetupLabelPhone => "የህዝብ መገኛ ስልክ ቁጥር";
  @override
  String get professionalSetupHintPhone => "+251 9...";
  @override
  String professionalSetupValidatorRequired(String label) => "$label ያስፈልጋል።";

  // Section: Expertise
  @override
  String get professionalSetupExpertiseTitle => "የእርስዎ ሙያ";
  @override
  String get professionalSetupExpertiseSubtitle => "የልምድ እና የክህሎትዎን ዝርዝር ያስገቡ።";
  @override
  String get professionalSetupLabelExperience => "የሙያ ልምድ (በአመታት)";
  @override
  String get professionalSetupHintExperience => "ለምሳሌ፦ 5";
  @override
  String get professionalSetupLabelBio => "የሙያ ታሪክ";
  @override
  String get professionalSetupHintBio =>
      "ስለራስዎ፣ ስለስራ ስነምግባርዎ እና አገልግሎትዎን ልዩ ስለሚያደርገው ነገር ይግለጹ።";

  // Section: Skills
  @override
  String get professionalSetupSkillsDialogTitle => "ችሎታዎችዎን ይምረጡ";
  @override
  String get professionalSetupSkillsDialogSubtitle =>
      "ከሙያዎ ጋር የሚዛመዱትን ሁሉንም ችሎታዎች ይምረጡ።";
  @override
  String get professionalSetupSkillsDialogCancel => "ይቅር";
  @override
  String get professionalSetupSkillsDialogConfirm => "ችሎታዎችን ያረጋግጡ";
  @override
  String get professionalSetupSkillsEmptyButton => "ችሎታዎችዎን ይምረጡ";
  @override
  String get professionalSetupSkillsEditButton => "አክል/አስተካክል";
  @override
  String get professionalSetupSkillsSelectedTitle => "የተመረጡ ችሎታዎች";

  // Section: Location
  @override
  String get professionalSetupLocationTitle => "የአገልግሎት ክልል";
  @override
  String get professionalSetupLocationSubtitle =>
      "ዋና አካባቢዎን እና ለስራ ለመጓዝ ፈቃደኛ የሆኑበትን ርቀት ይግለጹ።";
  @override
  String get professionalSetupLabelCity => "ዋና ከተማ ወይም ሰፈር";
  @override
  String get professionalSetupHintCity => "ለምሳሌ፦ አዲስ አበባ፣ ኢትዮጵያ";
  @override
  String get professionalSetupTooltipGetLocation => "የአሁኑን ቦታ ያግኙ";
  @override
  String get professionalSetupServiceRadiusTitle => "የአገልግሎት ራዲየስ";
  @override
  String get professionalSetupServiceRadiusSubtitle =>
      "ለስራዎች ከአካባቢዎ ለመጓዝ ፈቃደኛ የሆኑበት ርቀት።";

  // Section: Showcase
  @override
  String get professionalSetupShowcaseTitle => "የሚዲያ ማሳያ";
  @override
  String get professionalSetupShowcaseSubtitle =>
      "በግል ቪዲዮ እና በስራዎ ፎቶዎች መተማመንን ይገንቡ።";
  @override
  String get professionalSetupVideoTitle => "የቪዲዮ መግቢያ";
  @override
  String get professionalSetupVideoEmptyButton => "የቪዲዮ መግቢያ አክል";
  @override
  String get professionalSetupGalleryTitle => "የስራ ማዕከለ-ስዕላት (ቢበዛ 6)";
  @override
  String get professionalSetupCertificationsTitle =>
      "የምስክር ወረቀቶች እና ፍቃዶች (ቢበዛ 6)";
  @override
  String get professionalSetupImageEmptyButton => "ምስል አክል";

  // Section: Operations
  @override
  String get professionalSetupOperationsTitle => "የንግድ ሥራዎች";
  @override
  String get professionalSetupOperationsSubtitle =>
      "የሰዓት ክፍያዎን እና የሳምንቱን የስራ መርሃ ግብር ያዘጋጁ።";
  @override
  String get professionalSetupPricingTitle => "ዋጋ";
  @override
  String get professionalSetupLabelRate => "መነሻ ዋጋ (በሰዓት፣ በብር)";
  @override
  String get professionalSetupAvailabilityTitle => "ሳምንታዊ ተገኝነት";
  @override
  String get professionalSetupAvailabilityTo => "እስከ";
}

// ===========================================================
//                 Oromo Implementation (Placeholder)
// ===========================================================
// TODO: Create AppStringsOm class implementing AppStrings with Oromo translations

// ===========================================================
//           Localization Delegate and Helper
// ===========================================================
class AppLocalizations {
  final Locale locale;
  final AppStrings strings;

  AppLocalizations(this.locale, this.strings);

  static AppStrings? of(BuildContext context) {
    try {
      // Use Provider for locale state management
      final provider = Provider.of<LocaleProvider>(context, listen: false);
      return getStrings(provider.locale);
    } catch (e) {
      debugPrint(
          "Error getting AppLocalizations via Provider: $e. Using default (English).");
      return _localizedValues['en']!; // Fallback
    }
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, AppStrings> _localizedValues = {
    'en': AppStringsEn(),
    'am': AppStringsAm(),
    // 'om': AppStringsOm(), // Uncomment and implement when Oromo is added
  };

  static AppStrings getStrings(Locale locale) {
    return _localizedValues[locale.languageCode] ?? _localizedValues['en']!;
  }

  static Iterable<Locale> get supportedLocales =>
      _localizedValues.keys.map((langCode) => Locale(langCode));
}

// Delegate for loading strings
class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  // Update with all supported language codes
  static const _supportedLanguageCodes = ['en', 'am']; // Add 'om' when ready

  @override
  bool isSupported(Locale locale) =>
      _supportedLanguageCodes.contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppStrings strings = AppLocalizations.getStrings(locale);
    return AppLocalizations(locale, strings);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;

  // Expose supported locales for MaterialApp
  Iterable<Locale> get supportedLocales =>
      _supportedLanguageCodes.map((langCode) => Locale(langCode));
}
