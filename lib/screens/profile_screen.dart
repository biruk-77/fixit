// lib/screens/profile/profile_screen.dart
// --- Dynamic Layered Profile: Responsive Hero with Interactive Cards ---

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth; // Alias
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:intl/intl.dart'; // Required for date formatting
import 'dart:io';
// For ImageFilter.blur

import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart'; // Import Provider

// Your project specific imports (ADJUST PATHS AS NEEDED)
import '../services/firebase_service.dart';
import '../models/user.dart';
import '../models/job.dart'; // Ensure Job model is imported
import '../services/app_string.dart'; // Your localization file (AppStrings, AppLocalizations)
import '../providers/locale_provider.dart'; // Your locale provider
import '../providers/theme_provider.dart'; // Your theme provider

// --- Placeholder Screens (Replace with your actual implementations) ---
// Assuming these are external files as per your project structure
import 'notifications_screen.dart'; // Already defined
import 'payment/managepayment.dart'; // Already defined (Ensure it's a class not commented out)
import 'privacy_security_screen.dart'; // Already defined
import 'account_screen.dart'; // Already defined (Used for client profile editing)
import 'help_support_screen.dart'; // Already defined
import 'professional_setup_edit.dart'; // Already defined (Used for professional profile editing)
import 'auth/login_screen.dart'; // Already defined
import 'jobs/job_detail_screen.dart'; // Already defined
// Assuming this is defined for navigation, could be placeholder

// --- Profile Screen ---

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

// Changed to TickerProviderStateMixin to allow multiple AnimationControllers
class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = true;
  bool _isUploadingImage = false;
  AppUser? _userProfile;
  bool isVerified = false;
  bool _isAvatarPressed =
      false; // Will be updated from _userProfile.isEmailVerified

  // --- Animation Controllers for the NEW design ---
  // For the avatar's pulsating glow effect
  late AnimationController _glowAnimationController;
  late Animation<double> _glowAnimation;

  // For initial staggered entry/fade-in of content sections
  late AnimationController _staggeredEntryController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // For managing scroll position to create header collapse effects
  final ScrollController _scrollController = ScrollController();
  double _headerScrollOffset = 0.0;

  @override
  void initState() {
    super.initState();

    // Initialize pulsating glow animation for the avatar
    _glowAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // Full cycle duration
    )..repeat(reverse: true); // Repeats back and forth
    _glowAnimation = Tween<double>(begin: 0.0, end: 8.0).animate(
      CurvedAnimation(
        parent: _glowAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Initialize staggered entry animations for content sections
    _staggeredEntryController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 800,
      ), // Total duration for all content to appear
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _staggeredEntryController, curve: Curves.easeIn),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _staggeredEntryController,
            curve: Curves.easeOutCubic,
          ),
        );

    // Add listener to the scroll controller for dynamic header effects
    _scrollController.addListener(() {
      setState(() {
        _headerScrollOffset = _scrollController.offset;
      });
    });

    // Load user profile after widgets are built, or if user is already logged in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (_firebaseService.getCurrentUser() == null) {
          // If no user is logged in, show an empty state or redirect to login
          setState(() => _isLoading = false);
          Navigator.of(
            context,
          ).pushReplacementNamed('/login'); // Example redirect
        } else {
          _loadUserProfile();
        }
      }
    });
  }

  @override
  void dispose() {
    _glowAnimationController.dispose();
    _staggeredEntryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // --- Data Loading ---
  /// Fetches the current user's profile from FirebaseService and updates the state.
  /// Manages loading and error states.
  Future<void> _loadUserProfile() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _isUploadingImage = false; // Reset upload state on refresh
    });

    // Access localization strings from the context
    final AppStrings? strings = AppLocalizations.of(context);
    if (strings == null) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error: Localization service not available.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return;
    }

    try {
      final userData = await _firebaseService.getCurrentUserProfile();
      if (!mounted) return;

      // Start content entry animation after profile loads
      _staggeredEntryController.forward(from: 0.0);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (mounted) {
        final errorMsg = strings.snackErrorLoadingProfile;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$errorMsg $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  // --- Image Picking and Uploading Logic ---
  /// Displays a modal bottom sheet for image source selection (Gallery/Camera).
  void _showImagePickerOptions() {
    final AppStrings strings = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(
                  Icons.photo_library,
                  color: theme.colorScheme.primary,
                ),
                title: Text(
                  strings.attachOptionGallery,
                  style: theme.textTheme.bodyLarge,
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickAndUploadImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.photo_camera,
                  color: theme.colorScheme.primary,
                ),
                title: Text(
                  strings.attachOptionCamera,
                  style: theme.textTheme.bodyLarge,
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickAndUploadImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.cancel, color: theme.colorScheme.error),
                title: Text(
                  strings.generalCancel,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                onTap: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  /// Handles the full lifecycle of picking, cropping, uploading an image,
  /// and updating the user's profile with the new image URL.
  Future<void> _pickAndUploadImage(ImageSource source) async {
    final AppStrings strings = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    if (_isUploadingImage || !mounted) return;

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null && mounted) {
        final CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Image',
              toolbarColor: theme.primaryColor,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
            ),
            IOSUiSettings(title: 'Crop Image', aspectRatioLockEnabled: true),
          ],
        );
        if (croppedFile != null && mounted) {
          setState(() => _isUploadingImage = true);

          final imageFile = File(croppedFile.path);
          final String? imageUrl = await _firebaseService
              .uploadProfileImageToSupabase(imageFile);

          if (imageUrl != null && mounted) {
            final userId = fb_auth.FirebaseAuth.instance.currentUser?.uid;
            final userRole = _userProfile?.role;

            if (userId != null && userRole != null) {
              try {
                await _firebaseService.updateUserProfileImageInFirestore(
                  userId,
                  imageUrl,
                  userRole,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(strings.snackSuccessProfileUpdated),
                      backgroundColor: Colors.green,
                    ),
                  );
                  await _loadUserProfile();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${strings.snackErrorSubmitting}: $e'),
                      backgroundColor: theme.colorScheme.error,
                    ),
                  );
                }
              }
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(strings.errorUserNotLoggedIn),
                    backgroundColor: theme.colorScheme.error,
                  ),
                );
              }
            }
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(strings.createJobSnackbarErrorUpload),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          }
        }
      } else if (mounted && pickedFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings.createJobSnackbarFileCancelled),
            duration: const Duration(seconds: 2),
            backgroundColor: theme.colorScheme.secondaryContainer,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = strings.snackErrorGeneric;
        if (e.toString().contains('camera_access_denied')) {
          errorMessage = strings.snackErrorCameraPermission;
        } else if (e.toString().contains('photo_access_denied')) {
          errorMessage = strings.snackErrorGalleryPermission;
        } else if (e.toString().contains('camera unavailable')) {
          errorMessage = strings.snackErrorCameraNotAvailable;
        } else {
          errorMessage = '$errorMessage: $e';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted && _isUploadingImage) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    // Get localized strings and theme data from providers
    final AppStrings? strings = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (strings == null) {
      // Fallback for when localization is not yet loaded
      return Scaffold(
        appBar: AppBar(title: const Text("Profile")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      // The CustomAppBar is removed here, as the new design uses a custom SliverAppBar directly
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : _userProfile == null
          ? _buildErrorState(context, strings, theme)
          : _buildProfileContent(context, strings, theme),
    );
  }

  // --- Widget Building Helper Methods ---

  /// Builds the error state widget when profile data is not found or loaded.
  Widget _buildErrorState(
    BuildContext context,
    AppStrings strings,
    ThemeData theme,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off_outlined,
              size: 60,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              strings.profileNotFound,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'We couldn\'t load your profile details. Please check your connection and try again.', // TODO: Localize this string
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 25),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: Text(strings.retryButton),
              onPressed: _loadUserProfile,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the main content of the profile screen, wrapped in a RefreshIndicator
  /// and using a CustomScrollView for advanced layout and scroll effects.
  Widget _buildProfileContent(
    BuildContext context,
    AppStrings strings,
    ThemeData theme,
  ) {
    if (_userProfile == null) {
      return _buildErrorState(context, strings, theme);
    }
    final bool isWorker =
        _userProfile!.role == 'worker' || _userProfile!.role == 'professional';

    return RefreshIndicator(
      onRefresh: _loadUserProfile,
      color: theme.colorScheme.primary,
      backgroundColor: theme.colorScheme.surface,
      child: CustomScrollView(
        // CustomScrollView allows for SliverAppBar and other custom scroll effects
        controller: _scrollController,
        physics:
            const AlwaysScrollableScrollPhysics(), // Ensures pull-to-refresh works even if content is small
        slivers: [
          _buildDynamicHeader(
            context,
            strings,
            theme,
          ), // The new dynamic header
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Staggered entry animations for the main content blocks
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAboutMeSection(context, strings, theme, isWorker),
                        const SizedBox(height: 24),
                        _buildContactAndJoinedInfo(context, strings, theme),
                        const SizedBox(height: 24),
                        _buildProfileStatsSection(
                          context,
                          strings,
                          theme,
                          isWorker,
                        ),
                        const SizedBox(height: 24),
                        _buildJobHistorySection(
                          context,
                          strings,
                          theme,
                          isWorker,
                        ),
                        const SizedBox(height: 24),
                        _buildSettingsSection(context, strings, theme),
                        const SizedBox(height: 32),
                        _buildEditProfileButton(
                          context,
                          strings,
                          theme,
                          isWorker,
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  /// --- NEW: Dynamic Header (SliverAppBar with FlexibleSpaceBar) ---
  /// This section creates a rich, interactive header that collapses into a standard AppBar.
  SliverAppBar _buildDynamicHeader(
    BuildContext context,
    AppStrings strings,
    ThemeData theme,
  ) {
    final profileData = _userProfile!;
    final name = profileData.name.isNotEmpty
        ? profileData.name
        : (profileData.email ?? 'No Name');
    final profileImage = profileData.profileImage;
    String userTypeDisplay = strings.getUserTypeDisplayName(profileData.role);

    const double avatarRadiusExpanded = 50; // Size when expanded
    const double expandedHeight = 280.0; // Total height of the flexible space
    const double minHeight =
        kToolbarHeight + 40; // A bit taller than default AppBar when collapsed

    // Calculate opacity and scale for elements as the header collapses
    // Clamped between 0.0 and 1.0 based on scroll offset vs. flexible space height
    final double scrollFactor =
        (_headerScrollOffset / (expandedHeight - minHeight)).clamp(0.0, 1.0);
    final double avatarScale =
        1.0 - (scrollFactor * 0.3); // Shrink avatar slightly
    final double textOpacity =
        1.0 - (scrollFactor * 1.5); // Fade out text faster
    final double backgroundParallax =
        -_headerScrollOffset * 0.4; // Slower scroll for background

    // Define rich background gradient for the header
    final headerBackgroundGradient = LinearGradient(
      colors: theme.brightness == Brightness.light
          ? [
              theme.colorScheme.primary,
              theme.colorScheme.secondary.withOpacity(0.8),
            ]
          : [theme.colorScheme.primary, theme.colorScheme.secondary],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return SliverAppBar(
      expandedHeight: expandedHeight,
      floating: false, // Stays at top initially
      pinned: true, // Stays visible when scrolled up (as a regular AppBar)
      backgroundColor:
          theme.appBarTheme.backgroundColor, // Matches default AppBar theme
      elevation: 0, // Controlled by inner elements or shadow below
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: theme.colorScheme.onPrimary,
        ), // White icon for better contrast
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        // Theme toggle for collapsing AppBar
        Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
            return Opacity(
              opacity: scrollFactor, // Fades in with the collapsing header
              child: IconButton(
                icon: Icon(
                  isDarkMode ? Icons.wb_sunny_outlined : Icons.nightlight_round,
                  color: theme.colorScheme.onPrimary,
                ),
                tooltip: isDarkMode
                    ? strings.themeTooltipLight
                    : strings.themeTooltipDark,
                onPressed: scrollFactor > 0.5
                    ? () => themeProvider.toggleTheme()
                    : null, // Only clickable when visible
              ),
            );
          },
        ),
        // Language toggle for collapsing AppBar
        Consumer<LocaleProvider>(
          builder: (context, localeProvider, child) {
            final currentLocale = localeProvider.locale;
            final nextLocale = currentLocale.languageCode == 'en'
                ? const Locale('am')
                : const Locale('en');
            return Opacity(
              opacity: scrollFactor,
              child: IconButton(
                icon: Icon(Icons.language, color: theme.colorScheme.onPrimary),
                tooltip: strings.languageToggleTooltip,
                onPressed: scrollFactor > 0.5
                    ? () {
                        localeProvider.setLocale(nextLocale);
                        _loadUserProfile();
                      }
                    : null,
              ),
            );
          },
        ),
        // Logout for collapsing AppBar
        Opacity(
          opacity: scrollFactor,
          child: IconButton(
            icon: Icon(Icons.logout, color: theme.colorScheme.onPrimary),
            onPressed: scrollFactor > 0.5
                ? () async {
                    // Show loading during sign out
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(strings.loading),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                    await _firebaseService.signOut();
                    if (mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                        (Route<dynamic> route) => false,
                      );
                    }
                  }
                : null,
            tooltip: strings.generalLogout,
          ),
        ),
      ],
      flexibleSpace: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final currentHeight = constraints.biggest.height;
          final isExpanded =
              currentHeight >
              minHeight + 10; // Check if it's significantly expanded

          return FlexibleSpaceBar(
            centerTitle: true,
            titlePadding: EdgeInsets.only(
              bottom: isExpanded ? 16 : 8, // Adjust padding when collapsed
              left: isExpanded ? 16 : 56, // Push title right when collapsed
              right: isExpanded ? 16 : 16,
            ),
            title: Opacity(
              opacity: scrollFactor, // Title fades in as it collapses
              child: Text(
                name,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20, // Keep font size consistent when collapsed
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            background: Stack(
              fit: StackFit.expand,
              children: [
                // Animated background with parallax
                Transform.translate(
                  offset: Offset(0, backgroundParallax),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: headerBackgroundGradient,
                    ),
                  ),
                ),
                // Main content of the expanded header (avatar, name, role)
                Opacity(
                  opacity: 1.0 - scrollFactor, // Fades out as it collapses
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: kToolbarHeight + 10,
                    ), // Push down below standard app bar height
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Pulsating Animated Avatar
                        AnimatedBuilder(
                          animation: _glowAnimation,
                          builder: (context, child) {
                            return GestureDetector(
                              onTapDown: (_) =>
                                  setState(() => _isAvatarPressed = true),
                              onTapUp: (_) =>
                                  setState(() => _isAvatarPressed = false),
                              onTapCancel: () =>
                                  setState(() => _isAvatarPressed = false),
                              onTap: _isUploadingImage
                                  ? null
                                  : _showImagePickerOptions,
                              child: AnimatedScale(
                                scale: _isAvatarPressed
                                    ? 0.95
                                    : avatarScale, // Scale down on press, and shrink on scroll
                                duration: const Duration(milliseconds: 150),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: (avatarRadiusExpanded + 10) * 2,
                                      height: (avatarRadiusExpanded + 10) * 2,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: theme.colorScheme.tertiary
                                                .withOpacity(0.6),
                                            blurRadius: _glowAnimation
                                                .value, // Pulsating blur
                                            spreadRadius:
                                                _glowAnimation.value *
                                                0.5, // Pulsating spread
                                          ),
                                        ],
                                      ),
                                    ),
                                    ClipOval(
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          CircleAvatar(
                                            radius: avatarRadiusExpanded,
                                            backgroundColor: theme
                                                .colorScheme
                                                .surface
                                                .withOpacity(0.7),
                                            backgroundImage:
                                                (profileImage != null &&
                                                    profileImage.isNotEmpty)
                                                ? CachedNetworkImageProvider(
                                                    profileImage,
                                                  )
                                                : null,
                                            child:
                                                (profileImage == null ||
                                                    profileImage.isEmpty)
                                                ? Icon(
                                                    Icons.person_outline,
                                                    size:
                                                        avatarRadiusExpanded *
                                                        0.8,
                                                    color: theme
                                                        .colorScheme
                                                        .onSurface,
                                                  )
                                                : null,
                                          ),
                                          if (_isUploadingImage)
                                            Container(
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(
                                                  0.5,
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: CircularProgressIndicator(
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(
                                                        theme
                                                            .colorScheme
                                                            .onPrimary,
                                                      ),
                                                  strokeWidth: 3,
                                                ),
                                              ),
                                            ),
                                          if (isVerified)
                                            Positioned(
                                              top: 0,
                                              right: 0,
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.shade600,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: theme
                                                        .colorScheme
                                                        .surface,
                                                    width: 1.5,
                                                  ),
                                                ),
                                                child: const Icon(
                                                  Icons.verified_rounded,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        // User Name
                        Transform.translate(
                          offset: Offset(
                            0,
                            _headerScrollOffset * 0.1,
                          ), // Slight parallax for text
                          child: Text(
                            name,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white.withOpacity(textOpacity),
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(
                                    0.3 * textOpacity,
                                  ),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // User Role Chip
                        Transform.translate(
                          offset: Offset(
                            0,
                            _headerScrollOffset * 0.05,
                          ), // Slight parallax
                          child: Opacity(
                            opacity: textOpacity,
                            child: Chip(
                              label: Text(
                                userTypeDisplay,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: Colors.black87,
                                ),
                              ),
                              backgroundColor: Colors.white.withOpacity(0.8),
                              shape: StadiumBorder(),
                              materialTapTargetSize: MaterialTapTargetSize
                                  .shrinkWrap, // Reduce extra space
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Builds a generic section card with title and icon for consistent styling.
  Widget _buildSectionCard(
    ThemeData theme, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: theme.cardTheme.color, // Use theme card color
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary, size: 24),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  /// Builds a reusable info tile with an icon, label, and value.
  Widget _buildInfoTile(
    ThemeData theme,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            // Use Expanded to prevent overflow for long values
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// --- NEW SECTION: About Me & Skills ---
  /// Combines bio, website, and skills into one coherent card.
  Widget _buildAboutMeSection(
    BuildContext context,
    AppStrings strings,
    ThemeData theme,
    bool isWorker,
  ) {
    final profileData = _userProfile!;
    return _buildSectionCard(
      theme,
      title: strings.aboutMe,
      icon: Icons.info_outline,
      children: [],
    );
  }

  /// --- NEW SECTION: Contact & Joined Info ---
  /// Separates contact details and join date into their own card.
  Widget _buildContactAndJoinedInfo(
    BuildContext context,
    AppStrings strings,
    ThemeData theme,
  ) {
    final profileData = _userProfile!;
    final DateFormat formatter = DateFormat(
      'MMM dd, yyyy',
      strings.locale.languageCode,
    );

    return _buildSectionCard(
      theme,
      title: strings.contactInfo,
      icon: Icons.contact_mail_outlined,
      children: [
        _buildInfoTile(
          theme,
          Icons.email_outlined,
          "emailLabel",
          profileData.email,
        ),
        _buildInfoTile(
          theme,
          Icons.phone_outlined,
          strings.phoneLabel,
          profileData.phoneNumber ?? 'N/A',
        ),
        _buildInfoTile(
          theme,
          Icons.location_on_outlined,
          "addressLabel",
          profileData.location ?? 'N/A',
        ),
      ],
    );
  }

  /// Builds the user statistics section, conditional on user role.
  /// Uses the ProfileStatCard for consistent display.
  Widget _buildProfileStatsSection(
    BuildContext context,
    AppStrings strings,
    ThemeData theme,
    bool isWorker,
  ) {
    final profile = _userProfile!;
    final String title = isWorker
        ? strings.profileStatsTitleWorker
        : strings.profileStatsTitleClient;

    List<Widget> statRows = [];

    if (isWorker) {
      statRows = [
        Row(
          children: [
            // Using ProfileStatCard - assuming it fetches strings internally or takes string literals
            ProfileStatCard(
              label: strings.profileStatJobsCompleted,
              value: '${profile.jobsCompleted ?? 0}',
              icon: Icons.task_alt_rounded,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            ProfileStatCard(
              label: strings.profileStatRating,
              value: '${(profile.rating ?? 0.0).toStringAsFixed(1)} ★',
              icon: Icons.star_half_rounded,
              color: theme.colorScheme.secondary,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            ProfileStatCard(
              label: strings.profileStatExperience,
              value: strings.yearsExperience(profile.experience ?? 0),
              icon: Icons.workspace_premium_outlined,
              color: theme.colorScheme.tertiary,
            ),
            const SizedBox(width: 12),
            ProfileStatCard(
              label: strings.profileStatReviews,
              value: '${profile.reviewCount ?? 0}',
              icon: Icons.reviews_outlined,
              color: Colors.purple.shade400,
            ),
          ],
        ),
      ];
    } else {
      statRows = [
        Row(
          children: [
            ProfileStatCard(
              label: strings.profileStatJobsPosted,
              value: '${profile.jobsPosted ?? 0}',
              icon: Icons.post_add_rounded,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            ProfileStatCard(
              label: strings.profileStatJobsCompleted,
              value: '${profile.jobsCompleted ?? 0}',
              icon: Icons.playlist_add_check_rounded,
              color: theme.colorScheme.secondary,
            ),
          ],
        ),
      ];
    }

    return _buildSectionCard(
      theme,
      title: title,
      icon: Icons.analytics_outlined,
      children: [
        if (statRows.isNotEmpty)
          Column(children: statRows)
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Text(
              'No statistics available yet.',
              style: theme.textTheme.bodyMedium,
            ), // TODO: Localize
          ),
      ],
    );
  }

  /// A single stat card used in the profile statistics section.
  Widget ProfileStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: color),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: color),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the recent job history section using a FutureBuilder.
  Widget _buildJobHistorySection(
    BuildContext context,
    AppStrings strings,
    ThemeData theme,
    bool isWorker,
  ) {
    if (_userProfile == null) return const SizedBox.shrink();

    return _buildSectionCard(
      theme,
      title: strings.profileJobHistoryTitle,
      icon: Icons.history_toggle_off,
      children: [
        Row(
          mainAxisAlignment:
              MainAxisAlignment.end, // Push "View All" to the right
          children: [
            if ((_userProfile!.jobsCompleted ?? 0) > 0 ||
                (_userProfile!.jobsPosted ?? 0) > 0)
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/jobs'),
                child: Text(strings.viewAllButton),
              ),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<Job>>(
          future: _firebaseService.getUserJobs(
            userId: _userProfile!.id,
            isWorker: isWorker,
          ), // Limit to 3 for overview
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 30.0),
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30.0),
                  child: Text(
                    '${strings.snackErrorLoading} ${snapshot.error}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              );
            }
            final List<Job> jobs = snapshot.data ?? [];
            if (jobs.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 30.0),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.history_toggle_off_outlined,
                        size: 48,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        strings.profileNoJobHistory,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'Jobs you post or complete will appear here.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ), // TODO: Localize
                    ],
                  ),
                ),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics:
                  const NeverScrollableScrollPhysics(), // Disable internal scrolling
              itemCount: jobs.length,
              itemBuilder: (context, index) => _buildJobHistoryItem(
                context,
                strings,
                theme,
                jobs[index],
                isWorker,
              ),
              separatorBuilder: (context, index) => const SizedBox(height: 8),
            );
          },
        ),
      ],
    );
  }

  /// Helper widget for a single job item in the history list.
  Widget _buildJobHistoryItem(
    BuildContext context,
    AppStrings strings,
    ThemeData theme,
    Job job,
    bool isCurrentUserWorker,
  ) {
    Color getStatusColor(String status) {
      switch (status.toLowerCase()) {
        case 'open':
          return theme.colorScheme.primary;
        case 'pending':
          return Colors.blue.shade600;
        case 'assigned':
        case 'working':
        case 'in_progress':
        case 'accepted':
          return theme.colorScheme.secondary;
        case 'completed':
          return Colors.green.shade600;
        case 'cancelled':
        case 'rejected':
          return theme.colorScheme.error;
        default:
          return theme.colorScheme.onSurface.withOpacity(0.5);
      }
    }

    IconData getStatusIcon(String status) {
      switch (status.toLowerCase()) {
        case 'open':
          return Icons.lock_open_rounded;
        case 'pending':
          return Icons.pending_actions_rounded;
        case 'assigned':
          return Icons.assignment_ind_outlined;
        case 'accepted':
          return Icons.how_to_reg_outlined;
        case 'working':
        case 'in_progress':
          return Icons.construction_rounded;
        case 'completed':
          return Icons.check_circle_outline_rounded;
        case 'cancelled':
        case 'rejected':
          return Icons.cancel_outlined;
        default:
          return Icons.help_outline_rounded;
      }
    }

    final String statusKey = job.status.isNotEmpty
        ? job.status.toLowerCase()
        : 'unknown';
    final String displayStatus = strings.getStatusName(statusKey).toUpperCase();
    final Color statusColor = getStatusColor(statusKey);
    final IconData statusIcon = getStatusIcon(statusKey);

    final String title = job.title.isNotEmpty ? job.title : strings.jobUntitled;
    final String location = job.location.isNotEmpty
        ? job.location
        : strings.notAvailable;
    final String budget = job.budget > 0
        ? strings.jobBudgetETB(job.budget.toStringAsFixed(0))
        : strings.notSet;
    final String description = job.description.isNotEmpty
        ? (job.description.length > 100
              ? '${job.description.substring(0, 97)}...'
              : job.description)
        : strings.jobNoDescription;

    String relevantName = '';
    String relevantNameLabel = '';

    if (isCurrentUserWorker) {
      relevantName = job.clientName.isNotEmpty
          ? job.clientName
          : strings.workerDetailAnonymous;
      relevantNameLabel = strings.clientNameLabel;
    } else {
      relevantName = job.workerName.isNotEmpty
          ? job.workerName
          : (statusKey == 'open' || statusKey == 'pending'
                ? strings.jobDetailNoWorkerAssigned
                : strings.workerDetailAnonymous);
      relevantNameLabel = strings.workerNameLabel;
    }

    return Card(
      margin: EdgeInsets.zero,
      elevation: theme.cardTheme.elevation ?? 2,
      shape:
          theme.cardTheme.shape ??
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: theme.cardTheme.color ?? theme.colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => JobDetailScreen(job: job)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: statusColor.withOpacity(0.15),
                child: Icon(statusIcon, color: statusColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: theme.textTheme.titleMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: statusColor.withOpacity(0.5),
                            ),
                          ),
                          child: Text(
                            displayStatus,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: theme.iconTheme.color?.withOpacity(0.7),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  location,
                                  style: theme.textTheme.bodySmall,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (job.budget > 0)
                          Row(
                            children: [
                              Icon(
                                Icons.monetization_on_outlined,
                                size: 16,
                                color: Colors.green.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                budget,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.green.shade800,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          isCurrentUserWorker
                              ? Icons.account_circle_outlined
                              : Icons.construction_outlined,
                          size: 16,
                          color: theme.iconTheme.color?.withOpacity(0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$relevantNameLabel: ',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            relevantName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the settings list section, encapsulated in a custom card.
  Widget _buildSettingsSection(
    BuildContext context,
    AppStrings strings,
    ThemeData theme,
  ) {
    void navigateToScreen(Widget screen) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
    }

    final settingsItems = [
      {
        'title': strings.settingsNotificationsTitle,
        'subtitle': strings.settingsNotificationsSubtitle,
        'icon': Icons.notifications_active_outlined,
        'action': () => navigateToScreen(const NotificationsScreen()),
      },
      {
        'title': strings.settingsPaymentTitle,
        'subtitle': strings.settingsPaymentSubtitle,
        'icon': Icons.payment_outlined,
        'action': () => navigateToScreen(const ManagePaymentMethodsScreen()),
      }, // Corrected usage of ManagePaymentMethodsScreen
      {
        'title': strings.settingsPrivacyTitle,
        'subtitle': strings.settingsPrivacySubtitle,
        'icon': Icons.security_outlined,
        'action': () => navigateToScreen(const PrivacySecurityScreen()),
      },
      {
        'title': strings.settingsAccountTitle,
        'subtitle': strings.settingsAccountSubtitle,
        'icon': Icons.account_circle_outlined,
        'action': () => navigateToScreen(const AccountScreen()),
      },
      {
        'title': strings.settingsHelpTitle,
        'subtitle': strings.settingsHelpSubtitle,
        'icon': Icons.help_outline_rounded,
        'action': () => navigateToScreen(const HelpSupportScreen()),
      },
    ];

    return _buildSectionCard(
      theme,
      title: strings.profileSettingsTitle,
      icon: Icons.settings_outlined,
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: settingsItems.length,
          itemBuilder: (context, index) {
            final item = settingsItems[index];
            return _buildSettingItem(
              context,
              strings,
              theme,
              item['title'] as String,
              item['subtitle'] as String,
              item['icon'] as IconData,
              item['action'] as VoidCallback,
            );
          },
          separatorBuilder: (context, index) => Divider(
            height: 1,
            thickness: 1,
            color: theme.dividerColor.withOpacity(0.3),
            indent: 58,
          ),
        ),
      ],
    );
  }

  /// Helper widget for a single setting item within the settings list.
  Widget _buildSettingItem(
    BuildContext context,
    AppStrings strings,
    ThemeData theme,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer.withOpacity(0.4),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: theme.colorScheme.onSecondaryContainer,
          size: 22,
        ),
      ),
      title: Text(title, style: theme.textTheme.titleMedium),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        vertical: 6.0,
        horizontal: 8.0,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  /// Builds the final "Edit Profile" button.
  Widget _buildEditProfileButton(
    BuildContext context,
    AppStrings strings,
    ThemeData theme,
    bool isWorker,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.edit_outlined, size: 20),
        label: Text(strings.profileEditButton),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: _isUploadingImage || _isLoading
            ? null
            : () {
                final screen = isWorker
                    ? ProfessionalHubScreen()
                    : AccountScreen(); // Use AccountScreen for client editing as per your provided placeholder
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => screen),
                ).then((result) {
                  if (result == true && mounted) {
                    _loadUserProfile(); // Refresh profile data when returning
                  }
                });
              },
      ),
    );
  }
}

class ProfileStateCard extends StatelessWidget {
  const ProfileStateCard({
    super.key,
    required this.state,
    required this.appStrings,
  });

  final String state;
  final AppStrings appStrings;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Text(state, style: const TextStyle(fontSize: 16))],
        ),
      ),
    );
  }
}
