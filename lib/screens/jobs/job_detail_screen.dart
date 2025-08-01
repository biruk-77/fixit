import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:cached_network_image/cached_network_image.dart';
import 'package:animate_do/animate_do.dart'; // For animations
import 'package:url_launcher/url_launcher.dart'; // To open attachment URLs

// --- Project Imports ---
import '../../models/job.dart';
import '../../models/worker.dart';
import '../../services/firebase_service.dart';
import '../../services/app_string.dart'; // Use AppStrings
// Use AppThemes
import '../payment/payment_screen.dart';
// Import other necessary screens like chat, review, etc.
// import '../chat_screen.dart';
// import '../review/leave_review_screen.dart'; // Example

class JobDetailScreen extends StatefulWidget {
  final Job job;

  const JobDetailScreen({super.key, required this.job});

  @override
  _JobDetailScreenState createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = false;
  bool _isApplying = false; // Separate loading state for apply button
  bool _isActionLoading = false; // General loading for other actions

  // User context state
  bool _isWorker = false;
  bool _isJobOwner = false; // Renamed from _isJobSeeker for clarity
  bool _hasApplied = false;
  String? _currentUserId;

  // Data state
  Worker? _assignedWorker;
  List<Worker> _applicants = []; // Changed from Map to List<Worker>

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    setState(() => _isLoading = true);
    _currentUserId = _firebaseService.getCurrentUser()?.uid;
    await _checkUserRoleAndLoadData();
    setState(() => _isLoading = false);
  }

  Future<void> _checkUserRoleAndLoadData() async {
    if (_currentUserId == null) return; // Cannot proceed without user ID

    final userProfile = await _firebaseService.getCurrentUserProfile();
    bool isWorker = false;
    bool isOwner = false;
    bool hasApplied = false;

    if (userProfile != null) {
      isWorker = userProfile.role == 'worker';
      isOwner = widget.job.seekerId ==
          _currentUserId; // Check if current user posted the job
      hasApplied = widget.job.applications.contains(_currentUserId);
    }

    // Fetch assigned worker if ID exists
    Worker? worker;
    if (widget.job.workerId != null && widget.job.workerId!.isNotEmpty) {
      try {
        worker = await _firebaseService.getWorkerById(widget.job.workerId!);
      } catch (e) {
        print("Error loading assigned worker: $e");
        if (mounted) {
          _showSnackbar(
              AppLocalizations.of(context)?.snackErrorLoading ??
                  'Error loading worker',
              isError: true);
        }
      }
    }

    // Fetch applicants if the current user is the job owner and there are applications
    List<Worker> fetchedApplicants = [];
    if (isOwner && widget.job.applications.isNotEmpty) {
      try {
        // getJobApplicants now returns List<Map>, convert to List<Worker>
        final applicantDataList =
            await _firebaseService.getJobApplicants(widget.job.id);
        fetchedApplicants =
            applicantDataList.map((data) => Worker.fromJson(data)).toList();
      } catch (e) {
        print("Error loading applicants: $e");
        if (mounted) {
          _showSnackbar(
              AppLocalizations.of(context)?.snackErrorLoading ??
                  'Error loading applicants',
              isError: true);
        }
      }
    }

    // Update state once after all async operations
    if (mounted) {
      setState(() {
        _isWorker = isWorker;
        _isJobOwner = isOwner;
        _hasApplied = hasApplied;
        _assignedWorker = worker;
        _applicants = fetchedApplicants;
      });
    }
  }

  // --- Action Methods ---

  Future<void> _applyForJob() async {
    if (!mounted || _currentUserId == null) return;
    final appStrings = AppLocalizations.of(context)!;
    setState(() => _isApplying = true);
    try {
      await _firebaseService.applyForJob(widget.job.id, _currentUserId!);

      setState(() => _hasApplied = true);
      _showSnackbar(appStrings.jobDetailSuccessApplied, isError: false);

      // No need to reload full details just for apply status usually
      // Refresh could be done if needed: await _checkUserRoleAndLoadData();
    } catch (e) {
      _showSnackbar(appStrings.jobDetailErrorApplying, isError: true);
      print('Error applying for job: $e');
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  Future<void> _assignWorker(String workerId) async {
    if (!mounted) return;
    final appStrings = AppLocalizations.of(context)!;
    setState(() => _isActionLoading = true); // Use general action loader
    try {
      // Use the simplified assignJob method
      await _firebaseService.assignJob(widget.job.id, workerId);
      // Reload details to show assigned worker and update status
      await _checkUserRoleAndLoadData();
      _showSnackbar(appStrings.jobDetailSuccessWorkerAssigned, isError: false);
    } catch (e) {
      _showSnackbar(appStrings.jobDetailErrorAssigningWorker, isError: true);
      print('Error assigning worker: $e');
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _markJobAsCompleted() async {
    if (!mounted) return;
    final appStrings = AppLocalizations.of(context)!;
    setState(() => _isActionLoading = true);
    try {
      // Use the updated updateJobStatus
      await _firebaseService.updateJobStatus(
        widget.job.id, // 1st: jobId
        widget.job.workerId, // 2nd: professionalId (can be null)
        widget.job.seekerId, // 3rd: clientId (using seekerId)
        'completed', // 4th: status
      );

      _showSnackbar(appStrings.jobDetailSuccessMarkedComplete, isError: false);
      Navigator.pop(context, true); // Pop and indicate success/refresh needed
    } catch (e) {
      _showSnackbar(appStrings.jobDetailErrorMarkingComplete, isError: true);
      print('Error marking job complete: $e');
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  void _showDeleteConfirmation() {
    if (!mounted) return;
    final appStrings = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(appStrings.jobDetailDeleteConfirmTitle,
            style: theme.textTheme.titleLarge),
        content: Text(appStrings.jobDetailDeleteConfirmContent,
            style: theme.textTheme.bodyMedium),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(appStrings.jobDetailDeleteConfirmKeep)),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog first
              if (!mounted) return;
              setState(() => _isActionLoading = true);
              try {
                await _firebaseService.deleteJob(widget.job.id);
                if (!mounted) return;
                _showSnackbar(appStrings.jobDetailSuccessDeleted,
                    isError: false);
                Navigator.pop(context, true); // Pop screen and indicate success
              } catch (e) {
                if (!mounted) return;
                _showSnackbar(appStrings.jobDetailErrorDeleting, isError: true);
                print("Error deleting job: $e");
              } finally {
                if (mounted) setState(() => _isActionLoading = false);
              }
            },
            child: Text(appStrings.jobDetailDeleteConfirmDelete,
                style: TextStyle(color: theme.colorScheme.error)),
          ),
        ],
      ),
    );
  }

  // Helper for showing Snackbars consistently
  void _showSnackbar(String message, {required bool isError}) {
    if (!mounted) return;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    ScaffoldMessenger.of(context)
        .removeCurrentSnackBar(); // Remove previous snackbar
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message,
          style: TextStyle(
              color: isError
                  ? colorScheme.onErrorContainer
                  : colorScheme.onTertiaryContainer)),
      backgroundColor:
          isError ? colorScheme.errorContainer : colorScheme.tertiaryContainer,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      elevation: 4,
    ));
  }

  // Helper to launch URL (for attachments)
  Future<void> _launchUrl(String urlString) async {
    final Uri uri = Uri.parse(urlString);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        _showSnackbar('Could not launch URL: $urlString', isError: true);
      }
    }
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final appStrings = AppLocalizations.of(context); // Null check below

    // Handle case where strings are not loaded yet
    if (appStrings == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
            child: CircularProgressIndicator(color: colorScheme.primary)),
      );
    }

    // Use the first attachment as the header image, fallback to placeholder
    // Assuming job.attachments contains Firebase Storage URLs
    String? headerImageUrl =
        widget.job.attachments.isNotEmpty ? widget.job.attachments.first : null;
    String placeholderImageUrl =
        'https://images.unsplash.com/photo-1517048676732-d65bc937f952?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1740&q=80'; // Generic placeholder

    return Scaffold(
      backgroundColor: colorScheme.surface, // Use theme background
      body: CustomScrollView(
        slivers: [
          // --- Themed SliverAppBar ---
          SliverAppBar(
            expandedHeight: 280.0, // Increased height
            floating: false,
            pinned: true,
            stretch: true, // Allow stretch effect
            backgroundColor:
                theme.appBarTheme.backgroundColor, // Use theme color
            foregroundColor:
                theme.appBarTheme.foregroundColor, // Icon/text color
            elevation: theme.appBarTheme.elevation,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Job Image or Placeholder
                  CachedNetworkImage(
                    imageUrl: headerImageUrl ?? placeholderImageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                        color:
                            colorScheme.surfaceContainer), // Placeholder color
                    errorWidget: (context, url, error) => Image.network(
                        placeholderImageUrl,
                        fit: BoxFit.cover), // Fallback on error
                  ),
                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.surface, // Match scaffold bg
                          colorScheme.surface.withOpacity(0.7),
                          Colors.transparent
                        ],
                        stops: const [
                          0.0,
                          0.4,
                          1.0
                        ], // Adjust stops for fade effect
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                ],
              ),
              titlePadding:
                  const EdgeInsets.only(left: 50, right: 50, bottom: 16),
              centerTitle: true,
              title: Text(
                widget.job.title.isEmpty
                    ? appStrings.jobUntitled
                    : widget.job.title,
                style: textTheme.titleLarge?.copyWith(
                    color:
                        colorScheme.onSurface, // Use text color on background
                    fontWeight: FontWeight.bold,
                    shadows: [
                      // Subtle shadow for readability
                      Shadow(
                          color: Colors.black.withOpacity(0.5), blurRadius: 4)
                    ]),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.fadeTitle
              ],
            ),
            // Actions Menu (Edit/Delete for Job Owner)
            actions: [
              if (_isJobOwner &&
                  widget.job.status !=
                      'completed') // Only owner can edit/delete active jobs
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded,
                      color: colorScheme.onPrimary), // Use theme color
                  color: colorScheme
                      .surfaceContainerHigh, // Use themed popup background
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showSnackbar(appStrings.jobDetailFeatureComingSoon,
                          isError: false);
                    } else if (value == 'delete') {
                      _showDeleteConfirmation();
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit_note_rounded,
                            color: colorScheme.primary),
                        title: Text('Edit Job',
                            style: textTheme.bodyMedium), // Use themed text
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete_forever_rounded,
                            color: colorScheme.error),
                        title: Text('Delete Job',
                            style: textTheme.bodyMedium
                                ?.copyWith(color: colorScheme.error)),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // --- Main Content Area ---
          SliverToBoxAdapter(
            child: FadeInUp(
              // Animate content appearance
              duration: const Duration(milliseconds: 300),
              child: Container(
                padding: const EdgeInsets.all(20.0),
                child: _isLoading
                    ? Center(
                        heightFactor: 5,
                        child: CircularProgressIndicator(
                            color: colorScheme.primary))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status and Budget Chips Row
                          Wrap(
                            // Use Wrap for responsiveness
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _buildThemedStatusChip(
                                  widget.job.status, appStrings, theme),
                              _buildThemedInfoChip(
                                  Icons.attach_money_rounded,
                                  appStrings.jobBudgetETB(
                                      widget.job.budget.toStringAsFixed(0)),
                                  colorScheme
                                      .secondary, // Accent color for budget
                                  theme),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Location and Date Details
                          _buildThemedDetailRow(
                              Icons.location_on_outlined,
                              appStrings.jobDetailLocationLabel,
                              widget.job.location,
                              theme),
                          _buildThemedDetailRow(
                              Icons.calendar_today_outlined,
                              appStrings.jobDetailPostedDateLabel,
                              DateFormat.yMMMd().format(widget.job.createdAt),
                              theme),
                          if (widget.job.scheduledDate !=
                              null) // This should now be a DateTime?
                            _buildThemedDetailRow(
                                Icons.event_available_outlined,
                                appStrings.jobDetailScheduledDateLabel,
                                // FIX: Ensure widget.job.scheduledDate is definitely DateTime?
                                DateFormat.yMMMEd()
                                    .format(widget.job.scheduledDate!),
                                theme), // Show scheduled date if available

                          const Divider(height: 32),

                          // Description Section
                          _buildSectionTitle(
                              appStrings.jobDetailDescriptionLabel, theme),
                          const SizedBox(height: 8),
                          Text(
                              widget.job.description.isEmpty
                                  ? appStrings.jobNoDescription
                                  : widget.job.description,
                              style: textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  height: 1.6)),

                          // Attachments Section (if any)
                          if (widget.job.attachments.isNotEmpty) ...[
                            const Divider(height: 32),
                            _buildSectionTitle(
                                appStrings.jobDetailAttachmentsLabel, theme),
                            const SizedBox(height: 12),
                            _buildAttachmentsGrid(
                                widget.job.attachments, theme),
                          ],

                          // Assigned Worker Section (if assigned)
                          if (_assignedWorker != null) ...[
                            const Divider(height: 32),
                            _buildSectionTitle(
                                appStrings.jobDetailAssignedWorkerLabel, theme),
                            const SizedBox(height: 12),
                            _buildThemedWorkerCard(_assignedWorker!, theme,
                                isAssigned:
                                    true), // Indicate this is the assigned worker
                          ]
                          // Applicants Section (if owner, job open, and applicants exist)
                          else if (_isJobOwner &&
                              widget.job.status == 'open' &&
                              _applicants.isNotEmpty) ...[
                            const Divider(height: 32),
                            _buildSectionTitle(
                                '${appStrings.jobDetailApplicantsLabel} (${_applicants.length})',
                                theme),
                            const SizedBox(height: 12),
                            _buildApplicantsList(), // Show list of applicants
                          ] else if (_isJobOwner &&
                              widget.job.status == 'open' &&
                              _applicants.isEmpty) ...[
                            const Divider(height: 32),
                            _buildSectionTitle(
                                appStrings.jobDetailApplicantsLabel, theme),
                            const SizedBox(height: 12),
                            Text(appStrings.jobDetailNoApplicantsYet,
                                style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant)),
                          ],

                          // Action Buttons Section
                          const SizedBox(height: 32),
                          if (!_isActionLoading) // Hide buttons while an action is processing
                            _buildActionButtonsWidget(appStrings, theme)
                          else
                            const Center(
                                heightFactor: 2,
                                child:
                                    CircularProgressIndicator()), // Show loader during actions

                          const SizedBox(height: 40), // Bottom padding
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(
        color: theme.colorScheme.primary, // Gold title
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildThemedStatusChip(
      String status, AppStrings appStrings, ThemeData theme) {
    final Color chipColor = status == 'open'
        ? theme.colorScheme.primary
        : Colors.green; // Get color based on status
    final Color onChipColor = chipColor.computeLuminance() > 0.5
        ? Colors.black
        : Colors.white; // Auto contrast text
    return Chip(
      label: Text(status.toUpperCase()),
      labelStyle: theme.textTheme.labelSmall
          ?.copyWith(color: onChipColor, fontWeight: FontWeight.bold),
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
    );
  }

  Widget _buildThemedInfoChip(
      IconData icon, String text, Color color, ThemeData theme) {
    final Color onChipColor =
        color.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    return Chip(
      avatar: Icon(icon, size: 16, color: onChipColor.withOpacity(0.8)),
      label: Text(text),
      labelStyle: theme.textTheme.bodyMedium
          ?.copyWith(color: onChipColor, fontWeight: FontWeight.w500),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
    );
  }

  Widget _buildThemedDetailRow(
      IconData icon, String label, String value, ThemeData theme,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              size: 20,
              color: theme.colorScheme.primary.withOpacity(0.9)), // Gold icon
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: valueColor ??
                        theme.colorScheme
                            .onSurface, // Use specific color or default
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsGrid(List<String> attachments, ThemeData theme) {
    // Simple grid view for attachments (assuming images for now)
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // Adjust number of columns
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.0, // Square aspect ratio
      ),
      itemCount: attachments.length,
      itemBuilder: (context, index) {
        final url = attachments[index];
        // Check if it looks like an image URL
        bool isImage = url.toLowerCase().contains('.jpg') ||
            url.toLowerCase().contains('.jpeg') ||
            url.toLowerCase().contains('.png') ||
            url.toLowerCase().contains('.gif');

        return InkWell(
          onTap: () => _launchUrl(url), // Open the attachment URL
          child: Container(
            decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: theme.colorScheme.outlineVariant.withOpacity(0.5))),
            child: isImage
                ? ClipRRect(
                    // Clip image to rounded corners
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                          child: SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2))),
                      errorWidget: (context, url, error) => Icon(
                          Icons.broken_image_outlined,
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  )
                : Column(
                    // Display icon for non-image files
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.insert_drive_file_outlined,
                          size: 32, color: theme.colorScheme.primary),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Text(
                          "View File",
                          style: theme.textTheme.labelSmall,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildThemedWorkerCard(Worker worker, ThemeData theme,
      {bool isAssigned = false}) {
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final appStrings = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer, // Use a themed container color
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor:
                colorScheme.secondaryContainer, // Accent container color
            // **IMPORTANT: Use CachedNetworkImageProvider for Supabase URL**
            backgroundImage: worker.profileImage.isNotEmpty
                ? CachedNetworkImageProvider(worker.profileImage)
                : null,
            child: worker.profileImage.isEmpty
                ? Icon(Icons.person_outline_rounded,
                    size: 30, color: colorScheme.onSecondaryContainer)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  worker.name,
                  style: textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  worker.profession,
                  style: textTheme.bodyMedium
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.star_rounded,
                        color: colorScheme.secondary, size: 18), // Gold star
                    const SizedBox(width: 4),
                    Text(
                      worker.rating.toStringAsFixed(1),
                      style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '(${worker.completedJobs} $appStrings)', // Reuse string
                      style: textTheme.bodySmall
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Action Button (Conditional)
          if (!isAssigned &&
              _isJobOwner) // Only show "Hire" if it's an applicant card viewed by owner
            ElevatedButton(
              onPressed: () => _assignWorker(worker.id),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary, // Gold
                foregroundColor: colorScheme.onPrimary,
              ),
              child: Text(appStrings.jobDetailApplicantHireButton),
            )
          else if (isAssigned) // Show View Profile for the assigned worker
            TextButton(
              onPressed: () {/* Navigate to worker profile screen */},
              child: Text(appStrings.jobDetailViewWorkerProfile),
            ),
        ],
      ),
    );
  }

  Widget _buildApplicantsList() {
    // Builds list of themed applicant cards
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _applicants.length,
      itemBuilder: (context, index) {
        return _buildThemedWorkerCard(_applicants[index], Theme.of(context),
            isAssigned: false);
      },
      separatorBuilder: (context, index) => const SizedBox(height: 12),
    );
  }

  Widget _buildActionButtonsWidget(AppStrings appStrings, ThemeData theme) {
    final colorScheme = theme.colorScheme;

    // --- Worker Actions ---
    if (_isWorker) {
      if (widget.job.status == 'open' && !_hasApplied) {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: _isApplying
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: colorScheme.onPrimary))
                : const Icon(Icons.send_rounded, size: 18),
            label: Text(_isApplying
                ? appStrings.jobDetailActionApplying
                : appStrings.jobDetailActionApply),
            onPressed: _isApplying ? null : _applyForJob,
            // Style uses theme automatically (primary button)
          ),
        );
      } else if (widget.job.status == 'open' && _hasApplied) {
        return Container(
          // Show confirmation/cancel button
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.secondary) // Green border
              ),
          child: Row(
            children: [
              Icon(Icons.check_circle_outline_rounded,
                  color: colorScheme.secondary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(appStrings.jobDetailActionApplied,
                      style: theme.textTheme.bodyMedium)),
              TextButton(
                onPressed: () {
                  _showSnackbar(appStrings.jobDetailFeatureComingSoon,
                      isError: false);
                }, // Placeholder for cancel
                child: Text(appStrings.jobDetailActionCancelApplication,
                    style: TextStyle(color: colorScheme.error)),
              )
            ],
          ),
        );
      } else if (widget.job.workerId == _currentUserId &&
          ['assigned', 'accepted', 'in_progress', 'started working']
              .contains(widget.job.status.toLowerCase())) {
        // Worker assigned actions
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.task_alt_rounded, size: 18),
            label: Text(appStrings.jobDetailActionMarkComplete),
            onPressed: _isActionLoading
                ? null
                : _markJobAsCompleted, // Use mark complete function
            style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.secondary), // Green button
          ),
        );
        // Add Contact Client button if needed
      }
    }
    // --- Client Actions ---
    else if (_isJobOwner) {
      if (widget.job.status == 'open' && _applicants.isNotEmpty) {
        // Button to view applicants (if not shown inline)
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.people_alt_outlined, size: 18),
            label: Text(
                "${appStrings.jobDetailViewApplicantsButton} (${_applicants.length})"),
            onPressed: () {
              /* Navigate to dedicated applicants screen if needed */
            },
            // Style uses theme automatically
          ),
        );
      } else if (widget.job.status == 'assigned') {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.payment_rounded, size: 18),
            label: Text(appStrings.jobDetailActionPayNow),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => PaymentScreen(job: widget.job))),
            // Style uses theme automatically
          ),
        );
        // Add Message Worker button if needed
      } else if (widget.job.status == 'completed') {
        // Add Leave Review button
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.rate_review_outlined, size: 18),
            label: Text(appStrings.jobDetailActionLeaveReview),
            onPressed: () {
              _showSnackbar(appStrings.jobDetailFeatureComingSoon,
                  isError: false); /* Navigate to review screen */
            },
            // Style uses theme automatically
          ),
        );
        // Add Post Similar Job button if needed
      }
    }

    // Default: No specific actions available for this user/status
    return const SizedBox.shrink();
  }
} // End of _JobDetailScreenState
