import 'package:flutter/material.dart';
import '../models/job.dart';
import '../services/firebase_service.dart';
import 'jobs/job_detail_screen.dart';

class JobHistoryScreen extends StatefulWidget {
  const JobHistoryScreen({super.key});

  @override
  _JobHistoryScreenState createState() => _JobHistoryScreenState();
}

class _JobHistoryScreenState extends State<JobHistoryScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = true;
  List<Job> _activeJobs = [];
  List<Job> _completedJobs = [];
  List<Job> _pendingJobs = [];
  String? _userType;
  TabController? _tabController;
  String currentUserId = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserType();
    _loadJobs();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadUserType() async {
    final userProfile = await _firebaseService.getCurrentUserProfile();
    if (userProfile != null && mounted) {
      setState(() {
        _userType = userProfile.role;
      });
      setState(() {
        currentUserId = userProfile.id;
      });
    }
  }

  Future<void> _loadJobs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final jobs = await _firebaseService.getJobs();

      final List<Job> active = [];
      final List<Job> completed = [];
      final List<Job> pending = [];

      for (var job in jobs) {
        final status = job.status;

        if (status == 'in_progress') {
          active.add(job);
        } else if (status == 'completed' || status == 'cancelled') {
          completed.add(job);
        } else if (status == 'pending' ||
            status == 'accepted' ||
            status == 'rejected') {
          pending.add(job);
        }
      }

      if (mounted) {
        setState(() {
          _activeJobs = active;
          _completedJobs = completed;
          _pendingJobs = pending;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading jobs: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadJobs,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Pending'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildJobList(_activeJobs, 'active'),
                _buildJobList(_pendingJobs, 'pending'),
                _buildJobList(_completedJobs, 'completed'),
              ],
            ),
    );
  }

  Widget _buildJobList(List<Job> jobs, String type) {
    if (jobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'active'
                  ? Icons.work_off
                  : (type == 'pending' ? Icons.pending : Icons.history),
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              type == 'active'
                  ? 'No active jobs'
                  : (type == 'pending'
                      ? 'No pending requests'
                      : 'No completed jobs'),
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadJobs,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: jobs.length,
        itemBuilder: (context, index) {
          final job = jobs[index];
          return _buildJobCard(job);
        },
      ),
    );
  }

  Widget _buildJobCard(Job job) {
    final bool isClient = _userType == 'client';
    final String status = job.status;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'Pending';
        statusIcon = Icons.pending;
        break;
      case 'accepted':
        statusColor = Colors.blue;
        statusText = 'Accepted';
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'Rejected';
        statusIcon = Icons.cancel;
        break;
      case 'in_progress':
        statusColor = Colors.green;
        statusText = 'In Progress';
        statusIcon = Icons.engineering;
        break;
      case 'completed':
        statusColor = Colors.purple;
        statusText = 'Completed';
        statusIcon = Icons.task_alt;
        break;
      case 'cancelled':
        statusColor = Colors.grey;
        statusText = 'Cancelled';
        statusIcon = Icons.block;
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Unknown';
        statusIcon = Icons.help;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => JobDetailScreen(job: job),
            ),
          ).then((_) => _loadJobs());
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      job.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusIcon,
                          size: 16,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person, color: Colors.blue, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      isClient ? job.workerName : job.clientName,
                      style: const TextStyle(color: Colors.blue),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.red, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      job.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.attach_money, color: Colors.green, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${job.budget.toStringAsFixed(0)} ETB',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (status == 'pending' && !isClient)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () async {
                        final success = await _firebaseService.updateJobStatus(
                          job.id,
                          job.clientId,
                          job.seekerId,
                          'rejected',
                        );
                        if (success && mounted) {
                          _loadJobs();
                        }
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Reject'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final success = await _firebaseService.updateJobStatus(
                          job.id,
                          job.clientId,
                          job.seekerId,
                          'accepted',
                        );
                        if (success && mounted) {
                          _loadJobs();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Accept'),
                    ),
                  ],
                ),
              if (status == 'accepted' && !isClient)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        final success = await _firebaseService.updateJobStatus(
                          job.id,
                          job.clientId,
                          job.seekerId,
                          'accepted',
                        );
                        if (success && mounted) {
                          _loadJobs();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Start Work'),
                    ),
                  ],
                ),
              if (status == 'in_progress' && !isClient)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        final success = await _firebaseService.updateJobStatus(
                          job.id,
                          job.clientId,
                          job.seekerId,
                          'accepted',
                        );
                        if (success && mounted) {
                          _loadJobs();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Mark as Completed'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
