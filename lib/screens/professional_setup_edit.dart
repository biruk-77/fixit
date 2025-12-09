// lib/screens/professional_setup_edit.dart
import 'dart:io';
import 'dart:ui' as ui; // For ImageFilter (blur effect)
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/app_string.dart';
import '../../services/firebase_service.dart';
import 'home/home_layout.dart';

class ProfessionalHubScreen extends StatefulWidget {
  const ProfessionalHubScreen({super.key});
  @override
  _ProfessionalHubScreenState createState() => _ProfessionalHubScreenState();
}

class _ProfessionalHubScreenState extends State<ProfessionalHubScreen>
    with TickerProviderStateMixin {
  final _firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  bool _isLoading = true;
  bool _isSaving = false;
  int _currentSectionIndex = 0;
  double _profileStrength = 0.0;
  bool _showAppBarTitle = false;
  bool _isFetchingLocation = false;

  double? _currentLatitude;
  double? _currentLongitude;

  // --- Media ---
  XFile? _profileImageFile;
  String? _existingProfileImageUrl;
  PlatformFile? _introVideoFile;
  String? _existingIntroVideoUrl;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  // FIX #1: Gallery files are now a Map to hold categories.
  Map<String, List<dynamic>> _galleryImageFiles = {
    'Before/After': [],
    'Work Process': [],
    'Tools & Gear': [],
  };
  List<dynamic> _certificationImageFiles = [];

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
  double _serviceRadius = 20.0;
  Map<String, TimeRange> _availability = {
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
      'Tutoring (Specify Subject)',
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
    _nameController.addListener(_calculateProfileStrength);
    _professionController.addListener(_calculateProfileStrength);
    _aboutController.addListener(_calculateProfileStrength);
    _locationController.addListener(_calculateProfileStrength);
    _scrollController.addListener(() {
      final shouldShow =
          _scrollController.hasClients && _scrollController.offset > 150;
      if (shouldShow != _showAppBarTitle) {
        setState(() => _showAppBarTitle = shouldShow);
      }
    });
    _loadProfileData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _professionController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _experienceController.dispose();
    _aboutController.dispose();
    _baseRateController.dispose();
    _videoController?.dispose();
    _chewieController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocationAndUpdateField() async {
    final appStrings = AppLocalizations.of(context);
    if (appStrings == null || !mounted) return;

    if (_isFetchingLocation) return;
    setState(() => _isFetchingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(appStrings.professionalSetupErrorLocationDisabled),
            ),
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
              SnackBar(
                content: Text(appStrings.professionalSetupErrorLocationDenied),
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                appStrings.professionalSetupErrorLocationPermanentlyDenied,
              ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              appStrings.professionalSetupErrorGettingLocation(e.toString()),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  Future<void> _loadProfileData() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final appStrings = AppLocalizations.of(context);
      if (appStrings == null || !mounted) return;

      setState(() => _isLoading = true);
      final userId = _firebaseService.currentUserId;
      if (userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(appStrings.professionalSetupErrorNotLoggedIn),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      try {
        final profile = await _firebaseService.getWorker(userId);
        if (profile != null && mounted) {
          _nameController.text = profile.name;
          _professionController.text = profile.profession ?? '';
          _phoneController.text = profile.phoneNumber;
          _locationController.text = profile.location;
          _experienceController.text = profile.experience.toString() ?? '0';
          _aboutController.text = profile.about ?? '';
          _baseRateController.text = profile.priceRange.toString() ?? '0';

          setState(() {
            _existingProfileImageUrl = profile.profileImage;
            _existingIntroVideoUrl = profile.introVideoUrl;
            if (_existingIntroVideoUrl != null &&
                _existingIntroVideoUrl!.isNotEmpty) {
              _initializeVideoPlayer(_existingIntroVideoUrl!);
            }
            _skills = List.from(profile.skills ?? []);

            // FIX: Logic to load categorized gallery data from Firebase.
            final loadedMap = Map<String, dynamic>.from(
              profile.galleryImages as Map,
            );
            _galleryImageFiles = {
              'Before/After':
                  loadedMap['Before/After']?.cast<dynamic>()?.toList() ?? [],
              'Work Process':
                  loadedMap['Work Process']?.cast<dynamic>()?.toList() ?? [],
              'Tools & Gear':
                  loadedMap['Tools & Gear']?.cast<dynamic>()?.toList() ?? [],
            };

            _certificationImageFiles = List.from(
              profile.certificationImages ?? [],
            );
            _serviceRadius = profile.serviceRadius ?? 20.0;
            _currentLatitude = profile.latitude;
            _currentLongitude = profile.longitude;

            final Map<String, TimeRange> loadedAvailability = {};
            profile.availability.forEach((day, data) {
              loadedAvailability[day] = TimeRange.fromJson(
                data as Map<String, dynamic>,
              );
            });
            _availability = loadedAvailability;
          });

          if (_locationController.text.trim().isEmpty) {
            await _getCurrentLocationAndUpdateField();
          }
        } else {
          await _getCurrentLocationAndUpdateField();
        }
      } catch (e, s) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                appStrings.professionalSetupErrorLoading(e.toString()),
              ),
              backgroundColor: Colors.red,
            ),
          );
          print('please check your network: $e\n$s');
        }
      } finally {
        if (mounted) {
          _calculateProfileStrength();
          setState(() => _isLoading = false);
        }
      }
    });
  }

  // A helper function for categorized file uploads. FirebaseService should have this.
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
          // IMPORTANT: Assumes FirebaseService has `uploadGenericImage`
          final url = await _firebaseService.uploadGenericImage(
            File(file.path),
            'gallery_images/$category',
          );
          if (url != null) {
            urls.add(url);
          }
        }
      }
      uploadedUrls[category] = urls;
    }
    return uploadedUrls;
  }

  Future<void> _saveProfile() async {
    final appStrings = AppLocalizations.of(context);
    if (appStrings == null || !mounted) return;

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(appStrings.professionalSetupErrorFormValidation),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      messenger.showSnackBar(
        SnackBar(content: Text(appStrings.professionalSetupInfoUploadingMedia)),
      );

      String? profileImageUrl = _existingProfileImageUrl;
      if (_profileImageFile != null) {
        // IMPORTANT: Assumes FirebaseService has `uploadProfileImage`
        profileImageUrl = await _firebaseService.uploadProfileImage(
          File(_profileImageFile!.path),
        );
      }

      String? introVideoUrl = _existingIntroVideoUrl;
      if (_introVideoFile != null) {
        // IMPORTANT: Assumes FirebaseService has `uploadProfileVideoToSupabase`
        introVideoUrl = await _firebaseService.uploadProfileVideoToSupabase(
          platformFile: _introVideoFile!,
        );
      }

      // FIX: Use the new categorized upload logic
      Map<String, List<String>> finalGalleryUrls = await uploadCategorizedFiles(
        _galleryImageFiles,
      );

      List<String> finalCertificationUrls = await _uploadFileList(
        _certificationImageFiles,
        'certification_images',
      );

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text(appStrings.professionalSetupInfoSavingData)),
      );

      final availabilityData = _availability.map(
        (key, value) => MapEntry(key, value.toJson()),
      );

      // IMPORTANT: `saveWorker` in FirebaseService MUST be updated to accept `Map<String, List<String>> galleryImageUrls`
      await _firebaseService.saveWorker(
        name: _nameController.text,
        profession: _professionController.text,
        phone: _phoneController.text,
        location: _locationController.text,
        experience: int.tryParse(_experienceController.text) ?? 0,
        about: _aboutController.text,
        priceRange: double.tryParse(_baseRateController.text) ?? 0.0,
        skills: _skills,
        profileImageUrl: profileImageUrl,
        galleryImageUrls: finalGalleryUrls, // Sending the map
        certificationImageUrls: finalCertificationUrls,
        introVideoUrl: introVideoUrl,
        serviceRadius: _serviceRadius,
        availability: availabilityData,
        latitude: _currentLatitude,
        longitude: _currentLongitude,
      );

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(appStrings.professionalSetupSuccess),
          backgroundColor: Colors.green,
        ),
      );

      _calculateProfileStrength();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeLayout()),
        );
      }
    } catch (e, s) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(appStrings.professionalSetupErrorSaving(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
      print('Error saving profile: $e\n$s');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _calculateProfileStrength() {
    int score = 0;
    const int maxScore = 9;

    if (_nameController.text.trim().isNotEmpty) score++;
    if (_professionController.text.trim().isNotEmpty) score++;
    if (_locationController.text.trim().isNotEmpty) score++;
    if (_aboutController.text.trim().length > 50) score++;
    if (_existingProfileImageUrl != null || _profileImageFile != null) score++;
    if (_skills.isNotEmpty) score++;
    // Check if any of the gallery categories has at least one image
    if (_galleryImageFiles.values.any((list) => list.isNotEmpty)) score++;
    if (_certificationImageFiles.isNotEmpty) score++;
    if (_existingIntroVideoUrl != null || _introVideoFile != null) score++;

    if (mounted) {
      setState(() => _profileStrength = score / maxScore);
    }
  }

  // This function is fine for the non-categorized certifications list
  Future<List<String>> _uploadFileList(
    List<dynamic> fileList,
    String folder,
  ) async {
    final urls = <String>[];
    for (var file in fileList) {
      if (file is String) {
        urls.add(file);
      } else if (file is XFile) {
        final url = await _firebaseService.uploadGenericImage(
          File(file.path),
          folder,
        );
        if (url != null) urls.add(url);
      }
    }
    return urls;
  }

  void _initializeVideoPlayer(String url) {
    _videoController?.dispose();
    _chewieController?.dispose();
    _videoController = VideoPlayerController.networkUrl(Uri.parse(url))
      ..initialize().then((_) {
        _chewieController = ChewieController(
          videoPlayerController: _videoController!,
          autoPlay: false,
          looping: true,
          aspectRatio: _videoController!.value.isInitialized
              ? _videoController!.value.aspectRatio
              : 9 / 16,
          allowFullScreen: true,
          placeholder: Container(
            color: Colors.black,
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorBuilder: (context, errorMessage) {
            return Center(
              child: Text(
                errorMessage,
                style: const TextStyle(color: Colors.white),
              ),
            );
          },
        );
        if (mounted) setState(() {});
      });
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
      setState(() {
        _introVideoFile = result.files.first;
        _existingIntroVideoUrl = null;
        _videoController?.dispose();
        _chewieController?.dispose();
        _videoController =
            VideoPlayerController.file(File(_introVideoFile!.path!))
              ..initialize().then((_) {
                _chewieController = ChewieController(
                  videoPlayerController: _videoController!,
                  autoPlay: true,
                  looping: true,
                  aspectRatio: _videoController!.value.aspectRatio,
                  allowFullScreen: true,
                );
                if (mounted) setState(() {});
              });
      });
      _calculateProfileStrength();
    }
  }

  // FIX: This is the correct image picker that works with categories
  Future<void> _pickMultiImage(
    String category,
    List<dynamic> targetList,
  ) async {
    final appStrings = AppLocalizations.of(context)!;
    if (targetList.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appStrings.professionalSetupErrorMaxImages)),
      );
      return;
    }
    final pickedFiles = await ImagePicker().pickMultiImage(
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (pickedFiles.isNotEmpty && mounted) {
      setState(() {
        targetList.addAll(pickedFiles);
      });
      _calculateProfileStrength();
    }
  }

  void _removeMedia(dynamic file, List<dynamic> targetList) {
    if (!mounted) return;
    setState(() {
      targetList.remove(file);
      if (file == _introVideoFile || file == _existingIntroVideoUrl) {
        _introVideoFile = null;
        _existingIntroVideoUrl = null;
        _videoController?.dispose();
        _chewieController?.dispose();
        _videoController = null;
        _chewieController = null;
      }
    });
    _calculateProfileStrength();
  }

  void _showSkillSelectionDialog() {
    final appStrings = AppLocalizations.of(context);
    if (appStrings == null) return;

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
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      appStrings.professionalSetupSkillsDialogTitle,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  Text(
                    appStrings.professionalSetupSkillsDialogSubtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Divider(height: 24, indent: 16, endIndent: 16),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: _predefinedSkills.keys.length,
                      itemBuilder: (_, index) {
                        String category = _predefinedSkills.keys.elementAt(
                          index,
                        );
                        List<String> skillsInCategory =
                            _predefinedSkills[category]!;
                        return ExpansionTile(
                          title: Text(
                            category,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          initiallyExpanded: true,
                          children: skillsInCategory
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
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: Text(
                              appStrings.professionalSetupSkillsDialogCancel,
                            ),
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
                            child: Text(
                              appStrings.professionalSetupSkillsDialogConfirm,
                            ),
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
    final appStrings = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (appStrings == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final bgGradients = theme.brightness == Brightness.dark
        ? [const Color(0xFF232526), const Color(0xFF414345)]
        : [const Color(0xFFeef2f3), theme.colorScheme.surfaceContainerLow];

    return Scaffold(
      floatingActionButton: _isLoading ? null : _buildSaveButton(appStrings),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(seconds: 1),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: bgGradients,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 1000) {
                      return _buildWideLayout(appStrings, theme);
                    } else {
                      return _buildMobileLayout(appStrings, theme);
                    }
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(AppStrings appStrings, ThemeData theme) {
    return Form(
      key: _formKey,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            pinned: true,
            stretch: true,
            expandedHeight: 120.0,
            backgroundColor: theme.colorScheme.surface.withOpacity(0.85),
            elevation: 1,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 60, bottom: 16),
              title: AnimatedOpacity(
                opacity: _showAppBarTitle ? 1.0 : 0.0,
                duration: 200.ms,
                child: Text(
                  appStrings.professionalSetupTitle,
                  style: theme.textTheme.titleLarge,
                ),
              ),
              background: ClipRect(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                  child: Container(
                    color: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 24,
                        bottom: 16,
                        right: 24,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appStrings.professionalSetupNavHeader,
                            style: theme.textTheme.headlineSmall,
                          ),
                          Text(
                            appStrings.professionalSetupSubtitle,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            actions: [_buildAppBarActions(theme, appStrings)],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _ProfileStrengthIndicator(
                  strength: _profileStrength,
                ).animate().fadeIn(delay: 200.ms),
                _buildBasicInfoSection(appStrings),
                _buildExpertiseSection(appStrings),
                _buildLocationAndRadiusSection(appStrings),
                _buildShowcaseSection(appStrings),
                _buildOperationsSection(appStrings),
                const SizedBox(height: 80), // Padding for the FAB
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWideLayout(AppStrings appStrings, ThemeData theme) {
    final sections = [
      _ProfileSectionModel(
        title: appStrings.professionalSetupNavBasic,
        icon: Icons.badge_outlined,
        child: _buildBasicInfoSection(appStrings),
      ),
      _ProfileSectionModel(
        title: appStrings.professionalSetupNavExpertise,
        icon: Icons.school_outlined,
        child: _buildExpertiseSection(appStrings),
      ),
      _ProfileSectionModel(
        title: appStrings.professionalSetupNavLocation,
        icon: Icons.map_outlined,
        child: _buildLocationAndRadiusSection(appStrings),
      ),
      _ProfileSectionModel(
        title: appStrings.professionalSetupNavShowcase,
        icon: Icons.perm_media_outlined,
        child: _buildShowcaseSection(appStrings),
      ),
      _ProfileSectionModel(
        title: appStrings.professionalSetupNavRates,
        icon: Icons.business_center_outlined,
        child: _buildOperationsSection(appStrings),
      ),
    ];
    return Form(
      key: _formKey,
      child: Row(
        children: [
          _WideNavMenu(
            sections: sections,
            selectedIndex: _currentSectionIndex,
            onSelect: (index) => setState(() => _currentSectionIndex = index),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            child: Column(
              children: [
                _HeaderBar(
                  profileStrength: _profileStrength,
                  onSave: _isSaving ? null : _saveProfile,
                  isSaving: _isSaving,
                ),
                const Divider(height: 1, thickness: 1),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: 300.ms,
                    transitionBuilder: (child, anim) =>
                        FadeTransition(opacity: anim, child: child),
                    child: SingleChildScrollView(
                      key: ValueKey(_currentSectionIndex),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 24,
                      ),
                      child: sections[_currentSectionIndex].child,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBarActions(ThemeData theme, AppStrings appStrings) {
    final isDarkMode = theme.brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            isDarkMode ? Icons.wb_sunny_outlined : Icons.nightlight_round,
          ),
          tooltip: isDarkMode
              ? appStrings.themeTooltipLight
              : appStrings.themeTooltipDark,
          onPressed: () =>
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme(),
        ),
        IconButton(
          icon: const Icon(Icons.language),
          tooltip: appStrings.languageToggleTooltip,
          onPressed: () {
            final provider = Provider.of<LocaleProvider>(
              context,
              listen: false,
            );
            final nextLocale = provider.locale.languageCode == 'en'
                ? const Locale('am')
                : const Locale('en');
            provider.setLocale(nextLocale);
          },
        ),
      ],
    );
  }

  Widget _buildSaveButton(AppStrings appStrings) {
    return FloatingActionButton.extended(
      onPressed: _isSaving ? null : _saveProfile,
      icon: _isSaving ? null : const Icon(Icons.save_alt_outlined),
      label: _isSaving
          ? SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            )
          : Text(appStrings.professionalSetupSaveAll),
    );
  }

  Widget _buildBasicInfoSection(AppStrings appStrings) {
    return _SectionCard(
      title: appStrings.professionalSetupBasicTitle,
      description: appStrings.professionalSetupBasicSubtitle,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: kIsWeb ? 2 : 3,
            child: _ProfileImagePicker(
              existingImageUrl: _existingProfileImageUrl,
              selectedImageFile: _profileImageFile,
              onTap: () => _pickImage(ImageSource.gallery),
            ),
          ),
          const SizedBox(width: 32),
          Expanded(
            flex: 5,
            child: Column(
              children: [
                _CustomTextField(
                  controller: _nameController,
                  label: appStrings.professionalSetupLabelName,
                  hint: appStrings.professionalSetupHintName,
                  icon: Icons.person_outline,
                ),
                _CustomTextField(
                  controller: _professionController,
                  label: appStrings.professionalSetupLabelProfession,
                  hint: appStrings.professionalSetupHintProfession,
                  icon: Icons.work_outline,
                ),
                _CustomTextField(
                  controller: _phoneController,
                  label: appStrings.professionalSetupLabelPhone,
                  hint: appStrings.professionalSetupHintPhone,
                  icon: Icons.phone_outlined,
                  isNumeric: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpertiseSection(AppStrings appStrings) {
    return _SectionCard(
      title: appStrings.professionalSetupExpertiseTitle,
      description: appStrings.professionalSetupExpertiseSubtitle,
      child: Column(
        children: [
          _CustomTextField(
            controller: _experienceController,
            label: appStrings.professionalSetupLabelExperience,
            icon: Icons.workspace_premium_outlined,
            isNumeric: true,
            hint: appStrings.professionalSetupHintExperience,
          ),
          const SizedBox(height: 16),
          _CustomTextField(
            controller: _aboutController,
            label: appStrings.professionalSetupLabelBio,
            maxLines: 5,
            hint: appStrings.professionalSetupHintBio,
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
        ],
      ),
    );
  }

  Widget _buildLocationAndRadiusSection(AppStrings appStrings) {
    return _SectionCard(
      title: appStrings.professionalSetupLocationTitle,
      description: appStrings.professionalSetupLocationSubtitle,
      child: _LocationCard(
        locationController: _locationController,
        radius: _serviceRadius,
        onRadiusChanged: (newRadius) =>
            setState(() => _serviceRadius = newRadius),
        isFetchingLocation: _isFetchingLocation,
        onGetLocation: _getCurrentLocationAndUpdateField,
      ),
    );
  }

  // FIX #2: The new showcase section with categorized galleries
  Widget _buildShowcaseSection(AppStrings appStrings) {
    final galleryCategories = _galleryImageFiles.keys.toList();

    return _SectionCard(
      title: appStrings.professionalSetupShowcaseTitle,
      description: appStrings.professionalSetupShowcaseSubtitle,
      child: Column(
        children: [
          _TitledContent(
            title: appStrings.professionalSetupVideoTitle,
            child: _IntroVideoManager(
              chewieController: _chewieController,
              videoFile: _introVideoFile,
              videoUrl: _existingIntroVideoUrl,
              onPickVideo: _pickVideo,
              onRemoveVideo: () =>
                  _removeMedia(_introVideoFile ?? _existingIntroVideoUrl, []),
            ),
          ),
          const Divider(height: 48),
          _TitledContent(
            title: appStrings.professionalSetupGalleryTitle,
            child: DefaultTabController(
              length: galleryCategories.length,
              child: Column(
                mainAxisSize: MainAxisSize.min, // Important for layout
                children: [
                  TabBar(
                    isScrollable: true,
                    tabs: galleryCategories
                        .map((cat) => Tab(text: cat))
                        .toList(),
                  ),
                  Container(
                    height: 300,
                    padding: const EdgeInsets.only(top: 20),
                    child: TabBarView(
                      children: galleryCategories.map((category) {
                        final fileList = _galleryImageFiles[category]!;
                        return _MediaGridUploader(
                          files: fileList,
                          onAdd: () => _pickMultiImage(category, fileList),
                          onRemove: (file) => _removeMedia(file, fileList),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 48),
          _TitledContent(
            title: appStrings.professionalSetupCertificationsTitle,
            child: _MediaGridUploader(
              files: _certificationImageFiles,
              onAdd: () => _pickMultiImage('certs', _certificationImageFiles),
              onRemove: (f) => _removeMedia(f, _certificationImageFiles),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationsSection(AppStrings appStrings) {
    return _SectionCard(
      title: appStrings.professionalSetupOperationsTitle,
      description: appStrings.professionalSetupOperationsSubtitle,
      child: Column(
        children: [
          _TitledContent(
            title: appStrings.professionalSetupPricingTitle,
            child: _CustomTextField(
              controller: _baseRateController,
              label: appStrings.professionalSetupLabelRate,
              icon: Icons.attach_money_outlined,
              isNumeric: true,
            ),
          ),
          const Divider(height: 48),
          _TitledContent(
            title: appStrings.professionalSetupAvailabilityTitle,
            child: _DayAvailabilityGrid(
              availability: _availability,
              onChanged: (day, newRange) =>
                  setState(() => _availability[day] = newRange),
            ),
          ),
        ],
      ),
    );
  }
}

// All helper widgets from here down are part of the State class
class _ProfileSectionModel {
  final String title;
  final IconData icon;
  final Widget child;
  _ProfileSectionModel({
    required this.title,
    required this.icon,
    required this.child,
  });
}

class _HeaderBar extends StatelessWidget {
  final double profileStrength;
  final VoidCallback? onSave;
  final bool isSaving;
  const _HeaderBar({
    required this.profileStrength,
    this.onSave,
    required this.isSaving,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appStrings = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: theme.colorScheme.surface,
      child: Row(
        children: [
          Expanded(child: _ProfileStrengthIndicator(strength: profileStrength)),
          const SizedBox(width: 24),
          ElevatedButton.icon(
            onPressed: onSave,
            icon: isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_alt_outlined, size: 20),
            label: Text(
              isSaving
                  ? appStrings.professionalSetupSaving
                  : appStrings.professionalSetupSaveAll,
            ),
          ),
        ],
      ),
    );
  }
}

class _WideNavMenu extends StatelessWidget {
  final List<_ProfileSectionModel> sections;
  final int selectedIndex;
  final Function(int) onSelect;
  const _WideNavMenu({
    required this.sections,
    required this.selectedIndex,
    required this.onSelect,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appStrings = AppLocalizations.of(context)!;
    return Container(
      width: 260,
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              appStrings.professionalSetupNavHeader,
              style: theme.textTheme.titleLarge,
            ),
          ),
          const Divider(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: sections.length,
              itemBuilder: (context, index) {
                final section = sections[index];
                return _NavTile(
                  title: section.title,
                  icon: section.icon,
                  isSelected: selectedIndex == index,
                  onTap: () => onSelect(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  const _NavTile({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedColor = theme.colorScheme.primary;
    final unselectedColor = theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Material(
        color: isSelected ? selectedColor.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border(
                left: BorderSide(
                  color: isSelected ? selectedColor : Colors.transparent,
                  width: 4,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: isSelected ? selectedColor : unselectedColor),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isSelected
                          ? selectedColor
                          : theme.colorScheme.onSurface,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileStrengthIndicator extends StatelessWidget {
  final double strength;
  const _ProfileStrengthIndicator({required this.strength});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appStrings = AppLocalizations.of(context)!;
    final percent = (strength * 100).toInt();
    final progressColor = Color.lerp(
      Colors.orange,
      theme.colorScheme.primary,
      strength,
    )!;
    return _SectionCard(
      title: appStrings.professionalSetupStrengthTitle,
      description: percent < 50
          ? appStrings.professionalSetupStrengthIncomplete
          : percent < 90
          ? appStrings.professionalSetupStrengthGood
          : appStrings.professionalSetupStrengthExcellent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: LinearProgressIndicator(
          value: strength,
          minHeight: 10,
          valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title, description;
  final Widget child;
  const _SectionCard({
    required this.title,
    required this.description,
    required this.child,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Divider(height: 32),
                child,
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, curve: Curves.easeOut);
  }
}

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

class _CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final Widget? suffixIcon;
  final bool isNumeric, isRequired;
  final int maxLines;

  const _CustomTextField({
    super.key, // Good practice to add super.key
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
    final appStrings = AppLocalizations.of(context)!;
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
            ? (v) => (v == null || v.isEmpty)
                  ? appStrings.professionalSetupValidatorRequired(label)
                  : null
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
    final appStrings = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          appStrings.professionalSetupSkillsSelectedTitle,
          style: theme.textTheme.titleMedium,
        ),
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
                    label: Text(appStrings.professionalSetupSkillsEmptyButton),
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
                      label: Text(appStrings.professionalSetupSkillsEditButton),
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

class _LocationCard extends StatelessWidget {
  final TextEditingController locationController;
  final double radius;
  final ValueChanged<double> onRadiusChanged;
  final bool isFetchingLocation;
  final VoidCallback onGetLocation;

  const _LocationCard({
    required this.locationController,
    required this.radius,
    required this.onRadiusChanged,
    required this.isFetchingLocation,
    required this.onGetLocation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appStrings = AppLocalizations.of(context)!;
    return Column(
      children: [
        _CustomTextField(
          controller: locationController,
          label: appStrings.professionalSetupLabelCity,
          hint: appStrings.professionalSetupHintCity,
          icon: Icons.location_city_outlined,
          suffixIcon: isFetchingLocation
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
                  onPressed: onGetLocation,
                  tooltip: appStrings.professionalSetupTooltipGetLocation,
                ),
        ),
        const SizedBox(height: 24),
        Text(
          appStrings.professionalSetupServiceRadiusTitle,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          appStrings.professionalSetupServiceRadiusSubtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(
              Icons.social_distance_outlined,
              color: theme.colorScheme.primary,
            ),
            Expanded(
              child: Slider(
                value: radius,
                min: 5,
                max: 100,
                divisions: 19,
                label: "${radius.round()} km",
                onChanged: onRadiusChanged,
              ),
            ),
            Text(
              "${radius.round()} km",
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _IntroVideoManager extends StatelessWidget {
  final ChewieController? chewieController;
  final PlatformFile? videoFile;
  final String? videoUrl;
  final VoidCallback onPickVideo, onRemoveVideo;

  const _IntroVideoManager({
    this.chewieController,
    this.videoFile,
    this.videoUrl,
    required this.onPickVideo,
    required this.onRemoveVideo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appStrings = AppLocalizations.of(context)!;
    final bool hasVideo =
        videoFile != null || (videoUrl != null && videoUrl!.isNotEmpty);

    if (!hasVideo) {
      // NEW, CORRECTED CODE
      return DottedBorder(
        options: RoundedRectDottedBorderOptions(
          color: theme.colorScheme.primary,
          strokeWidth: 2,
          dashPattern: const [8, 8],
          radius: const Radius.circular(16),
          padding: EdgeInsets.zero, // Important to keep child alignment
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
                    appStrings
                        .professionalSetupVideoEmptyButton, // Your string variable
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
        aspectRatio: chewieController?.aspectRatio ?? 9 / 16,
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
  final List<dynamic> files;
  final VoidCallback onAdd;
  final ValueChanged<dynamic> onRemove;
  const _MediaGridUploader({
    required this.files,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final appStrings = AppLocalizations.of(context)!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;
        final int crossAxisCount = availableWidth > 600 ? 4 : 3;
        const double spacing = 10.0;
        final double itemWidth =
            (availableWidth - (spacing * (crossAxisCount - 1))) /
            crossAxisCount;

        final List<Widget> children = [];

        for (final file in files) {
          ImageProvider imageProvider;
          if (file is String) {
            imageProvider = NetworkImage(file);
          } else {
            imageProvider = FileImage(File((file as XFile).path));
          }
          children.add(
            SizedBox(
              width: itemWidth,
              height: itemWidth,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image(
                      image: imageProvider,
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
              // NEW CODE - FIXED
              // NEW, CORRECTED CODE
              child: DottedBorder(
                options: RoundedRectDottedBorderOptions(
                  color: Theme.of(context).colorScheme.primary,
                  strokeWidth: 1.5,
                  dashPattern: const [6, 6],
                  radius: const Radius.circular(12),
                  padding: EdgeInsets.zero, // Important to keep child alignment
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
                          appStrings
                              .professionalSetupImageEmptyButton, // Your string variable
                          textAlign: TextAlign.center,
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

class _ProfileImagePicker extends StatelessWidget {
  final XFile? selectedImageFile;
  final String? existingImageUrl;
  final VoidCallback onTap;
  const _ProfileImagePicker({
    this.selectedImageFile,
    this.existingImageUrl,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    ImageProvider? imageProvider;
    if (selectedImageFile != null) {
      imageProvider = FileImage(File(selectedImageFile!.path));
    } else if (existingImageUrl != null && existingImageUrl!.isNotEmpty) {
      imageProvider = NetworkImage(existingImageUrl!);
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
                    Icons.person_outline,
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
    final appStrings = AppLocalizations.of(context)!;
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(appStrings.professionalSetupAvailabilityTo),
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
