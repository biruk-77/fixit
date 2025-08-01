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
  List<Job> _myJobs = []; // Client: Posted Jobs | Worker: Assigned Jobs
  List<Job> _appliedJobs = []; // Worker: Jobs they applied for
  List<Job> _requestedJobs = []; // Client: Jobs requested (direct requests)
  List<Job> _assignedJobs =
      []; // Worker: Jobs that are assigned, accepted, in progress etc. (for 'Active Work' tab)

  // Map to store worker profiles for easy lookup in applications view
  // Key: workerId, Value: Worker object
  Map<String, Worker> _applicantWorkers = {};

  int _selectedFilterIndex = 0;
  bool _isWorker = false;
  AppUser? _userProfile; // Make sure this AppUser has 'uid' field

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    // Use WidgetsBinding.instance.addPostFrameCallback to ensure context is available
    // for AppLocalizations.of(context) on first build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  void _handleTabChange() {
    // Only reset filter and reload if the tab actually changed by user interaction
    // Or if the tab controller is being initialized for the first time
    if (!_tabController.indexIsChanging) {
      setState(() => _selectedFilterIndex = 0);
      _loadJobs();
    }
  }

  @override
  void dispose() {
    _tabController
        .removeListener(_handleTabChange); // Important to remove listener
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
        _showErrorSnackbar(appStrings.errorLoadingData(e.toString()));
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

    if (!mounted) return; // Prevent setState if widget is unmounted

    setState(() {
      _isLoading = true;
      // Clear previous data while loading new
      _myJobs = [];
      _appliedJobs = [];
      _requestedJobs = [];
      _assignedJobs = [];
      _applicantWorkers = {};
    });

    try {
      if (_isWorker) {
        // Worker's perspective
        final myAssignedJobs = await _firebaseService.getWorkerJobs(userId);
        final myAppliedJobs = await _firebaseService.getAppliedJobs(userId);
        // _assignedJobs will hold jobs relevant to 'Active Work' tab (assigned, accepted, in progress)
        final workerActiveJobs =
            await _firebaseService.getWorkerAssignedJobs(userId);

        if (mounted) {
          setState(() {
            _myJobs = myAssignedJobs; // For 'ASSIGNED JOBS' tab
            _appliedJobs = myAppliedJobs; // For 'MY APPLICATIONS' tab
            _assignedJobs = workerActiveJobs; // For 'ACTIVE WORK' tab
          });
        }
      } else {
        // Client's perspective
        final [postedJobs, requestedJobs] = await Future.wait([
          _firebaseService.getClientJobsWithApplications(userId),
          _firebaseService.getRequestedJobs(userId),
        ]);

        // Pre-fetch worker profiles for applications for performance
        final Set<String> allApplicantIds = {};
        for (var job in postedJobs) {
          allApplicantIds.addAll(job.applications);
        }

        final Map<String, Worker> tempApplicantWorkers = {};
        await Future.wait(allApplicantIds.map((id) async {
          final worker = await _firebaseService.getWorkerById(id);
          if (worker != null) {
            tempApplicantWorkers[id] = worker;
          }
        }));

        if (mounted) {
          setState(() {
            _myJobs =
                postedJobs; // For 'MY POSTED JOBS' and 'APPLICATIONS' tabs
            _requestedJobs = requestedJobs; // For 'MY REQUESTS' tab
            _applicantWorkers = tempApplicantWorkers;
          });
        }
      }
    } catch (e) {
      print('Error loading jobs: $e');
      if (mounted) {
        _showErrorSnackbar(appStrings.errorLoadingJobs(e.toString()));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Action Methods
  Future<void> _cancelJob(Job job) async {
    if (!mounted) return;
    final appStrings = AppLocalizations.of(context)!; // Corrected call
    try {
      setState(() => _isLoading = true);
      await _firebaseService.deleteJob(job.id);
      _showSuccessSnackbar(appStrings.jobCancelledSuccessfullyText);
      await _loadUserData(); // Reload all data
    } catch (e) {
      _showErrorSnackbar(appStrings.errorCancellingJob(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptApplication(
      Job job, String workerId, String clientId) async {
    if (!mounted) return;
    final appStrings = AppLocalizations.of(context)!; // Corrected call
    try {
      setState(() => _isLoading = true);
      await _firebaseService.acceptJobApplication(job.id, workerId, clientId);
      _showSuccessSnackbar(appStrings.applicationAcceptedSuccessfullyText);
      await _loadJobs(); // Reload jobs for updated status
    } catch (e) {
      _showErrorSnackbar(appStrings.errorAcceptingApplication(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptJob(Job job, String userID) async {
    if (!mounted) return;
    final appStrings = AppLocalizations.of(context)!; // Corrected call
    try {
      setState(() => _isLoading = true);
      print('Accepting job ${job.id} for user $userID');
      await _firebaseService.updateJobStatus(
          job.id, userID, job.clientId, 'accepted');

      await _loadJobs();
      _showSuccessSnackbar(appStrings.jobAcceptedSuccessfullyText);
    } catch (e) {
      _showErrorSnackbar(appStrings.errorAcceptingJob(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _completeJob(Job job, String workerID) async {
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
      _showSuccessSnackbar(appStrings.jobMarkedAsCompletedSuccessfullyText);
      await _loadJobs();
    } catch (e) {
      _showErrorSnackbar(appStrings.errorCompletingJob(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _startWork(Job job) async {
    if (!mounted) return;
    final appStrings = AppLocalizations.of(context)!; // Corrected call
    try {
      setState(() => _isLoading = true);
      await _firebaseService.updateJobStatus(
        job.id,
        _firebaseService.getCurrentUser()!.uid, // Current worker user
        job.clientId,
        'started working',
      );
      _showSuccessSnackbar(appStrings.workStartedSuccessfullyText);
      await _loadJobs();
    } catch (e) {
      _showErrorSnackbar(appStrings.errorStartingWork(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // UI Helper Methods
  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: TextStyle(color: Theme.of(context).colorScheme.onError)),
        backgroundColor: Theme.of(context).colorScheme.error,
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
    ).then((_) => _loadUserData()); // Reload data after returning from detail
  }

  void _navigateToEditJob(Job job) {
    Navigator.pushNamed(context, '/post-job', arguments: job)
        .then((_) => _loadUserData()); // Reload data after editing
  }

  void _navigateToJobApplications(Job job) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JobApplicationsScreen(
          job: job,
          preFetchedApplicants: _applicantWorkers, // Pass prefetched data
        ),
      ),
    ).then((result) {
      if (result == true) {
        // If an application was accepted, reload
        _loadUserData();
      }
    });
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
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text(
          _isWorker
              ? appStrings.myWorkDashboardText
              : appStrings.myJobsDashboardText,
          style: textTheme.titleLarge?.copyWith(color: colorScheme.onPrimary),
        ),
        backgroundColor: colorScheme.primary, // AppBar background
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: colorScheme.onPrimary),
            onSelected: (String value) {
              if (value == 'switch_role') {
                setState(() {
                  _isWorker = !_isWorker;
                  _selectedFilterIndex = 0; // Reset filter on role switch
                });
                _loadUserData(); // Reload data for new role
                _showSuccessSnackbar(_isWorker
                    ? appStrings.switchedToWorkerView
                    : appStrings.switchedToClientView);
              } else if (value == 'settings') {
                // Navigator.pushNamed(context, '/settings'); // Placeholder for settings
                _showSuccessSnackbar('Navigating to settings...');
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'switch_role',
                child: Text(_isWorker
                    ? appStrings.switchToClientViewTooltip
                    : appStrings.switchToWorkerViewTooltip),
              ),
              PopupMenuItem<String>(
                value: 'settings',
                child: Text(appStrings.profileSettingsTitle),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colorScheme.secondary, // Accent color for indicator
          labelColor: colorScheme.onPrimary,
          unselectedLabelColor: colorScheme.onPrimary.withOpacity(0.7),
          labelStyle:
              textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
          tabs: _isWorker
              ? [
                  Tab(text: appStrings.assignedJobsText),
                  Tab(text: appStrings.myApplicationsText),
                  Tab(text: appStrings.activeWorkText),
                ]
              : [
                  Tab(text: appStrings.myPostedJobsText),
                  Tab(text: appStrings.applicationsText),
                  Tab(text: appStrings.myRequestsText),
                ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        color: colorScheme.primary,
        child: TabBarView(
          controller: _tabController,
          children: _isWorker
              ? [
                  _buildTabContent(_myJobs, _buildAssignedJobsView),
                  _buildTabContent(_appliedJobs, _buildAppliedJobsView),
                  _buildTabContent(_assignedJobs,
                      _buildWorksForMeView), // _assignedJobs holds active jobs for worker
                ]
              : [
                  _buildTabContent(_myJobs, _buildPostedJobsView),
                  _buildTabContent(_myJobs, _buildApplicationsView),
                  _buildTabContent(_requestedJobs, _buildRequestedJobsView),
                ],
        ),
      ),
      floatingActionButton: !_isWorker
          ? FloatingActionButton(
              onPressed: () => Navigator.pushNamed(context, '/post-job')
                  .then((_) => _loadUserData()),
              backgroundColor: colorScheme.secondary, // Amber for FAB
              child: Icon(Icons.add,
                  size: 28,
                  color: colorScheme
                      .onSecondary), // Use onSecondary for icon color
              elevation: 6,
            )
          : null,
    );
  }

  // Wrapper for tab content to handle loading and animations
  Widget _buildTabContent(List<Job> jobs, Widget Function() builder) {
    return _isLoading
        ? _buildShimmerList(jobs.length > 0
            ? jobs.length
            : 3) // Show shimmer if loading, guess 3 items if list is empty
        : builder();
  }

  // Shimmer effect for loading states
  Widget _buildShimmerList(int itemCount) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: colorScheme.surfaceVariant,
          highlightColor: colorScheme.surfaceContainer,
          child: Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      width: double.infinity, height: 20, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(width: 100, height: 10, color: Colors.white),
                  const SizedBox(height: 16),
                  Container(
                      width: double.infinity, height: 12, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(
                      width: double.infinity, height: 12, color: Colors.white),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(width: 80, height: 40, color: Colors.white),
                      const SizedBox(width: 12),
                      Container(width: 80, height: 40, color: Colors.white),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
            appStrings.completedText),
        const SizedBox(height: 16),
        _buildJobCountDisplay(filteredJobs.length, appStrings.assignedJobText,
            appStrings.assignedJobsPluralText),
        Expanded(
          child: filteredJobs.isEmpty
              ? _buildEmptyState(
                  // This method is defined below within this class
                  appStrings.noAssignedJobsYetText,
                  Icons.assignment_turned_in,
                  appStrings.whenJobsAreAssignedToYouText,
                )
              : AnimationLimiter(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredJobs.length,
                    itemBuilder: (context, index) {
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: _buildJobCard(
                              filteredJobs[index],
                              showAcceptButton:
                                  true, // Show accept/decline for worker on assigned jobs
                              showApplications:
                                  false, // Not for worker's assigned jobs
                              checkbutton:
                                  true, // Allow the conditional buttons inside the card
                            ),
                          ),
                        ),
                      );
                    },
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
            appStrings.closedText),
        const SizedBox(height: 16),
        _buildJobCountDisplay(
            filteredJobs.length, appStrings.jobText, appStrings.jobsText),
        Expanded(
          child: filteredJobs.isEmpty
              ? _buildEmptyState(
                  // This method is defined below within this class
                  appStrings.noApplicationsYetText,
                  Icons.send,
                  appStrings.jobsYouApplyForWillAppearHereText,
                )
              : AnimationLimiter(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredJobs.length,
                    itemBuilder: (context, index) {
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: _buildJobCard(
                              filteredJobs[index],
                              showStatus: true,
                              checkbutton:
                                  false, // No accept/decline buttons for applied jobs
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildWorksForMeView() {
    final appStrings = AppLocalizations.of(context)!; // Corrected call
    List<Job> filteredJobs = _applyStatusFilter(
        _assignedJobs); // Use _assignedJobs for active worker jobs

    return Column(
      children: [
        _buildFilterChips(
            true,
            appStrings.allText,
            appStrings.acceptedText,
            appStrings.inProgressText, // Adjusted to in_progress
            appStrings.completedText,
            appStrings.cancelledText),
        const SizedBox(height: 16),
        _buildJobCountDisplay(filteredJobs.length, appStrings.activeJobText,
            appStrings.activeJobsPluralText),
        Expanded(
          child: filteredJobs.isEmpty
              ? _buildEmptyState(
                  // This method is defined below within this class
                  appStrings.noActiveWorkText,
                  Icons.work,
                  appStrings.yourActiveJobsWillAppearHereText,
                )
              : AnimationLimiter(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredJobs.length,
                    itemBuilder: (context, index) {
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: _buildJobCard(
                              filteredJobs[index],
                              showCompleteButton: true, // Allow complete
                              showActiveWorkActions:
                                  true, // Show start/complete buttons
                              showApplications:
                                  false, // Not relevant for worker's active jobs
                              checkbutton:
                                  false, // No general accept/decline for active work
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildPostedJobsView() {
    final appStrings = AppLocalizations.of(context)!; // Corrected call
    final filteredJobs =
        _applyStatusFilter(_myJobs); // _myJobs for client are posted jobs

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterChips(
            false,
            appStrings.allText,
            appStrings.openText,
            appStrings.pendingText,
            appStrings.acceptedText,
            appStrings.completedText),
        const SizedBox(height: 16),
        _buildJobCountDisplay(
            filteredJobs.length, appStrings.jobText, appStrings.jobsText),
        Expanded(
          child: filteredJobs.isEmpty
              ? _buildEmptyState(
                  // This method is defined below within this class
                  appStrings.noPostedJobsYetText,
                  Icons.post_add,
                  appStrings.tapThePlusButtonToPostYourFirstJobText,
                  showActionButton: true,
                )
              : AnimationLimiter(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredJobs.length,
                    itemBuilder: (context, index) {
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: _buildJobCard(
                              filteredJobs[index],
                              showEditButton: true,
                              showApplications:
                                  true, // Show application count for client's posted jobs
                              checkbutton: true, // Manage button for client
                            ),
                          ),
                        ),
                      );
                    },
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
            appStrings.closedText),
        const SizedBox(height: 16),
        _buildJobCountDisplay(
            filteredJobs.length, appStrings.jobText, appStrings.jobsText),
        Expanded(
          child: filteredJobs.isEmpty
              ? _buildEmptyState(
                  // This method is defined below within this class
                  appStrings.noApplicationsYetText,
                  Icons.people_outline,
                  appStrings
                      .jobsYouApplyForWillAppearHereText, // Adjusted for context
                )
              : AnimationLimiter(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredJobs.length,
                    itemBuilder: (context, index) {
                      return AnimationConfiguration.staggeredList(
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
                      );
                    },
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
            appStrings.rejectedText),
        const SizedBox(height: 16),
        _buildJobCountDisplay(
            filteredJobs.length, appStrings.jobText, appStrings.jobsText),
        Expanded(
          child: filteredJobs.isEmpty
              ? _buildEmptyState(
                  // This method is defined below within this class
                  appStrings.noJobRequestsText,
                  Icons.request_quote,
                  appStrings.yourPersonalJobRequestsWillAppearHereText,
                )
              : AnimationLimiter(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredJobs.length,
                    itemBuilder: (context, index) {
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: _buildJobCard(
                              filteredJobs[index],
                              showEditButton: true,
                              showCancelButton: true,
                              // showAcceptButton is false as direct 'accept' on requests tab implies client accepting their own request, which is usually handled through 'manage' or is not a direct worker acceptance.
                              showAcceptButton: false,
                              showCompleteButton: false,
                              showApplications:
                                  false, // Requests don't have applications in this context
                              checkbutton:
                                  true, // Manage button for client on requests
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  // UI Components
  Widget _buildFilterChips(bool isWorkerTab, String all, String option1,
      String option2, String? option3, String? option4) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    final filters = [
      all,
      option1,
      option2,
      if (option3 != null) option3,
      if (option4 != null) option4
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: colorScheme.surface, // Use theme surface color
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
                    selectedColor: colorScheme.primary.withOpacity(0.2),
                    labelStyle: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(
                          color: _selectedFilterIndex == filters.indexOf(filter)
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                    onSelected: (selected) => setState(
                      () => _selectedFilterIndex =
                          selected ? filters.indexOf(filter) : 0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: _selectedFilterIndex == filters.indexOf(filter)
                            ? colorScheme.primary
                            : colorScheme.outlineVariant,
                        width: 1,
                      ),
                    ),
                    backgroundColor: colorScheme.surfaceContainerLow,
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildJobCountDisplay(int count, String singular, String plural) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Text(
          '$count ${count == 1 ? singular : plural}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ),
    );
  }

  Widget _buildJobCard(
    Job job, {
    bool showEditButton = false,
    bool showCancelButton = false,
    bool showAcceptButton =
        false, // For worker accepting assigned job (specific to worker assigned tab)
    bool showCompleteButton = false, // For worker marking job complete
    bool showStatus = false, // For worker's applied jobs, just show job status
    bool showApplications =
        true, // For client's posted jobs, show applicant count
    bool checkbutton =
        true, // General control for action button block visibility
    bool showActiveWorkActions =
        false, // Worker's active work actions (for 'ACTIVE WORK' tab)
  }) {
    final appStrings = AppLocalizations.of(context)!; // Corrected call
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    final statusColor = _getStatusColor(job.status);
    // final formattedDate = job.scheduledDate != null; // original variable, not directly used now

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: colorScheme.surfaceContainerHigh,
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
                          style: textTheme.titleMedium
                              ?.copyWith(color: colorScheme.onSurface),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${appStrings.postedText} ${_getTimeAgo(job.createdAt)}',
                          style: textTheme.bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
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
                    color: Colors.green, // Specific green for money
                  ),
                  if (showApplications) // For client's posted jobs
                    _buildDetailItem(
                      Icons.person_outline,
                      job.applications.isEmpty
                          ? appStrings.noApplicantsText
                          : '${job.applications.length} ${job.applications.length == 1 ? appStrings.applicantText : appStrings.applicantsText}',
                      color: colorScheme
                          .secondary, // Secondary color for applications count
                    )
                  else if (job.status !=
                      'completed') // Original condition logic from first code
                    _buildDetailItem(
                      Icons.person_outline,
                      _isWorker
                          ? appStrings.waitingForWorkerToAcceptText
                          : appStrings.yourWorkingIsOnPendingText,
                    )
                  else if (job.status == 'completed' &&
                      !_isWorker) // Original condition logic from first code
                    _buildDetailItem(
                      Icons.payment, // Changed icon for payment
                      appStrings.payText, // Changed label for payment
                      color: colorScheme
                          .tertiary, // Use a themed color for payment
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Progress Timeline (only if not rejected/cancelled)
              if (job.status.toLowerCase() != 'rejected' &&
                  job.status.toLowerCase() != 'cancelled')
                _buildProgressTimeline(job.status),

              const SizedBox(height: 16),

              // Action Buttons - Replicating original logic exactly, with new styling
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(Icons.remove_red_eye,
                          size: 18, color: colorScheme.primary),
                      label: Text(appStrings.viewDetailsText),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: colorScheme.primary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _navigateToJobDetail(job),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (checkbutton) // Overall control from original code
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
                                    appStrings.acceptText), // Added text label
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade700,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () => _acceptJob(job,
                                    _firebaseService.getCurrentUser()!.uid),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.close,
                                    size: 16, color: Colors.white),
                                label: Text(
                                    appStrings.declineText), // Added text label
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade700,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () async {
                                  final currentUserId =
                                      _firebaseService.getCurrentUser()!.uid;
                                  await _firebaseService.declineJobApplication(
                                      job.clientId, job.id, currentUserId);
                                  _showSuccessSnackbar(appStrings
                                      .applicationDeclinedSuccessfullyText);
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
                          icon: Icon(Icons.star_rate,
                              size: 18,
                              color: colorScheme
                                  .onPrimary), // Changed icon to rate
                          label: Text(appStrings
                              .payText), // Label for client 'Rate' action (original said rate but payment seems more logical for assigned completed client jobs)
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
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
                              size: 18, color: colorScheme.onPrimary),
                          label: Text(appStrings.manageText),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
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
                              size: 18, color: colorScheme.onPrimary),
                          label: Text(appStrings.manageText),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => _navigateToJobApplications(job),
                        ),
                      )
                    else if (_isWorker &&
                        job.status ==
                            'assigned' && // This condition was specific in original
                        job.status != 'completed' &&
                        job.status != 'cancelled' &&
                        job.status != 'rejected' &&
                        job.status != 'in_progress' && // Original had this
                        job.status ==
                            'open') // Original had this, making it complex
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.play_arrow,
                              size: 18, color: colorScheme.onPrimary),
                          label: Text(appStrings
                              .startButton), // Changed from Start Work
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => _startWork(job), // Calls _startWork
                        ),
                      )
                    else
                      SizedBox.shrink()
                ],
              ),
              // This Card was separate in your first code, adding it back as per "whole card"
              if (showActiveWorkActions &&
                  job.status != 'completed') // Original condition
                Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(
                      top: 16), // Add margin to separate from above row
                  color: colorScheme.surfaceContainerLow,
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
                                  onPressed: () =>
                                      _startWork(job), // This calls _startWork
                                  child: Text(appStrings.startButton),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade700,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _completeJob(job,
                                    _firebaseService.getCurrentUser()!.uid),
                                child: Text(appStrings.completeButton),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade700,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
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
        return 0; // Initial stage: "Pending"
      case 'accepted':
      case 'assigned':
        return 1; // Middle stage: "Accepted/Assigned"
      case 'in_progress':
      case 'started working':
        return 2; // Middle stage: "In Progress"
      case 'completed':
      case 'closed':
        return 3; // Final stage: "Completed"
      default:
        return -1; // Special case for rejected/cancelled, don't show timeline
    }
  }

  Widget _buildProgressTimeline(String status) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final appStrings = AppLocalizations.of(context)!; // Corrected call

    final stages = [
      appStrings.timelinePending,
      appStrings.acceptedText,
      appStrings.timelineInProgress,
      appStrings.timelineCompleted,
    ];
    final currentIndex = _getTimelineIndex(status);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(stages.length, (index) {
            final isActive = index <= currentIndex;
            return Expanded(
              child: Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isActive
                          ? colorScheme.primary
                          : colorScheme.surfaceVariant,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        isActive ? Icons.check : Icons.circle,
                        size: 14,
                        color: isActive
                            ? Colors.white
                            : colorScheme.onSurfaceVariant.withOpacity(0.6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stages[index],
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight:
                              isActive ? FontWeight.bold : FontWeight.normal,
                          color: isActive
                              ? colorScheme.onSurface
                              : colorScheme.onSurfaceVariant.withOpacity(0.8),
                        ),
                  ),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        // Line connecting dots
        Row(
          children: List.generate(stages.length * 2 - 1, (index) {
            if (index % 2 == 0) {
              return Expanded(
                  child: const SizedBox(
                      width: 24, height: 1)); // Placeholder for dot
            } else {
              final previousStageIndex = (index - 1) ~/ 2;
              final isActiveLine = previousStageIndex < currentIndex;
              return Expanded(
                child: Container(
                  height: 2,
                  color: isActiveLine
                      ? colorScheme.primary
                      : colorScheme.outlineVariant,
                ),
              );
            }
          }),
        ),
      ],
    );
  }

  Widget _buildDetailItem(IconData icon, String text, {Color? color}) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: color ?? colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color ?? colorScheme.onSurface,
                  fontWeight:
                      color != null ? FontWeight.bold : FontWeight.normal,
                ),
          ),
        ),
      ],
    );
  }

  // NOTE: This widget is for the client's "APPLICATIONS" tab, showing applicants for their jobs.
  Widget _buildJobWithApplicationsCard(Job job) {
    final appStrings = AppLocalizations.of(context)!; // Corrected call
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: colorScheme.surfaceContainerHigh,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () => _navigateToJobDetail(job),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      job.title,
                      style: textTheme.titleMedium
                          ?.copyWith(color: colorScheme.onSurface),
                    ),
                  ),
                  Chip(
                    label: Text(
                      job.status.toUpperCase(),
                      style: textTheme.labelSmall
                          ?.copyWith(color: colorScheme.onPrimary),
                    ),
                    backgroundColor: _getStatusColor(job.status),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                job.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on,
                      size: 16, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    job.location,
                    style: textTheme.bodySmall
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  const Spacer(),
                  Icon(Icons.attach_money,
                      size: 16, color: Colors.green.shade700),
                  const SizedBox(width: 4),
                  Text(
                    '${job.budget.toStringAsFixed(0)} ETB',
                    style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time,
                      size: 16, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    '${appStrings.postedText} ${_getTimeAgo(job.createdAt)}',
                    style: textTheme.bodySmall
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    appStrings.applicationsText.toUpperCase(),
                    style: textTheme.titleSmall
                        ?.copyWith(color: colorScheme.onSurface),
                  ),
                  const Spacer(),
                  Chip(
                    label: Text(
                      job.applications.length.toString(),
                      style: textTheme.labelSmall
                          ?.copyWith(color: colorScheme.onSecondary),
                    ),
                    backgroundColor: colorScheme.secondary,
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _navigateToJobApplications(job),
                  icon: Icon(Icons.people_alt, color: colorScheme.primary),
                  label: Text(appStrings.viewDetailsText,
                      style: TextStyle(color: colorScheme.primary)),
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                  ),
                ),
              ),
              if (job.applications.isEmpty)
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 48,
                        color: colorScheme.outlineVariant,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        appStrings.noApplicationsYetText,
                        style: textTheme.bodyMedium
                            ?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: [
                    ...job.applications.take(3).map((applicantId) {
                      final applicant = _applicantWorkers[applicantId];
                      if (applicant == null) {
                        return ListTile(
                          leading: CircularProgressIndicator(
                              color: colorScheme.primary),
                          title: Text(appStrings.loadingText,
                              style: textTheme.bodyMedium),
                        );
                      }
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        color: colorScheme.surfaceContainerLow,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: colorScheme.surfaceVariant,
                                backgroundImage: applicant.profileImage != null
                                    ? NetworkImage(applicant.profileImage!)
                                    : null,
                                child: applicant.profileImage == null
                                    ? Icon(Icons.person,
                                        size: 24,
                                        color: colorScheme.onSurfaceVariant)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          applicant.name,
                                          style: textTheme.titleSmall?.copyWith(
                                              color: colorScheme.onSurface),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(Icons.star,
                                            size: 16, color: Colors.amber),
                                        const SizedBox(width: 2),
                                        Text(
                                          applicant.rating == null
                                              ? '0.0'
                                              : applicant.rating
                                                  .toStringAsFixed(1),
                                          style: textTheme.bodySmall?.copyWith(
                                              color:
                                                  colorScheme.onSurfaceVariant),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      applicant.profession,
                                      style: textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.location_on,
                                            size: 14,
                                            color:
                                                colorScheme.onSurfaceVariant),
                                        const SizedBox(width: 4),
                                        Text(
                                          applicant.location,
                                          style: textTheme.bodySmall?.copyWith(
                                              color:
                                                  colorScheme.onSurfaceVariant),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${applicant.completedJobs} ${appStrings.jobsText}',
                                          style: textTheme.bodySmall?.copyWith(
                                              color:
                                                  colorScheme.onSurfaceVariant),
                                        ),
                                        const Spacer(),
                                        IconButton(
                                          icon: Icon(Icons.message,
                                              color: colorScheme.onSurface),
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
                              // Action Button for each applicant (Accept)
                              Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  ElevatedButton(
                                    onPressed: () => _acceptApplication(
                                      job,
                                      applicantId,
                                      _firebaseService.getCurrentUser()!.uid,
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      backgroundColor: colorScheme.primary,
                                      foregroundColor: colorScheme.onPrimary,
                                    ),
                                    child: Text(
                                      appStrings.acceptText,
                                      style: textTheme.labelLarge,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  OutlinedButton(
                                    onPressed: () async {
                                      final currentUserId = _firebaseService
                                          .getCurrentUser()!
                                          .uid;
                                      await _firebaseService
                                          .declineJobApplication(job.clientId,
                                              job.id, applicantId);
                                      _showSuccessSnackbar(appStrings
                                          .applicationDeclinedSuccessfullyText);
                                      _loadJobs(); // Corrected: Reload dashboard jobs after decline
                                    },
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      side:
                                          BorderSide(color: colorScheme.error),
                                      foregroundColor: colorScheme.error,
                                    ),
                                    child: Text(
                                      appStrings.declineText,
                                      style: textTheme.labelLarge,
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    }).toList(),
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
      ),
    );
  }

  // Helper method for status colors
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.blue.shade700;
      case 'pending':
        return Colors.orange.shade700;
      case 'assigned':
        return Colors.deepPurple.shade700;
      case 'accepted':
        return Colors.green.shade700;
      case 'in_progress':
      case 'started working':
        return Colors.amber.shade700;
      case 'completed':
        return Colors.teal.shade700;
      case 'cancelled':
        return Colors.red.shade700;
      case 'rejected':
        return Colors.grey.shade700;
      case 'closed':
        return Colors.brown.shade700;
      default:
        return Colors.grey;
    }
  }

  // Helper method for time ago formatting using AppLocalizations
  String _getTimeAgo(DateTime date) {
    final appStrings = AppLocalizations.of(context)!; // Corrected call
    return appStrings.formatTimeAgo(date);
  }

  List<Job> _applyStatusFilter(List<Job> jobs) {
    if (_selectedFilterIndex == 0) return jobs; // 'All' filter

    final appStrings = AppLocalizations.of(context)!; // Corrected call
    final String filterStatus;

    // Determine the correct filter based on the current tab
    if (_isWorker) {
      if (_tabController.index == 0) {
        // ASSIGNED JOBS (Worker)
        filterStatus = [
          appStrings.allText,
          appStrings.openText,
          appStrings.pendingText,
          appStrings.acceptedText,
          appStrings.completedText
        ][_selectedFilterIndex]
            .toLowerCase();
      } else if (_tabController.index == 1) {
        // MY APPLICATIONS (Worker)
        filterStatus = [
          appStrings.allText,
          appStrings.openText,
          appStrings.pendingText,
          appStrings.acceptedText,
          appStrings.closedText
        ][_selectedFilterIndex]
            .toLowerCase();
      } else {
        // ACTIVE WORK (Worker)
        filterStatus = [
          appStrings.allText,
          appStrings.acceptedText,
          appStrings.inProgressText, // Adjusted to in_progress for filter
          appStrings.completedText,
          appStrings
              .cancelledText // Allow filtering by cancelled in active work too
        ][_selectedFilterIndex]
            .toLowerCase();
      }
    } else {
      // Client
      if (_tabController.index == 0) {
        // MY POSTED JOBS (Client)
        filterStatus = [
          appStrings.allText,
          appStrings.openText,
          appStrings.pendingText,
          appStrings.acceptedText,
          appStrings.completedText
        ][_selectedFilterIndex]
            .toLowerCase();
      } else if (_tabController.index == 1) {
        // APPLICATIONS (Client)
        filterStatus = [
          appStrings.allText,
          appStrings.openText,
          appStrings.pendingText,
          appStrings.acceptedText,
          appStrings.closedText
        ][_selectedFilterIndex]
            .toLowerCase();
      } else {
        // MY REQUESTS (Client)
        filterStatus = [
          appStrings.allText,
          appStrings.pendingText,
          appStrings.acceptedText,
          appStrings.completedText,
          appStrings.rejectedText // Added rejected for requests
        ][_selectedFilterIndex]
            .toLowerCase();
      }
    }

    if (filterStatus == appStrings.allText.toLowerCase()) {
      return jobs;
    } else if (filterStatus == appStrings.inProgressText.toLowerCase()) {
      // Handle 'in_progress' which might include 'started working' etc.
      return jobs
          .where((job) => ['in_progress', 'started working']
              .contains(job.status.toLowerCase()))
          .toList();
    } else {
      return jobs
          .where((job) => job.status.toLowerCase() == filterStatus)
          .toList();
    }
  }

  // --- Start of _buildEmptyState method (must be inside _JobDashboardScreenState class) ---
  Widget _buildEmptyState(
    String title,
    IconData icon,
    String subtitle, {
    bool showActionButton = false,
  }) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
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
              color: colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: textTheme.headlineSmall
                  ?.copyWith(color: colorScheme.onBackground),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: textTheme.bodyMedium
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (showActionButton) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/post-job')
                    .then((_) => _loadUserData()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  appStrings.postAJobText,
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.onPrimary,
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
  // --- End of _buildEmptyState method ---
}

// Separate JobApplicationsScreen widget
class JobApplicationsScreen extends StatefulWidget {
  final Job job;
  final Map<String, Worker> preFetchedApplicants; // Receive prefetched data

  const JobApplicationsScreen({
    Key? key,
    required this.job,
    required this.preFetchedApplicants,
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
    if (!mounted) return;
    final appStrings = AppLocalizations.of(context)!; // Corrected call
    try {
      setState(() => _isLoading = true);

      final List<Worker> applicants = [];
      for (String applicantId in widget.job.applications) {
        // Use pre-fetched data first
        if (widget.preFetchedApplicants.containsKey(applicantId)) {
          applicants.add(widget.preFetchedApplicants[applicantId]!);
        } else {
          // If not pre-fetched (e.g., job was updated after initial load), fetch individually
          final worker = await _firebaseService.getWorkerById(applicantId);
          if (worker != null) {
            applicants.add(worker);
          }
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
            content: Text(appStrings.applicantLoadError + ': $e',
                style: TextStyle(color: Theme.of(context).colorScheme.onError)),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _acceptApplicant(String workerId) async {
    if (!mounted) return;
    final appStrings = AppLocalizations.of(context)!; // Corrected call
    try {
      setState(() => _isLoading = true);
      await _firebaseService.acceptJobApplication(
          widget.job.id, workerId, widget.job.clientId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(appStrings.applicationAcceptedSuccessfullyText,
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
            backgroundColor: Colors.green.shade700,
          ),
        );
        Navigator.of(context).pop(true); // Return success to dashboard
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(appStrings.errorAcceptingApplication(e.toString()),
                style: TextStyle(color: Theme.of(context).colorScheme.onError)),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _declineApplicant(String workerId) async {
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
            content: Text(appStrings.applicationDeclinedSuccessfullyText,
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
            backgroundColor: Colors.orange.shade700,
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
                'Error declining applicant: $e', // Use a specific error string in AppStrings
                style: TextStyle(color: Theme.of(context).colorScheme.onError)),
            backgroundColor: Theme.of(context).colorScheme.error,
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
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
            appStrings.applicantsForJob(
                widget.job.title), // Using applicantsForJob method
            style:
                textTheme.titleLarge?.copyWith(color: colorScheme.onPrimary)),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
              ),
            ),
        ],
      ),
      backgroundColor: colorScheme.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Initial loading
          : _applicants.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline,
                          size: 64, color: colorScheme.outlineVariant),
                      const SizedBox(height: 16),
                      Text(
                        appStrings.noApplicationsYetText,
                        style: textTheme.headlineSmall
                            ?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                )
              : AnimationLimiter(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _applicants.length,
                    itemBuilder: (context, index) {
                      final applicant = _applicants[index];
                      return AnimationConfiguration.staggeredList(
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
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: colorScheme.surfaceVariant,
                  backgroundImage: applicant.profileImage != null
                      ? NetworkImage(applicant.profileImage!)
                      : null,
                  child: applicant.profileImage == null
                      ? Icon(Icons.person,
                          size: 30, color: colorScheme.onSurfaceVariant)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        applicant.name,
                        style: textTheme.titleMedium
                            ?.copyWith(color: colorScheme.onSurface),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        applicant.profession,
                        style: textTheme.bodyMedium
                            ?.copyWith(color: colorScheme.onSurfaceVariant),
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
                    size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  applicant.location,
                  style: textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(width: 16),
                Icon(Icons.star, size: 16, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  applicant.rating.toStringAsFixed(1),
                  style: textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(width: 16),
                Icon(Icons.work, size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  '${applicant.completedJobs} ${appStrings.jobsText}',
                  style: textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (applicant.about.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${appStrings.aboutText}:',
                    style: textTheme.labelLarge
                        ?.copyWith(color: colorScheme.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    applicant.about,
                    style: textTheme.bodyMedium
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            if (applicant.skills.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${appStrings.skillsText}:',
                    style: textTheme.labelLarge
                        ?.copyWith(color: colorScheme.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: applicant.skills
                        .map((skill) => Chip(
                              label: Text(skill),
                              backgroundColor: colorScheme.secondaryContainer,
                              labelStyle: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSecondaryContainer),
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
                    // Navigate to worker profile - you'll need to implement this
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                    side: BorderSide(color: colorScheme.primary),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(appStrings.viewProfileText),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _acceptApplicant(applicant.id),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: colorScheme.onPrimary,
                    backgroundColor: colorScheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(appStrings.acceptText),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _declineApplicant(applicant.id),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: colorScheme.onError,
                    backgroundColor: colorScheme.error,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(appStrings.declineText),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
