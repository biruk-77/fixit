import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <-- Import for PlatformException
import 'package:table_calendar/table_calendar.dart';
import 'package:file_picker/file_picker.dart'; // For general files
import 'package:image_picker/image_picker.dart'; // For camera/gallery images (XFile)
import 'dart:io';
// Required for Uint8List
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:animate_do/animate_do.dart';
import '../../models/worker.dart';
import '../../services/firebase_service.dart';
import '../../services/app_string.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateJobScreen extends StatefulWidget {
  final String? preselectedWorkerId;

  const CreateJobScreen({super.key, this.preselectedWorkerId});

  @override
  _CreateJobScreenState createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends State<CreateJobScreen>
    with SingleTickerProviderStateMixin {
  // Services and Keys
  final FirebaseService _firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  // --- State Variables ---
  bool _isLoading = false;
  bool _isUploading = false;
  Worker? _selectedWorker;
  DateTime? _selectedDate;
  DateTime _focusedDay = DateTime.now();
  final List<dynamic> _attachments = []; // Unified list for XFile/PlatformFile
  bool _isUrgent = false;
  String? _selectedCategory;
  String? _selectedSkill;
  Map<String, List<String>> _jobCategories = {};

  // Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  final _locationController = TextEditingController();

  late AnimationController _buttonAnimationController;

  @override
  void initState() {
    super.initState();
    _buttonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    final appStrings = AppLocalizations.of(context);
    if (appStrings != null) {
      if (mounted) {
        setState(() => _jobCategories = appStrings.jobCategoriesAndSkills);
      }
    } else {
      debugPrint(
        "Warning: AppStrings not available for categories. Using fallback.",
      );
      if (mounted) setState(() => _jobCategories = _getDefaultCategories());
    }
    if (widget.preselectedWorkerId != null && mounted) {
      await _loadPreselectedWorker();
    }
  }

  Map<String, List<String>> _getDefaultCategories() {
    // Fallback categories
    return {
      'Plumbing': ['Leak Repair'],
      'Other': ['Specify in Description'],
    };
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    _locationController.dispose();
    _buttonAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadPreselectedWorker() async {
    if (widget.preselectedWorkerId == null || !mounted) return;
    final appStrings = AppLocalizations.of(context);
    if (appStrings == null) return;
    if (mounted) {
      setState(
        () => _isLoading = true,
      ); // Show loading specifically for worker fetch
    }
    try {
      final workerData = await _firebaseService.getWorkerById(
        widget.preselectedWorkerId!,
      );
      if (mounted) {
        setState(() {
          _selectedWorker = workerData;
          if (workerData?.location != null) {
            _locationController.text = workerData!.location;
          }
          if (workerData?.profession != null &&
              _jobCategories.containsKey(workerData!.profession)) {
            _selectedCategory = workerData.profession;
            _selectedSkill = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackbar(appStrings.createJobSnackbarErrorWorker, isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Attachment Upload (ADAPTED to use existing service method) ---
  Future<List<String>> _uploadAttachments() async {
    if (_attachments.isEmpty || !mounted) return [];
    final appStrings = AppLocalizations.of(context);
    if (appStrings == null) return [];
    final user = _firebaseService.getCurrentUser();
    if (user == null) {
      _showSnackbar(appStrings.snackPleaseLogin, isError: true);
      return [];
    }

    if (mounted) setState(() => _isUploading = true);
    List<String> downloadUrls = [];
    List<dynamic> successfullyUploaded = [];

    try {
      debugPrint(
        'Starting upload loop (Adapter) for ${_attachments.length} attachments...',
      );
      for (int i = 0; i < _attachments.length; i++) {
        if (!mounted) return [];
        final attachment = _attachments[i];
        PlatformFile? platformFileToUpload;

        // --- Prepare PlatformFile data ---
        if (attachment is PlatformFile) {
          platformFileToUpload = attachment;
          debugPrint("  Prep: PlatformFile ${i + 1}: ${platformFileToUpload.name}");
        } else if (attachment is XFile) {
          debugPrint("  Prep: Converting XFile ${i + 1}: ${attachment.name}...");
          Uint8List? bytes;
          int size = 0;
          try {
            size = await attachment.length();
            if (kIsWeb) bytes = await attachment.readAsBytes();
          } catch (e) {
            debugPrint("    Error reading XFile data: $e");
            _showSnackbar(appStrings.snackErrorReadFile, isError: true);
            continue;
          }
          platformFileToUpload = PlatformFile(
            name: attachment.name,
            path: kIsWeb ? null : attachment.path,
            size: size,
            bytes: bytes,
          );
          debugPrint("    Prep: Conversion complete.");
        } else {
          debugPrint("  Skipping unknown type at index $i");
          _showSnackbar(appStrings.snackSkippingUnknownType, isError: true);
          continue;
        }
        // --- End Prep ---

        debugPrint(
          "    Calling _firebaseService.uploadJobAttachment for ${platformFileToUpload.name}...",
        );
        // *** CALL THE METHOD THAT ACCEPTS PlatformFile ***
        final String? url = await _firebaseService.uploadJobAttachment(
          platformFile: platformFileToUpload,
          userId: user.uid,
        );

        if (url != null && url.isNotEmpty) {
          debugPrint("    Upload Success! URL: $url");
          downloadUrls.add(url);
          successfullyUploaded.add(attachment);
        } else {
          debugPrint(
            "    Upload Failed for ${platformFileToUpload.name}. Skipping.",
          );
        }
      } // End for loop

      if (mounted) {
        setState(() {
          _attachments.removeWhere(
            (item) => successfullyUploaded.contains(item),
          );
        });
      }
      debugPrint('Finished upload loop. ${downloadUrls.length} successful URLs.');
      return downloadUrls;
    } catch (e, s) {
      debugPrint('Error during adapted upload process: $e\n$s');
      if (mounted) {
        _showSnackbar(appStrings.createJobSnackbarErrorUpload, isError: true);
      }
      return [];
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // --- Job Creation ---
  Future<void> _createJob() async {
    if (!mounted) return;
    final appStrings = AppLocalizations.of(context);
    if (appStrings == null) return;
    if (!_formKey.currentState!.validate()) {
      _showSnackbar(appStrings.createJobSnackbarErrorForm, isError: true);
      return;
    }
    if (_selectedCategory == null || _selectedCategory!.isEmpty) {
      _showSnackbar(appStrings.createJobErrorCategory, isError: true);
      return;
    }
    bool requiresSkill =
        _jobCategories[_selectedCategory!]?.first !=
        appStrings.specifyInDescription;
    if (requiresSkill && (_selectedSkill == null || _selectedSkill!.isEmpty)) {
      _showSnackbar(appStrings.createJobErrorSkill, isError: true);
      return;
    }
    final currentUser = _firebaseService.getCurrentUser();
    if (currentUser == null) {
      _showSnackbar(appStrings.snackPleaseLogin, isError: true);
      return;
    }

    if (mounted) setState(() => _isLoading = true);
    try {
      List<String> attachmentUrls = [];
      int initialAttachmentCount = _attachments.length;
      if (initialAttachmentCount > 0) {
        debugPrint("Starting attachment upload process...");
        attachmentUrls = await _uploadAttachments();
        debugPrint(
          "Attachment upload finished. URLs count: ${attachmentUrls.length}",
        );
        if (_attachments.isNotEmpty && !_isUploading) {
          debugPrint("Some attachments failed to upload.");
          if (mounted) {
            _showSnackbar(
              appStrings.createJobSnackbarErrorUploadPartial,
              isError: true,
            );
            setState(() => _isLoading = false);
          }
          return;
        } else if (attachmentUrls.isEmpty &&
            initialAttachmentCount > 0 &&
            !_isUploading) {
          debugPrint("All attachments failed.");
          if (mounted) {
            _showSnackbar(
              appStrings.createJobSnackbarErrorUpload,
              isError: true,
            );
            setState(() => _isLoading = false);
          }
          return;
        }
      }

      final jobData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'skill': _selectedSkill ?? appStrings.specifyInDescription,
        'budget': double.tryParse(_budgetController.text.trim()) ?? 0.0,
        'location': _locationController.text.trim(),
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
        'seekerId': currentUser.uid,
        'clientName': currentUser.displayName ?? 'Client',
        'clientPhotoUrl': currentUser.photoURL ?? '',
        'scheduledDate': _selectedDate != null
            ? Timestamp.fromDate(_selectedDate!)
            : null,
        'attachments': attachmentUrls,
        'isUrgent': _isUrgent,
        'applications': _selectedWorker != null ? [_selectedWorker!.id] : [],
        'workerId': null,
        'clientPhone': currentUser.phoneNumber,
        'clientEmail': currentUser.email,
      };
      debugPrint("Creating job document in Firestore...");
      String jobId = await _firebaseService.createJob(jobData);
      debugPrint("Job document created with ID: $jobId.");

      await _firebaseService.createNotification(
        userId: currentUser.uid,
        title: "Job Posted",
        body: "You posted a new job: '${_titleController.text.trim()}'",
        type: "job_posted_self",
        data: {
          'jobId': jobId,
          'jobTitle': _titleController.text.trim(),
          'category': _selectedCategory,
          'jobImageUrl': attachmentUrls.isNotEmpty
              ? attachmentUrls.first
              : null,
        },
      );
      debugPrint('Sent notification to posting user: ${currentUser.uid}');

      final workersQuery = await FirebaseFirestore.instance
          .collection('professionals')
          .where('role', isEqualTo: 'worker')
          .where('profession', isEqualTo: _selectedCategory)
          .get();

      debugPrint(
        'Found \'${workersQuery.docs.length}\' workers with profession: \'$_selectedCategory\'.',
      );
      int notifiedCount = 0;
      for (final doc in workersQuery.docs) {
        await _firebaseService.createNotification(
          userId: doc.id,
          title: "New Job: $_selectedCategory",
          body:
              "A new job '${_titleController.text.trim()}' is available near you!",
          type: "job_posted",
          data: {
            'jobId': jobId,
            'jobTitle': _titleController.text.trim(),
            'category': _selectedCategory,
            'budget': double.tryParse(_budgetController.text.trim()) ?? 0.0,
            'location': _locationController.text.trim(),
            'isUrgent': _isUrgent,
            'jobImageUrl': attachmentUrls.isNotEmpty
                ? attachmentUrls.first
                : null,
            'clientName': currentUser.displayName ?? 'A Client',
            'clientImageUrl': currentUser.photoURL,
          },
        );
        notifiedCount++;
      }
      debugPrint('Sent notifications to $notifiedCount workers.');
      if (!mounted) return;
      _showSnackbar(appStrings.createJobSnackbarSuccess, isError: false);
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } catch (e, s) {
      debugPrint('Error during job creation: $e\n$s');
      if (mounted) {
        _showSnackbar(appStrings.createJobSnackbarError, isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Main Build Method (Enhanced UI) ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final appStrings = AppLocalizations.of(context);

    if (appStrings == null ||
        _jobCategories.isEmpty ||
        (widget.preselectedWorkerId != null &&
            _selectedWorker == null &&
            _isLoading)) {
      return Scaffold(
        appBar: AppBar(
          title: Text(appStrings?.createJobAppBarTitle ?? "Create Job"),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    bool skillDropdownEnabled =
        _selectedCategory != null &&
        _jobCategories.containsKey(_selectedCategory) &&
        _jobCategories[_selectedCategory]!.isNotEmpty &&
        _jobCategories[_selectedCategory!]?.first !=
            appStrings.specifyInDescription;
    List<String> availableSkills = skillDropdownEnabled
        ? _jobCategories[_selectedCategory]!
        : [];
    if (_selectedSkill != null &&
        !availableSkills.contains(_selectedSkill) &&
        mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedSkill = null);
      });
    }
    bool isProcessing = _isLoading || _isUploading;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: FadeInDown(child: Text(appStrings.createJobAppBarTitle)),
        centerTitle: true,
        backgroundColor: colorScheme.surfaceContainerHighest,
        elevation: 1,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 120.0),
          children: [
            if (_selectedWorker != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: FadeInUp(
                  child: _buildSectionCard(
                    title: appStrings.createJobSelectedWorkerSectionTitle,
                    icon: Icons.person_pin_rounded,
                    colorScheme: colorScheme,
                    children: [_buildThemedWorkerCard(_selectedWorker!, theme)],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: FadeInUp(
                delay: const Duration(milliseconds: 50),
                child: _buildSectionCard(
                  title: appStrings.createJobDetailsSectionTitle,
                  icon: Icons.description_outlined,
                  colorScheme: colorScheme,
                  children: [
                    // NEW WIDGET: Visual Category Selector
                    _buildCategorySelector(theme, appStrings),
                    const SizedBox(height: 16),
                    _buildDropdownFormField(
                      context: context,
                      label: appStrings.createJobSkillLabel,
                      hint: appStrings.createJobSkillHint,
                      value: _selectedSkill,
                      items: availableSkills,
                      enabled: skillDropdownEnabled,
                      onChanged: (value) {
                        if (mounted) {
                          setState(() => _selectedSkill = value);
                        }
                      },
                      validator: (v) =>
                          skillDropdownEnabled && (v == null || v.isEmpty)
                          ? appStrings.createJobErrorSkill
                          : null,
                      icon: Icons.construction_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildTextFormField(
                      controller: _titleController,
                      labelText: appStrings.createJobTitleLabel,
                      hintText: appStrings.createJobTitleHint,
                      icon: Icons.title,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? appStrings.createJobTitleError
                          : null,
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                    ),
                    const SizedBox(height: 16),
                    _buildTextFormField(
                      controller: _descriptionController,
                      labelText: appStrings.createJobDescLabel,
                      hintText: appStrings.createJobDescHint,
                      icon: Icons.text_snippet_outlined,
                      maxLines: 5,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return appStrings.createJobDescErrorEmpty;
                        }
                        if (v.trim().length < 20) {
                          return appStrings.createJobDescErrorShort;
                        }
                        return null;
                      },
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                    ),
                    const SizedBox(height: 16),
                    _buildTextFormField(
                      controller: _budgetController,
                      labelText: appStrings.createJobBudgetLabel,
                      hintText: appStrings.createJobBudgetHint,
                      icon: Icons.attach_money_outlined,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return appStrings.createJobBudgetErrorEmpty;
                        }
                        final b = double.tryParse(v.trim());
                        if (b == null) {
                          return appStrings.createJobBudgetErrorNaN;
                        }
                        if (b <= 0) {
                          return appStrings.createJobBudgetErrorPositive;
                        }
                        return null;
                      },
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                    ),
                    const SizedBox(height: 16),
                    _buildTextFormField(
                      controller: _locationController,
                      labelText: appStrings.createJobLocationLabel,
                      hintText: appStrings.createJobLocationHint,
                      icon: Icons.location_on_outlined,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? appStrings.createJobLocationError
                          : null,
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: FadeInUp(
                delay: const Duration(milliseconds: 100),
                child: _buildSectionCard(
                  title: appStrings.createJobOptionalSectionTitle,
                  icon: Icons.add_circle_outline_rounded,
                  colorScheme: colorScheme,
                  children: [
                    _buildPickerTile(
                      title: _selectedDate == null
                          ? appStrings.createJobScheduleLabelOptional
                          : appStrings.createJobScheduleLabelSet(
                              DateFormat.yMMMd().format(_selectedDate!),
                            ),
                      subtitle: appStrings.createJobScheduleSub,
                      icon: Icons.calendar_today_outlined,
                      onTap: _showCalendarDialog,
                      theme: theme,
                    ),
                    const SizedBox(height: 16),
                    _buildPickerTile(
                      title: appStrings.createJobAttachmentsLabelOptional,
                      subtitle: _attachments.isEmpty
                          ? appStrings.createJobAttachmentsSubAdd
                          : appStrings.createJobAttachmentsSubCount(
                              _attachments.length,
                            ),
                      icon: Icons.attach_file_rounded,
                      onTap: _showAttachmentOptions,
                      theme: theme,
                    ),
                    if (_attachments.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: _buildAttachmentPreviewGrid(theme, appStrings),
                      ),
                    const SizedBox(height: 16),
                    _buildUrgentSwitch(theme, appStrings),
                  ],
                ),
              ),
            ),
            FadeInUp(
              delay: const Duration(milliseconds: 150),
              child: ScaleTransition(
                scale: CurvedAnimation(
                  parent: _buttonAnimationController,
                  curve: Curves.elasticOut,
                ),
                child: _buildSubmitButton(theme, appStrings, isProcessing),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- NEW WIDGET: Visual category selector ---
  Widget _buildCategorySelector(ThemeData theme, AppStrings appStrings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 12.0),
          child: Text(
            appStrings.createJobCategoryLabel,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        SizedBox(
          height: 95,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _jobCategories.keys.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final category = _jobCategories.keys.elementAt(index);
              return FadeInRight(
                delay: Duration(milliseconds: 50 * index),
                child: _buildCategoryChip(
                  categoryName: category,
                  icon: _getIconForCategory(category),
                  isSelected: _selectedCategory == category,
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                      _selectedSkill =
                          null; // Reset skill when category changes
                    });
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- NEW WIDGET: Individual category chip ---
  Widget _buildCategoryChip({
    required String categoryName,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      splashColor: colorScheme.primary.withOpacity(0.1),
      highlightColor: colorScheme.primary.withOpacity(0.05),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 90,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant.withOpacity(0.4),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 30,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              categoryName,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- NEW HELPER: Maps category names to icons ---
  IconData _getIconForCategory(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'plumbing':
        return Icons.plumbing_rounded;
      case 'electrical':
        return Icons.electrical_services_rounded;
      case 'cleaning':
        return Icons.cleaning_services_rounded;
      case 'painting':
        return Icons.format_paint_rounded;
      case 'carpentry':
        return Icons.construction_rounded;
      case 'gardening':
        return Icons.local_florist_rounded;
      case 'moving':
        return Icons.local_shipping_rounded;
      case 'handyman':
        return Icons.handyman_rounded;
      default:
        return Icons.work_outline_rounded;
    }
  }

  // --- Helper Widgets (The rest are the same as your original code) ---

  // (All the other _build... and helper methods from your original code go here)
  // ... _buildSectionCard, _buildThemedWorkerCard, _buildTextFormField, etc. ...
  // ... I've included them below for completeness ...

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required ColorScheme colorScheme,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(title, icon, colorScheme),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    IconData icon,
    ColorScheme colorScheme,
  ) {
    return Row(
      children: [
        Icon(icon, color: colorScheme.primary, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildThemedWorkerCard(Worker worker, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: colorScheme.secondaryContainer,
            backgroundImage: worker.profileImage.isNotEmpty
                ? CachedNetworkImageProvider(worker.profileImage)
                : null,
            child: worker.profileImage.isEmpty
                ? Icon(
                    Icons.person_outline_rounded,
                    size: 25,
                    color: colorScheme.onSecondaryContainer,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  worker.name,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  worker.profession,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData icon,
    required FormFieldValidator<String>? validator,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      enabled: enabled,
      style: textTheme.bodyLarge?.copyWith(
        color: enabled
            ? colorScheme.onSurface
            : colorScheme.onSurface.withOpacity(0.5),
      ),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        filled: true,
        fillColor: enabled
            ? colorScheme.surfaceContainerHighest.withOpacity(0.6)
            : colorScheme.surfaceContainer.withOpacity(0.4),
        prefixIcon: Icon(
          icon,
          color: enabled
              ? colorScheme.primary
              : colorScheme.onSurface.withOpacity(0.4),
          size: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant.withOpacity(0.7),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 12,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),
      validator: enabled ? validator : null,
    );
  }

  Widget _buildDropdownFormField({
    required BuildContext context,
    required String label,
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required FormFieldValidator<String>? validator,
    required IconData icon,
    bool enabled = true,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        );
      }).toList(),
      onChanged: enabled ? onChanged : null,
      validator: enabled ? validator : null,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: textTheme.bodyLarge?.copyWith(
        color: enabled
            ? colorScheme.onSurface
            : colorScheme.onSurface.withOpacity(0.5),
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: enabled
            ? colorScheme.surfaceContainerHighest.withOpacity(0.6)
            : colorScheme.surfaceContainer.withOpacity(0.4),
        prefixIcon: Icon(
          icon,
          color: enabled
              ? colorScheme.primary
              : colorScheme.onSurface.withOpacity(0.4),
          size: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant.withOpacity(0.7),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 0),
      ),
      dropdownColor: colorScheme.surfaceContainerHigh,
      iconEnabledColor: enabled
          ? colorScheme.primary
          : colorScheme.onSurface.withOpacity(0.4),
      iconDisabledColor: colorScheme.onSurface.withOpacity(0.4),
      isExpanded: true,
    );
  }

  Widget _buildPickerTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: colorScheme.primary.withOpacity(0.1),
        highlightColor: colorScheme.primary.withOpacity(0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outlineVariant.withOpacity(0.4),
            ),
            color: colorScheme.surfaceContainer,
          ),
          child: Row(
            children: [
              Icon(icon, color: colorScheme.primary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // All other methods like _pickMedia, _showAttachmentOptions, etc. are unchanged
  // and are included below for completeness.

  Future<void> _pickMedia(String sourceOption) async {
    if (!mounted) return;
    final appStrings = AppLocalizations.of(context);
    if (appStrings == null) return;
    try {
      List<dynamic> newlyPicked = [];
      if (sourceOption == 'camera') {
        try {
          final XFile? image = await _picker.pickImage(
            source: ImageSource.camera,
          );
          if (image != null) newlyPicked.add(image);
        } on PlatformException catch (e) {
          debugPrint("!!! Camera PlatformException: ${e.code}");
          String msg = appStrings.createJobSnackbarErrorPick;
          if (e.code == 'no_available_camera') {
            msg = appStrings.snackErrorCameraNotAvailable;
          } else if (e.code == 'camera_access_denied')
            msg = appStrings.snackErrorCameraPermission;
          if (mounted) _showSnackbar(msg, isError: true);
          return;
        } catch (e) {
          debugPrint("!!! Camera error: $e");
          if (mounted) {
            _showSnackbar(appStrings.createJobSnackbarErrorPick, isError: true);
          }
          return;
        }
      } else if (sourceOption == 'gallery') {
        try {
          final List<XFile> images = await _picker.pickMultipleMedia();
          if (images.isNotEmpty) newlyPicked.addAll(images);
        } on PlatformException catch (e) {
          debugPrint("!!! Gallery PlatformException: ${e.code}");
          String msg = appStrings.createJobSnackbarErrorPick;
          if (e.code == 'photo_access_denied') {
            msg = appStrings.snackErrorGalleryPermission;
          }
          if (mounted) _showSnackbar(msg, isError: true);
          return;
        } catch (e) {
          debugPrint("Gallery pick error: $e");
          if (mounted) {
            _showSnackbar(appStrings.createJobSnackbarErrorPick, isError: true);
          }
          return;
        }
      } else if (sourceOption == 'file') {
        try {
          FilePickerResult? result = await FilePicker.platform.pickFiles(
            allowMultiple: true,
            type: FileType.custom,
            allowedExtensions: [
              'jpg',
              'jpeg',
              'png',
              'gif',
              'webp',
              'pdf',
              'doc',
              'docx',
              'txt',
            ],
            withData: kIsWeb,
          );
          if (result?.files.isNotEmpty ?? false) {
            newlyPicked.addAll(result!.files);
          }
        } catch (e) {
          debugPrint("File pick error: $e");
          if (mounted) {
            _showSnackbar(appStrings.createJobSnackbarErrorPick, isError: true);
          }
          return;
        }
      }

      if (!mounted) return;
      if (newlyPicked.isNotEmpty) {
        setState(() => _attachments.addAll(newlyPicked));
        _showSnackbar(
          appStrings.createJobSnackbarFileSelected(newlyPicked.length),
          isError: false,
        );
      } else if (sourceOption != 'cancelled') {
        _showSnackbar(
          appStrings.createJobSnackbarFileCancelled,
          isError: false,
        );
      }
    } catch (e, s) {
      debugPrint('Error in _pickMedia: $e\n$s');
      if (mounted) {
        _showSnackbar(appStrings.createJobSnackbarErrorPick, isError: true);
      }
    }
  }

  void _showAttachmentOptions() {
    if (!mounted) return;
    final appStrings = AppLocalizations.of(context);
    final theme = Theme.of(context);
    if (appStrings == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  appStrings.attachTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _buildBottomSheetOption(
                context,
                appStrings.attachOptionGallery,
                Icons.photo_library_outlined,
                'gallery',
              ),
              _buildBottomSheetOption(
                context,
                appStrings.attachOptionCamera,
                Icons.camera_alt_outlined,
                'camera',
              ),
              _buildBottomSheetOption(
                context,
                appStrings.attachOptionFile,
                Icons.attach_file_rounded,
                'file',
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              Padding(
                padding: const EdgeInsets.only(
                  top: 8.0,
                  left: 8.0,
                  right: 8.0,
                  bottom: 4.0,
                ),
                child: TextButton.icon(
                  icon: Icon(
                    Icons.cancel_outlined,
                    color: theme.colorScheme.error,
                  ),
                  label: Text(
                    appStrings.attachOptionCancel,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    minimumSize: const Size(double.infinity, 40),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSheetOption(
    BuildContext context,
    String title,
    IconData icon,
    String sourceOption,
  ) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title, style: TextStyle(color: theme.colorScheme.onSurface)),
      onTap: () {
        Navigator.pop(context);
        _pickMedia(sourceOption);
      },
    );
  }

  void _showCalendarDialog() {
    if (!mounted) return;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appStrings = AppLocalizations.of(context);
    if (appStrings == null) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          appStrings.createJobCalendarTitle,
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        contentPadding: const EdgeInsets.only(top: 20, bottom: 0),
        content: SizedBox(
          width: double.maxFinite,
          child: TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 365 * 2)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
            calendarFormat: CalendarFormat.month,
            availableGestures: AvailableGestures.horizontalSwipe,
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: theme.textTheme.titleMedium!.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
              leftChevronIcon: Icon(
                Icons.chevron_left,
                color: colorScheme.primary,
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right,
                color: colorScheme.primary,
              ),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(color: colorScheme.onSurfaceVariant),
              weekendStyle: TextStyle(color: colorScheme.secondary),
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              defaultTextStyle: TextStyle(color: colorScheme.onSurface),
              weekendTextStyle: TextStyle(color: colorScheme.secondary),
              todayDecoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              selectedTextStyle: TextStyle(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
              todayTextStyle: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            onDaySelected: (selectedDay, focusedDay) {
              if (!mounted) return;
              setState(() {
                if (isSameDay(_selectedDate, selectedDay)) {
                  _selectedDate = null;
                } else {
                  _selectedDate = selectedDay;
                }
                _focusedDay = focusedDay;
              });
              Navigator.pop(context);
            },
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actionsPadding: const EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: 10,
          top: 10,
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (mounted) setState(() => _selectedDate = null);
              Navigator.pop(context);
            },
            child: Text(
              appStrings.clear,
              style: TextStyle(color: colorScheme.error),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              appStrings.ok,
              style: TextStyle(color: colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackbar(String message, {required bool isError}) {
    if (!mounted) return;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: isError
                  ? colorScheme.onErrorContainer
                  : colorScheme.onTertiaryContainer,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: isError
                      ? colorScheme.onErrorContainer
                      : colorScheme.onTertiaryContainer,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError
            ? colorScheme.errorContainer
            : colorScheme.tertiaryContainer,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 5, 16, 10),
        elevation: 4,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildAttachmentPreviewGrid(ThemeData theme, AppStrings appStrings) {
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.2)),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: _attachments.map((attachment) {
          final key = ValueKey(attachment.hashCode);
          return FadeIn(
            duration: const Duration(milliseconds: 300),
            child: _buildAttachmentPreviewItem(
              key,
              attachment,
              theme,
              appStrings,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAttachmentPreviewItem(
    Key key,
    dynamic attachment,
    ThemeData theme,
    AppStrings appStrings,
  ) {
    final colorScheme = theme.colorScheme;
    bool isImage = false;
    String? extension;
    Uint8List? bytes;
    String? path;
    if (attachment is PlatformFile) {
      extension = attachment.extension?.toLowerCase();
      bytes = kIsWeb ? attachment.bytes : null;
      path = !kIsWeb ? attachment.path : null;
    } else if (attachment is XFile) {
      extension = attachment.name.split('.').last.toLowerCase();
      path = attachment.path;
    }
    isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension);

    return SizedBox(
      key: key,
      width: 80,
      height: 80,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 75,
            height: 75,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colorScheme.outlineVariant.withOpacity(0.4),
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.08),
                  blurRadius: 2,
                  offset: Offset(1, 1),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7.0),
              child: _buildPreviewContent(
                attachment,
                isImage,
                bytes,
                path,
                colorScheme,
              ),
            ),
          ),
          Positioned(
            top: -6,
            right: -6,
            child: Material(
              type: MaterialType.circle,
              color: colorScheme.errorContainer.withOpacity(0.9),
              elevation: 1,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  if (mounted) {
                    setState(() => _attachments.remove(attachment));
                  }
                },
                child: Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewContent(
    dynamic attachment,
    bool isImage,
    Uint8List? bytes,
    String? path,
    ColorScheme colorScheme,
  ) {
    if (isImage) {
      if (kIsWeb && bytes != null) {
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: 75,
          height: 75,
          errorBuilder: (c, e, s) => _buildFileIconPlaceholder(colorScheme),
        );
      } else if (!kIsWeb && path != null) {
        return Image.file(
          File(path),
          fit: BoxFit.cover,
          width: 75,
          height: 75,
          errorBuilder: (c, e, s) => _buildFileIconPlaceholder(colorScheme),
        );
      } else if (kIsWeb && attachment is XFile) {
        return FutureBuilder<Uint8List>(
          future: attachment.readAsBytes(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.hasData) {
              return Image.memory(
                snapshot.data!,
                fit: BoxFit.cover,
                width: 75,
                height: 75,
                errorBuilder: (c, e, s) =>
                    _buildFileIconPlaceholder(colorScheme),
              );
            } else if (snapshot.hasError) {
              return _buildFileIconPlaceholder(colorScheme);
            } else {
              return const Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
          },
        );
      }
    }
    return _buildFileIconPlaceholder(colorScheme);
  }

  Widget _buildFileIconPlaceholder(ColorScheme colorScheme) {
    return Center(
      child: Icon(
        Icons.insert_drive_file_rounded,
        color: colorScheme.primary.withOpacity(0.6),
        size: 30,
      ),
    );
  }

  Widget _buildUrgentSwitch(ThemeData theme, AppStrings appStrings) {
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    return Row(
      children: [
        Icon(
          Icons.flash_on_rounded,
          color: _isUrgent
              ? colorScheme.secondary
              : colorScheme.onSurfaceVariant.withOpacity(0.6),
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appStrings.createJobUrgentLabel,
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                appStrings.createJobUrgentSub,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: _isUrgent,
          onChanged: (v) {
            if (mounted) setState(() => _isUrgent = v);
          },
          activeThumbColor: colorScheme.secondary,
          inactiveThumbColor: colorScheme.outline,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }

  Widget _buildSubmitButton(
    ThemeData theme,
    AppStrings appStrings,
    bool isProcessing,
  ) {
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isProcessing
              ? [Colors.grey.shade500, Colors.grey.shade600]
              : [
                  colorScheme.primary,
                  Color.lerp(colorScheme.primary, colorScheme.secondary, 0.6)!,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: isProcessing
            ? []
            : [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ElevatedButton.icon(
        onPressed: isProcessing ? null : _createJob,
        icon: isProcessing
            ? Container(
                width: 18,
                height: 18,
                margin: const EdgeInsets.only(right: 8),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.onPrimary,
                ),
              )
            : Icon(Icons.send_rounded, size: 20, color: colorScheme.onPrimary),
        label: Text(
          isProcessing
              ? appStrings.createJobButtonPosting
              : appStrings.createJobButtonPost,
          style: textTheme.labelLarge?.copyWith(
            color: isProcessing
                ? colorScheme.onSurface.withOpacity(0.7)
                : colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 0.8,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
          disabledBackgroundColor: Colors.transparent,
          disabledForegroundColor: colorScheme.onSurface.withOpacity(0.7),
          splashFactory: InkRipple.splashFactory,
        ),
      ),
    );
  }
}
