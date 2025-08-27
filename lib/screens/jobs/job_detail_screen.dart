// lib/screens/jobs/job_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:animate_do/animate_do.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- Project Imports ---
import '../../models/job.dart';
import '../../models/worker.dart';
import '../../models/user.dart';
import '../../services/firebase_service.dart';
import '../../services/app_string.dart';
import '../payment/payment_screen.dart';
import '../chat_screen.dart';

class JobDetailScreen extends StatefulWidget {
  final Job job;
  const JobDetailScreen({super.key, required this.job});

  @override
  _JobDetailScreenState createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  late Stream<DocumentSnapshot> _jobStream;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = _firebaseService.getCurrentUser()?.uid;
    _jobStream = FirebaseFirestore.instance
        .collection('jobs')
        .doc(widget.job.id)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final appStrings = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: StreamBuilder<DocumentSnapshot>(
        stream: _jobStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return _JobDetailShimmer(jobTitle: widget.job.title);
          }
          if (snapshot.hasError) {
            return _ErrorState(
              message:
                  appStrings?.jobDetailErrorLoading ??
                  "Error loading job details.",
            );
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return _ErrorState(
              message:
                  appStrings?.emptyStateJobs ??
                  "This job is no longer available.",
            );
          }

          final jobData = snapshot.data!.data() as Map<String, dynamic>;
          jobData['id'] = snapshot.data!.id;
          final currentJob = Job.fromJson(jobData);

          return _JobDetailContent(
            job: currentJob,
            firebaseService: _firebaseService,
            currentUserId: _currentUserId,
          );
        },
      ),
    );
  }
}

// --- Main Content Widget ---
class _JobDetailContent extends StatelessWidget {
  final Job job;
  final FirebaseService firebaseService;
  final String? currentUserId;

  const _JobDetailContent({
    required this.job,
    required this.firebaseService,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appStrings = AppLocalizations.of(context);
    final isJobOwner = job.seekerId == currentUserId;

    String? headerImageUrl = job.attachments.isNotEmpty
        ? job.attachments.first
        : null;
    const placeholderImageUrl =
        'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&w=1740&q=80';

    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(
          headerImageUrl,
          placeholderImageUrl,
          theme,
          isJobOwner,
          context,
          appStrings,
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoChips(theme, appStrings),
                const SizedBox(height: 24),
                _buildDetailRows(theme, appStrings),
                const Divider(height: 40, thickness: 0.5),
                _buildClientInfoSection(theme, appStrings),
                _buildSection(
                  title: appStrings?.jobDetailDescriptionLabel ?? 'Description',
                  content: Text(
                    job.description.isEmpty
                        ? (appStrings?.jobNoDescription ??
                              'No description provided.')
                        : job.description,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.6,
                    ),
                  ),
                  theme: theme,
                ),
                if (job.attachments.isNotEmpty)
                  _buildSection(
                    title:
                        appStrings?.jobDetailAttachmentsLabel ?? 'Attachments',
                    content: _buildAttachmentsGrid(theme, context, appStrings),
                    theme: theme,
                  ),
                _buildAssignedWorkerSection(theme, appStrings),
                if (job.workerId != null && job.workerId!.isNotEmpty)
                  _buildReviewsSection(theme, appStrings, job.workerId!),
                _buildApplicantsSection(theme, isJobOwner, appStrings),
                const SizedBox(height: 32),
                _ActionButtons(
                  job: job,
                  currentUserId: currentUserId,
                  firebaseService: firebaseService,
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClientInfoSection(ThemeData theme, AppStrings? appStrings) {
    return _buildSection(
      title: appStrings?.jobDetailAboutTheClient ?? 'About the Client',
      content: FutureBuilder<AppUser?>(
        future: firebaseService.getUser(job.seekerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return Text(
              appStrings?.profileDataUnavailable ?? 'Client data unavailable.',
            );
          }
          final client = snapshot.data!;
          return _ClientInfoCard(client: client);
        },
      ),
      theme: theme,
    );
  }

  SliverAppBar _buildSliverAppBar(
    String? imageUrl,
    String placeholder,
    ThemeData theme,
    bool isJobOwner,
    BuildContext context,
    AppStrings? appStrings,
  ) {
    return SliverAppBar(
      expandedHeight: 280.0,
      pinned: true,
      stretch: true,
      backgroundColor: theme.colorScheme.surfaceContainer,
      foregroundColor: theme.colorScheme.onSurface,
      elevation: 2,
      actions: [
        if (isJobOwner && job.status != 'completed')
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            color: theme.colorScheme.surfaceContainerHigh,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) =>
                _handleMenuSelection(value, context, appStrings),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(
                    Icons.edit_note_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(appStrings?.profileEditButton ?? 'Edit Job'),
                ),
              ),
              if (job.workerId != null &&
                  job.workerId!.isNotEmpty &&
                  job.status.toLowerCase() != 'completed' &&
                  job.status.toLowerCase() != 'paycompleted')
                PopupMenuItem(
                  value: 'change_worker',
                  child: ListTile(
                    leading: Icon(
                      Icons.change_circle_outlined,
                      color: theme.colorScheme.secondary,
                    ),
                    title: Text('Change Worker'),
                  ),
                ),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(
                    Icons.delete_forever_rounded,
                    color: theme.colorScheme.error,
                  ),
                  title: Text(
                    appStrings?.jobDetailDeleteConfirmDelete ?? 'Delete Job',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              ),
            ],
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Hero(
          tag: 'job_image_${job.id}',
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: imageUrl ?? placeholder,
                fit: BoxFit.cover,
                placeholder: (c, u) =>
                    Container(color: theme.colorScheme.surfaceContainer),
                errorWidget: (c, u, e) =>
                    Image.network(placeholder, fit: BoxFit.cover),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.surface,
                      theme.colorScheme.surface.withOpacity(0.0),
                    ],
                    stops: const [0.0, 0.7],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
            ],
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 60, right: 60, bottom: 16),
        centerTitle: true,
        title: Text(
          job.title,
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(color: Colors.black.withOpacity(0.6), blurRadius: 6),
            ],
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        stretchModes: const [StretchMode.zoomBackground, StretchMode.fadeTitle],
      ),
    );
  }

  void _handleMenuSelection(
    String value,
    BuildContext context,
    AppStrings? appStrings,
  ) {
    if (value == 'edit') {
      _showSnackbar(
        context,
        appStrings?.jobDetailFeatureComingSoon ?? 'Edit feature coming soon!',
        isError: false,
      );
    } else if (value == 'delete') {
      _showDeleteConfirmation(context, appStrings);
    } else if (value == 'change_worker') {
      _showChangeWorkerConfirmation(context, appStrings);
    }
  }

  void _showChangeWorkerConfirmation(
    BuildContext context,
    AppStrings? appStrings,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Change Assigned Worker?'),
        content: Text(
          'This will remove the current worker and reopen the job for applications. The current worker will be notified. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(appStrings?.generalCancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                // NOTE: Assumes `changeAssignedWorker` exists in FirebaseService
                await firebaseService.changeAssignedWorker(
                  jobId: job.id,
                  clientId: job.seekerId,
                  currentlyAssignedWorkerId: job.workerId!,
                );
                if (context.mounted)
                  _showSnackbar(
                    context,
                    'Worker has been unassigned. The job is now open.',
                    isError: false,
                  );
              } catch (e) {
                if (context.mounted)
                  _showSnackbar(
                    context,
                    'Failed to change worker.',
                    isError: true,
                  );
              }
            },
            child: Text(
              'Confirm',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, AppStrings? appStrings) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(appStrings?.jobDetailDeleteConfirmTitle ?? 'Delete Job?'),
        content: Text(
          appStrings?.jobDetailDeleteConfirmContent ??
              'This action is permanent and cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(appStrings?.generalCancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await firebaseService.deleteJob(job.id);
                if (context.mounted) {
                  _showSnackbar(
                    context,
                    appStrings?.jobDetailSuccessDeleted ??
                        'Job deleted successfully.',
                    isError: false,
                  );
                  Navigator.pop(context, true);
                }
              } catch (e) {
                if (context.mounted) {
                  _showSnackbar(
                    context,
                    appStrings?.jobDetailErrorDeleting ??
                        'Failed to delete job.',
                    isError: true,
                  );
                }
              }
            },
            child: Text(
              appStrings?.jobDetailDeleteConfirmDelete ?? 'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required Widget content,
    required ThemeData theme,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeInUp(
            delay: const Duration(milliseconds: 100),
            child: Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          FadeInUp(delay: const Duration(milliseconds: 200), child: content),
        ],
      ),
    );
  }

  Widget _buildInfoChips(ThemeData theme, AppStrings? appStrings) {
    return FadeInUp(
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _StatusChip(status: job.status),
          _InfoChip(
            icon: Icons.attach_money_rounded,
            text:
                appStrings?.jobBudgetETB(job.budget.toStringAsFixed(0)) ??
                'ETB ${job.budget.toStringAsFixed(0)}',
            color: theme.colorScheme.tertiary,
          ),
          if (job.isUrgent)
            _InfoChip(
              icon: Icons.flash_on_rounded,
              text: appStrings?.createJobUrgentLabel ?? 'Urgent',
              color: Colors.red.shade700,
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRows(ThemeData theme, AppStrings? appStrings) {
    return Column(
      children: [
        _DetailRow(
          icon: Icons.category_outlined,
          label: appStrings?.createJobCategoryLabel ?? 'Category',
          value: '${job.category} / ${job.skill}',
          delay: 50,
        ),
        _DetailRow(
          icon: Icons.location_on_outlined,
          label: appStrings?.jobDetailLocationLabel ?? 'Location',
          value: job.location,
          delay: 100,
        ),
        _DetailRow(
          icon: Icons.calendar_today_outlined,
          label: appStrings?.jobDetailPostedDateLabel ?? 'Posted',
          value: DateFormat.yMMMd().format(job.createdAt),
          delay: 150,
        ),
        if (job.scheduledDate != null)
          _DetailRow(
            icon: Icons.event_available_outlined,
            label: appStrings?.jobDetailScheduledDateLabel ?? 'Scheduled For',
            value: DateFormat.yMMMEd().format(job.scheduledDate!),
            delay: 200,
          ),
      ],
    );
  }

  Widget _buildAttachmentsGrid(
    ThemeData theme,
    BuildContext context,
    AppStrings? appStrings,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.0,
      ),
      itemCount: job.attachments.length,
      itemBuilder: (context, index) {
        final url = job.attachments[index];
        bool isImage = [
          '.jpg',
          '.jpeg',
          '.png',
          '.gif',
          '.webp',
        ].any((ext) => url.toLowerCase().contains(ext));

        return InkWell(
          onTap: () => _launchUrl(url, context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withOpacity(0.5),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: isImage
                  ? CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      placeholder: (c, u) => const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (c, u, e) => Icon(
                        Icons.broken_image_outlined,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.insert_drive_file_outlined,
                          size: 32,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Text(
                            appStrings?.viewButton ?? "View File",
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAssignedWorkerSection(ThemeData theme, AppStrings? appStrings) {
    if (job.workerId == null || job.workerId!.isEmpty) {
      return const SizedBox.shrink();
    }
    return FutureBuilder<Worker?>(
      future: firebaseService.getWorkerById(job.workerId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }
        final worker = snapshot.data!;
        return _buildSection(
          title: appStrings?.jobDetailAssignedWorkerLabel ?? 'Assigned Worker',
          content: _WorkerCard(
            worker: worker,
            action: TextButton(
              onPressed: () {}, // TODO: Implement navigation to worker profile
              child: Text(
                appStrings?.jobDetailViewWorkerProfile ?? 'View Profile',
              ),
            ),
          ),
          theme: theme,
        );
      },
    );
  }

  Widget _buildReviewsSection(
    ThemeData theme,
    AppStrings? appStrings,
    String workerId,
  ) {
    return _buildSection(
      title: 'Reviews for this Worker',
      content: _ReviewList(
        workerId: workerId,
        firebaseService: firebaseService,
      ),
      theme: theme,
    );
  }

  Widget _buildApplicantsSection(
    ThemeData theme,
    bool isJobOwner,
    AppStrings? appStrings,
  ) {
    if (!isJobOwner || job.status != 'open') return const SizedBox.shrink();
    return FutureBuilder<List<Worker>>(
      key: ValueKey(job.applications.join(',')),
      future: firebaseService
          .getJobApplicants(job.id)
          .then((data) => data.map((d) => Worker.fromJson(d)).toList()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (!snapshot.hasData)
          return Text(
            appStrings?.applicantLoadError ?? 'Could not load applicants.',
          );
        final applicants = snapshot.data!;
        return _buildSection(
          title:
              '${appStrings?.jobDetailApplicantsLabel ?? 'Applicants'} (${applicants.length})',
          content: applicants.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      appStrings?.jobDetailNoApplicantsYet ??
                          'No applications received yet.',
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: applicants.length,
                  itemBuilder: (context, index) => _WorkerCard(
                    worker: applicants[index],
                    action: ElevatedButton(
                      onPressed: () => _assignWorker(
                        context,
                        applicants[index].id,
                        appStrings,
                      ),
                      child: Text(
                        appStrings?.jobDetailApplicantHireButton ?? 'Hire',
                      ),
                    ),
                  ),
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                ),
          theme: theme,
        );
      },
    );
  }

  void _showSnackbar(
    BuildContext context,
    String message, {
    required bool isError,
  }) {
    if (!context.mounted) return;
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: isError
                ? theme.colorScheme.onErrorContainer
                : theme.colorScheme.onTertiaryContainer,
          ),
        ),
        backgroundColor: isError
            ? theme.colorScheme.errorContainer
            : theme.colorScheme.tertiaryContainer,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _launchUrl(String url, BuildContext context) async {
    final appStrings = AppLocalizations.of(context);
    if (!await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    )) {
      if (context.mounted) {
        _showSnackbar(
          context,
          appStrings?.errorCouldNotLaunchUrl ?? 'Could not launch URL',
          isError: true,
        );
      }
    }
  }

  Future<void> _assignWorker(
    BuildContext context,
    String workerId,
    AppStrings? appStrings,
  ) async {
    try {
      await firebaseService.assignJob(job.id, workerId);
      if (context.mounted) {
        _showSnackbar(
          context,
          appStrings?.jobDetailSuccessWorkerAssigned ??
              'Worker has been assigned!',
          isError: false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackbar(
          context,
          appStrings?.jobDetailErrorAssigningWorker ??
              'Failed to assign worker.',
          isError: true,
        );
      }
    }
  }
}

// --- Action Buttons ---
class _ActionButtons extends StatefulWidget {
  final Job job;
  final String? currentUserId;
  final FirebaseService firebaseService;
  const _ActionButtons({
    required this.job,
    this.currentUserId,
    required this.firebaseService,
  });
  @override
  __ActionButtonsState createState() => __ActionButtonsState();
}

class __ActionButtonsState extends State<_ActionButtons> {
  bool _isActionLoading = false;

  @override
  Widget build(BuildContext context) {
    if (_isActionLoading) {
      return const Center(heightFactor: 2, child: CircularProgressIndicator());
    }
    final theme = Theme.of(context);
    final appStrings = AppLocalizations.of(context);

    return FutureBuilder<AppUser?>(
      future: widget.firebaseService.getCurrentUserProfile(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 50);
        }

        final isJobOwner = widget.job.seekerId == widget.currentUserId;
        final isWorkerUser = userSnapshot.data?.role == 'worker';
        final isAssignedWorker = widget.job.workerId == widget.currentUserId;
        final hasApplied = widget.job.applications.contains(
          widget.currentUserId,
        );
        final status = widget.job.status.toLowerCase();

        if (isWorkerUser) {
          if (isAssignedWorker && status != 'open') {
            // ... code for assigned worker (no change here) ...
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ActionButton(
                  label:
                      appStrings?.jobDetailActionContactClient ??
                      'Message Client',
                  icon: Icons.chat_bubble_outline_rounded,
                  onPressed: () =>
                      _navigateToChat(context, widget.job.seekerId),
                  backgroundColor: theme.colorScheme.secondary,
                ),
                if (status != 'completed' && status != 'paycompleted') ...[
                  const SizedBox(height: 12),
                  _ActionButton(
                    label:
                        appStrings?.jobDetailActionMarkComplete ??
                        'Mark as Completed',
                    icon: Icons.task_alt_rounded,
                    onPressed: _markJobAsCompleted,
                    backgroundColor: Colors.green.shade700,
                  ),
                ],
              ],
            );
          }
          if (status == 'open' && !hasApplied) {
            // --- THIS IS THE MAIN FIX ---
            return Row(
              children: [
                // MESSAGE BUTTON
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 20,
                    ),
                    label: Text(
                      appStrings?.jobDetailActionContactClient ?? 'Message',
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: theme.colorScheme.secondary,
                      side: BorderSide(color: theme.colorScheme.secondary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () =>
                        _navigateToChat(context, widget.job.seekerId),
                  ),
                ),
                const SizedBox(width: 12),
                // APPLY BUTTON
                Expanded(
                  flex: 2, // Make the apply button slightly larger
                  child: _ActionButton(
                    label: appStrings?.jobDetailActionApply ?? 'Apply Now',
                    icon: Icons.send_rounded,
                    onPressed: _applyForJob,
                  ),
                ),
              ],
            );
            // -------------------------
          }
          if (status == 'open' && hasApplied) {
            return _ConfirmationBox(
              text:
                  appStrings?.jobDetailActionApplied ??
                  'You have applied for this job.',
              icon: Icons.check_circle_outline_rounded,
              color: theme.colorScheme.tertiary,
            );
          }
        }
        // --- Job Owner Actions ---
        else if (isJobOwner) {
          if ((status == 'assigned' ||
                  status == 'in_progress' ||
                  status == 'started working') &&
              widget.job.workerId != null) {
            return _ActionButton(
              label:
                  appStrings?.jobDetailActionMessageWorker ?? 'Message Worker',
              icon: Icons.chat_bubble_outline_rounded,
              onPressed: () => _navigateToChat(context, widget.job.workerId!),
              backgroundColor: theme.colorScheme.secondary,
            );
          }
          if (status == 'completed') {
            return _ActionButton(
              label: appStrings?.jobDetailActionPayNow ?? 'Proceed to Payment',
              icon: Icons.payment_rounded,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PaymentScreen(job: widget.job),
                ),
              ),
            );
          }
          if (status == 'paycompleted') {
            return _ActionButton(
              label: appStrings?.jobDetailActionLeaveReview ?? 'Leave a Review',
              icon: Icons.rate_review_outlined,
              onPressed: () =>
                  _showReviewDialog(context, widget.job.workerId!, appStrings),
            );
          }
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _showReviewDialog(
    BuildContext context,
    String workerId,
    AppStrings? appStrings,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ReviewDialog(
        firebaseService: widget.firebaseService,
        workerId: workerId,
        jobTitle: widget.job.title,
        clientPhotoUrl: (widget.firebaseService.getCurrentUser()?.photoURL),
      ),
    );
  }

  void _showSnackbar(
    BuildContext context,
    String message, {
    required bool isError,
  }) {
    if (!context.mounted) return;
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: isError
                ? theme.colorScheme.onErrorContainer
                : theme.colorScheme.onTertiaryContainer,
          ),
        ),
        backgroundColor: isError
            ? theme.colorScheme.errorContainer
            : theme.colorScheme.tertiaryContainer,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _navigateToChat(BuildContext context, String otherUserId) {
    if (widget.currentUserId == null) {
      final appStrings = AppLocalizations.of(context);
      _showSnackbar(
        context,
        appStrings?.snackPleaseLogin ?? 'You must be logged in to chat.',
        isError: true,
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UnifiedChatScreen(
          // <-- FIX: Use the new name
          initialSelectedUserId: otherUserId, // <-- FIX: Use the new parameter
        ),
      ),
    );
  }

  Future<void> _applyForJob() async {
    if (widget.currentUserId == null) return;
    final appStrings = AppLocalizations.of(context);
    setState(() => _isActionLoading = true);
    try {
      await widget.firebaseService.applyForJob(
        widget.job.id,
        widget.currentUserId!,
      );
      if (mounted) {
        _showSnackbar(
          context,
          appStrings?.jobDetailSuccessApplied ?? 'Application sent!',
          isError: false,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackbar(
          context,
          appStrings?.jobDetailErrorApplying ?? 'Failed to apply.',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _markJobAsCompleted() async {
    final appStrings = AppLocalizations.of(context);
    setState(() => _isActionLoading = true);
    try {
      await widget.firebaseService.updateJobStatus(
        widget.job.id,
        widget.job.workerId,
        widget.job.seekerId,
        'completed',
      );
      if (mounted) {
        _showSnackbar(
          context,
          appStrings?.jobDetailSuccessMarkedComplete ??
              'Job marked as completed!',
          isError: false,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackbar(
          context,
          appStrings?.jobDetailErrorMarkingComplete ??
              'Could not mark job as complete.',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }
}

// --- Reusable, Stylized UI Components ---
class _JobDetailShimmer extends StatelessWidget {
  final String jobTitle;
  const _JobDetailShimmer({required this.jobTitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Shimmer.fromColors(
      baseColor: theme.colorScheme.surfaceContainerHighest,
      highlightColor: theme.colorScheme.surfaceContainer,
      child: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 280.0,
            pinned: true,
            backgroundColor: theme.colorScheme.surface,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(color: Colors.white),
              centerTitle: true,
              title: Text(
                jobTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.transparent,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _shimmerBox(120, 36),
                      const SizedBox(width: 12),
                      _shimmerBox(150, 36),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _shimmerBox(double.infinity, 20),
                  const SizedBox(height: 12),
                  _shimmerBox(double.infinity, 20),
                  const Divider(height: 40),
                  _shimmerBox(150, 24),
                  const SizedBox(height: 16),
                  _shimmerBox(double.infinity, 20),
                  const SizedBox(height: 12),
                  _shimmerBox(double.infinity, 20),
                  const SizedBox(height: 12),
                  _shimmerBox(200, 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shimmerBox(double width, double height) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Theme.of(context).colorScheme.error,
              size: 50,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)?.back ?? 'Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appStrings = AppLocalizations.of(context);
    final Color color;
    final String label;

    switch (status.toLowerCase()) {
      case 'open':
        color = theme.colorScheme.primary;
        label = appStrings?.jobStatusOpen ?? 'OPEN';
        break;
      case 'assigned':
        color = Colors.orange.shade700;
        label = appStrings?.jobStatusAssigned ?? 'ASSIGNED';
        break;
      case 'in_progress':
      case 'started working':
        color = Colors.blue.shade700;
        label = appStrings?.jobStatusInProgress ?? 'IN PROGRESS';
        break;
      case 'completed':
        color = Colors.green.shade700;
        label = appStrings?.jobStatusCompleted ?? 'COMPLETED';
        break;
      case 'paycompleted':
        color = Colors.teal.shade600;
        label = 'PAID & CLOSED';
        break;
      default:
        color = Colors.grey.shade600;
        label = (appStrings?.getStatusName(status) ?? status).toUpperCase();
    }
    return Chip(
      label: Text(label),
      labelStyle: theme.textTheme.labelMedium?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      side: BorderSide.none,
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _InfoChip({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Chip(
      avatar: Icon(icon, size: 18, color: Colors.white70),
      label: Text(text),
      labelStyle: theme.textTheme.bodyMedium?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w500,
      ),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      side: BorderSide.none,
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final int delay;
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.delay = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FadeInUp(
      delay: Duration(milliseconds: delay),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22, color: theme.colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
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
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkerCard extends StatelessWidget {
  final Worker worker;
  final Widget action;
  const _WorkerCard({required this.worker, required this.action});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appStrings = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: theme.colorScheme.secondaryContainer,
            backgroundImage: worker.profileImage.isNotEmpty
                ? CachedNetworkImageProvider(worker.profileImage)
                : null,
            child: worker.profileImage.isEmpty
                ? Icon(
                    Icons.person,
                    size: 30,
                    color: theme.colorScheme.onSecondaryContainer,
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  worker.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  worker.profession,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '${worker.rating.toStringAsFixed(1)} (${appStrings?.jobsCount(worker.completedJobs) ?? '${worker.completedJobs} jobs'})',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          action,
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 20),
        label: Text(label),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontSize: 16),
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _ConfirmationBox extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  const _ConfirmationBox({
    required this.text,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientInfoCard extends StatelessWidget {
  final AppUser client;
  const _ClientInfoCard({required this.client});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage =
        client.profileImage != null && client.profileImage!.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: theme.colorScheme.secondaryContainer,
            backgroundImage: hasImage
                ? CachedNetworkImageProvider(client.profileImage!)
                : null,
            child: !hasImage
                ? Icon(
                    Icons.person,
                    size: 30,
                    color: theme.colorScheme.onSecondaryContainer,
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewDialog extends StatefulWidget {
  final FirebaseService firebaseService;
  final String workerId;
  final String? jobTitle;
  final String? clientPhotoUrl;

  const _ReviewDialog({
    required this.firebaseService,
    required this.workerId,
    this.jobTitle,
    this.clientPhotoUrl,
  });

  @override
  _ReviewDialogState createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  double _rating = 4.0;
  final _commentController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitReview() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please write a comment.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await widget.firebaseService.addReview(
        widget.workerId,
        _commentController.text.trim(),
        _rating,
        jobTitle: widget.jobTitle,
        clientPhotoUrl: widget.clientPhotoUrl,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Review submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit review.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Leave a Review', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 16),
          Center(
            child: _RatingBar(
              rating: _rating,
              onRatingUpdate: (rating) => setState(() => _rating = rating),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentController,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              labelText: 'Share your experience',
              alignLabelWithHint: true,
            ),
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _submitReview,
              icon: _isLoading
                  ? const SizedBox.shrink()
                  : const Icon(Icons.send_rounded),
              label: _isLoading
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    )
                  : const Text('Submit Review'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _RatingBar extends StatelessWidget {
  final double rating;
  final Function(double) onRatingUpdate;
  const _RatingBar({required this.rating, required this.onRatingUpdate});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return IconButton(
          onPressed: () => onRatingUpdate(index + 1.0),
          icon: Icon(
            index < rating ? Icons.star_rounded : Icons.star_border_rounded,
            color: Colors.amber,
            size: 40,
          ),
        );
      }),
    );
  }
}

class _ReviewList extends StatelessWidget {
  final String workerId;
  final FirebaseService firebaseService;

  const _ReviewList({required this.workerId, required this.firebaseService});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: firebaseService.streamWorkerReviews(workerId),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final reviews = snapshot.data!;
        if (reviews.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Text('No reviews yet for this worker.')),
          );
        }
        return ListView.separated(
          itemCount: reviews.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final review = reviews[index];
            final hasImage =
                review['clientPhotoUrl'] != null &&
                review['clientPhotoUrl'].isNotEmpty;
            return Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: hasImage
                              ? CachedNetworkImageProvider(
                                  review['clientPhotoUrl'],
                                )
                              : null,
                          child: !hasImage ? const Icon(Icons.person) : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                review['userName'] ?? 'Client',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                DateFormat.yMMMd().format(
                                  (review['createdAt'] as Timestamp).toDate(),
                                ),
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              Icons.star,
                              color: i < (review['rating'] ?? 0)
                                  ? Colors.amber
                                  : Colors.grey.shade300,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      review['comment'] ?? '',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            );
          },
          separatorBuilder: (context, index) => const SizedBox(height: 8),
        );
      },
    );
  }
}
