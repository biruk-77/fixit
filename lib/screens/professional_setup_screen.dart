// lib/screens/professional_setup_screen.dart
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../services/firebase_service.dart';
import '../../services/app_string.dart';
import 'home/home_layout.dart';

class ProfessionalSetupScreen extends StatefulWidget {
  const ProfessionalSetupScreen({super.key});

  @override
  _ProfessionalSetupScreenState createState() =>
      _ProfessionalSetupScreenState();
}

class _ProfessionalSetupScreenState extends State<ProfessionalSetupScreen> {
  // --- Services & Controllers ---
  final _firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentPage = 0;
  bool _isSaving = false;
  double _profileStrength = 0.0;
  bool _isFetchingLocation = false;
  double? _currentLatitude;
  double? _currentLongitude;

  // --- Media ---
  XFile? _profileImageFile;
  PlatformFile? _introVideoFile;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  final Map<String, List<dynamic>> _galleryImageFiles = {
    'Before/After': [],
    'Work Process': [],
    'Tools & Gear': [],
  };
  final List<XFile> _certificationImageFiles = [];

  // --- Form Controllers ---
  final _nameController = TextEditingController();
  final _professionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _experienceController = TextEditingController();
  final _aboutController = TextEditingController();
  final _baseRateController = TextEditingController();

  // --- Data & Logic ---
  List<String> _skills = [];
  final Map<String, TimeRange> _availability = {
    'Mon': TimeRange(
      const TimeOfDay(hour: 9, minute: 0),
      const TimeOfDay(hour: 17, minute: 0),
      true,
    ),
    'Tue': TimeRange(
      const TimeOfDay(hour: 9, minute: 0),
      const TimeOfDay(hour: 17, minute: 0),
      true,
    ),
    'Wed': TimeRange(
      const TimeOfDay(hour: 9, minute: 0),
      const TimeOfDay(hour: 17, minute: 0),
      true,
    ),
    'Thu': TimeRange(
      const TimeOfDay(hour: 9, minute: 0),
      const TimeOfDay(hour: 17, minute: 0),
      true,
    ),
    'Fri': TimeRange(
      const TimeOfDay(hour: 9, minute: 0),
      const TimeOfDay(hour: 17, minute: 0),
      true,
    ),
    'Sat': TimeRange(
      const TimeOfDay(hour: 10, minute: 0),
      const TimeOfDay(hour: 14, minute: 0),
      false,
    ),
    'Sun': TimeRange(
      const TimeOfDay(hour: 0, minute: 0),
      const TimeOfDay(hour: 0, minute: 0),
      false,
    ),
  };
  final Map<String, List<String>> _predefinedSkills = {
    'Construction & Repair': [
      'Plumbing',
      'Electrical Wiring',
      'Carpentry',
      'Welding',
      'Painting',
      'Masonry',
      'HVAC Repair',
      'Appliance Repair',
      'Tiling',
      'Roofing',
    ],
    'Automotive Services': [
      'General Mechanic',
      'Auto Detailing',
      'Tire Repair & Change',
      'Oil Change',
      'Brake Service',
    ],
    'IT & Electronics': [
      'Computer Repair',
      'Networking Setup',
      'Software Installation',
      'Smartphone Repair',
      'TV Mounting',
      'Home Theater Setup',
    ],
    'Home & Garden': [
      'Gardening & Lawn Care',
      'Landscaping Design',
      'General Cleaning',
      'Deep Cleaning',
      'Pest Control',
      'Moving Services',
      'Furniture Assembly',
    ],
    'Creative & Personal': [
      'Tutoring',
      'Event Planning',
      'Photography',
      'Videography',
      'Personal Chef',
      'Graphic Design',
    ],
  };

  @override
  void initState() {
    super.initState();
    final controllers = [
      _nameController,
      _professionController,
      _aboutController,
      _locationController,
      _experienceController,
      _baseRateController,
    ];
    for (var controller in controllers) {
      controller.addListener(_calculateProfileStrength);
    }
    _getCurrentLocationAndUpdateField();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _professionController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _experienceController.dispose();
    _aboutController.dispose();
    _baseRateController.dispose();
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocationAndUpdateField() async {
    if (_isFetchingLocation) return;
    setState(() => _isFetchingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled.')),
          );
        }
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permissions are denied.')),
            );
          }
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permissions are permanently denied.'),
            ),
          );
        }
        return;
      }
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentLatitude = position.latitude;
        _currentLongitude = position.longitude;
      });
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address =
            "${place.locality}, ${place.administrativeArea}, ${place.country}";
        _locationController.text = address;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to get location: $e')));
      }
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  void _calculateProfileStrength() {
    int score = 0;
    const maxScore = 8;
    if (_nameController.text.trim().isNotEmpty) score++;
    if (_professionController.text.trim().isNotEmpty) score++;
    if (_locationController.text.trim().isNotEmpty) score++;
    if (_aboutController.text.trim().length > 20) score++;
    if (_profileImageFile != null) score++;
    if (_skills.isNotEmpty) score++;
    if (_galleryImageFiles.values.any((list) => list.isNotEmpty)) score++;
    if (_introVideoFile != null) score++;
    if (mounted) setState(() => _profileStrength = score / maxScore);
  }

  void _nextPage() {
    if (_currentPage == 1) {
      if (!(_formKey.currentState?.validate() ?? false)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill out all required fields on this page.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }
    if (_currentPage < 4) {
      _pageController.nextPage(duration: 300.ms, curve: Curves.easeOutCubic);
    }
  }

  Future<Map<String, List<String>>> uploadCategorizedFiles(
    Map<String, List<dynamic>> fileMap,
  ) async {
    final Map<String, List<String>> uploadedUrls = {};
    for (var category in fileMap.keys) {
      final List<String> urls = [];
      for (var file in fileMap[category]!) {
        if (file is String) {
          urls.add(file);
        } else if (file is XFile) {
          final url = await _firebaseService.uploadGenericImage(
            File(file.path),
            'gallery_images/$category',
          );
          if (url != null) urls.add(url);
        }
      }
      uploadedUrls[category] = urls;
    }
    return uploadedUrls;
  }

  Future<void> _saveProfileAndFinish() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill out all required fields before finishing.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      messenger.showSnackBar(
        const SnackBar(content: Text('Uploading media...')),
      );
      String? profileImageUrl;
      if (_profileImageFile != null) {
        profileImageUrl = await _firebaseService.uploadProfileImage(
          File(_profileImageFile!.path),
        );
      }
      String? introVideoUrl;
      if (_introVideoFile != null) {
        introVideoUrl = await _firebaseService.uploadProfileVideoToSupabase(
          platformFile: _introVideoFile!,
        );
      }
      Map<String, List<String>> finalGalleryUrls = await uploadCategorizedFiles(
        _galleryImageFiles,
      );
      List<String> finalCertificationUrls = await _uploadFileList(
        _certificationImageFiles,
        'certification_images',
      );
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('Finalizing profile...')),
      );
      final availabilityData = _availability.map(
        (key, value) => MapEntry(key, value.toJson()),
      );
      await _firebaseService.saveWorker(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        location: _locationController.text.trim(),
        profession: _professionController.text.trim(),
        about: _aboutController.text.trim(),
        experience: int.tryParse(_experienceController.text) ?? 0,
        priceRange: double.tryParse(_baseRateController.text) ?? 0.0,
        skills: _skills,
        profileImageUrl: profileImageUrl,
        introVideoUrl: introVideoUrl,
        galleryImageUrls: finalGalleryUrls,
        certificationImageUrls: finalCertificationUrls,
        availability: availabilityData,
        latitude: _currentLatitude,
        longitude: _currentLongitude,
        serviceRadius: 20.0,
      );
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Welcome! Your profile is live.'),
          backgroundColor: Colors.green,
        ),
      );
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeLayout()),
          (route) => false,
        );
      }
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to save profile: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<List<String>> _uploadFileList(
    List<XFile> fileList,
    String folder,
  ) async {
    final urls = <String>[];
    for (var file in fileList) {
      final url = await _firebaseService.uploadGenericImage(
        File(file.path),
        folder,
      );
      if (url != null) urls.add(url);
    }
    return urls;
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1024,
    );
    if (pickedFile != null && mounted) {
      setState(() => _profileImageFile = pickedFile);
      _calculateProfileStrength();
    }
  }

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null && result.files.first.path != null && mounted) {
      final file = result.files.first;
      _videoController?.dispose();
      _chewieController?.dispose();
      _videoController = VideoPlayerController.file(File(file.path!))
        ..initialize().then((_) {
          _chewieController = ChewieController(
            videoPlayerController: _videoController!,
            autoPlay: true,
            looping: true,
            aspectRatio: 9 / 16,
          );
          if (mounted) setState(() {});
        });
      setState(() => _introVideoFile = file);
      _calculateProfileStrength();
    }
  }

  Future<void> _pickMultiImage(
    String category,
    List<dynamic> targetList,
  ) async {
    if (targetList.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 6 images allowed per category.')),
      );
      return;
    }
    final pickedFiles = await ImagePicker().pickMultiImage(
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (pickedFiles.isNotEmpty && mounted) {
      setState(() => targetList.addAll(pickedFiles));
      _calculateProfileStrength();
    }
  }

  void _removeMedia(dynamic file, List<dynamic> targetList) {
    setState(() {
      targetList.remove(file);
      if (file == _introVideoFile) {
        _introVideoFile = null;
        _videoController?.dispose();
        _chewieController?.dispose();
      }
    });
    _calculateProfileStrength();
  }

  void _showSkillSelectionDialog() {
    final theme = Theme.of(context);
    List<String> tempSelectedSkills = List.from(_skills);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.85,
            maxChildSize: 0.85,
            expand: false,
            builder: (_, scrollController) => Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Select Your Skills',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: _predefinedSkills.keys.length,
                      itemBuilder: (_, index) {
                        String category = _predefinedSkills.keys.elementAt(
                          index,
                        );
                        return ExpansionTile(
                          title: Text(
                            category,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          initiallyExpanded: index == 0,
                          children: _predefinedSkills[category]!
                              .map(
                                (skill) => CheckboxListTile(
                                  title: Text(skill),
                                  value: tempSelectedSkills.contains(skill),
                                  onChanged: (val) => setModalState(() {
                                    if (val == true) {
                                      tempSelectedSkills.add(skill);
                                    } else {
                                      tempSelectedSkills.remove(skill);
                                    }
                                  }),
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16).copyWith(bottom: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() => _skills = tempSelectedSkills);
                              _calculateProfileStrength();
                              Navigator.of(ctx).pop();
                            },
                            child: const Text('Confirm'),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appStrings = AppLocalizations.of(context);
    if (appStrings == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final pages = [
      _buildWelcomePage(theme, appStrings),
      _buildBasicInfoPage(theme, appStrings),
      _buildExpertisePage(theme, appStrings),
      _buildShowcasePage(theme, appStrings),
      _buildOperationsPage(theme, appStrings),
    ];
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentPage > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => _pageController.previousPage(
                  duration: 300.ms,
                  curve: Curves.easeOutCubic,
                ),
              )
            : null,
        title: Text("Create Your Profile", style: theme.textTheme.titleLarge),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: List.generate(
                  pages.length,
                  (index) => Expanded(
                    child: AnimatedContainer(
                      duration: 300.ms,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 6,
                      decoration: BoxDecoration(
                        color: index <= _currentPage
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: pages.length,
                onPageChanged: (page) => setState(() => _currentPage = page),
                itemBuilder: (context, index) => pages[index],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(theme, appStrings),
    );
  }

  Widget _buildBottomBar(ThemeData theme, AppStrings appStrings) {
    final isLastPage = _currentPage == 4;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
        border: Border(top: BorderSide(color: theme.dividerColor, width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Profile Strength", style: theme.textTheme.titleSmall),
              Text(
                "${(_profileStrength * 100).toInt()}%",
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearPercentIndicator(
            percent: _profileStrength,
            lineHeight: 8.0,
            barRadius: const Radius.circular(4),
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            progressColor: Color.lerp(
              Colors.orange.shade300,
              theme.colorScheme.primary,
              _profileStrength,
            )!,
            animation: true,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSaving
                  ? null
                  : (isLastPage ? _saveProfileAndFinish : _nextPage),
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      isLastPage
                          ? Icons.check_circle_outline
                          : Icons.arrow_forward_ios_rounded,
                    ),
              label: Text(
                _isSaving
                    ? 'Finishing Up...'
                    : (isLastPage ? 'Complete & Go Live' : 'Next Step'),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomePage(ThemeData theme, AppStrings appStrings) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.primary.withOpacity(0.05),
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.shield_moon_rounded, size: 80)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .shimmer(
                  delay: 400.ms,
                  duration: 1800.ms,
                  color: theme.colorScheme.secondary.withOpacity(0.3),
                )
                .animate()
                .fadeIn(duration: 1200.ms, curve: Curves.easeOut)
                .scale(duration: 1200.ms),
            const SizedBox(height: 32),
            Text(
              "Let's Build Your Professional Profile!",
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
            const SizedBox(height: 16),
            Text(
              "A complete, trustworthy profile helps you stand out and win more jobs. Let's start with a friendly photo.",
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: 48),
            _ProfileImagePicker(
              selectedImageFile: _profileImageFile,
              onTap: () => _pickImage(ImageSource.gallery),
            ).animate().fadeIn(delay: 600.ms).scale(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoPage(ThemeData theme, AppStrings appStrings) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        _buildSectionHeader(
          theme,
          "About You",
          "This is how clients will identify you.",
        ),
        _CustomTextField(
          controller: _nameController,
          label: 'Full Name',
          hint: 'e.g., Abebe Bikila',
          icon: Icons.person_outline,
        ),
        _CustomTextField(
          controller: _professionController,
          label: 'Primary Profession',
          hint: 'e.g., Master Electrician',
          icon: Icons.work_outline,
        ),
        _CustomTextField(
          controller: _phoneController,
          label: 'Public Contact Number',
          hint: '+251 9...',
          icon: Icons.phone_outlined,
          isNumeric: true,
        ),
        _CustomTextField(
          controller: _locationController,
          label: 'Primary City or Town',
          hint: 'e.g., Addis Ababa, Ethiopia',
          icon: Icons.location_city_outlined,
          suffixIcon: _isFetchingLocation
              ? const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.my_location),
                  onPressed: _getCurrentLocationAndUpdateField,
                  tooltip: 'Get Current Location',
                ),
        ),
      ].animate(interval: 100.ms).fadeIn(duration: 300.ms).slideX(begin: 0.2),
    );
  }

  Widget _buildExpertisePage(ThemeData theme, AppStrings appStrings) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        _buildSectionHeader(
          theme,
          "Your Expertise",
          "Showcase your experience and skills.",
        ),
        _CustomTextField(
          controller: _experienceController,
          label: 'Years of Professional Experience',
          icon: Icons.workspace_premium_outlined,
          isNumeric: true,
          hint: 'e.g., 5',
        ),
        const SizedBox(height: 16),
        _CustomTextField(
          controller: _aboutController,
          label: 'Professional Bio',
          maxLines: 5,
          hint:
              'Describe yourself, your work ethic, and what makes your service unique...',
        ),
        const SizedBox(height: 24),
        _SkillSelector(
          selectedSkills: _skills,
          onAddSkills: _showSkillSelectionDialog,
          onRemoveSkill: (skill) {
            setState(() => _skills.remove(skill));
            _calculateProfileStrength();
          },
        ),
      ].animate(interval: 100.ms).fadeIn(duration: 300.ms).slideX(begin: 0.2),
    );
  }

  Widget _buildShowcasePage(ThemeData theme, AppStrings appStrings) {
    final galleryCategories = _galleryImageFiles.keys.toList();
    return DefaultTabController(
      length: galleryCategories.length,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          _buildSectionHeader(
            theme,
            "Media Showcase",
            "A picture is worth a thousand words. A video is worth a million.",
          ),
          const SizedBox(height: 16),
          _TitledContent(
            title: "Introduce Yourself (Optional Video)",
            child: _IntroVideoManager(
              chewieController: _chewieController,
              videoFile: _introVideoFile,
              onPickVideo: _pickVideo,
              onRemoveVideo: () => _removeMedia(_introVideoFile, []),
            ),
          ),
          const Divider(height: 48),
          _TitledContent(
            title: "Your Work Gallery",
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TabBar(
                  isScrollable: true,
                  tabs: galleryCategories.map((cat) => Tab(text: cat)).toList(),
                ),
                Container(
                  height: 350,
                  padding: const EdgeInsets.only(top: 20),
                  child: TabBarView(
                    children: galleryCategories.map((category) {
                      final fileList = _galleryImageFiles[category]!;
                      return _MediaGridUploader(
                        files: fileList.whereType<XFile>().toList(),
                        onAdd: () => _pickMultiImage(category, fileList),
                        onRemove: (file) => _removeMedia(file, fileList),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 48),
          _TitledContent(
            title: "Certifications & Licenses (Max 6)",
            child: _MediaGridUploader(
              files: _certificationImageFiles,
              onAdd: () => _pickMultiImage('certs', _certificationImageFiles),
              onRemove: (f) => _removeMedia(f, _certificationImageFiles),
            ),
          ),
        ].animate(interval: 100.ms).fadeIn(duration: 300.ms).slideX(begin: 0.2),
      ),
    );
  }

  Widget _buildOperationsPage(ThemeData theme, AppStrings appStrings) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        _buildSectionHeader(
          theme,
          "Business Details",
          "Set your rates and working hours.",
        ),
        const SizedBox(height: 16),
        _TitledContent(
          title: 'Your Base Rate',
          child: _CustomTextField(
            controller: _baseRateController,
            label: 'Base Rate (per hour, in ETB)',
            icon: Icons.attach_money_outlined,
            isNumeric: true,
          ),
        ),
        const Divider(height: 48),
        _TitledContent(
          title: 'Your Weekly Availability',
          child: _DayAvailabilityGrid(
            availability: _availability,
            onChanged: (day, newRange) =>
                setState(() => _availability[day] = newRange),
          ),
        ),
      ].animate(interval: 100.ms).fadeIn(duration: 300.ms).slideX(begin: 0.2),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// --- HELPER WIDGETS ---
class _TitledContent extends StatelessWidget {
  final String title;
  final Widget child;
  const _TitledContent({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 12),
      child,
    ],
  );
}

class _ProfileImagePicker extends StatelessWidget {
  final XFile? selectedImageFile;
  final VoidCallback onTap;
  const _ProfileImagePicker({this.selectedImageFile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    ImageProvider? imageProvider;
    if (selectedImageFile != null) {
      imageProvider = FileImage(File(selectedImageFile!.path));
    }
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 80,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest,
            backgroundImage: imageProvider,
            child: imageProvider == null
                ? Icon(
                    Icons.person_add_alt_1_rounded,
                    size: 80,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withOpacity(0.5),
                  )
                : null,
          ),
          Positioned(
            bottom: 4,
            right: 4,
            child: Material(
              color: Theme.of(context).colorScheme.primary,
              shape: const CircleBorder(),
              elevation: 4,
              child: InkWell(
                onTap: onTap,
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.edit, color: Colors.white, size: 24),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroVideoManager extends StatelessWidget {
  final ChewieController? chewieController;
  final PlatformFile? videoFile;
  final VoidCallback onPickVideo, onRemoveVideo;

  const _IntroVideoManager({
    this.chewieController,
    this.videoFile,
    required this.onPickVideo,
    required this.onRemoveVideo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool hasVideo = videoFile != null;

    if (!hasVideo) {
      // =================================================================
      // ========== FIX #1: Correct DottedBorder Syntax Here ==========
      // =================================================================
      return DottedBorder(
        options: RoundedRectDottedBorderOptions(
          color: theme.colorScheme.primary,
          strokeWidth: 2,
          dashPattern: const [8, 8],
          radius: const Radius.circular(16),
          padding: EdgeInsets.zero,
        ),
        child: AspectRatio(
          aspectRatio: 9 / 16,
          child: InkWell(
            onTap: onPickVideo,
            borderRadius: BorderRadius.circular(15),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.video_call_outlined,
                    color: theme.colorScheme.primary,
                    size: 40,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add Video Introduction',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 9 / 16,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              color: Colors.black,
              child:
                  chewieController != null &&
                      chewieController!
                          .videoPlayerController
                          .value
                          .isInitialized
                  ? Chewie(controller: chewieController!)
                  : const Center(child: CircularProgressIndicator()),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: InkWell(
                onTap: onRemoveVideo,
                child: const CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.black54,
                  child: Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaGridUploader extends StatelessWidget {
  final List<XFile> files;
  final VoidCallback onAdd;
  final ValueChanged<XFile> onRemove;
  const _MediaGridUploader({
    required this.files,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;
        final int crossAxisCount = 3;
        const double spacing = 10.0;
        final double itemWidth =
            (availableWidth - (spacing * (crossAxisCount - 1))) /
            crossAxisCount;
        final List<Widget> children = [];

        for (final file in files) {
          children.add(
            SizedBox(
              width: itemWidth,
              height: itemWidth,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      File(file.path),
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.error_outline),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: InkWell(
                        onTap: () => onRemove(file),
                        child: const CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.black54,
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (files.length < 6) {
          children.add(
            SizedBox(
              width: itemWidth,
              height: itemWidth,
              // =================================================================
              // ========== FIX #2: Correct DottedBorder Syntax Here ==========
              // =================================================================
              child: DottedBorder(
                options: RoundedRectDottedBorderOptions(
                  color: Theme.of(context).colorScheme.primary,
                  strokeWidth: 1.5,
                  dashPattern: const [6, 6],
                  radius: const Radius.circular(12),
                  padding: EdgeInsets.zero,
                ),
                child: InkWell(
                  onTap: onAdd,
                  borderRadius: BorderRadius.circular(11),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Add Image',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        return Wrap(spacing: spacing, runSpacing: spacing, children: children);
      },
    );
  }
}
class _CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final Widget? suffixIcon;
  final bool isNumeric, isRequired;
  final int maxLines;

  const _CustomTextField({
    super.key, // Good practice
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.suffixIcon,
    this.isNumeric = false,
    this.isRequired = false, // <--- THIS WAS MISSING
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: isNumeric
            ? TextInputType.number
            : TextInputType.multiline,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: icon != null ? Icon(icon) : null,
          suffixIcon: suffixIcon,
          alignLabelWithHint: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: isRequired
            ? (v) =>
                (v == null || v.trim().isEmpty) ? '$label is required.' : null
            : null,
      ),
    );
  }
}

class _SkillSelector extends StatelessWidget {
  final List<String> selectedSkills;
  final VoidCallback onAddSkills;
  final ValueChanged<String> onRemoveSkill;
  const _SkillSelector({
    required this.selectedSkills,
    required this.onAddSkills,
    required this.onRemoveSkill,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Your Skills", style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: selectedSkills.isEmpty
              ? Center(
                  child: TextButton.icon(
                    onPressed: onAddSkills,
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text("Select your skills"),
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...selectedSkills.map(
                      (skill) => Chip(
                        label: Text(skill),
                        onDeleted: () => onRemoveSkill(skill),
                        backgroundColor: theme.colorScheme.primaryContainer,
                        labelStyle: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    ActionChip(
                      label: const Text('Add/Edit'),
                      avatar: const Icon(Icons.edit_outlined, size: 18),
                      onPressed: onAddSkills,
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _DayAvailabilityGrid extends StatelessWidget {
  final Map<String, TimeRange> availability;
  final Function(String, TimeRange) onChanged;
  const _DayAvailabilityGrid({
    required this.availability,
    required this.onChanged,
  });

  Future<void> _pickTime(
    BuildContext context,
    String day,
    bool isStart,
    TimeRange currentRange,
  ) async {
    final time = await showTimePicker(
      context: context,
      initialTime: isStart ? currentRange.start : currentRange.end,
    );
    if (time != null) {
      final newRange = TimeRange(
        isStart ? time : currentRange.start,
        !isStart ? time : currentRange.end,
        currentRange.isActive,
      );
      onChanged(day, newRange);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = availability.keys.toList();
    return Column(
      children: days.map((day) {
        final range = availability[day]!;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Text(day, style: theme.textTheme.labelLarge),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () => range.isActive
                      ? _pickTime(context, day, true, range)
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: range.isActive
                          ? theme.colorScheme.surface
                          : theme.colorScheme.surfaceContainer,
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      range.start.format(context),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: range.isActive
                            ? theme.colorScheme.primary
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text('to'),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => range.isActive
                      ? _pickTime(context, day, false, range)
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: range.isActive
                          ? theme.colorScheme.surface
                          : theme.colorScheme.surfaceContainer,
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      range.end.format(context),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: range.isActive
                            ? theme.colorScheme.primary
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: range.isActive,
                onChanged: (val) =>
                    onChanged(day, TimeRange(range.start, range.end, val)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class TimeRange {
  TimeOfDay start, end;
  bool isActive;
  TimeRange(this.start, this.end, this.isActive);

  Map<String, dynamic> toJson() => {
    'start':
        '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}',
    'end':
        '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}',
    'isActive': isActive,
  };

  factory TimeRange.fromJson(Map<String, dynamic> json) {
    TimeOfDay parseTime(String? timeStr, TimeOfDay fallback) {
      if (timeStr == null) return fallback;
      try {
        final parts = timeStr.split(':');
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      } catch (e) {
        return fallback;
      }
    }

    return TimeRange(
      parseTime(json['start'], const TimeOfDay(hour: 9, minute: 0)),
      parseTime(json['end'], const TimeOfDay(hour: 17, minute: 0)),
      json['isActive'] ?? false,
    );
  }
}
