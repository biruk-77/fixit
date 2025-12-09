import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// For shimmer effect
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart'; // For staggered animations

import '../../models/job.dart';
import '../../models/worker.dart';
import '../../models/user.dart';
import '../../services/firebase_service.dart';
import 'job_detail_screen.dart'; // Ensure this exists and is correct
import '../payment/payment_screen.dart'; // Ensure this exists and is correct
import '../chat_screen.dart'; // Ensure this exists and is correct
import '../../services/app_string.dart'; // Import your AppStrings (which contains AppLocalizations)
import '../worker_detail_screen.dart';

// Enum for sorting options
enum SortOption { byDate, byName }

class JobDashboardScreen extends StatefulWidget {
  const JobDashboardScreen({super.key});

  @override
  _JobDashboardScreenState createState() => _JobDashboardScreenState();
}

class _JobDashboardScreenState extends State<JobDashboardScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  late TabController _tabController;
  bool _isLoading = true;

  List<Job> _myJobs = [];
  List<Job> _appliedJobs = [];
  List<Job> _requestedJobs = [];
  List<Job> _assignedJobs = [];
  List<Job> worksforme = []; // Retaining this unused variable as per request

  int _selectedFilterIndex = 0;
  bool _isWorker = false;
  AppUser? _userProfile;

  // --- Search and Sorting Variables ---
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  SortOption _currentSortOption = SortOption.byDate; // Default sort by date

  // Theme Colors - These will be largely overridden by Material 3 theming
  // but kept for reference if needed for specific non-themed widgets.
  static const Color primaryColor = Color(0xFF2E7D32); // Deep Green
  static const Color secondaryColor = Color(0xFF6A1B9A); // Purple
  static const Color accentColor = Color(0xFFFFA000); // Amber
  // Other colors are not directly used in the original logic,
  // but their visual intent will be captured by ColorScheme.

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    // Ensure context is available for AppLocalizations.of(context) on first build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() => _selectedFilterIndex = 0);
      _loadJobs();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose(); // Dispose the controller
    super.dispose();
  }

  Future<void> _loadUserData() async {
    // Ensure context is available before using AppLocalizations.of
    if (!mounted) return;
    final appStrings = AppLocalizations.of(context)!; // Corrected call

    setState(() => _isLoading = true);
    try {
      final userProfile = await _firebaseService.getCurrentUserProfile();
      if (mounted) {
        setState(() {
          _userProfile = userProfile;
          _isWorker = userProfile?.role == 'worker';
        });
      }
      await _loadJobs();
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar(
          appStrings.errorLoadingData(e.toString()),
        ); // Using AppStrings
        print('Error loading data: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadJobs() async {
    // Ensure context is available before using AppLocalizations.of
    if (!mounted) return;
    final appStrings = AppLocalizations.of(context)!; // Corrected call

    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      if (_isWorker) {
        final assignedJobs = await _firebaseService.getWorkerJobs(userId);
        // For worksForMeJobs, also include assigned jobs with appropriate status
        final worksForMeJobs = await _firebaseService.getWorkerAssignedJobs(
          userId,
        );
        // If empty, fall back to assigned jobs with 'accepted' or 'in_progress' status
        final effectiveWorksForMe = worksForMeJobs.isNotEmpty
            ? worksForMeJobs
            : assignedJobs
                  .where(
                    (job) => [
                      'accepted',
                      'in_progress',
                      'assigned',
                      'cancelled',
                      'completed',
                      'rejected',
                      'started working',
                    ].contains(job.status.toLowerCase()),
                  )
                  .toList();
        final appliedJobs = await _firebaseService.getAppliedJobs(userId);
        if (mounted) {
          // Check mounted before setState
          setState(() {
            _myJobs = assignedJobs;
            _appliedJobs = appliedJobs;
            _assignedJobs = effectiveWorksForMe; // Use the effective list
          });
        }
        print('Final works for me jobs: ${_assignedJobs.length}');
      } else {
        // For clients, fetch both posted jobs and requested jobs in parallel
        final [postedJobs, requestedJobs] = await Future.wait([
          _firebaseService.getClientJobsWithApplications(userId),
          _firebaseService.getRequestedJobs(userId),
        ]);
        if (mounted) {
          // Check mounted before setState
          setState(() {
            _myJobs = postedJobs;
            _requestedJobs = requestedJobs;
          });
        }
      }
    } catch (e) {
      print('Error loading jobs: $e');
      _showErrorSnackbar(
        appStrings.errorLoadingJobs(e.toString()),
      ); // Using AppStrings
    } finally {
      if (mounted) {
        // Check mounted before setState
        setState(() => _isLoading = false);
      }
    }
  }

  // Action Methods
  Future<void> _cancelJob(Job job) async {
    // Ensure context is available before using AppLocalizations.of
    if (!mounted) return;
    final appStrings = AppLocalizations.of(context)!; // Corrected call

    try {
      setState(() => _isLoading = true);
      await _firebaseService.deleteJob(job.id);
      _showSuccessSnackbar(
        appStrings.jobCancelledSuccessfullyText,
      ); // Using AppStrings
      await _loadUserData();
    } catch (e) {
      _showErrorSnackbar(
        appStrings.errorCancellingJob(e.toString()),
      ); // Using AppStrings
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptApplication(
    Job job,
    String workerId,
    String clientId,
  ) async {
    // Ensure context is available before using AppLocalizations.of
    if (!mounted) return;
    final appStrings = AppLocalizations.of(context)!; // Corrected call

    try {
      setState(() => _isLoading = true);
      await _firebaseService.acceptJobApplication(job.id, workerId, clientId);
      _showSuccessSnackbar(
        appStrings.applicationAcceptedSuccessfullyText,
      ); // Using AppStrings
      await _loadJobs();
    } catch (e) {
      _showErrorSnackbar(
        appStrings.errorAcceptingApplication(e.toString()),
      ); // Using AppStrings
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptJob(Job job, userID) async {
    // Ensure context is available before using AppLocalizations.of
    if (!mounted) return;
    final appStrings = AppLocalizations.of(context)!; // Corrected call
    try {
      setState(() => _isLoading = true);
      print(userID);
      await _firebaseService.updateJobStatus1(
        job.id,
        userID,
        job.clientId,
        'accepted',
      );

      await _loadJobs();
      _showSuccessSnackbar(
        appStrings.jobAcceptedSuccessfullyText,
      ); // Using AppStrings

      // Original logic for navigating to 'ACTIVE WORK' tab
      if (_isWorker) {
        _tabController.animateTo(2); // Navigate to 'ACTIVE WORK' tab (index 2)
      }
    } catch (e) {
      _showErrorSnackbar(
        appStrings.errorAcceptingJob(e.toString()),
      ); // Using AppStrings
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _completeJob(Job job, workerID) async {
    // Ensure context is available before using AppLocalizations.of
    if (!mounted) return;
    final appStrings = AppLocalizations.of(context)!; // Corrected call

    try {
      setState(() => _isLoading = true);
      await _firebaseService.updateJobStatus1(
        job.id,
        workerID,
        job.clientId,
        'completed',
      );
      _showSuccessSnackbar(
        appStrings.jobMarkedAsCompletedSuccessfullyText,
      ); // Using AppStrings
      await _loadJobs();
    } catch (e) {
      _showErrorSnackbar(
        appStrings.errorCompletingJob(e.toString()),
      ); // Using AppStrings
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startWork1(Job job) async {
    // Ensure context is available before using AppLocalizations.of
    if (!mounted) return;
    final appStrings = AppLocalizations.of(context)!; // Corrected call

    final currentUserId = _firebaseService.getCurrentUser()?.uid;
    if (currentUserId == null) {
      _showErrorSnackbar("Error: You are not logged in.");
      return;
    }

    try {
      setState(() => _isLoading = true);
      print('Current user ID: ${_firebaseService.getCurrentUser()?.uid}');
      print('currentuserID from start work: $currentUserId');

      await _firebaseService.updateJobStatus1(
        job.id,
        currentUserId, // This was job.seekerId, which was incorrect
        job.clientId,
        'started working',
      );

      _showSuccessSnackbar(
        appStrings.workStartedSuccessfullyText,
      ); // Using AppStrings
      await _loadJobs();
    } catch (e) {
      _showErrorSnackbar(
        appStrings.errorStartingWork(e.toString()),
      ); // Using AppStrings
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _startWork(Job job) async {
    // Ensure context is available before using AppLocalizations.of
    if (!mounted) return;
    final appStrings = AppLocalizations.of(context)!; // Corrected call

    final currentUserId = _firebaseService.getCurrentUser()?.uid;
    if (currentUserId == null) {
      _showErrorSnackbar("Error: You are not logged in.");
      return;
    }

    try {
      setState(() => _isLoading = true);
      print('Current user ID: ${_firebaseService.getCurrentUser()?.uid}');
      print('currentuserID from start work: $currentUserId');

      await _firebaseService.updateJobStatus(
        job.id,
        currentUserId, // This was job.seekerId, which was incorrect
        job.clientId,
        'started working',
      );

      _showSuccessSnackbar(
        appStrings.workStartedSuccessfullyText,
      ); // Using AppStrings
      await _loadJobs();
    } catch (e) {
      _showErrorSnackbar(
        appStrings.errorStartingWork(e.toString()),
      ); // Using AppStrings
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // UI Helper Methods
  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ), // Original hardcoded white text
        backgroundColor: Theme.of(
          context,
        ).colorScheme.primary, // Using theme color
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ), // Original hardcoded white text
        backgroundColor: Theme.of(
          context,
        ).colorScheme.error, // Using theme color
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // --- ADD THIS HELPER METHOD ---
  void _navigateToChat(String otherUserId) {
    if (otherUserId.isEmpty) {
      _showErrorSnackbar("Cannot start chat: User ID is missing.");
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            UnifiedChatScreen(initialSelectedUserId: otherUserId),
      ),
    );
  }

  void _navigateToJobDetail(Job job) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JobDetailScreen(job: job),
        fullscreenDialog: true,
      ),
    ).then((_) => _loadUserData());
  }

  void _navigateToEditJob(Job job) {
    Navigator.pushNamed(
      context,
      '/post-job',
      arguments: job,
    ).then((_) => _loadUserData());
  }

  void _navigateToJobApplications(Job job) {
    final currentUserId = _firebaseService.getCurrentUser()?.uid;
    if (currentUserId == null || currentUserId.isEmpty) {
      _showErrorSnackbar("Your user ID is missing. Please re-login.");
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JobApplicationsScreen(
          job: job,
          clientId: currentUserId, // Pass the guaranteed ID
        ),
      ),
    ).then((_) => _loadUserData());
  }

  @override
  Widget build(BuildContext context) {
    final appStrings = AppLocalizations.of(context)!; // Corrected call
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface, // Using theme color
      appBar: AppBar(
        // --- MODIFICATION: AppBar now dynamically shows title or search field ---
        title: _isSearching
            ? _buildSearchField()
            : Text(
                _isWorker
                    ? appStrings.myWorkDashboardText
                    : appStrings.myJobsDashboardText,
                style: textTheme.titleLarge?.copyWith(
                  color: colorScheme.onPrimary,
                ),
              ),
        actions: _buildAppBarActions(),
        // --- END MODIFICATION ---
        backgroundColor: colorScheme.primary, // AppBar background from theme
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colorScheme.secondary, // Accent color from theme
          labelColor: colorScheme.onPrimary, // White from theme
          unselectedLabelColor: colorScheme.onPrimary.withOpacity(
            0.7,
          ), // White70 from theme
          labelStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ), // Using theme text
          tabs: _isWorker
              ? [
                  Tab(text: appStrings.assignedJobsText), // Using AppStrings
                  Tab(text: appStrings.myApplicationsText), // Using AppStrings
                  Tab(text: appStrings.activeWorkText), // Using AppStrings
                ]
              : [
                  Tab(text: appStrings.myPostedJobsText), // Using AppStrings
                  Tab(text: appStrings.applicationsText), // Using AppStrings
                  Tab(text: appStrings.myRequestsText), // Using AppStrings
                ],
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  colorScheme.primary,
                ), // Using theme color
                strokeWidth: 3,
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadUserData,
              color: colorScheme.primary, // Using theme color
              child: AnimationLimiter(
                // Added AnimationLimiter
                child: TabBarView(
                  controller: _tabController,
                  children: _isWorker
                      ? [
                          _buildAssignedJobsView(),
                          _buildAppliedJobsView(),
                          _buildWorksForMeView(),
                        ]
                      : [
                          _buildPostedJobsView(),
                          _buildApplicationsView(),
                          _buildRequestedJobsView(),
                        ],
                ),
              ),
            ),
      floatingActionButton: !_isWorker
          ? FloatingActionButton(
              onPressed: () => Navigator.pushNamed(
                context,
                '/post-job',
              ).then((_) => _loadUserData()),
              backgroundColor: colorScheme.secondary, // Icon color from theme
              elevation: 4, // Accent color from theme
              child: Icon(
                Icons.add,
                size: 28,
                color: colorScheme.onSecondary,
              ),
            )
          : null,
    );
  }

  // --- NEW: Helper widget for the search text field ---
  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      decoration: const InputDecoration(
        hintText: 'Search by job title...',
        hintStyle: TextStyle(color: Colors.white70),
        border: InputBorder.none,
      ),
      style: const TextStyle(color: Colors.white, fontSize: 18.0),
      onChanged: (query) {
        setState(() {
          _searchQuery = query;
        });
      },
    );
  }

  // --- NEW: Helper widget for the AppBar actions (search/sort/close) ---
  List<Widget> _buildAppBarActions() {
    final onPrimaryColor = Theme.of(context).colorScheme.onPrimary;
    if (_isSearching) {
      return [
        IconButton(
          icon: Icon(Icons.close, color: onPrimaryColor),
          onPressed: () {
            if (_searchController.text.isNotEmpty) {
              _searchController.clear();
            }
            setState(() {
              _isSearching = false;
              _searchQuery = '';
            });
          },
        ),
      ];
    }
    return [
      IconButton(
        icon: Icon(Icons.search, color: onPrimaryColor),
        onPressed: () {
          setState(() {
            _isSearching = true;
          });
        },
      ),
      PopupMenuButton<SortOption>(
        icon: Icon(Icons.sort, color: onPrimaryColor),
        onSelected: (SortOption result) {
          setState(() {
            _currentSortOption = result;
          });
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<SortOption>>[
          PopupMenuItem<SortOption>(
            value: SortOption.byDate,
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: _currentSortOption == SortOption.byDate
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                ),
                const SizedBox(width: 8),
                const Text('Sort by Date'),
              ],
            ),
          ),
          PopupMenuItem<SortOption>(
            value: SortOption.byName,
            child: Row(
              children: [
                Icon(
                  Icons.sort_by_alpha,
                  color: _currentSortOption == SortOption.byName
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                ),
                const SizedBox(width: 8),
                const Text('Sort by Name (A-Z)'),
              ],
            ),
          ),
        ],
      ),
    ];
  }

  Widget _buildAssignedJobsView() {
    final appStrings = AppLocalizations.of(context)!; // Corrected call
    final filteredJobs = _applyStatusFilter(_myJobs);

    // --- MODIFICATION: Apply sorting ---
    filteredJobs.sort((a, b) {
      if (_currentSortOption == SortOption.byDate) {
        return b.createdAt.compareTo(a.createdAt); // Newest first
      } else {
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      }
    });

    return Column(
      children: [
        _buildFilterChips(
          true,
          appStrings.allText,
          appStrings.openText,
          appStrings.pendingText,
          appStrings.acceptedText,
          appStrings.completedText,
        ), // Using AppStrings
        const SizedBox(height: 16),
        Align(
          alignment: const Alignment(0.9, -1),
          child: Text(
            '${filteredJobs.length} ${appStrings.assignedJobText}${filteredJobs.length == 1 ? '' : 's'}', // Using AppStrings
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ), // Using theme text
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: filteredJobs.isEmpty
              ? _buildEmptyState(
                  appStrings.noAssignedJobsYetText, // Using AppStrings
                  Icons.assignment_turned_in,
                  appStrings.whenJobsAreAssignedToYouText, // Using AppStrings
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredJobs.length,
                  itemBuilder: (context, index) =>
                      AnimationConfiguration.staggeredList(
                        // Added animation
                        position: index,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: _buildJobCard(
                              filteredJobs[index],
                              showAcceptButton: true,
                              showApplications: false,
                            ),
                          ),
                        ),
                      ),
                ),
        ),
      ],
    );
  }

  Widget _buildAppliedJobsView() {
    final appStrings = AppLocalizations.of(context)!; // Corrected call
    final filteredJobs = _applyStatusFilter(_appliedJobs);

    // --- MODIFICATION: Apply sorting ---
    filteredJobs.sort((a, b) {
      if (_currentSortOption == SortOption.byDate) {
        return b.createdAt.compareTo(a.createdAt); // Newest first
      } else {
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      }
    });

    return Column(
      children: [
        _buildFilterChips(
          true,
          appStrings.allText,
          appStrings.openText,
          appStrings.pendingText,
          appStrings.acceptedText,
          appStrings.closedText,
        ), // Using AppStrings
        const SizedBox(height: 16),
        Align(
          alignment: const Alignment(0.9, -1),
          child: Text(
            '${filteredJobs.length} ${appStrings.jobText}${filteredJobs.length == 1 ? '' : 's'}', // Using AppStrings
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ), // Using theme text
          ),
        ),
        Expanded(
          child: filteredJobs.isEmpty
              ? _buildEmptyState(
                  appStrings.noApplicationsYetText, // Using AppStrings
                  Icons.send,
                  appStrings
                      .jobsYouApplyForWillAppearHereText, // Using AppStrings
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredJobs.length,
                  itemBuilder: (context, index) =>
                      AnimationConfiguration.staggeredList(
                        // Added animation
                        position: index,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: _buildJobCard(
                              filteredJobs[index],
                              showStatus: true,
                              showCompleteButton: true,
                              checkbutton:
                                  false, // This ensures the default buttons don't show, allowing our new logic to take over
                            ),
                          ),
                        ),
                      ),
                ),
        ),
      ],
    );
  }

  Widget _buildWorksForMeView() {
    final appStrings = AppLocalizations.of(context)!; // Corrected call

    // First, ensure we're showing all relevant statuses for active work
    List<Job> relevantJobs = _assignedJobs.where((job) {
      return [
        'accepted',
        'in_progress',
        'completed',
        'assigned',
        'cancelled',
        'rejected',
        'started working',
      ].contains(job.status.toLowerCase());
    }).toList();

    // --- MODIFICATION: Apply sorting before filtering by status chip ---
    relevantJobs.sort((a, b) {
      if (_currentSortOption == SortOption.byDate) {
        return b.createdAt.compareTo(a.createdAt); // Newest first
      } else {
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      }
    });

    // Apply search filter and status filter
    List<Job> filteredJobs = _applyStatusFilter(relevantJobs);

    return Column(
      children: [
        _buildFilterChips(
          true,
          appStrings.allText,
          appStrings.acceptedText,
          appStrings.inProgressText,
          appStrings.completedText,
          appStrings.cancelledText,
        ), // Using AppStrings
        const SizedBox(height: 16),
        Align(
          alignment: const Alignment(0.9, -1),
          child: Text(
            '${filteredJobs.length} ${appStrings.activeJobText}${filteredJobs.length == 1 ? '' : 's'}', // Using AppStrings
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ), // Using theme text
          ),
        ),
        Expanded(
          child: filteredJobs.isEmpty
              ? _buildEmptyState(
                  appStrings.noActiveWorkText, // Using AppStrings
                  Icons.work,
                  appStrings
                      .yourActiveJobsWillAppearHereText, // Using AppStrings
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredJobs.length,
                  itemBuilder: (context, index) =>
                      AnimationConfiguration.staggeredList(
                        // Added animation
                        position: index,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: _buildJobCard(
                              filteredJobs[index],
                              showCompleteButton: true,
                              showActiveWorkActions: true,
                              showApplications:
                                  false, // Add any other relevant parameters
                            ),
                          ),
                        ),
                      ),
                ),
        ),
      ],
    );
  }

  Widget _buildPostedJobsView() {
    final appStrings = AppLocalizations.of(context)!; // Corrected call
    final filteredJobs = _applyStatusFilter(_myJobs);

    // --- MODIFICATION: Apply sorting ---
    filteredJobs.sort((a, b) {
      if (_currentSortOption == SortOption.byDate) {
        return b.createdAt.compareTo(a.createdAt); // Newest first
      } else {
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterChips(
          false,
          appStrings.allText,
          appStrings.openText,
          appStrings.pendingText,
          appStrings.acceptedText,
          appStrings.completedText,
        ), // Using AppStrings
        const SizedBox(height: 16),
        Align(
          alignment: const Alignment(0.9, -1),
          child: Text(
            '${filteredJobs.length} ${appStrings.jobText}${filteredJobs.length == 1 ? '' : 's'}', // Using AppStrings
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ), // Using theme text
          ),
        ),
        Expanded(
          child: filteredJobs.isEmpty
              ? _buildEmptyState(
                  appStrings.noPostedJobsYetText, // Using AppStrings
                  Icons.post_add,
                  appStrings
                      .tapThePlusButtonToPostYourFirstJobText, // Using AppStrings
                  showActionButton: true,
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredJobs.length,
                  itemBuilder: (context, index) =>
                      AnimationConfiguration.staggeredList(
                        // Added animation
                        position: index,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: _buildJobCard(
                              filteredJobs[index],
                              showEditButton: true,
                            ),
                          ),
                        ),
                      ),
                ),
        ),
      ],
    );
  }

  Widget _buildApplicationsView() {
    final appStrings = AppLocalizations.of(context)!; // Corrected call
    final jobsWithApplications = _myJobs
        .where((job) => job.applications.isNotEmpty)
        .toList();
    final filteredJobs = _applyStatusFilter(jobsWithApplications);

    // --- MODIFICATION: Apply sorting ---
    filteredJobs.sort((a, b) {
      if (_currentSortOption == SortOption.byDate) {
        return b.createdAt.compareTo(a.createdAt); // Newest first
      } else {
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      }
    });

    return Column(
      children: [
        _buildFilterChips(
          false,
          appStrings.allText,
          appStrings.openText,
          appStrings.pendingText,
          appStrings.acceptedText,
          appStrings.closedText,
        ), // Using AppStrings
        const SizedBox(height: 16),
        Align(
          alignment: const Alignment(0.9, -1),
          child: Text(
            '${filteredJobs.length} ${appStrings.jobText}${filteredJobs.length == 1 ? '' : 's'}', // Using AppStrings
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ), // Using theme text
          ),
        ),
        Expanded(
          child: filteredJobs.isEmpty
              ? _buildEmptyState(
                  appStrings.noApplicationsYetText, // Using AppStrings
                  Icons.people_outline,
                  appStrings.applicationsText, // Using AppStrings
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredJobs.length,
                  itemBuilder: (context, index) =>
                      AnimationConfiguration.staggeredList(
                        // Added animation
                        position: index,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: _buildJobWithApplicationsCard(
                              filteredJobs[index],
                            ),
                          ),
                        ),
                      ),
                ),
        ),
      ],
    );
  }

  Widget _buildRequestedJobsView() {
    final appStrings = AppLocalizations.of(context)!; // Corrected call
    final filteredJobs = _applyStatusFilter(_requestedJobs);

    // --- MODIFICATION: Apply sorting ---
    filteredJobs.sort((a, b) {
      if (_currentSortOption == SortOption.byDate) {
        return b.createdAt.compareTo(a.createdAt); // Newest first
      } else {
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      }
    });

    return Column(
      children: [
        _buildFilterChips(
          false,
          appStrings.allText,
          appStrings.pendingText,
          appStrings.acceptedText,
          appStrings.completedText,
          appStrings.rejectedText,
        ), // Using AppStrings
        const SizedBox(height: 16),
        Align(
          alignment: const Alignment(0.9, -1),
          child: Text(
            '${filteredJobs.length} ${appStrings.jobText}${filteredJobs.length == 1 ? '' : 's'}', // Using AppStrings
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ), // Using theme text
          ),
        ),
        Expanded(
          child: filteredJobs.isEmpty
              ? _buildEmptyState(
                  appStrings.noJobRequestsText, // Using AppStrings
                  Icons.request_quote,
                  appStrings
                      .yourPersonalJobRequestsWillAppearHereText, // Using AppStrings
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredJobs.length,
                  itemBuilder: (context, index) =>
                      AnimationConfiguration.staggeredList(
                        // Added animation
                        position: index,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: _buildJobCard(
                              filteredJobs[index],
                              showEditButton: true,
                              showCancelButton: true,
                              showAcceptButton: true,
                              showCompleteButton: true,
                              showApplications: false,
                            ),
                          ),
                        ),
                      ),
                ),
        ),
      ],
    );
  }

  // UI Components
  Widget _buildFilterChips(
    bool isWorker,
    String all,
    String option1,
    String option2,
    String? option3,
    String? option4,
  ) {
    final ColorScheme colorScheme = Theme.of(
      context,
    ).colorScheme; // Use theme color
    final TextTheme textTheme = Theme.of(context).textTheme; // Use theme text

    final filters = isWorker
        ? [
            all,
            option1,
            option2,
            if (option3 != null) option3,
            if (option4 != null) option4,
          ]
        : [
            all,
            option1,
            option2,
            if (option3 != null) option3,
            if (option4 != null) option4,
          ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: colorScheme.surface, // Using theme color
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters
              .map(
                (filter) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: _selectedFilterIndex == filters.indexOf(filter),
                    selectedColor: colorScheme.primary.withOpacity(
                      0.2,
                    ), // Using theme color
                    labelStyle: textTheme.labelMedium?.copyWith(
                      // Using theme text
                      color: _selectedFilterIndex == filters.indexOf(filter)
                          ? colorScheme
                                .primary // Using theme color
                          : colorScheme.onSurfaceVariant, // Using theme color
                      fontWeight: FontWeight.w500,
                    ),
                    onSelected: (selected) => setState(
                      () => _selectedFilterIndex = selected
                          ? filters.indexOf(filter)
                          : 0,
                    ),
                    shape: RoundedRectangleBorder(
                      // Added rounded border from M3
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: _selectedFilterIndex == filters.indexOf(filter)
                            ? colorScheme
                                  .primary // Using theme color
                            : colorScheme.outlineVariant, // Using theme color
                        width: 1,
                      ),
                    ),
                    backgroundColor:
                        colorScheme.surfaceContainerLow, // Using theme color
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildJobCard(
    Job job, {
    bool showEditButton = false,
    bool showCancelButton = false,
    bool showAcceptButton = false,
    bool showCompleteButton = false,
    bool showStatus = false,
    bool showApplications = true,
    bool checkbutton = true,
    bool showActiveWorkActions = false,
  }) {
    final appStrings = AppLocalizations.of(context)!; // Corrected call
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final statusColor = _getStatusColor(job.status);

    final formattedDate = job.scheduledDate != null;
    print('this is the date formatt$formattedDate');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: colorScheme.surfaceContainerHigh, // Using theme color
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () => _navigateToJobDetail(job),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.title,
                          style: textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface,
                          ), // Using theme text & color
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${appStrings.postedText} ${_getTimeAgo(job.createdAt)}', // Using AppStrings
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ), // Using theme text & color
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor, width: 1),
                    ),
                    child: Text(
                      job.status.toUpperCase(),
                      style: textTheme.labelSmall?.copyWith(
                        // Using theme text
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Details Grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                children: [
                  _buildDetailItem(Icons.location_on, job.location),
                  _buildDetailItem(
                    Icons.calendar_today,
                    DateFormat('dd MMM yyyy').format(job.createdAt),
                  ),
                  _buildDetailItem(
                    Icons.attach_money,
                    '${job.budget.toStringAsFixed(0)} ETB',
                    color: Colors
                        .green, // Specific green for money, as in original
                  ),
                  if (showApplications)
                    _buildDetailItem(
                      Icons.person_outline,
                      job.applications.isEmpty
                          ? appStrings
                                .noApplicantsText // Using AppStrings
                          : '${job.applications.length} ${job.applications.length == 1 ? appStrings.applicantText : appStrings.applicantsText}', // Using AppStrings
                      color: colorScheme.secondary, // Using theme color
                    )
                  else if (job.status != 'completed')
                    _buildDetailItem(
                      Icons.person_outline,
                      job.applications.isEmpty
                          ? appStrings
                                .waitingForWorkerToAcceptText // Using AppStrings
                          : appStrings
                                .yourWorkingIsOnPendingText, // Using AppStrings
                    ),
                  if (job.status == 'completed' && !_isWorker)
                    _buildActionButton(
                      // Uses original _buildActionButton
                      appStrings.payText, // Using AppStrings
                      Icons.payment,
                      colorScheme.secondary, // Using theme color
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PaymentScreen(job: job),
                          ),
                        );
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // Progress Timeline
              _buildProgressTimeline(job.status),
              const SizedBox(height: 16),
              // Action Buttons - New logic for worker's "Start Work" button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(
                        Icons.remove_red_eye,
                        size: 18,
                        color: colorScheme.primary,
                      ), // Using theme color
                      label: Text(
                        appStrings.viewDetailsText,
                      ), // Using AppStrings
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            colorScheme.primary, // Using theme color
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(
                          color: colorScheme.primary,
                        ), // Using theme color
                      ),
                      onPressed: () => _navigateToJobDetail(job),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (_isWorker) ...[
                    // WORKER'S VIEW: Can chat only if the job is assigned or in progress.
                    if (job.clientId.isNotEmpty &&
                        ![
                          'open',
                          'pending',
                          'rejected',
                          'cancelled',
                        ].contains(job.status.toLowerCase()))
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12.0),
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.chat_bubble_outline, size: 18),
                            label: Text("Chat Client"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.tertiary,
                              foregroundColor: colorScheme.onTertiary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () => _navigateToChat(job.clientId),
                          ),
                        ),
                      ),
                  ] else ...[
                    // CLIENT'S VIEW: Can chat if a worker has been assigned.
                    if (job.workerId != null && job.workerId!.isNotEmpty)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12.0),
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.chat_bubble_outline, size: 18),
                            label: Text("Chat Worker"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.tertiary,
                              foregroundColor: colorScheme.onTertiary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () => _navigateToChat(job.workerId!),
                          ),
                        ),
                      ),
                  ],

                  // THIS IS THE NEW LOGIC:
                  // If the user is a worker and this job has been assigned to them,
                  // show a "Start Work" button. This takes priority over other button logic.
                  if (_isWorker &&
                      job.status.toLowerCase() == 'assigned' &&
                      job.workerId == _firebaseService.getCurrentUser()?.uid)
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(
                          Icons.play_circle_outline,
                          size: 18,
                          color: colorScheme.onSecondary,
                        ),
                        label: Text(appStrings.startButton),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              colorScheme.secondary, // Use a distinct color
                          foregroundColor: colorScheme.onSecondary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => _startWork(job),
                      ),
                    )
                  else if (_isWorker &&
                      job.status.toLowerCase() == 'started working' &&
                      job.workerId == _firebaseService.getCurrentUser()?.uid &&
                      showCompleteButton)
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(
                          Icons.check_circle_outline,
                          size: 18,
                          color: colorScheme.onSecondary,
                        ),
                        label: Text(appStrings.completeButton),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              colorScheme.secondary, // Use a distinct color
                          foregroundColor: colorScheme.onSecondary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => _completeJob(
                          job,
                          _firebaseService.getCurrentUser()!.uid,
                        ),
                      ),
                    )
                  else if (checkbutton)
                    if (_isWorker &&
                        (job.status == 'open' || job.status == 'pending'))
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(
                                  Icons.check,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  appStrings.acceptText,
                                ), // Using AppStrings
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      colorScheme.primary, // Using theme color
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                onPressed: () => _acceptJob(
                                  job,
                                  _firebaseService.getCurrentUser()!.uid,
                                ),
                              ),
                            ),
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  appStrings.declineText,
                                ), // Using AppStrings
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      colorScheme.error, // Using theme color
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                onPressed: () async {
                                  final currentUserId = _firebaseService
                                      .getCurrentUser()!
                                      .uid;
                                  await _firebaseService.declineJobApplication(
                                    job.clientId,
                                    job.id,
                                    currentUserId,
                                  );
                                  _showSuccessSnackbar(
                                    appStrings
                                        .applicationDeclinedSuccessfullyText,
                                  ); // Using AppStrings
                                  _loadJobs();
                                },
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (!_isWorker && job.status == 'assigned')
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: Icon(
                            Icons.edit,
                            size: 18,
                            color: colorScheme.onPrimary,
                          ), // Using theme color
                          label: Text(appStrings.rateText), // Using AppStrings
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                colorScheme.primary, // Using theme color
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () => _navigateToJobApplications(job),
                        ),
                      )
                    else if (!_isWorker &&
                        !job.status.contains('completed') &&
                        job.status != 'cancelled' &&
                        job.status != 'rejected')
                      Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.edit,
                              size: 18,
                              color: ColorScheme.dark().primaryContainer,
                            ), // Using theme color
                            onPressed: () => _navigateToJobApplications(job),
                          ),
                        ],
                      )
                    else if (!_isWorker && // Duplicated logic from original, preserving it
                        job.status.contains('completed') &&
                        job.status != 'cancelled' &&
                        job.status != 'rejected')
                      Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.edit,
                              size: 18,
                              color: ColorScheme.dark().primaryContainer,
                            ), // Using theme color
                            onPressed: () => _navigateToJobApplications(job),
                          ),
                        ],
                      )
                    else
                      const SizedBox.shrink() // Use shrink to take no space
                  else
                    const SizedBox.shrink(), // Use shrink to take no space
                ],
              ),
              // Card for active work actions - This was a separate Card in your original code
              if (showActiveWorkActions &&
                  job.status != 'completed') // Original condition
                Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(
                    top: 16,
                  ), // Added margin for spacing
                  color: colorScheme.surfaceContainerLow, // Using theme color
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            if (job.status == 'started working' && _isWorker)
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _startWork1(job), // Using AppStrings
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colorScheme
                                        .primary, // Using theme color
                                    foregroundColor: colorScheme
                                        .onPrimary, // Using theme color
                                  ),
                                  child: Text(
                                    appStrings.startButton,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _completeJob(
                                  job,
                                  _firebaseService.getCurrentUser()!.uid,
                                ), // Using AppStrings
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme
                                      .secondary, // Using theme color
                                  foregroundColor: colorScheme
                                      .onSecondary, // Using theme color
                                ),
                                child: Text(
                                  appStrings.completeButton,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  int _getTimelineIndex(String status) {
    switch (status.toLowerCase()) {
      case 'open':
      case 'pending':
      case 'rejected':
      case 'cancelled':
        return 0; // Initial stage: "Pending" - Keeping original values
      case 'accepted':
      case 'assigned':
      case 'in_progress':
      case 'started working':
        return 1; // Middle stage: "In Progress" - Keeping original values
      case 'completed':
      case 'closed':
      case 'paycompleted':
      case 'paid':
        return 2; // Final stage: "Completed" - Keeping original values
      default:
        return 0; // Keeping original value
    }
  }

  Widget _buildProgressTimeline(String status) {
    final ColorScheme colorScheme = Theme.of(
      context,
    ).colorScheme; // Using theme color
    final TextTheme textTheme = Theme.of(context).textTheme; // Using theme text
    final appStrings = AppLocalizations.of(context)!; // Corrected call

    final stages = [
      appStrings.timelinePending,
      appStrings.inProgressText,
      appStrings.completedText,
    ]; // Using AppStrings
    final currentIndex = _getTimelineIndex(status); // Use the helper method

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(stages.length, (index) {
            final isActive = index <= currentIndex;
            return Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isActive
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest, // Using theme color
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  isActive ? Icons.check : Icons.circle,
                  size: 14,
                  color: isActive
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant.withOpacity(
                          0.6,
                        ), // Using theme color
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(stages.length, (index) {
            final isActive = index <= currentIndex;
            return Text(
              stages[index],
              style: textTheme.labelSmall?.copyWith(
                // Using theme text
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant, // Using theme color
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildDetailItem(IconData icon, String text, {Color? color}) {
    final ColorScheme colorScheme = Theme.of(
      context,
    ).colorScheme; // Using theme color
    final TextTheme textTheme = Theme.of(context).textTheme; // Using theme text

    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: color ?? colorScheme.onSurfaceVariant,
        ), // Using theme color
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style: textTheme.bodyMedium?.copyWith(
              // Using theme text
              color: color ?? colorScheme.onSurface, // Using theme color
              fontWeight: color != null ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildJobWithApplicationsCard(Job job) {
    final appStrings = AppLocalizations.of(context)!; // Corrected call
    final ColorScheme colorScheme = Theme.of(
      context,
    ).colorScheme; // Using theme color
    final TextTheme textTheme = Theme.of(context).textTheme; // Using theme text

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4, // Increased elevation for consistency
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15), // Consistent border radius
      ),
      color: colorScheme.surfaceContainerHigh, // Using theme color
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Job Title and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    job.title,
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ), // Using theme text & color
                  ),
                ),
                Chip(
                  label: Text(
                    job.status.toUpperCase(),
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onPrimary,
                    ), // Using theme text & color
                  ),
                  backgroundColor: _getStatusColor(job.status),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Job Description
            Text(
              job.description,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ), // Using theme text & color
            ),
            const SizedBox(height: 12),
            // Location and Budget
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ), // Using theme color
                const SizedBox(width: 4),
                Text(
                  job.location,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ), // Using theme text & color
                ),
                const Spacer(),
                Icon(
                  Icons.attach_money,
                  size: 16,
                  color: Colors.green[700],
                ), // Keeping original color for money
                const SizedBox(width: 4),
                Text(
                  '${job.budget.toStringAsFixed(0)} ETB',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color:
                        Colors.green[700], // Keeping original color for money
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Posted Time
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ), // Using theme color
                const SizedBox(width: 4),
                Text(
                  '${appStrings.postedText} ${_getTimeAgo(job.createdAt)}', // Using AppStrings
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ), // Using theme text & color
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Applications Section Header
            Row(
              children: [
                Text(
                  appStrings.applicationsText.toUpperCase(), // Using AppStrings
                  style: textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurface,
                  ), // Using theme text & color
                ),
                const Spacer(),
                const SizedBox(width: 8),
                Chip(
                  label: Text(
                    job.applications.length.toString(),
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSecondary,
                    ), // Using theme text & color
                  ),
                  backgroundColor: colorScheme.secondary, // Using theme color
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _navigateToJobApplications(job),
                icon: Icon(
                  Icons.people_alt,
                  color: colorScheme.primary,
                ), // Using theme color
                label: Text(
                  appStrings.viewDetailsText,
                  style: TextStyle(color: colorScheme.primary),
                ), // Using AppStrings & theme color
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.primary, // Using theme color
                ),
              ),
            ),
            // Applications List or Empty State
            if (job.applications.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 48,
                      color: colorScheme.outlineVariant, // Using theme color
                    ),
                    const SizedBox(height: 8),
                    Text(
                      appStrings.noApplicationsYetText, // Using AppStrings
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ), // Using theme text & color
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  ...job.applications
                      .take(3)
                      .map(
                        (applicantId) => FutureBuilder<Worker?>(
                          future: _firebaseService.getWorkerById(applicantId),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            }
                            if (!snapshot.hasData) {
                              return ListTile(
                                leading: Icon(
                                  Icons.error,
                                  color: colorScheme.error,
                                ),
                                title: Text(
                                  appStrings.couldNotLoadApplicantText,
                                ),
                              );
                            }
                            final applicant = snapshot.data!;

                            // --- THIS IS THE CHANGE ---
                            // Replace the big Card(...) widget with a call to our new helper.
                            // We pass it the main `job` object so it knows the job's status.
                            return _buildApplicantPreviewCard(job, applicant);
                          },
                        ),
                      ),
                  if (job.applications.length > 3)
                    TextButton(
                      onPressed: () => _navigateToJobApplications(job),
                      child: Text(
                        '+ ${job.applications.length - 3} ${appStrings.moreApplicantsText}',
                        style: TextStyle(color: colorScheme.primary),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicantPreviewCard(Job job, Worker applicant) {
    final appStrings = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // --- State Determination ---
    final bool isThisApplicantTheAssignedWorker = job.workerId == applicant.id;
    final bool isJobOpenForApplications = [
      'open',
      'pending',
    ].contains(job.status.toLowerCase());
    final Color statusColor = _getStatusColor(job.status);

    // New State: Can the client change the worker from this preview?
    // Yes, if the job status is exactly 'assigned'.
    final bool canChangeWorker = job.status.toLowerCase() == 'assigned';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isThisApplicantTheAssignedWorker ? 4.0 : 1.0,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isThisApplicantTheAssignedWorker
              ? statusColor
              : Colors.transparent,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      color: colorScheme.surfaceContainerLow,
      child: Opacity(
        opacity: !isJobOpenForApplications && !isThisApplicantTheAssignedWorker
            ? 0.6
            : 1.0,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // --- Worker Info Section (No Changes) ---
              CircleAvatar(
                radius: 28,
                backgroundColor: colorScheme.surfaceContainerHighest,
                backgroundImage: NetworkImage(applicant.profileImage),
                child: null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      applicant.name,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      applicant.profession,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _navigateToChat(applicant.id),
                      icon: Icon(
                        Icons.chat_bubble_outline,
                        color: colorScheme.primary,
                      ),
                      label: Text(
                        appStrings.workerDetailChat,
                        style: TextStyle(color: colorScheme.primary),
                      ),
                    ),
                  ],
                ),
              ),

              // --- ACTION BUTTON LOGIC (WITH "CHANGE" FUNCTIONALITY) ---

              // STATE 1: Job is OPEN. Everyone gets an "Accept" (+) button.
              if (isJobOpenForApplications)
                ElevatedButton(
                  onPressed: () => _acceptApplication(
                    job,
                    applicant.id,
                    _firebaseService.getCurrentUser()!.uid,
                  ),
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(12),
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                  child: const Icon(Icons.add),
                )
              // STATE 2: Job is NOT OPEN.
              else
              // Sub-State 2a: This IS the assigned worker.
              if (isThisApplicantTheAssignedWorker)
                // If the job is COMPLETED, show the PAY button.
                if (job.status.toLowerCase() == 'completed')
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaymentScreen(job: job),
                      ),
                    ),
                    icon: const Icon(Icons.payment, size: 18),
                    label: Text(appStrings.payText),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.secondary,
                      foregroundColor: colorScheme.onSecondary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  )
                // If the job is ASSIGNED, show a status chip AND a "Change" button.
                else if (canChangeWorker)
                  Row(
                    children: [
                      Chip(
                        label: const Text(
                          "ASSIGNED",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                        backgroundColor: statusColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                      ),
                      const SizedBox(width: 4),
                      // The "Change" button opens the full applicant screen.
                      IconButton(
                        icon: Icon(
                          Icons.change_circle_outlined,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () => _navigateToJobApplications(job),
                        tooltip: "Change Worker",
                      ),
                    ],
                  )
                // Otherwise (started working), just show the status chip.
                else
                  Chip(
                    label: Text(
                      job.status.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                    backgroundColor: statusColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  )
              // Sub-State 2b: This is NOT the assigned worker. Show "FILLED".
              else
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    "FILLED",
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(String status) {
    // This method is used by _buildJobWithApplicationsCard internally,
    // but its own styling needs to be theme-adapted.
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 0.5),
      ),
      child: Text(
        status.toUpperCase(),
        style: textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionButton(
    // This method is used by _buildJobCard directly
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed, {
    bool small = false,
  }) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: small ? 16 : 18, color: color),
      label: Text(
        label,
        style: textTheme.labelLarge?.copyWith(
          // Using theme text
          color: color,
          fontSize: small ? 12 : 14,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        elevation: 0,
        padding: EdgeInsets.symmetric(
          horizontal: small ? 8 : 12,
          vertical: small ? 4 : 8,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildEmptyState(
    String title,
    IconData icon,
    String subtitle, {
    bool showActionButton = false,
  }) {
    final ColorScheme colorScheme = Theme.of(
      context,
    ).colorScheme; // Using theme color
    final TextTheme textTheme = Theme.of(context).textTheme; // Using theme text
    final appStrings = AppLocalizations.of(context)!; // Corrected call

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: colorScheme.outlineVariant, // Using theme color
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
              ), // Using theme text & color
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ), // Using theme text & color
              textAlign: TextAlign.center,
            ),
            if (showActionButton) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  '/post-job',
                ).then((_) => _loadUserData()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary, // Using theme color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  appStrings.postAJobText, // Using AppStrings
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.onPrimary, // Using theme color
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- MODIFICATION: Updated to include search functionality ---
  List<Job> _applyStatusFilter(List<Job> jobs) {
    // Apply search filter first
    List<Job> searchedJobs = _searchQuery.isEmpty
        ? jobs
        : jobs.where((job) {
            return job.title.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();

    if (_selectedFilterIndex == 0) return searchedJobs; // 'All' filter

    // Retaining original hardcoded filter strings for behavior consistency
    final filter = _tabController.index == 0
        ? [
            'all',
            'open',
            'pending',
            'accepted',
            'completed',
          ][_selectedFilterIndex]
        : _tabController.index == 1
        ? ['all', 'open', 'pending', 'accepted', 'closed'][_selectedFilterIndex]
        : [
            'all',
            'pending',
            'accepted',
            'completed',
            'rejected',
          ][_selectedFilterIndex];

    return searchedJobs
        .where((job) => job.status.toLowerCase() == filter)
        .toList();
  }

  Color _getStatusColor(String status) {
    // Retaining original hardcoded status colors
    switch (status.toLowerCase()) {
      case 'open':
        return const Color.fromARGB(221, 6, 30, 244);
      case 'pending':
        return const Color.fromARGB(219, 2, 254, 31);
      case 'assigned':
        return const Color.fromARGB(255, 7, 43, 7);
      case 'active': // Not explicitly used in the filtering logic, but defined here
        return const Color(0xFFffc107);
      case 'in_progress':
      case 'started working':
        return const Color(0xFFff9800);
      case 'completed':
        return const Color(0xFF4caf50);
      case 'cancelled':
        return const Color(0xFFff5252);
      case 'rejected':
        return const Color(0xFFe53935);
      default:
        return Colors.grey;
    }
  }

  String _getTimeAgo(DateTime date) {
    final appStrings = AppLocalizations.of(context)!; // Corrected call
    return appStrings.formatTimeAgo(date); // Using AppStrings formatting
  }
}

class JobApplicationsScreen extends StatefulWidget {
  final Job job;
  final String clientId; // Guaranteed to be non-empty

  const JobApplicationsScreen({
    super.key,
    required this.job,
    required this.clientId, // Receives the guaranteed ID
  });

  @override
  _JobApplicationsScreenState createState() => _JobApplicationsScreenState();
}

class _JobApplicationsScreenState extends State<JobApplicationsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = true;
  List<Worker> _applicants = [];
  late Job _currentJob;

  @override
  void initState() {
    super.initState();
    _currentJob = widget.job;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final refreshedJob = await _firebaseService.getJobById(widget.job.id);
      if (!mounted) return;
      setState(() {
        _currentJob = refreshedJob ?? _currentJob;
      });

      final applicantIds = _currentJob.applications;
      if (applicantIds.isEmpty) {
        if (mounted) setState(() => _applicants = []);
        return;
      }
      final fetchedApplicants = <Worker>[];
      for (String id in applicantIds) {
        final worker = await _firebaseService.getWorkerById(id);
        if (worker != null) fetchedApplicants.add(worker);
      }
      if (mounted) setState(() => _applicants = fetchedApplicants);
    } catch (e) {
      _showErrorSnackbar('Failed to load applicant data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  // --- SAFE & ROBUST ACTION HANDLERS ---
  Future<void> _acceptApplicant(String workerId) async {
    setState(() => _isLoading = true);
    try {
      await _firebaseService.acceptJobApplication(
        _currentJob.id,
        workerId,
        widget.clientId,
      );
      await _loadData();
    } catch (e) {
      _showErrorSnackbar("Acceptance Failed: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleChangeWorker() async {
    final workerId = _currentJob.workerId;
    if (workerId == null || workerId.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await _firebaseService.changeAssignedWorker(
        jobId: _currentJob.id,
        clientId: widget.clientId,
        currentlyAssignedWorkerId: workerId,
      );
      await _loadData();
    } catch (e) {
      _showErrorSnackbar("Operation Failed: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showChangeWorkerConfirmationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Assigned Worker?'),
        content: const Text(
          'This will un-assign the current worker and make the job available again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _handleChangeWorker();
            },
            child: const Text(
              'Confirm Change',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _declineApplicant(String workerId) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    await _firebaseService.declineJobApplication(
      _currentJob.id,
      workerId,
      widget.clientId,
    );
    await _loadData();
  }

  void _navigateToWorkerDetail(Worker worker) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkerDetailScreen(worker: worker),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Applicants'),
            Text(
              _currentJob.title,
              style: Theme.of(context).textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _applicants.isEmpty
          ? _buildEmptyState()
          : _buildApplicantList(),
    );
  }

  Widget _buildApplicantList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _applicants.length,
      itemBuilder: (context, index) => _buildApplicantCard(_applicants[index]),
    );
  }

  bool _isValidUrl(String? url) =>
      (url != null && Uri.tryParse(url)?.isAbsolute == true);

  Widget _buildApplicantCard(Worker applicant) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isJobAssigned = _currentJob.status.toLowerCase() == 'assigned';
    final isThisApplicantAssigned =
        isJobAssigned && _currentJob.workerId == applicant.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isThisApplicantAssigned ? 8.0 : 2.0,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isThisApplicantAssigned
              ? colorScheme.primary
              : colorScheme.outline.withOpacity(0.2),
          width: isThisApplicantAssigned ? 2.0 : 1.0,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _navigateToWorkerDetail(applicant),
        child: Opacity(
          opacity: isJobAssigned && !isThisApplicantAssigned ? 0.55 : 1.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Hero(
                        tag: 'applicant-avatar-${applicant.id}',
                        child: CircleAvatar(
                          radius: 32,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          backgroundImage: _isValidUrl(applicant.profileImage)
                              ? NetworkImage(applicant.profileImage)
                              : null,
                          child: !_isValidUrl(applicant.profileImage)
                              ? const Icon(Icons.person, size: 32)
                              : null,
                        ),
                      ),
                      title: Text(
                        applicant.name,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        applicant.profession,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem(
                          Icons.star_border,
                          '${applicant.rating.toStringAsFixed(1)} Rating',
                        ),
                        _buildStatItem(
                          Icons.check_circle_outline,
                          '${applicant.completedJobs} Jobs',
                        ),
                        _buildStatItem(
                          Icons.location_on_outlined,
                          applicant.location,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (applicant.skills.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Skills", style: textTheme.labelLarge),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 4.0,
                            children: applicant.skills
                                .map((skill) => Chip(label: Text(skill)))
                                .toList(),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              _buildActionPanel(applicant),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionPanel(Worker applicant) {
    final appStrings = AppLocalizations.of(context)!;
    final isJobAssigned = _currentJob.status.toLowerCase() == 'assigned';
    final isThisApplicantAssigned =
        isJobAssigned && _currentJob.workerId == applicant.id;
    final canChangeWorker =
        isJobAssigned &&
        ![
          'in_progress',
          'started working',
          'completed',
        ].contains(_currentJob.status.toLowerCase());
    final isJobInProgressOrHigher = [
      'in_progress',
      'started working',
      'completed',
    ].contains(_currentJob.status);
    final isassigned = ['assigned'].contains(_currentJob.status);

    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Builder(
        builder: (context) {
          if (isThisApplicantAssigned) {
            return Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'ASSIGNED',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (canChangeWorker)
                  TextButton(
                    onPressed: _showChangeWorkerConfirmationDialog,
                    child: const Text('Change'),
                  ),
              ],
            );
          }

          if (isJobAssigned) {
            return Center(
              child: Text(
                "Position filled",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }
          if (isJobInProgressOrHigher) {
            return Center(
              child: Text(
                _currentJob.workerId == applicant.id
                    ? "WORK IN PROGRESS"
                    : "Position Filled",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: _currentJob.workerId == applicant.id
                      ? Theme.of(context).colorScheme.secondary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          if (!isassigned) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => _declineApplicant(applicant.id),
                  child: Text(appStrings.declineText),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _acceptApplicant(applicant.id),
                  child: Text(appStrings.acceptText),
                ),
              ],
            );
          }
          return Center(
            child: Text(
              _currentJob.workerId == applicant.id
                  ? "WORK IN PROGRESS"
                  : "Position Filled",
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: _currentJob.workerId == applicant.id
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(text, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_search_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Waiting for Applicants',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Professionals who apply to this job will appear here.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
