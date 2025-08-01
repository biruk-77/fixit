import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
// Keep if using url_launcher for calls
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:share_plus/share_plus.dart';
import 'package:animated_rating_stars/animated_rating_stars.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart'; // For subtle animations

import '../models/worker.dart';
// Alias if User conflicts
import '../services/firebase_service.dart';
import '../services/auth_service.dart'; // Assuming AuthService provides user role
import 'jobs/create_job_screen.dart';
// Keep if using quick request
// import 'chat_screen.dart'; // Uncomment if you have chat

class WorkerDetailScreen extends StatefulWidget {
  final Worker worker;

  const WorkerDetailScreen({super.key, required this.worker});

  @override
  _WorkerDetailScreenState createState() => _WorkerDetailScreenState();
}

class _WorkerDetailScreenState extends State<WorkerDetailScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final AuthService _authService =
      AuthService(); // Use AuthService for user info
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _currentUserRole; // Store user role ('client', 'worker', etc.)
  double _currentReviewRating = 0.0;
  final _reviewController = TextEditingController();
  bool _isSubmittingReview = false;
  bool _isWorkerFavorite = false;
  bool _isLoadingFavorite = true; // Start true until checked

  bool _showAllReviews = false;
  final int _initialReviewCount = 3;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadUserRole();
    await _checkFavoriteStatus(); // Check fav status after knowing user role
  }

  Future<void> _loadUserRole() async {
    try {
      final userProfile =
          await _authService.getCurrentUserProfile(); // Use AuthService
      if (mounted && userProfile != null) {
        setState(() {
          _currentUserRole = userProfile.role;
          print("Current User Role: $_currentUserRole");
        });
      } else if (mounted) {
        setState(() {
          _currentUserRole = null;
        }); // Explicitly set null if no profile
        print("No user profile found or user not logged in.");
      }
    } catch (e) {
      print('Error loading user profile: $e');
      if (mounted) {
        _showErrorSnackbar('Error loading your profile.');
      }
    }
  }

  Future<void> _checkFavoriteStatus() async {
    // Ensure we know the user is a client and logged in
    if (_currentUserRole != 'client') {
      if (mounted) setState(() => _isLoadingFavorite = false);
      return;
    }
    final user = _authService.getCurrentUser(); // Use AuthService
    if (user == null) {
      if (mounted) setState(() => _isLoadingFavorite = false);
      return; // Not logged in
    }

    setState(() {
      _isLoadingFavorite = true;
    }); // Indicate loading

    try {
      final favDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(widget.worker.id)
          .get();

      if (mounted) {
        setState(() {
          _isWorkerFavorite = favDoc.exists;
          _isLoadingFavorite = false;
          print('Favorite status checked: $_isWorkerFavorite');
        });
      }
    } catch (e) {
      print('Error checking favorite status: $e');
      if (mounted) {
        _showErrorSnackbar('Error checking favorites.');
        setState(() {
          _isLoadingFavorite = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isLoadingFavorite || _currentUserRole != 'client') {
      return; // Only clients can favorite
    }

    final user = _authService.getCurrentUser();
    if (user == null) {
      _showErrorSnackbar('Please log in to manage favorites.');
      return;
    }

    setState(() {
      _isLoadingFavorite = true;
    });

    final favRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(widget.worker.id);

    try {
      if (_isWorkerFavorite) {
        // Remove from favorites
        await favRef.delete();
        if (mounted) {
          _showSuccessSnackbar('Removed from favorites');
          setState(() => _isWorkerFavorite = false);
        }
      } else {
        // Add to favorites
        await favRef.set({
          'workerId': widget.worker.id,
          'workerName': widget.worker.name, // Store extra info if needed
          'workerProfession': widget.worker.profession,
          'workerImageUrl': widget.worker.profileImage,
          'addedAt': FieldValue.serverTimestamp(),
        });
        if (mounted) {
          _showSuccessSnackbar('Added to favorites!');
          setState(() => _isWorkerFavorite = true);
        }
      }
    } catch (e) {
      print("Error toggling favorite: $e");
      if (mounted) _showErrorSnackbar('Could not update favorites.');
    } finally {
      if (mounted) setState(() => _isLoadingFavorite = false);
    }
  }

  // Function to show phone number (similar logic, ensure worker data source)
  Future<void> _showPhoneNumberDialog() async {
    // Determine potential paths (adjust based on your actual structure)
    final professionalRef =
        _firestore.collection('professionals').doc(widget.worker.id);
    final workerRef = _firestore.collection('workers').doc(widget.worker.id);

    DocumentSnapshot doc;
    try {
      doc = await professionalRef.get();
      if (!doc.exists) {
        print("Checking 'workers' collection...");
        doc = await workerRef.get();
      }

      if (!doc.exists) {
        if (mounted) _showErrorSnackbar('Worker profile not found.');
        return;
      }

      final data = doc.data() as Map<String, dynamic>?; // Safe cast
      final phoneNumber = data?['phoneNumber'] as String?;

      if (phoneNumber == null || phoneNumber.isEmpty) {
        if (mounted) _showErrorSnackbar('Phone number not available.');
        return;
      }

      // Show dialog with copy functionality
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) {
            final dialogTheme = Theme.of(context); // Use theme in dialog
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              backgroundColor: dialogTheme.colorScheme.surface,
              title: Text('Contact Number',
                  style: dialogTheme.textTheme.titleLarge),
              content: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                      child: Text(phoneNumber,
                          style: dialogTheme.textTheme.bodyLarge)),
                  IconButton(
                    icon: Icon(Icons.copy_rounded,
                        color: dialogTheme.colorScheme.primary),
                    tooltip: 'Copy Number',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: phoneNumber));
                      Navigator.pop(context); // Close dialog after copy
                      _showSuccessSnackbar('Phone number copied!');
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close',
                      style: TextStyle(color: dialogTheme.colorScheme.primary)),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print("Error fetching phone number: $e");
      if (mounted) _showErrorSnackbar('Error getting contact info.');
    }
  }

  // Simplified Hire Logic (Example - adapt as needed)
  void _handleHire() {
    // Option 1: Directly navigate to Quick Request (if preferred default)
    /*
     Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => QuickJobRequestScreen(worker: widget.worker)),
     );
     */

    // Option 2: Directly navigate to Full Job Post
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>
              CreateJobScreen(preselectedWorkerId: widget.worker.id)),
    );

    // Option 3: Show a non-blocking choice (e.g., two buttons at the bottom)
    // This requires more UI changes. The dialog might be acceptable if simple.
    // _showHireOptionsBottomSheet(); // Example: A custom bottom sheet
  }

  Future<void> _submitReview() async {
    if (_isSubmittingReview) return;
    final reviewText = _reviewController.text.trim();

    if (reviewText.isEmpty || _currentReviewRating <= 0.0) {
      _showErrorSnackbar('Please provide both a rating and comment.');
      return;
    }

    setState(() {
      _isSubmittingReview = true;
    });

    try {
      await _firebaseService.addReview(
          widget.worker.id, reviewText, _currentReviewRating);
      if (mounted) {
        _reviewController.clear();
        setState(() {
          _currentReviewRating = 0.0;
          _isSubmittingReview = false;
        });
        _showSuccessSnackbar('Review submitted successfully!');
        // Consider refreshing the review list here if using pagination or complex state
      }
    } catch (e) {
      print("Error submitting review: $e");
      if (mounted) {
        setState(() {
          _isSubmittingReview = false;
        });
        _showErrorSnackbar('Failed to submit review.');
      }
    }
  }

  // --- Helper Methods for UI ---

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Theme.of(context).colorScheme.error,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _showSuccessSnackbar(String message) {
    if (!mounted) return;
    // Define success color or get from theme extension if available
    final successColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.green[400]!
        : Colors.green[700]!;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: successColor,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // --- Build Method ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      // Use theme background color
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(theme, colorScheme, textTheme),
          SliverPadding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // --- Worker Info Header ---
                _buildWorkerHeader(theme, colorScheme, textTheme),
                const SizedBox(height: 24),

                // --- Action Buttons (Clients Only) ---
                if (_currentUserRole == 'client') ...[
                  _buildActionButtons(theme, colorScheme, textTheme),
                  const SizedBox(height: 24),
                ],

                // --- Key Information Chips ---
                _buildInfoChips(theme, colorScheme, textTheme),
                const SizedBox(height: 24),

                // --- About Section ---
                _buildSectionTitle(
                    textTheme, 'About ${widget.worker.name.split(' ').first}'),
                const SizedBox(height: 8),
                Text(
                    widget.worker.about.isEmpty
                        ? 'No details provided.'
                        : widget.worker.about,
                    style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.9))),
                const SizedBox(height: 24),

                // --- Skills Section ---
                _buildSectionTitle(textTheme, 'Skills'),
                const SizedBox(height: 12),
                _buildSkillsChips(theme, colorScheme),
                const SizedBox(height: 24),

                // --- Availability Section ---
                _buildSectionTitle(textTheme, 'Availability'),
                const SizedBox(height: 12),
                _buildAvailabilitySection(theme, colorScheme, textTheme),
                const SizedBox(height: 24),

                // --- Reviews Section ---
                _buildReviewsSection(theme, colorScheme, textTheme),
                const SizedBox(height: 24),

                // --- Add Review Section (Clients Only) ---
                if (_currentUserRole == 'client') ...[
                  _buildAddReviewSection(theme, colorScheme, textTheme),
                  const SizedBox(height: 80), // Space for potential FAB overlap
                ] else ...[
                  const SizedBox(
                      height: 20), // Padding at the bottom for non-clients
                ],
              ]),
            ),
          ),
        ],
      ),
      // Optional FAB - Consider if needed with buttons above
      // floatingActionButton: _currentUserRole == 'client' ? _buildHireFAB(theme, colorScheme, textTheme) : null,
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // --- UI Helper Widgets ---

  Widget _buildSliverAppBar(
      ThemeData theme, ColorScheme colorScheme, TextTheme textTheme) {
    return SliverAppBar(
      expandedHeight: 250.0, // Slightly taller for more impact
      floating: false,
      pinned: true,
      stretch: true, // Allows stretching on overscroll
      backgroundColor:
          theme.colorScheme.surface, // Use surface color, image fades in
      foregroundColor:
          colorScheme.onSurface, // Controls back button color when collapsed
      iconTheme: theme.iconTheme, // Use main icon theme
      actions: [
        // Favorite Button (Clients Only)
        if (_currentUserRole == 'client')
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FadeIn(
              // Subtle fade for the button
              delay: const Duration(milliseconds: 300),
              child: IconButton(
                icon: _isLoadingFavorite
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation(colorScheme.primary)))
                    : Icon(
                        _isWorkerFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: _isWorkerFavorite
                            ? colorScheme.error
                            : colorScheme.onSurface.withOpacity(0.7),
                        size: 26,
                      ),
                tooltip: _isWorkerFavorite ? 'Remove Favorite' : 'Add Favorite',
                onPressed: _toggleFavorite,
              ),
            ),
          ),
        // Share Button
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: FadeIn(
            // Subtle fade
            delay: const Duration(milliseconds: 400),
            child: IconButton(
              icon: Icon(Icons.share_rounded,
                  color: colorScheme.onSurface.withOpacity(0.7)),
              tooltip: 'Share Profile',
              onPressed: () {
                Share.share(
                  'Check out this professional on FixIt: ${widget.worker.name}, ${widget.worker.profession}. Find them on the app!',
                  subject: '${widget.worker.name} - FixIt Professional',
                );
              },
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true, // Center title when collapsed
        titlePadding:
            const EdgeInsets.symmetric(horizontal: 50.0, vertical: 12.0),
        title: Text(
          widget.worker.name,
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface, // Ensure visibility when collapsed
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        background: Hero(
          tag:
              'worker_image_grid_${widget.worker.id}', // Match tag from grid card
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: widget.worker.profileImage,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    Container(color: colorScheme.surfaceContainerHighest),
                errorWidget: (context, url, error) => Container(
                    color: colorScheme.surfaceContainerHighest,
                    child: Icon(Icons.person,
                        size: 80,
                        color: colorScheme.onSurfaceVariant.withOpacity(0.5))),
              ),
              // Gradient overlay for text readability
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.5),
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ],
          ),
        ),
        stretchModes: const [StretchMode.zoomBackground, StretchMode.fadeTitle],
      ),
    );
  }

  Widget _buildWorkerHeader(
      ThemeData theme, ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.worker.profession,
          style: textTheme.headlineSmall?.copyWith(
              color: colorScheme.primary, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Use StreamBuilder for live rating updates
            StreamBuilder<double>(
                stream: _firebaseService.streamWorkerRating(widget.worker.id),
                builder: (context, snapshot) {
                  // --- ADDED CHECKS ---
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SizedBox(
                        height: 22,
                        width: 80,
                        child: Center(
                            child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 1.5))));
                  }
                  if (snapshot.hasError) {
                    print("Error streaming rating: ${snapshot.error}");
                    final displayRating = widget.worker.rating; // Fallback
                    return AnimatedRatingStars(
                      initialRating: displayRating,
                      minRating: 0.0, maxRating: 5.0,
                      filledColor: Colors.amber,
                      emptyColor: Colors.grey.withOpacity(0.5),
                      // Ensure all icons are present
                      customFilledIcon: Icons.star_rounded,
                      customHalfFilledIcon: Icons.star_half_rounded,
                      customEmptyIcon: Icons.star_border_rounded,
                      onChanged: (rating) {}, displayRatingValue: true,
                      interactiveTooltips: false, starSize: 22.0,
                      // Added back
                      readOnly: true, // Added back
                    );
                  }
                  // --- END OF ADDED CHECKS ---

                  final displayRating = snapshot.data ??
                      widget.worker.rating; // Use data or fallback
                  return AnimatedRatingStars(
                    initialRating: displayRating,
                    minRating: 0.0, maxRating: 5.0,
                    filledColor: Colors.amber, // Keep amber for stars
                    emptyColor: Colors.grey.withOpacity(0.5),
                    // Ensure all icons are present
                    customFilledIcon: Icons.star_rounded,
                    customHalfFilledIcon: Icons.star_half_rounded,
                    customEmptyIcon: Icons.star_border_rounded,
                    onChanged: (rating) {}, // Read-only display
                    displayRatingValue: true, // Show numeric value
                    // NO ratingValueStyle
                    // Added back
                    readOnly: true, // Added back
                  );
                }),
            const SizedBox(width: 12),
            Icon(Icons.location_on_outlined,
                size: 18, color: colorScheme.onSurface.withOpacity(0.7)),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                widget.worker.location,
                style: textTheme.bodyMedium
                    ?.copyWith(color: colorScheme.onSurface.withOpacity(0.8)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(
      ThemeData theme, ColorScheme colorScheme, TextTheme textTheme) {
    return Row(
      children: [
        // Hire Button (Primary Action)
        Expanded(
          flex: 2, // Give Hire button more space
          child: ElevatedButton.icon(
            icon: const Icon(Icons.work_outline_rounded, size: 18),
            label: const Text('Hire Now'),
            onPressed: _handleHire,
            style: theme.elevatedButtonTheme.style?.copyWith(
              padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(vertical: 12)), // Adjust padding
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Call Button (Secondary Action)
        Expanded(
          flex: 1,
          child: OutlinedButton(
            onPressed: _showPhoneNumberDialog,
            style: theme.outlinedButtonTheme.style?.copyWith(
              padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(vertical: 12)),
            ),
            child: const Icon(Icons.phone_outlined),
          ),
        ),
        // Chat Button (Optional)
        /*
        const SizedBox(width: 12),
        Expanded(
          flex: 1,
          child: OutlinedButton(
             child: const Icon(Icons.chat_bubble_outline_rounded),
             onPressed: () {
                 // Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(peerId: widget.worker.id, peerName: widget.worker.name, peerAvatar: widget.worker.profileImage)));
             },
              style: theme.outlinedButtonTheme.style?.copyWith(
               padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 12)),
             ),
          ),
        ),
        */
      ],
    );
  }

  Widget _buildInfoChips(
      ThemeData theme, ColorScheme colorScheme, TextTheme textTheme) {
    return Wrap(
      spacing: 12.0,
      runSpacing: 10.0,
      children: [
        _buildInfoChip(theme, Icons.check_circle_outline_rounded,
            '${widget.worker.completedJobs} Jobs Done', colorScheme.secondary),
        _buildInfoChip(
            theme,
            Icons.history_toggle_off_rounded,
            '${widget.worker.experience} yrs Exp',
            colorScheme.tertiaryContainer ??
                colorScheme.primaryContainer), // Use container colors
        _buildInfoChip(
            theme,
            Icons.price_change_outlined,
            '${widget.worker.priceRange.toInt()} ETB/hr',
            colorScheme.primaryContainer),
      ],
    );
  }

  Widget _buildInfoChip(
      ThemeData theme, IconData icon, String label, Color backgroundColor) {
    // Determine text color based on background brightness
    Color textColor =
        backgroundColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    return Chip(
      avatar: Icon(icon, size: 18, color: textColor.withOpacity(0.8)),
      label: Text(label),
      labelStyle: theme.textTheme.bodySmall
          ?.copyWith(color: textColor, fontWeight: FontWeight.w500),
      backgroundColor: backgroundColor.withOpacity(0.9),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: BorderSide.none,
    );
  }

  Widget _buildSectionTitle(TextTheme textTheme, String title) {
    return Text(title,
        style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600));
  }

  Widget _buildSkillsChips(ThemeData theme, ColorScheme colorScheme) {
    if (widget.worker.skills.isEmpty) {
      return Text('No skills listed.',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)));
    }
    return Wrap(
      spacing: 8.0,
      runSpacing: 6.0,
      children: widget.worker.skills
          .map((skill) => Chip(
                label: Text(skill),
                // Use theme's chip style
                backgroundColor: theme.chipTheme.backgroundColor,
                labelStyle: theme.chipTheme.labelStyle,
                padding: theme.chipTheme.padding,
                shape: theme.chipTheme.shape,
                side: theme.chipTheme.side,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ))
          .toList(),
    );
  }

  // Redesigned Availability Section
  Widget _buildAvailabilitySection(
      ThemeData theme, ColorScheme colorScheme, TextTheme textTheme) {
    final now = DateTime.now();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        height: 95, // Adjusted height
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 7, // Show next 7 days
          itemBuilder: (context, index) {
            final date = now.add(Duration(days: index));
            final dayFormat =
                DateFormat('E'); // Abbreviated day name (Mon, Tue)
            final dayName = dayFormat.format(date);

            return StreamBuilder<bool>(
              stream: _firebaseService.streamDayAvailability(
                  widget.worker.id, date),
              initialData: true, // Assume available initially
              builder: (context, snapshot) {
                final isAvailable = snapshot.data ??
                    false; // Default to false if error or no data
                bool isToday = date.day == now.day &&
                    date.month == now.month &&
                    date.year == now.year;

                return GestureDetector(
                  onTap: isAvailable
                      ? () => _showTimeSlotDialog(date)
                      : null, // Allow tapping available days
                  child: Container(
                    width: 70, // Fixed width for each day
                    margin: const EdgeInsets.only(right: 10.0),
                    decoration: BoxDecoration(
                      color: isAvailable
                          ? colorScheme.surface
                          : colorScheme.surfaceContainerHighest
                              .withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: isToday
                              ? colorScheme.primary
                              : (isAvailable
                                  ? colorScheme.outline.withOpacity(0.5)
                                  : Colors.transparent),
                          width: isToday ? 1.5 : 1.0),
                      boxShadow: isAvailable
                          ? [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: Offset(0, 2))
                            ]
                          : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          dayName,
                          style: textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isAvailable
                                  ? colorScheme.primary
                                  : colorScheme.onSurface.withOpacity(0.5)),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${date.day}',
                          style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isAvailable
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurface.withOpacity(0.5)),
                        ),
                        const SizedBox(height: 6),
                        // Subtle availability indicator
                        Container(
                          height: 6,
                          width: 6,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isAvailable
                                  ? Colors.greenAccent[400]
                                  : Colors.redAccent[100]?.withOpacity(0.7)),
                        )
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // Builds Reviews Section (using StreamBuilder)
  Widget _buildReviewsSection(
      ThemeData theme, ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: _firebaseService.streamWorkerReviews(widget.worker.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // Show shimmer placeholders while loading reviews
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(textTheme, 'Reviews'),
                  const SizedBox(height: 12),
                  _buildReviewShimmer(theme, colorScheme),
                  _buildReviewShimmer(theme, colorScheme),
                ],
              );
            }
            if (snapshot.hasError) {
              print("Error loading reviews: ${snapshot.error}");
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(textTheme, 'Reviews'),
                  const SizedBox(height: 8),
                  Text('Could not load reviews.',
                      style: textTheme.bodyMedium
                          ?.copyWith(color: colorScheme.error)),
                ],
              );
            }

            final reviews = snapshot.data ?? [];
            final totalReviews = reviews.length;
            final reviewsToShow = _showAllReviews
                ? reviews
                : reviews.take(_initialReviewCount).toList();
            final canShowMore =
                totalReviews > _initialReviewCount && !_showAllReviews;
            final canShowLess =
                totalReviews > _initialReviewCount && _showAllReviews;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildSectionTitle(textTheme, 'Reviews ($totalReviews)'),
                    if (canShowMore || canShowLess)
                      TextButton(
                        onPressed: () =>
                            setState(() => _showAllReviews = !_showAllReviews),
                        style: theme.textButtonTheme.style,
                        child: Text(canShowMore ? 'Show All' : 'Show Less'),
                      )
                  ],
                ),
                const SizedBox(height: 12),
                if (reviews.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(
                      child: Text('No reviews yet.',
                          style: textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.7))),
                    ),
                  )
                else
                  ListView.separated(
                    itemCount: reviewsToShow.length,
                    shrinkWrap: true, // Important inside CustomScrollView
                    physics:
                        const NeverScrollableScrollPhysics(), // Let outer scroll handle it
                    itemBuilder: (context, index) => FadeInUp(
                        from: 20, // Animate from bottom
                        delay: Duration(
                            milliseconds: index * 50), // Stagger animation
                        child: _buildReviewCard(theme, colorScheme, textTheme,
                            reviewsToShow[index])),
                    separatorBuilder: (context, index) => Divider(
                        height: 20,
                        thickness: 0.5,
                        indent: 16,
                        endIndent: 16,
                        color: theme.dividerColor.withOpacity(0.5)),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  // Builds a single Review Card with improved styling
  Widget _buildReviewCard(ThemeData theme, ColorScheme colorScheme,
      TextTheme textTheme, Map<String, dynamic> review) {
    final reviewDate =
        _parseReviewDate(review['createdAt']); // Use safe parsing
    final rating = review['rating'] as double? ?? 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(
          vertical: 12.0, horizontal: 8.0), // Less horizontal padding
      // No explicit background color, relies on section background or scaffold
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor:
                colorScheme.surfaceContainerHighest, // Themed background
            backgroundImage: review['clientPhotoUrl'] != null &&
                    (review['clientPhotoUrl'] as String).isNotEmpty
                ? CachedNetworkImageProvider(review['clientPhotoUrl'])
                : null,
            child: (review['clientPhotoUrl'] == null ||
                    (review['clientPhotoUrl'] as String).isEmpty)
                ? Icon(Icons.person_outline,
                    size: 20, color: colorScheme.onSurfaceVariant)
                : null,
          ),
          const SizedBox(width: 12),
          // Review Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // User Name & Time
                    Expanded(
                      child: Text(
                        review['userName'] ?? 'Anonymous',
                        style: textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      timeago.format(reviewDate, locale: 'en_short'),
                      style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6)),
                    ), // Short time format
                  ],
                ),
                const SizedBox(height: 4),
                // Rating Stars
                if (rating > 0)
                  Row(
                    children: List.generate(
                        5,
                        (index) => Icon(
                              index < rating
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: Colors
                                  .amber[600], // Keep star color consistent
                              size: 16,
                            )),
                  ),
                const SizedBox(height: 8),
                // Review Comment
                Text(
                  review['comment'] ?? 'No comment provided.',
                  style: textTheme.bodyMedium
                      ?.copyWith(color: colorScheme.onSurface.withOpacity(0.9)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Builds Shimmer Placeholder for a Review Card
  Widget _buildReviewShimmer(ThemeData theme, ColorScheme colorScheme) {
    final isDarkMode = theme.brightness == Brightness.dark;
    Color baseColor = isDarkMode ? Colors.grey[800]! : Colors.grey[200]!;
    Color highlightColor = isDarkMode ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
                radius: 20, backgroundColor: Colors.white), // Placeholder color
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      height: 14,
                      width: 100,
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 6)),
                  Container(
                      height: 10,
                      width: 60,
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 10)),
                  Container(
                      height: 12,
                      width: double.infinity,
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 6)),
                  Container(
                      height: 12,
                      width: double.infinity * 0.7,
                      color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Builds "Add Review" Section
  Widget _buildAddReviewSection(
      ThemeData theme, ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(textTheme, 'Leave a Review'),
        const SizedBox(height: 16),
        // Rating Input
        Center(
          // Center the stars
          child: AnimatedRatingStars(
            customFilledIcon: Icons.star_rounded,
            customHalfFilledIcon: Icons.star_half_rounded,
            customEmptyIcon: Icons.star_border,
            initialRating: _currentReviewRating,
            minRating: 0.0,
            maxRating: 5.0,
            filledColor: Colors.amber,
            emptyColor: Colors.grey.withOpacity(0.5),
            filledIcon: Icons.star_rounded,
            emptyIcon: Icons.star_border_rounded,
            onChanged: (rating) =>
                setState(() => _currentReviewRating = rating),
            displayRatingValue: true,
            interactiveTooltips: true,
            starSize: 35.0,
            animationDuration: const Duration(milliseconds: 300),
            readOnly: _isSubmittingReview,
          ),
        ),
        const SizedBox(height: 16),
        // Comment Input Field
        TextFormField(
          controller: _reviewController,
          decoration: InputDecoration(
            // Use themed input decoration
            hintText: 'Share your experience...',
            // Use hintStyle from theme if available
            hintStyle: theme.inputDecorationTheme.hintStyle ??
                textTheme.bodyLarge
                    ?.copyWith(color: colorScheme.onSurface.withOpacity(0.6)),
            filled: true,
            fillColor: theme.inputDecorationTheme.fillColor ??
                colorScheme.surfaceContainerHighest.withOpacity(0.5),
            border: theme.inputDecorationTheme.border ??
                OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
            enabledBorder: theme.inputDecorationTheme.enabledBorder ??
                OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
            focusedBorder: theme.inputDecorationTheme.focusedBorder ??
                OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colorScheme.primary)),
            contentPadding: theme.inputDecorationTheme.contentPadding ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabled: !_isSubmittingReview,
          ),
          maxLines: 4,
          maxLength: 400, // Adjusted length slightly
          style: textTheme.bodyLarge,
          textCapitalization: TextCapitalization.sentences,
          buildCounter: (context,
              {required currentLength, required isFocused, maxLength}) {
            return Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child:
                  Text('$currentLength/$maxLength', style: textTheme.bodySmall),
            );
          },
        ),
        const SizedBox(height: 16),
        // Submit Button
        SizedBox(
          // Ensure button takes full width
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSubmittingReview ? null : _submitReview,
            style: theme.elevatedButtonTheme.style?.copyWith(
              padding: WidgetStateProperty.all(const EdgeInsets.symmetric(
                  vertical: 14)), // Consistent padding
            ),
            child: _isSubmittingReview
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white)))
                : const Text('Submit Review'),
          ),
        ),
      ],
    );
  }

  // --- Date Parsing Helper ---
  DateTime _parseReviewDate(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is String) {
      // Attempt to parse ISO 8601 string (add more formats if needed)
      try {
        return DateTime.parse(timestamp);
      } catch (_) {}
    }
    // Fallback if parsing fails or type is unexpected
    print("Warning: Could not parse review date: $timestamp");
    return DateTime.now(); // Or return null and handle it in the UI
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  // Keep _showTimeSlotDialog as it was, just ensure it uses themed elements if possible
  void _showTimeSlotDialog(DateTime date) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        // Use a different context name
        final dialogTheme =
            Theme.of(dialogContext); // Get theme from this context
        final dialogColorScheme = dialogTheme.colorScheme;
        final dialogTextTheme = dialogTheme.textTheme;

        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: dialogColorScheme.surface,
          title: Text('Select Time Slot', style: dialogTextTheme.titleLarge),
          content: StreamBuilder<List<bool>>(
            stream: _firebaseService.streamTimeSlots(widget.worker.id, date),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final timeSlots = snapshot.data ??
                  List.filled(9, false); // Default to unavailable if error
              return SizedBox(
                width: double.maxFinite,
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2.2, // Adjust aspect ratio
                    crossAxisSpacing: 10, mainAxisSpacing: 10,
                  ),
                  itemCount: 9,
                  itemBuilder: (context, index) {
                    final hour = index + 9; // Assuming slots from 9:00 to 17:00
                    final isAvailable = timeSlots.length > index
                        ? timeSlots[index]
                        : false; // Safety check
                    return InkWell(
                      onTap: isAvailable
                          ? () {
                              Navigator.pop(dialogContext); // Use dialogContext
                              _handleHire(); // Go to hire flow
                            }
                          : null, // Disable tap if unavailable
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isAvailable
                              ? dialogColorScheme.primaryContainer
                                  .withOpacity(0.2)
                              : dialogColorScheme.surfaceContainerHighest
                                  .withOpacity(0.5),
                          border: Border.all(
                              color: isAvailable
                                  ? dialogColorScheme.primaryContainer
                                  : dialogColorScheme.outline.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$hour:00',
                          style: dialogTextTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isAvailable
                                  ? dialogColorScheme.onPrimaryContainer
                                  : dialogColorScheme.onSurfaceVariant
                                      .withOpacity(0.6)),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext), // Use dialogContext
              child: Text('Cancel',
                  style: TextStyle(color: dialogColorScheme.primary)),
            ),
          ],
        );
      },
    );
  }
} // End of _WorkerDetailScreenState
