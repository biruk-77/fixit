// --- Full ProfileScreen.dart Code with Fixes and Navigation ---

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth; // Alias
import 'package:image_picker/image_picker.dart';
// !! IMPORTANT: Replace with correct path to your ManagePaymentMethodsScreen !!
import 'payment/managepayment.dart';
import 'dart:io';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'professional_setup_edit.dart';

// Your project specific imports (ADJUST PATHS AS NEEDED)
import '../services/firebase_service.dart';
import '../models/user.dart';
import '../models/job.dart'; // Ensure Job model is imported
import 'auth/login_screen.dart';
import 'jobs/job_detail_screen.dart';
import 'professional_setup_screen.dart'; // For worker edit profile

// Placeholder imports for Settings Screens (REPLACE WITH ACTUAL PATHS/FILES)
// !! ENSURE this is the correct path to your PaymentScreen !!
// Note: If PaymentScreen requires a Job, you might need a different screen for general payment methods
// import 'payment/payment_screen.dart'; // Commented out, using ManagePaymentMethodsScreen instead

// Create these screens if they don't exist or adjust paths
// import 'settings/privacy_security_screen.dart';
// import 'settings/account_screen.dart';
// import 'settings/help_support_screen.dart';

// Theme and Localization
// ***** FIX THIS IMPORT PATH/FILENAME *****
// <<< MAKE SURE THIS IS CORRECT
import '../services/app_string.dart'; // Your localization file
import '../providers/locale_provider.dart'; // Your locale provider
import '../providers/theme_provider.dart'; // Your theme provider

// --- Placeholder Screens (Replace with your actual implementations) ---

// Placeholder screen for demonstration
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text("Notifications")), // TODO: Localize
      body: const Center(child: Text("Notifications Screen - TODO")));
}

// Placeholder for general Payment Methods Management
// class ManagePaymentMethodsScreen extends StatelessWidget {
//   const ManagePaymentMethodsScreen({Key? key}) : super(key: key);
//   @override
//   Widget build(BuildContext context) => Scaffold(
//       appBar: AppBar(title: const Text("Manage Payment Methods")), // TODO: Localize
//       body: const Center(child: Text("Manage Payments Screen - TODO")));
// }

// Placeholder screen for demonstration
class PrivacySecurityScreen extends StatelessWidget {
  const PrivacySecurityScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text("Privacy & Security")), // TODO: Localize
      body: const Center(child: Text("Privacy Screen - TODO")));
}

// Placeholder screen for demonstration (Can be used for Client profile editing)
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text("Account")), // TODO: Localize
      body: const Center(child: Text("Account Screen - TODO")));
}

// Placeholder screen for demonstration
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text("Help & Support")), // TODO: Localize
      body: const Center(child: Text("Help Screen - TODO")));
}

// --- Profile Screen ---

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

// Add SingleTickerProviderStateMixin for animation controller
class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = true;
  bool _isUploadingImage = false;
  AppUser? _userProfile;
  bool isVerified = true;

  // Animation Controller for the border
  late AnimationController _borderAnimationController;
  // For tap scale effect
  bool _isAvatarPressed = false;
  // For tilt effect (Optional)
  // double _tiltX = 0.0;
  // double _tiltY = 0.0;
  // StreamSubscription? _gyroscopeSubscription; // Optional

  @override
  void initState() {
    super.initState();

    // Initialize border animation controller
    _borderAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5), // Speed of rotation
    )..repeat(); // Make it loop continuously

    // --- Optional: Tilt Effect Listener ---
    // _gyroscopeSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
    //   if (mounted) {
    //     setState(() {
    //       // Adjust sensitivity and clamping as needed
    //       _tiltX = (_tiltX + event.y * 0.01).clamp(-0.1, 0.1);
    //       _tiltY = (_tiltY - event.x * 0.01).clamp(-0.1, 0.1);
    //     });
    //   }
    // });
    // --- End Optional Tilt ---

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadUserProfile();
      }
    });
  }

  @override
  void dispose() {
    _borderAnimationController.dispose(); // Dispose controller
    // _gyroscopeSubscription?.cancel(); // Optional: Cancel tilt listener
    super.dispose();
  }

  // --- Helper Methods Placed Before Build ---
  // (Keep _loadUserProfile, _signOut, _showImagePickerOptions, _pickAndUploadImage as they were)
  // --- Data Loading ---
  Future<void> _loadUserProfile() async {
    if (!mounted) return; // Check if widget is still in the tree
    setState(() {
      _isLoading = true;
      _isUploadingImage = false; // Reset upload state on refresh
    });

    // Ensure localization is ready
    final strings = AppLocalizations.of(context);
    if (strings == null) {
      print(
          "Error: AppLocalizations not found in context during profile load.");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: const Text(
                  'Error: Localization service not available.'), // Fallback text
              backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
      return;
    }

    try {
      final userData = await _firebaseService.getCurrentUserProfile();
      if (!mounted) return; // Check again after async operation
      setState(() {
        _userProfile = userData;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user profile: $e');
      if (!mounted) return; // Check again
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        // Check mounted before accessing context
        // !! Ensure 'snackErrorLoadingProfile' exists in AppStrings !!
        final errorMsg =
            strings.snackErrorLoadingProfile ?? 'Error loading profile:';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('$errorMsg $e'),
              backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    }
  }

  // --- Actions ---
  Future<void> _signOut() async {
    final strings = AppLocalizations.of(context);
    if (strings == null || !mounted) return;

    setState(() {
      _isLoading = true; // Show loader during sign out
    });
    try {
      await _firebaseService.signOut();
      if (!mounted) return;
      // Navigate to LoginScreen and remove all previous routes
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false; // Hide loader on error
      });
      // !! Ensure 'errorActionFailed' exists in AppStrings !!
      final errorMsg = strings.errorActionFailed ?? 'Sign out failed:';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('$errorMsg $e'),
            backgroundColor: Theme.of(context).colorScheme.error),
      );
    }
  }

  // --- Image Picking and Uploading Logic ---
  void _showImagePickerOptions(BuildContext context) {
    final strings = AppLocalizations.of(context);
    if (strings == null) {
      print("Error: AppLocalizations not found for image picker options.");
      // Optionally show a generic error snackbar
      return;
    }
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
                  leading: Icon(Icons.photo_library,
                      color: theme.colorScheme.primary),
                  title: Text(
                    strings.attachOptionGallery, // !! Ensure exists !!
                    style: theme.textTheme.bodyLarge,
                  ),
                  onTap: () {
                    Navigator.of(context).pop(); // Close bottom sheet first
                    _pickAndUploadImage(ImageSource.gallery);
                  }),
              ListTile(
                leading:
                    Icon(Icons.photo_camera, color: theme.colorScheme.primary),
                title: Text(
                  strings.attachOptionCamera, // !! Ensure exists !!
                  style: theme.textTheme.bodyLarge,
                ),
                onTap: () {
                  Navigator.of(context).pop(); // Close bottom sheet first
                  _pickAndUploadImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.cancel, color: theme.colorScheme.error),
                title: Text(
                  strings.generalCancel, // !! Ensure exists !!
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(color: theme.colorScheme.error),
                ),
                onTap: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 10), // Bottom padding
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);
    if (strings == null) {
      print("Error: AppLocalizations not found before picking image.");
      // Optionally show error snackbar
      return;
    }
    if (_isUploadingImage || !mounted) {
      return; // Prevent concurrent uploads or calls on disposed widget
    }

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800, // Constrain image size
        maxHeight: 800,
        imageQuality: 85, // Compress image slightly
      );

      if (pickedFile != null && mounted) {
        setState(() {
          _isUploadingImage = true; // Show uploading indicator
        });

        final imageFile = File(pickedFile.path);
        // Assume uploadProfileImageToSupabase returns the public URL or null
        final String? imageUrl =
            await _firebaseService.uploadProfileImageToSupabase(imageFile);

        if (imageUrl != null && mounted) {
          final userId = fb_auth.FirebaseAuth.instance.currentUser?.uid;
          final userRole = _userProfile?.role; // Get role from loaded profile

          if (userId != null && userRole != null) {
            try {
              // Update the URL in Firestore
              await _firebaseService.updateUserProfileImageInFirestore(
                  userId, imageUrl, userRole);
              if (mounted) {
                // !! Ensure 'snackSuccessProfileUpdated' exists !!
                final successMsg = strings.snackSuccessProfileUpdated ??
                    'Profile picture updated!';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(successMsg), backgroundColor: Colors.green),
                );
                // Refresh the profile data to show the new image
                await _loadUserProfile(); // Reloads profile, sets _isLoading, then sets it false
              }
            } catch (e) {
              print("Error updating profile image URL in Firestore: $e");
              if (mounted) {
                // !! Ensure 'snackErrorSubmitting' exists !!
                final errorMsg = strings.snackErrorSubmitting ??
                    'Failed to save profile picture:';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('[31m$errorMsg $e'),
                      backgroundColor: theme.colorScheme.error),
                );
              }
            }
          } else {
            print("Error: User ID or Role is null after image upload.");
            if (mounted) {
              // !! Ensure 'errorUserNotLoggedIn' exists !!
              final errorMsg = strings.errorUserNotLoggedIn ??
                  'Error: Could not find user data to save image.';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(errorMsg),
                    backgroundColor: theme.colorScheme.error),
              );
            }
          }
        } else if (mounted) {
          // Handle upload failure (imageUrl is null)
          // !! Ensure 'createJobSnackbarErrorUpload' exists !!
          final errorMsg =
              strings.createJobSnackbarErrorUpload ?? 'Failed to upload image.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(errorMsg),
                backgroundColor: theme.colorScheme.error),
          );
        }
      } else if (mounted && pickedFile == null) {
        // Handle cancellation
        // !! Ensure 'createJobSnackbarFileCancelled' exists !!
        final cancelMsg = strings.createJobSnackbarFileCancelled ??
            'Image selection cancelled.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(cancelMsg),
              duration: const Duration(seconds: 2),
              backgroundColor:
                  theme.colorScheme.secondaryContainer, // Less intrusive color
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))),
        );
      }
    } catch (e) {
      print('Error picking/uploading image: $e');
      if (mounted) {
        // !! Ensure these specific error strings exist in AppStrings !!
        String errorMessage = strings.snackErrorGeneric ?? 'An error occurred';
        if (e.toString().contains('camera_access_denied')) {
          errorMessage = strings.snackErrorCameraPermission ??
              'Camera permission denied. Please enable it in settings.';
        } else if (e.toString().contains('photo_access_denied')) {
          errorMessage = strings.snackErrorGalleryPermission ??
              'Gallery permission denied. Please enable it in settings.';
        } else if (e.toString().contains('camera unavailable')) {
          errorMessage = strings.snackErrorCameraNotAvailable ??
              'Camera not available on this device.';
        } else {
          errorMessage = '$errorMessage: $e'; // Generic fallback
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(errorMessage),
              backgroundColor: theme.colorScheme.error),
        );
      }
    } finally {
      // Ensure the uploading indicator is turned off robustly
      if (mounted && _isUploadingImage) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppLocalizations.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    if (strings == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Profile")),
        body: Center(
            child: CircularProgressIndicator(color: theme.colorScheme.primary)),
      );
    }

    // Loading state check remains the same
    final showOverallLoader =
        _isLoading; // Simplified: only show main loader when profile is loading
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      // AppBar remains the same
      appBar: AppBar(
        title: Text(strings.appBarMyProfile),
        actions: [
          IconButton(
            icon: Icon(
                isDarkMode ? Icons.wb_sunny_outlined : Icons.nightlight_round,
                color: isDarkMode ? Colors.amberAccent : Colors.black38),
            tooltip: isDarkMode
                ? strings.themeTooltipLight
                : strings.themeTooltipDark,
            onPressed: () => Provider.of<ThemeProvider>(context, listen: false)
                .toggleTheme(),
          ),
          IconButton(
            icon: Icon(Icons.language,
                color: isDarkMode ? Colors.amberAccent : Colors.black38),
            tooltip: strings.languageToggleTooltip,
            onPressed: () {
              final currentLocale =
                  Provider.of<LocaleProvider>(context, listen: false).locale;
              final nextLocale = currentLocale.languageCode == 'en'
                  ? const Locale('am')
                  : const Locale('en');
              Provider.of<LocaleProvider>(context, listen: false)
                  .setLocale(nextLocale);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _loadUserProfile();
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.logout,
                color: isDarkMode ? Colors.amberAccent : Colors.black38),
            onPressed: showOverallLoader ? null : _signOut,
            tooltip: strings.generalLogout,
          ),
        ],
      ),
      body: showOverallLoader
          ? Center(
              child:
                  CircularProgressIndicator(color: theme.colorScheme.primary))
          : _userProfile == null
              ? _buildErrorState(context, strings, theme)
              : _buildProfileContent(context, strings, theme),
    );
  }

  // --- Widget Building Helper Methods ---

  // (Keep _buildErrorState as it was)
  Widget _buildErrorState(
      BuildContext context, AppStrings strings, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_outlined,
                size: 60, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              // !! Ensure 'profileNotFound' exists !!
              strings.profileNotFound ?? 'User Profile Not Found',
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: theme.colorScheme.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              // !! Ensure 'profileNotFoundSub' exists !!

              'We couldn\'t load your profile details. Please check your connection and try again.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 25),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: Text(strings.retryButton), // !! Ensure exists !!
              onPressed: _loadUserProfile, // Retry loading
            )
          ],
        ),
      ),
    );
  }

  // (Keep _buildProfileContent as it was)
  Widget _buildProfileContent(
      BuildContext context, AppStrings strings, ThemeData theme) {
    // This check is slightly redundant due to the check in build(), but safe.
    if (_userProfile == null) {
      return _buildErrorState(context, strings, theme);
    }
    final bool isWorker =
        _userProfile!.role == 'worker' || _userProfile!.role == 'professional';

    return RefreshIndicator(
      onRefresh: _loadUserProfile, // Enable pull-to-refresh
      color: theme.colorScheme.primary,
      backgroundColor: theme.colorScheme.surface,
      child: SingleChildScrollView(
        physics:
            const AlwaysScrollableScrollPhysics(), // Ensure scroll physics for RefreshIndicator
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(context, strings, theme), // Use the NEW header
            const SizedBox(height: 24),
            _buildProfileStats(context, strings, theme),
            const SizedBox(height: 16),
            Divider(color: theme.dividerColor.withOpacity(0.7)),
            const SizedBox(height: 16),
            _buildJobHistory(context, strings, theme),
            const SizedBox(height: 16),
            Divider(color: theme.dividerColor.withOpacity(0.7)),
            const SizedBox(height: 16),
            _buildSettings(context, strings, theme),
            const SizedBox(height: 24),
            _buildEditProfileButton(context, strings, theme, isWorker),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- Profile Header Widget (ADVANCED VERSION) ---
  Widget _buildProfileHeader(
      BuildContext context, AppStrings strings, ThemeData theme) {
    final profileData = _userProfile!;
    final name = profileData.name.isNotEmpty
        ? profileData.name
        : (profileData.email ?? 'No Name');
    final profileImage = profileData.profileImage;
    // Assuming AppUser has isVerified

    String userTypeDisplay = strings.getUserTypeDisplayName(profileData.role);
    if (userTypeDisplay == profileData.role) {
      userTypeDisplay = profileData.role.isNotEmpty
          ? (profileData.role[0].toUpperCase() + profileData.role.substring(1))
          : 'User';
    }

    // Define gradient colors based on theme
    final gradientColors = theme.brightness == Brightness.light
        ? [
            theme.colorScheme.primaryContainer.withOpacity(0.6),
            theme.colorScheme.primary.withOpacity(0.4)
          ]
        : [
            theme.colorScheme.surfaceContainerHigh.withOpacity(0.5),
            theme.colorScheme.surfaceContainer.withOpacity(0.3)
          ];

    final borderGradientColors = [
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
      theme.colorScheme.tertiary,
      theme.colorScheme.primary, // Loop back
    ];

    final double avatarRadius = 60; // Increased radius
    final double borderThickness = 3.5;

    return ClipRRect(
      // Clip the backdrop filter
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        // Apply glassmorphism
        filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withOpacity(
                theme.brightness == Brightness.light
                    ? 0.4
                    : 0.2), // Semi-transparent background
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
            gradient: LinearGradient(
              // Subtle background gradient
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              // --- Optional: Tilt Effect Wrapper ---
              // Transform(
              //   transform: Matrix4.identity()
              //     ..setEntry(3, 2, 0.001) // Perspective
              //     ..rotateX(_tiltX)
              //     ..rotateY(_tiltY),
              //   alignment: FractionalOffset.center,
              //   child: // Place the GestureDetector and Stack inside here
              // ),
              // --- End Optional Tilt ---

              // Add GestureDetector for tap scale effect
              GestureDetector(
                onTapDown: (_) => setState(() => _isAvatarPressed = true),
                onTapUp: (_) => setState(() => _isAvatarPressed = false),
                onTapCancel: () => setState(() => _isAvatarPressed = false),
                onTap: _isUploadingImage
                    ? null
                    : () => _showImagePickerOptions(context),
                child: AnimatedScale(
                  scale: _isAvatarPressed ? 0.95 : 1.0, // Scale down on press
                  duration: const Duration(milliseconds: 150),
                  child: Tooltip(
                    message: _isUploadingImage
                        ? 'Uploading...'
                        : (strings.profileEditAvatarHint ??
                            'Tap to change picture'),
                    child: Stack(
                      alignment: Alignment.center, // Center elements in stack
                      children: [
                        // --- Animated Rotating Gradient Border ---
                        RotationTransition(
                          turns: _borderAnimationController,
                          child: Container(
                            width: (avatarRadius + borderThickness) * 2,
                            height: (avatarRadius + borderThickness) * 2,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: SweepGradient(
                                colors: borderGradientColors,
                                tileMode: TileMode
                                    .repeated, // Use repeated for smoother loop
                              ),
                            ),
                          ),
                        ),

                        // --- Avatar Container with Padding for Border ---
                        Container(
                          padding: EdgeInsets.all(
                              borderThickness), // Padding creates the border effect
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            // Background color slightly different from main card for definition
                            color: theme.cardTheme.color ??
                                theme.colorScheme.surface,
                          ),
                          child: ClipOval(
                            // Clip the content inside to be circular
                            child: Stack(
                              // Stack for image and upload overlay
                              alignment: Alignment.center,
                              children: [
                                // --- CircleAvatar with Image ---
                                CircleAvatar(
                                  radius: avatarRadius,
                                  backgroundColor: theme
                                      .colorScheme.secondaryContainer
                                      .withOpacity(0.5),
                                  backgroundImage: (profileImage != null &&
                                          profileImage.isNotEmpty)
                                      ? CachedNetworkImageProvider(profileImage)
                                      : null,
                                  onBackgroundImageError:
                                      (profileImage != null &&
                                              profileImage.isNotEmpty)
                                          ? (exception, stackTrace) {
                                              print(
                                                  "Error loading profile image: $exception");
                                              // Optionally update state to show placeholder explicitly on error
                                            }
                                          : null,
                                  child: (profileImage == null ||
                                          profileImage.isEmpty)
                                      ? Icon(Icons.person_outline,
                                          size: avatarRadius * 0.8,
                                          color: theme.colorScheme.primary)
                                      : null,
                                ),

                                // --- Uploading Overlay ---
                                Visibility(
                                  visible: _isUploadingImage,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black
                                          .withOpacity(0.5), // Dark overlay
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                theme.colorScheme.onPrimary),
                                        strokeWidth: 3,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // --- Edit Icon (Smaller, positioned differently) ---
                        Positioned(
                          bottom: 5,
                          right: 5,
                          child: IgnorePointer(
                            // Prevent this icon from blocking taps on avatar
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                  color: theme.colorScheme.secondary
                                      .withOpacity(0.8),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: theme.colorScheme.surface,
                                      width: 1.5)),
                              child: Icon(
                                Icons.edit_rounded, // Use edit icon
                                color: theme.colorScheme.onSecondary,
                                size: 16,
                              ),
                            ),
                          ),
                        ),

                        // --- Verification Badge (Conditional) ---
                        if (isVerified)
                          Positioned(
                            top: 5,
                            right: 5,
                            child: IgnorePointer(
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                    color: Colors
                                        .blue.shade600, // Verification color
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: theme.colorScheme.surface,
                                        width: 1.5)),
                                child: const Icon(
                                  Icons.verified_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                name,
                style: theme.textTheme.headlineMedium?.copyWith(
                    // Slightly larger name
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    shadows: [
                      // Subtle text shadow
                      Shadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 3,
                          offset: const Offset(0, 1))
                    ]),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              if (userTypeDisplay.isNotEmpty)
                Chip(
                  avatar: Icon(
                      profileData.role == 'worker'
                          ? Icons.construction_rounded
                          : Icons.person_pin_circle_outlined,
                      size: 16,
                      color: theme.colorScheme.primary),
                  label: Text(
                    userTypeDisplay,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  backgroundColor:
                      theme.colorScheme.primaryContainer.withOpacity(0.3),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: StadiumBorder(
                      side: BorderSide(
                          color: theme.colorScheme.primary
                              .withOpacity(0.4))), // Border matching primary
                ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Profile Stats Widget ---
  Widget _buildProfileStats(
      BuildContext context, AppStrings strings, ThemeData theme) {
    final profile = _userProfile!; // Assumed not null
    final bool isWorker =
        profile.role == 'worker' || profile.role == 'professional';

    // !! Ensure these stat title strings exist !!
    final String title = isWorker
        ? (strings.profileStatsTitleWorker ?? 'Professional Stats')
        : (strings.profileStatsTitleClient ?? 'Client Stats');

    List<Widget> statItems = [];

    // Build stats based on role
    if (isWorker) {
      // !! Ensure worker stat strings exist !!
      statItems = [
        Row(
          children: [
            _buildStatCard(
                context,
                strings,
                theme,
                strings.profileStatJobsCompleted ?? 'Jobs Completed',
                '${profile.jobsCompleted ?? 0}',
                Icons.task_alt_rounded,
                theme.colorScheme.primary),
            const SizedBox(width: 12),
            _buildStatCard(
                context,
                strings,
                theme,
                strings.profileStatRating ?? 'Rating',
                '${(profile.rating ?? 0.0).toStringAsFixed(1)} ★',
                Icons.star_half_rounded,
                theme.colorScheme.secondary),
          ],
        ),
        const SizedBox(height: 12), // Add space between rows
        Row(children: [
          _buildStatCard(
              context,
              strings,
              theme,
              strings.profileStatExperience ?? 'Experience',
              strings.yearsExperience(profile.experience ?? 0),
              Icons.workspace_premium_outlined,
              theme.colorScheme.tertiary), // Use localized years
          const SizedBox(width: 12),
          _buildStatCard(
              context,
              strings,
              theme,
              strings.profileStatReviews ?? 'Reviews',
              '${profile.reviewCount ?? 0}',
              Icons.reviews_outlined,
              Colors.purple.shade400), // Example color
        ])
      ];
    } else {
      // Client stats
      // !! Ensure client stat strings exist !!
      statItems = [
        Row(
          children: [
            _buildStatCard(
                context,
                strings,
                theme,
                strings.profileStatJobsPosted ?? 'Jobs Posted',
                '${profile.jobsPosted ?? 0}',
                Icons.post_add_rounded,
                theme.colorScheme.primary),
            const SizedBox(width: 12),
            _buildStatCard(
                context,
                strings,
                theme,
                strings.profileStatJobsCompleted ?? 'Hires Completed',
                '${profile.jobsCompleted ?? 0}',
                Icons.playlist_add_check_rounded,
                theme.colorScheme.secondary),
          ],
        )
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        // Display stats (handles single row or multiple rows)
        if (statItems.isNotEmpty)
          Column(children: statItems)
        else
          Padding(
            // Show message if no stats available (unlikely but possible)
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Text('No statistics available yet.',
                style: theme.textTheme.bodyMedium),
          ),
      ],
    );
  }

  // --- Stat Card (Helper) ---
  Widget _buildStatCard(BuildContext context, AppStrings strings,
      ThemeData theme, String label, String value, IconData icon, Color color) {
    return Expanded(
      // Ensure cards fill the row width
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: color.withOpacity(0.3)) // Subtle border
            ),
        color: color.withOpacity(0.05), // Very light background tint
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                value,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(color: color, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                maxLines: 1, // Prevent long labels from wrapping awkwardly
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Job History Section Widget ---
  Widget _buildJobHistory(
      BuildContext context, AppStrings strings, ThemeData theme) {
    if (_userProfile == null) {
      return const SizedBox.shrink(); // Don't build if profile isn't loaded
    }

    final bool isCurrentUserWorker =
        _userProfile!.role == 'worker' || _userProfile!.role == 'professional';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // !! Ensure 'profileJobHistoryTitle' exists !!
            Text(
              strings.profileJobHistoryTitle ?? 'Recent Activity',
              style: theme.textTheme.titleLarge,
            ),
            // We will add the 'View All' button conditionally inside the FutureBuilder
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<Job>>(
          // Fetch jobs based on the current user's ID and role
          future: _firebaseService.getUserJobs(
              userId: _userProfile!.id, // Assumes AppUser has an 'id' field
              isWorker: isCurrentUserWorker),
          builder: (context, snapshot) {
            // --- Loading State ---
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 30.0),
                  child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 3)),
                ),
              );
            }
            // --- Error State ---
            else if (snapshot.hasError) {
              print("Error loading job history: ${snapshot.error}");
              // !! Ensure 'snackErrorLoading' exists !!
              final errorMsg =
                  strings.snackErrorLoading ?? 'Error loading history:';
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30.0),
                  child: Text(
                    '$errorMsg ${snapshot.error}', // Consider showing a less technical message
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            // --- Data Loaded State ---
            else {
              final List<Job> jobs = snapshot.data ?? [];

              // --- Empty State ---
              if (jobs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30.0),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history_toggle_off_outlined,
                            size: 48,
                            color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(height: 8),
                        // !! Ensure 'profileNoJobHistory' exists !!
                        Text(
                          strings.profileNoJobHistory ?? 'No job history yet.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ),
                        // !! Ensure 'profileNoJobHistorySub' exists !!
                        Text(
                          'Jobs you post or complete will appear here.',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }
              // --- List View State ---
              else {
                // Display only the first few jobs (e.g., 5)
                final limitedJobs = jobs.length > 5 ? jobs.sublist(0, 5) : jobs;
                return Column(
                  // Use Column to potentially add 'View All' above the list
                  children: [
                    // Conditionally show 'View All' button *above* the list if there are jobs
                    if (jobs
                        .isNotEmpty) // Check original list length if needed for 'View All' logic
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            // TODO: Implement navigation to a full job history screen
                            Navigator.pushNamed(context,
                                '/jobs'); // Assuming '/jobs' is your jobs list screen
                          },
                          // !! Ensure 'viewAllButton' exists !!
                          child: Text(strings.viewAllButton ?? 'View All'),
                        ),
                      ),
                    if (jobs.isNotEmpty)
                      const SizedBox(
                          height: 8), // Space before list if button shown
                    ListView.separated(
                      shrinkWrap:
                          true, // Crucial for ListView inside Column/SingleChildScrollView
                      physics:
                          const NeverScrollableScrollPhysics(), // Disable internal scrolling
                      itemCount: limitedJobs.length,
                      itemBuilder: (context, index) {
                        return _buildJobHistoryItem(
                            context, strings, theme, limitedJobs[index]);
                      },
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8), // Space between items
                    ),
                  ],
                );
              }
            }
          }, // End of FutureBuilder builder
        ), // End of FutureBuilder
      ],
    );
  }

  // (Keep _buildJobHistoryItem as it was)
  Widget _buildJobHistoryItem(
      BuildContext context, AppStrings strings, ThemeData theme, Job job) {
    // Helper to get status color
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

    // Helper to get status icon
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

    final String statusKey =
        job.status.isNotEmpty ? job.status.toLowerCase() : 'unknown';
    // !! Ensure getStatusName exists and handles 'unknown' or provides fallback !!
    final String displayStatus = strings.getStatusName(statusKey).toUpperCase();
    final Color statusColor = getStatusColor(statusKey);
    final IconData statusIcon = getStatusIcon(statusKey);

    // Use localized fallbacks for job details
    final String title = job.title.isNotEmpty
        ? job.title
        : (strings.jobUntitled ?? 'Untitled Job');
    final String location = job.location.isNotEmpty
        ? job.location
        : (strings.notAvailable ?? 'N/A');
    // !! Ensure jobBudgetETB and notSet exist !!
    final String budget = job.budget > 0
        ? strings.jobBudgetETB(job.budget.toStringAsFixed(0)) // Format budget
        : (strings.notSet ?? 'Not set');
    // !! Ensure jobNoDescription exists !!
    final String description = job.description.isNotEmpty
        ? (job.description.length > 100
            ? '${job.description.substring(0, 97)}...'
            : job.description) // Truncate long description
        : (strings.jobNoDescription ?? 'No description provided.');

    // Determine relevant name and label based on current user's role
    String relevantName = '';
    String relevantNameLabel = '';
    final bool isCurrentUserWorker =
        _userProfile?.role == 'worker' || _userProfile?.role == 'professional';

    // !! Ensure these label/name strings exist !!
    if (isCurrentUserWorker) {
      relevantName = job.clientName.isNotEmpty
          ? job.clientName
          : (strings.workerDetailAnonymous ?? 'Client');
      relevantNameLabel = strings.clientNameLabel ?? 'Client';
    } else {
      // Current user is a client
      relevantName = job.workerName.isNotEmpty
          ? job.workerName
          : (statusKey == 'open' || statusKey == 'pending'
              ? (strings.jobDetailNoWorkerAssigned ?? 'Unassigned')
              : (strings.workerDetailAnonymous ?? 'Worker'));
      relevantNameLabel = strings.workerNameLabel ?? 'Worker';
    }

    return Card(
      margin: EdgeInsets.zero, // Let parent handle padding/spacing
      elevation: theme.cardTheme.elevation ?? 2,
      shape: theme.cardTheme.shape ??
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: theme.cardTheme.color ?? theme.colorScheme.surface,
      clipBehavior: Clip.antiAlias, // Ensures inkwell respects shape
      child: InkWell(
        onTap: () {
          // Navigate to Job Detail Screen when tapped
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
              // Status Icon
              CircleAvatar(
                radius: 24,
                backgroundColor: statusColor.withOpacity(0.15),
                child: Icon(statusIcon, color: statusColor, size: 24),
              ),
              const SizedBox(width: 16),
              // Job Details Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Status Badge Row
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
                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border:
                                Border.all(color: statusColor.withOpacity(0.5)),
                          ),
                          child: Text(
                            displayStatus,
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Description
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      maxLines: 2, // Limit description lines in list view
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    // Location and Budget Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Location Info
                        Flexible(
                            // Allow location to take available space but not overflow
                            child: Row(
                          mainAxisSize: MainAxisSize
                              .min, // Don't take full width if text is short
                          children: [
                            Icon(Icons.location_on_outlined,
                                size: 16,
                                color: theme.iconTheme.color?.withOpacity(0.7)),
                            const SizedBox(width: 4),
                            Flexible(
                                // Allow text itself to shrink/ellipsis
                                child: Text(
                              location,
                              style: theme.textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            )),
                          ],
                        )),
                        // Budget Info (only if budget > 0)
                        if (job.budget > 0)
                          Row(
                            children: [
                              Icon(Icons.monetization_on_outlined,
                                  size: 16, color: Colors.green.shade700),
                              const SizedBox(width: 4),
                              Text(budget,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.green.shade800)),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Client/Worker Name Row
                    Row(
                      children: [
                        Icon(
                            isCurrentUserWorker
                                ? Icons.account_circle_outlined
                                : Icons
                                    .construction_outlined, // Icon based on who the other party is
                            size: 16,
                            color: theme.iconTheme.color?.withOpacity(0.7)),
                        const SizedBox(width: 4),
                        Text('$relevantNameLabel: ',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                        Flexible(
                            // Allow name to shrink/ellipsis
                            child: Text(
                          relevantName,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        )),
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

  // (Keep _buildSettings, _buildSettingItem, _buildEditProfileButton as they were)
  Widget _buildSettings(
      BuildContext context, AppStrings strings, ThemeData theme) {
    // Helper function for navigation
    void navigateToScreen(Widget screen) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
    }

    // Define settings items with titles, subtitles, icons, and navigation actions
    // !! Ensure all these settings strings exist in AppStrings !!
    final settingsItems = [
      {
        'title': strings.settingsNotificationsTitle ?? 'Notifications',
        'subtitle':
            strings.settingsNotificationsSubtitle ?? 'Manage app notifications',
        'icon': Icons.notifications_active_outlined,
        'action': () => navigateToScreen(
            const NotificationsScreen()), // Navigate to NotificationsScreen
      },
      {
        'title': strings.settingsPaymentTitle ?? 'Payment Methods',
        'subtitle':
            strings.settingsPaymentSubtitle ?? 'Add or manage payment options',
        'icon': Icons.payment_outlined,
        // *** ACTION: Navigate to a screen for MANAGING payment methods ***
        // This should likely NOT be the PaymentScreen used for making a specific job payment,
        // unless that screen can also handle general method management.
        // Using ManagePaymentMethodsScreen placeholder. Replace with your actual screen.
        'action': () => navigateToScreen(
            const ManagePaymentMethodsScreen()), // Navigate to ManagePaymentMethodsScreen
      },
      {
        'title': strings.settingsPrivacyTitle ?? 'Privacy & Security',
        'subtitle':
            strings.settingsPrivacySubtitle ?? 'Password, account security',
        'icon': Icons.security_outlined,
        'action': () => navigateToScreen(
            const PrivacySecurityScreen()), // Navigate to PrivacySecurityScreen
      },
      {
        'title': strings.settingsAccountTitle ?? 'Account',
        'subtitle': strings.settingsAccountSubtitle ?? 'Manage account details',
        'icon': Icons.account_circle_outlined,
        'action': () => navigateToScreen(
            const ProfessionalHubScreen()), // Navigate to AccountScreen (might be used for client edit profile too)
      },
      {
        'title': strings.settingsHelpTitle ?? 'Help & Support',
        'subtitle': strings.settingsHelpSubtitle ?? 'Get help or contact us',
        'icon': Icons.help_outline_rounded,
        'action': () => navigateToScreen(
            const HelpSupportScreen()), // Navigate to HelpSupportScreen
      },
      // Add more settings items here as needed
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // !! Ensure 'profileSettingsTitle' exists !!
        Text(strings.profileSettingsTitle ?? 'Settings',
            style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        // Use ListView.separated for dividers between items
        ListView.separated(
          shrinkWrap: true, // Essential inside SingleChildScrollView
          physics:
              const NeverScrollableScrollPhysics(), // Disable internal scroll
          itemCount: settingsItems.length,
          itemBuilder: (context, index) {
            final item = settingsItems[index];
            // Build each setting item using a helper widget
            return _buildSettingItem(
              context,
              strings,
              theme,
              item['title'] as String,
              item['subtitle'] as String,
              item['icon'] as IconData,
              item['action'] as VoidCallback, // Pass the navigation action
            );
          },
          separatorBuilder: (context, index) => Divider(
            // Add dividers
            height: 1,
            thickness: 1,
            color: theme.dividerColor.withOpacity(0.5),
            indent: 58, // Indent divider to align with text
          ),
        ),
      ],
    );
  }

  // --- Settings Item (Helper) ---
  Widget _buildSettingItem(
      BuildContext context,
      AppStrings strings,
      ThemeData theme,
      String title,
      String subtitle,
      IconData icon,
      VoidCallback onTap) {
    return ListTile(
      leading: Container(
        // Styled container for the icon
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            // Use a subtle background color from the theme
            color: theme.colorScheme.secondaryContainer.withOpacity(0.4),
            borderRadius: BorderRadius.circular(10)),
        child:
            Icon(icon, color: theme.colorScheme.onSecondaryContainer, size: 22),
      ),
      title: Text(title, style: theme.textTheme.titleMedium),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodyMedium
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        maxLines: 1, // Prevent subtitle wrapping
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Icon(Icons.arrow_forward_ios,
          size: 16, color: theme.colorScheme.onSurfaceVariant),
      onTap: onTap, // Execute the provided navigation action on tap
      contentPadding: const EdgeInsets.symmetric(
          vertical: 6.0, horizontal: 8.0), // Adjust padding
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8)), // Optional rounded corners
    );
  }

  // --- Edit Profile Button Widget (Corrected Navigation) ---
  Widget _buildEditProfileButton(BuildContext context, AppStrings strings,
      ThemeData theme, bool isWorker) {
    return SizedBox(
      width: double.infinity, // Make button take full width
      child: ElevatedButton.icon(
        icon: const Icon(Icons.edit_outlined, size: 20),
        // !! Ensure 'profileEditButton' exists !!
        label: Text(strings.profileEditButton ?? 'Edit Profile'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14), // Button padding
          // Use theme colors for consistency
          // backgroundColor: theme.colorScheme.primary,
          // foregroundColor: theme.colorScheme.onPrimary,
        ),
        // Disable button during image upload or profile loading
        onPressed: _isUploadingImage || _isLoading
            ? null
            : () {
                // Navigate to the appropriate screen based on user role
                if (isWorker) {
                  // Navigate to Professional Setup/Edit Screen
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const ProfessionalHubScreen()) // Assumes this screen handles both setup and edit
                      ).then((result) {
                    // Refresh profile data when returning from edit screen
                    // The 'result' could potentially carry info if changes were made
                    if (mounted) {
                      print(
                          "Returned from ProfessionalHubScreen, refreshing profile...");
                      _loadUserProfile();
                    }
                  });
                } else {
                  // Navigate to a Client Account Edit Screen (Using AccountScreen placeholder)
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const ProfessionalHubScreen()) // Replace with your client edit screen
                      ).then((result) {
                    // Refresh profile data when returning
                    if (mounted) {
                      print(
                          "Returned from AccountScreen, refreshing profile...");
                      _loadUserProfile();
                    }
                  });
                }
              },
      ),
    );
  }
}
