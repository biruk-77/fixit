import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart'; // For shimmer effect
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart'; // For staggered animations

import '../../models/job.dart';
import '../../models/worker.dart';
import '../../services/firebase_service.dart';
import 'job_detail_screen.dart'; // Ensure this exists and is correct
import '../../models/user.dart'; // Ensure this AppUser model exists
import '../payment/payment_screen.dart'; // Ensure this exists and is correct
import '../chat_screen.dart'; // Ensure this exists and is correct
import '../../services/app_string.dart'; // Import your AppStrings (which contains AppLocalizations)

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
            appStrings.errorLoadingData(e.toString())); // Using AppStrings
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
        final worksForMeJobs =
            await _firebaseService.getWorkerAssignedJobs(userId);

        // If empty, fall back to assigned jobs with 'accepted' or 'in_progress' status
        final effectiveWorksForMe = worksForMeJobs.isNotEmpty
            ? worksForMeJobs
            : assignedJobs
                .where((job) => [
                      'accepted',
                      'in_progress',
                      'assigned',
                      'cancelled',
                      'completed',
                      'rejected',
                      'started working'
                    ].contains(job.status.toLowerCase()))
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
          appStrings.errorLoadingJobs(e.toString())); // Using AppStrings
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
          appStrings.jobCancelledSuccessfullyText); // Using AppStrings
      await _loadUserData();
    } catch (e) {
      _showErrorSnackbar(
          appStrings.errorCancellingJob(e.toString())); // Using AppStrings
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
          appStrings.applicationAcceptedSuccessfullyText); // Using AppStrings
      await _loadJobs();
    } catch (e) {
      _showErrorSnackbar(appStrings
          .errorAcceptingApplication(e.toString())); // Using AppStrings
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
      await _firebaseService.updateJobStatus(
          job.id, userID, job.clientId, 'accepted');

      await _loadJobs();
      _showSuccessSnackbar(
          appStrings.jobAcceptedSuccessfullyText); // Using AppStrings

      // Original logic for navigating to 'ACTIVE WORK' tab
      if (_isWorker) {
        _tabController.animateTo(2); // Navigate to 'ACTIVE WORK' tab (index 2)
      }
    } catch (e) {
      _showErrorSnackbar(
          appStrings.errorAcceptingJob(e.toString())); // Using AppStrings
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
      await _firebaseService.updateJobStatus(
        job.id,
        workerID,
        job.clientId,
        'completed',
      );
      _showSuccessSnackbar(
          appStrings.jobMarkedAsCompletedSuccessfullyText); // Using AppStrings
      await _loadJobs();
    } catch (e) {
      _showErrorSnackbar(
          appStrings.errorCompletingJob(e.toString())); // Using AppStrings
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startWork(Job job) async {
    // Ensure context is available before using AppLocalizations.of
    if (!mounted) return;
    final appStrings = AppLocalizations.of(context)!; // Corrected call
    try {
      setState(() => _isLoading = true);
      await _firebaseService.updateJobStatus(
        job.id,
        job.seekerId, // Original used job.seekerId, not current user ID
        job.clientId,
        'started working',
      );
      _showSuccessSnackbar(
          appStrings.workStartedSuccessfullyText); // Using AppStrings
      await _loadJobs();
    } catch (e) {
      _showErrorSnackbar(
          appStrings.errorStartingWork(e.toString())); // Using AppStrings
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // UI Helper Methods
  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(
                color: Colors.white)), // Original hardcoded white text
        backgroundColor:
            Theme.of(context).colorScheme.primary, // Using theme color
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(
                color: Colors.white)), // Original hardcoded white text
        backgroundColor:
            Theme.of(context).colorScheme.error, // Using theme color
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
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
    Navigator.pushNamed(context, '/post-job', arguments: job)
        .then((_) => _loadUserData());
  }

  void _navigateToJobApplications(Job job) {
    // Original JobApplicationsScreen does not take preFetchedApplicants
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JobApplicationsScreen(job: job),
      ),
    ).then((_) => _loadUserData());
  }

  void _navigateToChat(Job job, String workerID, String currentUsedID) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          otherUserId: workerID,
          currentUserId: currentUsedID,
          jobId: job.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appStrings = AppLocalizations.of(context)!; // Corrected call
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.background, // Using theme color
      appBar: AppBar(
        title: Text(
          _isWorker
              ? appStrings.myWorkDashboardText
              : appStrings.myJobsDashboardText, // Using AppStrings
          style: textTheme.titleLarge?.copyWith(
              color: colorScheme.onPrimary), // Using theme text & color
        ),
        backgroundColor: colorScheme.primary, // AppBar background from theme
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colorScheme.secondary, // Accent color from theme
          labelColor: colorScheme.onPrimary, // White from theme
          unselectedLabelColor:
              colorScheme.onPrimary.withOpacity(0.7), // White70 from theme
          labelStyle: textTheme.labelLarge
              ?.copyWith(fontWeight: FontWeight.bold), // Using theme text
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
                    colorScheme.primary), // Using theme color
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
              onPressed: () => Navigator.pushNamed(context, '/post-job')
                  .then((_) => _loadUserData()),
              backgroundColor: colorScheme.secondary, // Accent color from theme
              child: Icon(Icons.add,
                  size: 28,
                  color: colorScheme.onSecondary), // Icon color from theme
              elevation: 4,
            )
          : null,
    );
  }

  Widget _buildAssignedJobsView() {
    final appStrings = AppLocalizations.of(context)!; // Corrected call
    final filteredJobs = _applyStatusFilter(_myJobs);

    return Column(
      children: [
        _buildFilterChips(
            true,
            appStrings.allText,
            appStrings.openText,
            appStrings.pendingText,
            appStrings.acceptedText,
            appStrings.completedText), // Using AppStrings
        const SizedBox(height: 16),
        Align(
          alignment: const Alignment(0.9, -1),
          child: Text(
            '${filteredJobs.length} ${appStrings.assignedJobText}${filteredJobs.length == 1 ? '' : 's'}', // Using AppStrings
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontWeight: FontWeight.bold), // Using theme text
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

    return Column(
      children: [
        _buildFilterChips(
            true,
            appStrings.allText,
            appStrings.openText,
            appStrings.pendingText,
            appStrings.acceptedText,
            appStrings.closedText), // Using AppStrings
        const SizedBox(height: 16),
        Align(
          alignment: const Alignment(0.9, -1),
          child: Text(
            '${filteredJobs.length} ${appStrings.jobText}${filteredJobs.length == 1 ? '' : 's'}', // Using AppStrings
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontWeight: FontWeight.bold), // Using theme text
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
                          checkbutton: false,
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
    List<Job> filteredJobs = _assignedJobs.where((job) {
      return [
        'accepted',
        'in_progress',
        'completed',
        'assigned',
        'cancelled',
        'rejected',
        'started working'
      ].contains(job.status.toLowerCase());
    }).toList();

    // Apply additional filter if selected
    if (_selectedFilterIndex > 0) {
      final filter = [
        'all',
        'accepted',
        'in_working', // Original typo, retaining it
        'completed',
        'cancelled'
      ][_selectedFilterIndex];

      filteredJobs = filteredJobs
          .where((job) => job.status.toLowerCase() == filter)
          .toList();
    }

    return Column(
      children: [
        _buildFilterChips(
            true,
            appStrings.allText,
            appStrings.acceptedText,
            appStrings.inProgressText,
            appStrings.completedText,
            appStrings.cancelledText), // Using AppStrings
        const SizedBox(height: 16),
        Align(
          alignment: const Alignment(0.9, -1),
          child: Text(
            '${filteredJobs.length} ${appStrings.activeJobText}${filteredJobs.length == 1 ? '' : 's'}', // Using AppStrings
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontWeight: FontWeight.bold), // Using theme text
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
                          showApplications: false,
                          // Add any other relevant parameters
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterChips(
            false,
            appStrings.allText,
            appStrings.openText,
            appStrings.pendingText,
            appStrings.acceptedText,
            appStrings.completedText), // Using AppStrings
        const SizedBox(height: 16),
        Align(
          alignment: const Alignment(0.9, -1),
          child: Text(
            '${filteredJobs.length} ${appStrings.jobText}${filteredJobs.length == 1 ? '' : 's'}', // Using AppStrings
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontWeight: FontWeight.bold), // Using theme text
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
        .where((job) => job.applications != null && job.applications.isNotEmpty)
        .toList();
    final filteredJobs = _applyStatusFilter(jobsWithApplications);

    return Column(
      children: [
        _buildFilterChips(
            false,
            appStrings.allText,
            appStrings.openText,
            appStrings.pendingText,
            appStrings.acceptedText,
            appStrings.closedText), // Using AppStrings
        const SizedBox(height: 16),
        Align(
          alignment: const Alignment(0.9, -1),
          child: Text(
            '${filteredJobs.length} ${appStrings.jobText}${filteredJobs.length == 1 ? '' : 's'}', // Using AppStrings
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontWeight: FontWeight.bold), // Using theme text
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

    return Column(
      children: [
        _buildFilterChips(
            false,
            appStrings.allText,
            appStrings.pendingText,
            appStrings.acceptedText,
            appStrings.completedText,
            appStrings.rejectedText), // Using AppStrings
        const SizedBox(height: 16),
        Align(
          alignment: const Alignment(0.9, -1),
          child: Text(
            '${filteredJobs.length} ${appStrings.jobText}${filteredJobs.length == 1 ? '' : 's'}', // Using AppStrings
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontWeight: FontWeight.bold), // Using theme text
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
  Widget _buildFilterChips(bool isWorker, String all, String option1,
      String option2, String? option3, String? option4) {
    final ColorScheme colorScheme =
        Theme.of(context).colorScheme; // Use theme color
    final TextTheme textTheme = Theme.of(context).textTheme; // Use theme text

    final filters = isWorker
        ? [
            all,
            option1,
            option2,
            if (option3 != null) option3,
            if (option4 != null) option4
          ]
        : [
            all,
            option1,
            option2,
            if (option3 != null) option3,
            if (option4 != null) option4
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
                    selectedColor: colorScheme.primary
                        .withOpacity(0.2), // Using theme color
                    labelStyle: textTheme.labelMedium?.copyWith(
                      // Using theme text
                      color: _selectedFilterIndex == filters.indexOf(filter)
                          ? colorScheme.primary // Using theme color
                          : colorScheme.onSurfaceVariant, // Using theme color
                      fontWeight: FontWeight.w500,
                    ),
                    onSelected: (selected) => setState(
                      () => _selectedFilterIndex =
                          selected ? filters.indexOf(filter) : 0,
                    ),
                    shape: RoundedRectangleBorder(
                      // Added rounded border from M3
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: _selectedFilterIndex == filters.indexOf(filter)
                            ? colorScheme.primary // Using theme color
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
    final formattedDate =
        job.scheduledDate != null; // Original variable, not directly used now
    print('this is the date formatt$formattedDate');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
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
                              color: colorScheme
                                  .onSurface), // Using theme text & color
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${appStrings.postedText} ${_getTimeAgo(job.createdAt)}', // Using AppStrings
                          style: textTheme.bodySmall?.copyWith(
                              color: colorScheme
                                  .onSurfaceVariant), // Using theme text & color
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                  _buildDetailItem(Icons.calendar_today,
                      '${DateFormat('dd MMM yyyy').format(job.createdAt)}'),
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
                          ? appStrings.noApplicantsText // Using AppStrings
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
                              builder: (context) => PaymentScreen(
                                job: job,
                              ),
                            ));
                      },
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Progress Timeline
              _buildProgressTimeline(job.status),

              const SizedBox(height: 16),

              // Action Buttons - Replicating original logic exactly, with new styling
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(Icons.remove_red_eye,
                          size: 18,
                          color: colorScheme.primary), // Using theme color
                      label:
                          Text(appStrings.viewDetailsText), // Using AppStrings
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            colorScheme.primary, // Using theme color
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(
                            color: colorScheme.primary), // Using theme color
                      ),
                      onPressed: () => _navigateToJobDetail(job),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (checkbutton) // Original `checkbutton` condition
                    if (_isWorker &&
                        (job.status == 'open' || job.status == 'pending'))
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.check,
                                    size: 18, color: Colors.white),
                                label: Text(
                                    appStrings.acceptText), // Using AppStrings
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      colorScheme.primary, // Using theme color
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                                onPressed: () => _acceptJob(job,
                                    _firebaseService.getCurrentUser()!.uid),
                              ),
                            ),
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.close,
                                    size: 16, color: Colors.white),
                                label: Text(
                                    appStrings.declineText), // Using AppStrings
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      colorScheme.error, // Using theme color
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                                onPressed: () async {
                                  final currentUserId =
                                      _firebaseService.getCurrentUser()!.uid;
                                  await _firebaseService.declineJobApplication(
                                      job.clientId, job.id, currentUserId);
                                  _showSuccessSnackbar(appStrings
                                      .applicationDeclinedSuccessfullyText); // Using AppStrings
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
                          icon: Icon(Icons.edit,
                              size: 18,
                              color:
                                  colorScheme.onPrimary), // Using theme color
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
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.edit,
                              size: 18,
                              color:
                                  colorScheme.onPrimary), // Using theme color
                          label:
                              Text(appStrings.manageText), // Using AppStrings
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                colorScheme.primary, // Using theme color
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () => _navigateToJobApplications(job),
                        ),
                      )
                    else if (!_isWorker && // Duplicated logic from original, preserving it
                        job.status.contains('completed') &&
                        job.status != 'cancelled' &&
                        job.status != 'rejected')
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.edit,
                              size: 18,
                              color:
                                  colorScheme.onPrimary), // Using theme color
                          label:
                              Text(appStrings.manageText), // Using AppStrings
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                colorScheme.primary, // Using theme color
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () => _navigateToJobApplications(job),
                        ),
                      )
                    else if (_isWorker &&
                        job.status == 'assigned' &&
                        job.status != 'completed' &&
                        job.status != 'cancelled' &&
                        job.status != 'rejected' &&
                        job.status != 'in_progress' &&
                        job.status == 'open')
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.edit,
                              size: 18,
                              color:
                                  colorScheme.onPrimary), // Using theme color
                          label:
                              Text(appStrings.startButton), // Using AppStrings
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                colorScheme.primary, // Using theme color
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () =>
                              () {}, //_startWork(job) - Keeping original comment and empty lambda
                        ),
                      )
                    else
                      SizedBox()
                ],
              ),
              // Card for active work actions - This was a separate Card in your original code
              if (showActiveWorkActions &&
                  job.status != 'completed') // Original condition
                Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(
                      top: 16), // Added margin for spacing
                  color: colorScheme.surfaceContainerLow, // Using theme color
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            if (job.status == 'started working' &&
                                _isWorker &&
                                job.status != 'completed')
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _startWork(job),
                                  child: Text(appStrings
                                      .startButton), // Using AppStrings
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colorScheme
                                        .primary, // Using theme color
                                    foregroundColor: colorScheme
                                        .onPrimary, // Using theme color
                                  ),
                                ),
                              ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _completeJob(job,
                                    _firebaseService.getCurrentUser()!.uid),
                                child: Text(appStrings
                                    .completeButton), // Using AppStrings
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme
                                      .secondary, // Using theme color
                                  foregroundColor: colorScheme
                                      .onSecondary, // Using theme color
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                )
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
    final ColorScheme colorScheme =
        Theme.of(context).colorScheme; // Using theme color
    final TextTheme textTheme = Theme.of(context).textTheme; // Using theme text
    final appStrings = AppLocalizations.of(context)!; // Corrected call

    final stages = [
      appStrings.timelinePending,
      appStrings.inProgressText,
      appStrings.completedText
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
                    : colorScheme.surfaceVariant, // Using theme color
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  isActive ? Icons.check : Icons.circle,
                  size: 14,
                  color: isActive
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant
                          .withOpacity(0.6), // Using theme color
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
    final ColorScheme colorScheme =
        Theme.of(context).colorScheme; // Using theme color
    final TextTheme textTheme = Theme.of(context).textTheme; // Using theme text

    return Row(
      children: [
        Icon(icon,
            size: 20,
            color: color ?? colorScheme.onSurfaceVariant), // Using theme color
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
    final ColorScheme colorScheme =
        Theme.of(context).colorScheme; // Using theme color
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
                        color:
                            colorScheme.onSurface), // Using theme text & color
                  ),
                ),
                Chip(
                  label: Text(
                    job.status.toUpperCase(),
                    style: textTheme.labelSmall?.copyWith(
                        color:
                            colorScheme.onPrimary), // Using theme text & color
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
                  color:
                      colorScheme.onSurfaceVariant), // Using theme text & color
            ),

            const SizedBox(height: 12),

            // Location and Budget
            Row(
              children: [
                Icon(Icons.location_on,
                    size: 16,
                    color: colorScheme.onSurfaceVariant), // Using theme color
                const SizedBox(width: 4),
                Text(
                  job.location,
                  style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme
                          .onSurfaceVariant), // Using theme text & color
                ),
                const Spacer(),
                Icon(Icons.attach_money,
                    size: 16,
                    color:
                        Colors.green[700]), // Keeping original color for money
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
                Icon(Icons.access_time,
                    size: 16,
                    color: colorScheme.onSurfaceVariant), // Using theme color
                const SizedBox(width: 4),
                Text(
                  '${appStrings.postedText} ${_getTimeAgo(job.createdAt)}', // Using AppStrings
                  style: textTheme.bodySmall?.copyWith(
                      color: colorScheme
                          .onSurfaceVariant), // Using theme text & color
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
                      color: colorScheme.onSurface), // Using theme text & color
                ),
                const Spacer(),
                const SizedBox(width: 8),
                Chip(
                  label: Text(
                    job.applications.length.toString(),
                    style: textTheme.labelSmall?.copyWith(
                        color: colorScheme
                            .onSecondary), // Using theme text & color
                  ),
                  backgroundColor: colorScheme.secondary, // Using theme color
                ),
              ],
            ),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _navigateToJobApplications(job),
                icon: Icon(Icons.people_alt,
                    color: colorScheme.primary), // Using theme color
                label: Text(appStrings.viewDetailsText,
                    style: TextStyle(
                        color: colorScheme
                            .primary)), // Using AppStrings & theme color
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
                          color: colorScheme
                              .onSurfaceVariant), // Using theme text & color
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  ...job.applications.take(3).map((applicantId) =>
                      FutureBuilder<Worker?>(
                        // Retaining original FutureBuilder
                        future: _firebaseService.getWorkerById(applicantId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return ListTile(
                              // Using themed ListTile
                              leading: CircleAvatar(
                                child: CircularProgressIndicator(
                                    color: colorScheme
                                        .primary), // Themed indicator
                              ),
                              title: Text(appStrings.loadingText,
                                  style: textTheme
                                      .bodyMedium), // Using AppStrings & theme text
                            );
                          }

                          if (!snapshot.hasData) {
                            return ListTile(
                              // Using themed ListTile
                              leading: Icon(Icons.error,
                                  color: colorScheme.error), // Themed icon
                              title: Text(appStrings.couldNotLoadApplicantText,
                                  style: textTheme
                                      .bodyMedium), // Using AppStrings & theme text
                            );
                          }

                          final applicant = snapshot.data!;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            color: colorScheme
                                .surfaceContainerLow, // Using theme color
                            child: Padding(
                              padding: const EdgeInsets.all(
                                  12), // Slightly increased padding
                              child: Row(
                                children: [
                                  // Profile Picture
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: colorScheme
                                        .surfaceVariant, // Themed background
                                    backgroundImage: applicant.profileImage !=
                                            null
                                        ? NetworkImage(applicant.profileImage!)
                                        : null,
                                    child: applicant.profileImage == null
                                        ? Icon(Icons.person,
                                            size: 24,
                                            color: colorScheme
                                                .onSurfaceVariant) // Themed icon
                                        : null,
                                  ),
                                  const SizedBox(width: 12),

                                  // Applicant Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Name and Rating
                                        Row(
                                          children: [
                                            Text(
                                              applicant.name,
                                              style: textTheme.titleSmall?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: colorScheme
                                                      .onSurface), // Themed text
                                            ),
                                            const SizedBox(width: 8),
                                            Row(
                                              children: [
                                                Icon(Icons.star,
                                                    size: 16,
                                                    color: Colors
                                                        .amber), // Original color
                                                const SizedBox(width: 2),
                                                Text(
                                                  applicant.rating == null
                                                      ? '0.0'
                                                      : applicant.rating
                                                          .toStringAsFixed(1),
                                                  style: textTheme.bodySmall
                                                      ?.copyWith(
                                                          color: colorScheme
                                                              .onSurfaceVariant), // Themed text
                                                ),
                                                const SizedBox(
                                                    width:
                                                        12), // Original SizedBox
                                                Text(
                                                  '${applicant.completedJobs} ${appStrings.jobsText}', // Using AppStrings
                                                  style: textTheme.bodySmall
                                                      ?.copyWith(
                                                          color: colorScheme
                                                              .onSurfaceVariant), // Themed text
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),

                                        // Profession
                                        Text(
                                          applicant.profession,
                                          style: textTheme.bodySmall?.copyWith(
                                              color: colorScheme
                                                  .onSurfaceVariant), // Themed text
                                        ),

                                        const SizedBox(height: 4),

                                        // Location and Completed Jobs
                                        Row(
                                          children: [
                                            Icon(Icons.location_on,
                                                size: 14,
                                                color: colorScheme
                                                    .onSurfaceVariant), // Themed icon
                                            const SizedBox(width: 4),
                                            Text(
                                              applicant.location,
                                              style: textTheme.bodySmall?.copyWith(
                                                  color: colorScheme
                                                      .onSurfaceVariant), // Themed text
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.message,
                                                  color: colorScheme
                                                      .onSurface), // Themed icon
                                              onPressed: () {
                                                _navigateToChat(
                                                  job,
                                                  applicantId,
                                                  _firebaseService
                                                      .getCurrentUser()!
                                                      .uid,
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Action Button
                                  Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () => _acceptApplication(
                                          job,
                                          applicantId,
                                          _firebaseService
                                              .getCurrentUser()!
                                              .uid,
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 8),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          backgroundColor: colorScheme
                                              .primary, // Themed background
                                          foregroundColor: colorScheme
                                              .onPrimary, // Themed foreground
                                        ),
                                        child: Text(
                                          appStrings
                                              .acceptText, // Using AppStrings
                                          style: textTheme
                                              .labelLarge, // Themed text
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      )),
                  if (job.applications.length > 3)
                    TextButton(
                      onPressed: () => _navigateToJobApplications(job),
                      child: Text(
                        '+ ${job.applications.length - 3} ${appStrings.moreApplicantsText}', // Using AppStrings
                        style: TextStyle(
                            color: colorScheme.primary), // Themed color
                      ),
                    ),
                ],
              ),
          ],
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    String title,
    IconData icon,
    String subtitle, {
    bool showActionButton = false,
  }) {
    final ColorScheme colorScheme =
        Theme.of(context).colorScheme; // Using theme color
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
                  color: colorScheme.onBackground), // Using theme text & color
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: textTheme.bodyMedium?.copyWith(
                  color:
                      colorScheme.onSurfaceVariant), // Using theme text & color
              textAlign: TextAlign.center,
            ),
            if (showActionButton) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/post-job')
                    .then((_) => _loadUserData()),
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

  List<Job> _applyStatusFilter(List<Job> jobs) {
    if (_selectedFilterIndex == 0) return jobs; // 'All' filter

    // Retaining original hardcoded filter strings for behavior consistency
    final filter = _tabController.index == 0
        ? [
            'all',
            'open',
            'pending',
            'accepted',
            'completed'
          ][_selectedFilterIndex]
        : _tabController.index == 1
            ? [
                'all',
                'open',
                'pending',
                'accepted',
                'closed'
              ][_selectedFilterIndex]
            : [
                'all',
                'pending',
                'accepted',
                'completed',
                'rejected'
              ][_selectedFilterIndex];

    return jobs.where((job) => job.status.toLowerCase() == filter).toList();
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

// Separate JobApplicationsScreen widget
class JobApplicationsScreen extends StatefulWidget {
  final Job job;
  // Removed preFetchedApplicants as per first code's behavior for this screen
  // final Map<String, Worker> preFetchedApplicants;

  const JobApplicationsScreen({
    Key? key,
    required this.job,
    // this.preFetchedApplicants = const {}, // Initialize as empty map if not passed
  }) : super(key: key);

  @override
  _JobApplicationsScreenState createState() => _JobApplicationsScreenState();
}

class _JobApplicationsScreenState extends State<JobApplicationsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = true;
  List<Worker> _applicants = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadApplicants();
    });
  }

  Future<void> _loadApplicants() async {
    // Ensure context is available before using AppLocalizations.of
    if (!mounted) return;
    final appStrings = AppLocalizations.of(context)!; // Corrected call
    try {
      setState(() => _isLoading = true);

      // Get the list of applicant IDs from the job
      final applicantIds = widget.job.applications;

      if (applicantIds.isEmpty) {
        setState(() {
          _isLoading = false;
          _applicants = [];
        });
        return;
      }

      // Fetch each applicant's details from the professionals collection (original behavior)
      final List<Worker> applicants = [];
      for (String applicantId in applicantIds) {
        final worker = await _firebaseService.getWorkerById(applicantId);
        if (worker != null) {
          applicants.add(worker);
        }
      }

      if (mounted) {
        setState(() {
          _applicants = applicants;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                appStrings.applicantLoadError + ': $e', // Using AppStrings
                style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onError)), // Using theme color
            backgroundColor:
                Theme.of(context).colorScheme.error, // Using theme color
          ),
        );
      }
    }
  }

  Future<void> _acceptApplicant(String workerId) async {
    // Ensure context is available before using AppLocalizations.of
    if (!mounted) return;
    final appStrings = AppLocalizations.of(context)!; // Corrected call
    try {
      setState(() => _isLoading = true);
      await _firebaseService.acceptJobApplication(
          widget.job.id, workerId, widget.job.clientId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                appStrings
                    .applicationAcceptedSuccessfullyText, // Using AppStrings
                style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onPrimary)), // Using theme color
            backgroundColor:
                Theme.of(context).colorScheme.primary, // Using theme color
          ),
        );
        Navigator.of(context).pop(true); // Return success
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                appStrings.errorAcceptingApplication(
                    e.toString()), // Using AppStrings
                style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onError)), // Using theme color
            backgroundColor:
                Theme.of(context).colorScheme.error, // Using theme color
          ),
        );
      }
    }
  }

  Future<void> _declineApplicant(String workerId) async {
    // Ensure context is available before using AppLocalizations.of
    if (!mounted) return;
    final appStrings = AppLocalizations.of(context)!; // Corrected call
    try {
      setState(() => _isLoading = true);
      await _firebaseService.declineJobApplication(
          widget.job.clientId, // clientId is needed by FirebaseService
          widget.job.id,
          workerId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                appStrings
                    .applicationDeclinedSuccessfullyText, // Using AppStrings
                style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onPrimary)), // Using theme color
            backgroundColor: Colors.orange.shade700, // Using theme color
          ),
        );
        await _loadApplicants(); // Reload to update list
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Error declining applicant: $e', // Keeping original error string. If you want, add to AppStrings
                style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onError)), // Using theme color
            backgroundColor:
                Theme.of(context).colorScheme.error, // Using theme color
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appStrings = AppLocalizations.of(context)!; // Corrected call
    final ColorScheme colorScheme =
        Theme.of(context).colorScheme; // Using theme color
    final TextTheme textTheme = Theme.of(context).textTheme; // Using theme text

    return Scaffold(
      appBar: AppBar(
        title: Text(
            appStrings.applicantsForJob(widget.job.title), // Using AppStrings
            style: textTheme.titleLarge?.copyWith(
                color: colorScheme.onPrimary)), // Using theme text & color
        backgroundColor: colorScheme.primary, // Using theme color
        foregroundColor: colorScheme.onPrimary, // Using theme color
        actions: [
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.onPrimary), // Using theme color
              ),
            ),
        ],
      ),
      backgroundColor: colorScheme.background, // Using theme color
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator()) // Original indicator
          : _applicants.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline,
                          size: 64,
                          color:
                              colorScheme.outlineVariant), // Using theme color
                      const SizedBox(height: 16),
                      Text(
                        'no applications', //'noapplicationy', // Using AppStrings
                        style: textTheme.headlineSmall?.copyWith(
                            color: colorScheme
                                .onSurfaceVariant), // Using theme text & color
                      ),
                    ],
                  ),
                )
              : AnimationLimiter(
                  // Added AnimationLimiter
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _applicants.length,
                    itemBuilder: (context, index) {
                      final applicant = _applicants[index];
                      return AnimationConfiguration.staggeredList(
                        // Added animation
                        position: index,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: _buildApplicantCard(applicant),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildApplicantCard(Worker applicant) {
    final appStrings = AppLocalizations.of(context)!; // Corrected call
    final ColorScheme colorScheme =
        Theme.of(context).colorScheme; // Using theme color
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
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor:
                      colorScheme.surfaceVariant, // Themed background
                  backgroundImage: applicant.profileImage != null
                      ? NetworkImage(applicant.profileImage!)
                      : null,
                  child: applicant.profileImage == null
                      ? Icon(Icons.person,
                          size: 30,
                          color: colorScheme.onSurfaceVariant) // Themed icon
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        applicant.name,
                        style: textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface), // Themed text
                      ),
                      const SizedBox(height: 4),
                      Text(
                        applicant.profession,
                        style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant), // Themed text
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.location_on,
                    size: 16,
                    color: colorScheme.onSurfaceVariant), // Themed icon
                const SizedBox(width: 4),
                Text(
                  applicant.location,
                  style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant), // Themed text
                ),
                const SizedBox(width: 16),
                Icon(Icons.star,
                    size: 16, color: Colors.amber), // Original color
                const SizedBox(width: 4),
                Text(
                  applicant.rating.toStringAsFixed(1),
                  style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant), // Themed text
                ),
                const SizedBox(width: 16),
                Icon(Icons.work,
                    size: 16,
                    color: colorScheme.onSurfaceVariant), // Themed icon
                const SizedBox(width: 4),
                Text(
                  '${applicant.completedJobs} ${appStrings.jobsText}', // Using AppStrings
                  style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant), // Themed text
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (applicant.about.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${appStrings.aboutText}:', // Using AppStrings
                    style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface), // Themed text
                  ),
                  const SizedBox(height: 4),
                  Text(
                    applicant.about,
                    style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant), // Themed text
                  ),
                ],
              ),
            const SizedBox(height: 16),
            if (applicant.skills.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${appStrings.skillsText}:', // Using AppStrings
                    style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface), // Themed text
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: applicant.skills
                        .map((skill) => Chip(
                              label: Text(skill),
                              backgroundColor: colorScheme
                                  .secondaryContainer, // Themed color
                              labelStyle: textTheme.labelSmall?.copyWith(
                                  color: colorScheme
                                      .onSecondaryContainer), // Themed text & color
                            ))
                        .toList(),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () {
                    // Show more details or contact the applicant
                  },
                  child: Text(appStrings.viewProfileText), // Using AppStrings
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    foregroundColor: colorScheme.primary, // Themed color
                    side:
                        BorderSide(color: colorScheme.primary), // Themed color
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _acceptApplicant(applicant.id),
                  child: Text(appStrings.acceptText), // Using AppStrings
                  style: ElevatedButton.styleFrom(
                    foregroundColor: colorScheme.onPrimary, // Themed color
                    backgroundColor: colorScheme.primary, // Themed color
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () =>
                      _declineApplicant(applicant.id), // Calls decline method
                  child: Text(appStrings.declineText), // Using AppStrings
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    backgroundColor: colorScheme.error, // Themed color
                    foregroundColor: colorScheme.onError, // Themed color
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
