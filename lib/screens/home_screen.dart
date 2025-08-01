import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui; // Required for ImageFilter
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Used for potential font customization
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart'; // Needed for DateFormat in cards (though not directly used in the provided snippets, good to keep if used elsewhere)
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:animate_do/animate_do.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:geolocator/geolocator.dart'; // For location services and distance calculation
import 'package:provider/provider.dart';
import 'widgets/ai_chat_panel.dart';

// --- Models, Services, Screens & Localization ---
import '../models/worker.dart';
import '../models/job.dart';
import '../models/user.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import '../services/app_string.dart'; // Assuming this provides AppLocalizations.of(context)
import '../providers/locale_provider.dart';
import '../providers/theme_provider.dart';
import 'worker_detail_screen.dart';
import 'jobs/create_job_screen.dart';
import 'jobs/job_detail_screen.dart';
import 'notifications_screen.dart';
import 'job_history_screen.dart';
import 'professional_setup_screen.dart';
import '../services/ai_chat_service.dart';

// ============================================================
//               HomeScreen Widget - FULL POWER!
// ============================================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  // --- Services & Controllers ---
  final FirebaseService _firebaseService = FirebaseService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final CarouselSliderController _carouselController =
      CarouselSliderController();
  late AnimationController _fabAnimationController;

  // --- State Variables ---
  bool _isLoading = true;
  String _userType = 'client';
  AppUser? _currentUser;
  double _appBarOpacity = 1.0; // Corrected initial value
  int _currentGradientIndex = 0;
  Timer? _gradientTimer;
  final Random _random = Random();
  bool showOverallLoader = false; // Placeholder for global loader

  // --- Data Lists ---
  List<Worker> _workers = [];
  List<Worker> _filteredWorkers = [];
  List<Worker> _featuredWorkers = [];
  List<Job> _jobs = [];
  List<Job> _filteredJobs = [];
  List<Job> _featuredJobs = [];

  // --- Filter States ---
  String _filterSelectedLocation = 'All';
  String _filterSelectedCategory = 'All';
  String _tempSelectedLocation = 'All';
  String _tempSelectedCategory = 'All';
  List<String> _locations = ['All'];
  final List<String> _baseCategories = [
    'All',
    'Plumbing',
    'Electrical',
    'Carpentry',
    'Painting',
    'Cleaning',
    'Gardening',
    'Handyman',
    'Tech Repair',
    'Tutoring',
    'Other'
  ];
  List<String> _availableCategories = ['All'];
  String _filterSelectedJobStatus = 'All';
  String _tempSelectedJobStatus = 'All';
  final List<String> _jobStatuses = ['All', 'Open', 'Assigned', 'Completed'];
  final Set<String> _dynamicLocations = {'All'};
  StreamSubscription? _notificationsSubscription;
  int _unreadNotificationsCount = 0;

  // --- Location Data ---
  double? _userLongitude;
  double? _userLatitude;

  // --- Constants & Configuration ---
  final Duration _shimmerDuration = const Duration(milliseconds: 1500);
  final Duration _animationDuration = const Duration(milliseconds: 450);
  final Curve _animationCurve = Curves.easeInOutCubic;
  bool _isChatPanelVisible = false;
  String _searchQueryForAi = '';

  // For "help me search" feature
  Timer? _aiSuggestionDebounce;
  bool _showAiSearchSuggestion = false;
  AiChatService? _aiChatService;
  bool _isAiServiceInitialized = false;

  // Dark Mode Specific Gradients (Expanded)
  static const List<List<Color>> _gentleAnimatedBgGradientsDark = [
    [Color(0xFF232526), Color(0xFF414345)], // charcoal
    [Color(0xFF141E30), Color(0xFF243B55)], // navy steel
    [Color(0xFF360033), Color(0xFF0B8793)], // purple teal
    [Color(0xFF2E3141), Color(0xFF4E546A)], // smoky night
    [Color(0xFF16222A), Color(0xFF3A6073)], // night ocean
    [Color(0xFF3E404E), Color(0xFF646883)], // twilight grey
    [Color(0xFF0F2027), Color(0xFF2C5364)], // deep space blue
    [Color(0xFF1F1C2C), Color(0xFF928DAB)], // violet mist
    [Color(0xFF2C3E50), Color(0xFF4CA1AF)], // midnight ice
    [Color(0xFF373B44), Color(0xFF4286f4)], // cobalt grey-blue
    [Color(0xFF1A2980), Color(0xFF26D0CE)], // galaxy ocean
    [
      Color(0xFF1D2B64),
      Color(0xFFF8CDDA)
    ], // elegant indigo (fades to pink mist)
    [Color(0xFF0F0C29), Color(0xFF302B63)], // purple abyss
    [Color(0xFF000000), Color(0xFF434343)], // true black to soft black
    [Color(0xFF1B1B2F), Color(0xFF16213E)], // dark royal blue blend
    [Color(0xFF3A1C71), Color(0xFFD76D77)], // luxury violet-pink
  ];

  // Light Mode Specific Gradients (New & Beautiful)
  static const List<List<Color>> _gentleAnimatedBgGradientsLight = [
    [Color(0xFFFFF9C4), Color(0xFFFFF59D)], // soft yellow sunshine
    [Color(0xFFFFF1F0), Color(0xFFC1C8E4)], // soft pink to light blue
    [Color(0xFFB39DDB), Color(0xFF90CAF9)], // violet to light sky blue
    [Color(0xFFFFE082), Color(0xFFFFC107)], // mellow yellow glow
    [Color(0xFFFFF3E0), Color(0xFFF48FB1)], // cream to soft pink
    [Color(0xFFC5E1A5), Color(0xFF81C784)], // pastel green to mint
    [Color(0xFFFFF176), Color(0xFFFF8A65)], // sunlit peach
    [Color(0xFFFFECB3), Color(0xFFFFAB91)], // golden amber to coral
    [Color(0xFFBBDEFB), Color(0xFF9FA8DA)], // calm blue gradient
    [Color(0xFFFFF59D), Color(0xFFF48FB1)], // warm yellow to blush
    [Color(0xFFFFCDD2), Color(0xFFFFF9C4)], // soft rose white
    [Color(0xFFDCE775), Color(0xFFDCEDC8)], // citrus yellow to light green
  ];

  @override
  void initState() {
    super.initState();

    _fabAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _scrollController.addListener(_scrollListener);
    _searchController.addListener(_onSearchChanged);
    _determineUserTypeAndLoadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateBackgroundAnimationBasedOnTheme();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateBackgroundAnimationBasedOnTheme();
    _listenForNotifications();
  }

  @override
  void dispose() {
    _gradientTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _aiSuggestionDebounce?.cancel();
    _searchController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _fabAnimationController.dispose();
    _gradientTimer?.cancel();
    _aiSuggestionDebounce?.cancel(); // <-- ADD THIS
    _searchController.removeListener(_onSearchChanged);
    super.dispose();
  }

  // --- Core Logic & Data Fetching ---

  // Re-integrated _getCurrentUserLocation

  Future<void> _getCurrentUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("Location services are disabled.");
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print("Location permissions are denied.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print(
          "Location permissions are permanently denied, we cannot request permissions.");
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _userLatitude = position.latitude;
          _userLongitude = position.longitude;
        });
        print(
            "DEBUG: User location fetched: Lat: $_userLatitude, Lon: $_userLongitude");
      }
    } catch (e) {
      print("Error getting location: $e");
      if (mounted) {
        _showErrorSnackbar(
            "Could not get your location. Distances won't be available.");
      }
    }
  }

  void _listenForNotifications() {
    // Stop any previous listener
    _notificationsSubscription?.cancel();

    // Start listening to the stream from your FirebaseService
    _notificationsSubscription =
        _firebaseService.getUserNotificationsStream().listen((notifications) {
      if (mounted) {
        // Count notifications where 'isRead' is false
        final unreadCount = notifications.where((notif) {
          final isRead = notif['isRead'] as bool?;
          return isRead == false; // Only count unread items
        }).length;

        // Update the state to rebuild the AppBar badge
        setState(() {
          _unreadNotificationsCount = unreadCount;
        });
      }
    });
  }

  void _startBackgroundAnimation() {
    if (!mounted) return;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final List<List<Color>> activeGradients = isDarkMode
        ? _gentleAnimatedBgGradientsDark
        : _gentleAnimatedBgGradientsLight;

    _gradientTimer?.cancel();
    _gradientTimer = Timer.periodic(const Duration(seconds: 12), (timer) {
      if (mounted) {
        // Check theme again inside the timer callback, as it might change
        final currentIsDarkMode =
            Theme.of(context).brightness == Brightness.dark;
        if (currentIsDarkMode != isDarkMode) {
          // If theme changed, restart timer with new list
          _updateBackgroundAnimationBasedOnTheme();
          timer.cancel();
          return;
        }

        setState(() {
          _currentGradientIndex =
              (_currentGradientIndex + 1) % activeGradients.length;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _updateBackgroundAnimationBasedOnTheme() {
    if (!mounted) return;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bool isTimerActive =
        _gradientTimer != null && _gradientTimer!.isActive;
    // Get the current list being used by the timer, if any
    final List<List<Color>> currentActiveGradients = _gradientTimer == null ||
            _currentGradientIndex >=
                _gentleAnimatedBgGradientsDark.length // Fallback
        ? (isDarkMode
            ? _gentleAnimatedBgGradientsDark
            : _gentleAnimatedBgGradientsLight)
        : (Theme.of(context).brightness == Brightness.dark
            ? _gentleAnimatedBgGradientsDark
            : _gentleAnimatedBgGradientsLight); // More precise check

    final List<List<Color>> desiredGradients = isDarkMode
        ? _gentleAnimatedBgGradientsDark
        : _gentleAnimatedBgGradientsLight;

    // Restart timer if it's not active, or if the active gradient list has changed
    if (!isTimerActive || currentActiveGradients != desiredGradients) {
      _gradientTimer?.cancel();
      setState(() {
        _currentGradientIndex = 0; // Reset index when switching gradient sets
      });
      _startBackgroundAnimation();
    }
  }

  void _scrollListener() {
    if (!mounted) return;
    double offset = _scrollController.offset;
    double maxOffset = 150;
    double newOpacity = (1.0 - (offset / maxOffset)).clamp(0.0, 1.0);
    if (_appBarOpacity != newOpacity) {
      setStateIfMounted(() {
        _appBarOpacity = newOpacity;
      });
    }
  }

  void _onSearchChanged() {
    if (!mounted) return;

    // Debounce for AI suggestion
    if (_aiSuggestionDebounce?.isActive ?? false)
      _aiSuggestionDebounce!.cancel();
    _aiSuggestionDebounce = Timer(const Duration(milliseconds: 750), () {
      final text = _searchController.text.trim();
      final isQuestion = text.isNotEmpty &&
          (text.endsWith('?') ||
              text.toLowerCase().startsWith('how') ||
              text.toLowerCase().startsWith('what') ||
              text.toLowerCase().startsWith('can i'));

      if (isQuestion) {
        setStateIfMounted(() {
          _showAiSearchSuggestion = true;
          _searchQueryForAi = text;
        });
      } else {
        setStateIfMounted(() {
          _showAiSearchSuggestion = false;
          _searchQueryForAi = '';
        });
      }
    });

    // Regular filter logic (no change needed here)
    if (_userType == 'client') {
      _applyWorkerFilters();
    } else {
      _applyJobFilters();
    }
  }

  Future<void> _determineUserTypeAndLoadData() async {
    if (!mounted) return;
    setStateIfMounted(() {
      _isLoading = true;
    });
    await _getCurrentUserLocation(); // Ensure location is determined early
    _fabAnimationController.forward();
    try {
      final userProfile = await _authService.getCurrentUserProfile();
      if (!mounted) return;
      if (userProfile == null) {
        setStateIfMounted(() {
          _userType = 'client';
          _currentUser = null;
        });
      } else {
        setStateIfMounted(() {
          _currentUser = userProfile;
          _userType =
              userProfile.role?.toLowerCase() == 'worker' ? 'worker' : 'client';
        });
      }
      _filterSelectedLocation = _tempSelectedLocation = 'All';
      _filterSelectedCategory = _tempSelectedCategory = 'All';
      _filterSelectedJobStatus = _tempSelectedJobStatus = 'All';
      await _refreshData(isInitialLoad: true);
    } catch (e, s) {
      print('FATAL ERROR: Determining user type failed: $e\n$s');
      if (mounted) {
        _showErrorSnackbar(
            AppLocalizations.of(context)?.snackErrorLoadingProfile ??
                'Error loading profile.',
            isCritical: true);
      }
      if (mounted) {
        setStateIfMounted(() {
          _userType = 'client';
          _isLoading = false;
        });
      }
    } finally {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _isLoading) setStateIfMounted(() => _isLoading = false);
      });
    }
  }

  Future<void> _refreshData({bool isInitialLoad = false}) async {
    if (!mounted) return;
    if (_userLatitude == null || _userLongitude == null) {
      await _getCurrentUserLocation(); // Re-attempt location if null
    }
    if (isInitialLoad || !_isLoading) {
      setStateIfMounted(() => _isLoading = true);
    }
    try {
      if (_userType == 'client') {
        await _loadWorkers();
      } else {
        await _loadJobs();
      }
    } catch (e, s) {
      print('ERROR: Refreshing data failed: $e\n$s');
      if (mounted) {
        _showErrorSnackbar(AppLocalizations.of(context)?.snackErrorLoading ??
            'Failed to refresh.');
      }
    } finally {
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted && _isLoading) setStateIfMounted(() => _isLoading = false);
    }
  }

  void setStateIfMounted(VoidCallback f) {
    if (mounted) setState(f);
  }

  // --- Data Loading ---
  // Renamed from _loadUserProfile to avoid confusion with `_currentUser` loading
  // This is used specifically after locale change in AppBar actions.
  void _loadUserProfileAfterLocaleChange() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    final strings = AppLocalizations.of(context);
    if (strings == null) {
      print(
          "Error: AppLocalizations not found in context during profile load.");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: const Text(
                  'Error: Localization service not available.'), // Fallback text
              backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
      return;
    }

    try {
      final userData = await _firebaseService.getCurrentUserProfile();
      if (!mounted) return;
      setState(() {
        _currentUser = userData; // Update current user
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user profile: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        final errorMsg =
            strings.snackErrorLoadingProfile ?? 'Error loading profile:';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('$errorMsg $e'),
              backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    }
  }

// Replace your existing _onSearchChanged method with this new one

  Future<void> _loadWorkers() async {
    if (!mounted) return;
    print("DEBUG: Loading workers...");
    try {
      final workers = await _firebaseService.getWorkers();
      if (!mounted) return;
      print("DEBUG: Fetched ${workers.length} workers.");

      // Calculate distances for workers if user location is known
      if (_userLatitude != null && _userLongitude != null) {
        print("DEBUG: Pre-calculating distances as location is already known.");
        for (var worker in workers) {
          if (worker.latitude != null && worker.longitude != null) {
            final distanceInMeters = Geolocator.distanceBetween(
              _userLatitude!,
              _userLongitude!,
              worker.latitude!,
              worker.longitude!,
            );
            worker.distance =
                distanceInMeters / 1000.0; // Convert to kilometers
          }
        }
      }

      _dynamicLocations.clear();
      _dynamicLocations.add('All');
      final Set<String> dynamicCategories = {'All', ..._baseCategories};
      for (var worker in workers) {
        if (worker.location != null && worker.location!.isNotEmpty) {
          _dynamicLocations.add(worker.location!);
        }
        if (worker.profession != null && worker.profession!.isNotEmpty) {
          bool isBaseCategory = _baseCategories.any((b) =>
              b != 'All' &&
              worker.profession!.toLowerCase().contains(b.toLowerCase()));
          if (!isBaseCategory &&
              !_baseCategories.contains(worker.profession!) && // Added !
              worker.profession!.trim().isNotEmpty) {
            dynamicCategories.add(worker.profession!);
          }
        }
      }
      final sortedLocations = _dynamicLocations.toList()..sort();
      final sortedCategories = dynamicCategories.toList()
        ..sort((a, b) => a == 'All'
            ? -1
            : b == 'All'
                ? 1
                : a.compareTo(b));
      List<Worker> sortedByRating = List.from(workers)
        ..sort((a, b) => (b.rating ?? 0.0).compareTo(a.rating ?? 0.0));
      final featured = sortedByRating.take(5).toList();
      setStateIfMounted(() {
        _workers = workers;
        _featuredWorkers = featured;
        _locations = sortedLocations;
        _availableCategories = sortedCategories;
        _applyWorkerFilters();
      });
      await _initializeAiService();
    } catch (e, s) {
      print("DEBUG: Error loading workers: $e\n$s");
      if (mounted) {
        _showErrorSnackbar(
            AppLocalizations.of(context)?.snackErrorLoading ??
                "Error fetching professionals.",
            isCritical: true);
      }
      setStateIfMounted(() {
        _workers = [];
        _featuredWorkers = [];
        _filteredWorkers = [];
      });
    }
  }

  Future<void> _initializeAiService() async {
    print("HomeScreen: Initializing PERSONALIZED AI Service...");
    _aiChatService = AiChatService();

    // Call the new, more powerful initialization method
    await _aiChatService!.initializePersonalizedChat();

    setState(() {
      _isAiServiceInitialized = true; // AI is ready!
    });
    print("HomeScreen: PERSONALIZED AI Service is now ready.");
  }

  Future<void> _loadJobs() async {
    if (!mounted) return;
    print("DEBUG: Loading jobs...");
    try {
      final jobs = await _firebaseService.getJobs();
      if (!mounted) return;
      print("DEBUG: Fetched ${jobs.length} jobs.");
      List<Job> openJobs = jobs
          .where((j) => j.status?.toLowerCase() == 'open')
          .toList()
        ..sort((a, b) =>
            (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
      final featured = openJobs.take(5).toList();
      setStateIfMounted(() {
        _jobs = jobs;
        _featuredJobs = featured;
        _applyJobFilters();
      });
    } catch (e, s) {
      print("DEBUG: Error loading jobs: $e\n$s");
      if (mounted) {
        _showErrorSnackbar(
            AppLocalizations.of(context)?.snackErrorLoading ??
                "Error fetching jobs.",
            isCritical: true);
      }
      setStateIfMounted(() {
        _jobs = [];
        _featuredJobs = [];
        _filteredJobs = [];
      });
    }
  }

  void _applyWorkerFilters() {
    if (!mounted) return;
    final query = _searchController.text.toLowerCase().trim();
    final String allKey = 'All';
    if (_workers.isEmpty && !_isLoading) {
      setStateIfMounted(() => _filteredWorkers = []);
      return;
    }
    final List<Worker> filtered = _workers.where((worker) {
      final locationMatch = (_filterSelectedLocation == allKey ||
          (worker.location?.toLowerCase() ?? '') ==
              _filterSelectedLocation.toLowerCase());
      final categoryMatch = (_filterSelectedCategory == allKey ||
          (worker.profession?.toLowerCase() ?? '')
              .contains(_filterSelectedCategory.toLowerCase()));
      final searchMatch = query.isEmpty
          ? true
          : ((worker.name?.toLowerCase() ?? '').contains(query) ||
              (worker.profession?.toLowerCase() ?? '').contains(query) ||
              (worker.location?.toLowerCase() ?? '').contains(query) ||
              (worker.skills?.any((s) => (s?.toLowerCase() ?? '')
                      .contains(query)) ?? // Added null-aware
                  false) ||
              (worker.about?.toLowerCase() ?? '').contains(query));
      return locationMatch && categoryMatch && searchMatch;
    }).toList();
    print(
        "DEBUG: Workers filtered: ${filtered.length} results for query '$query', loc '$_filterSelectedLocation', cat '$_filterSelectedCategory'");
    setStateIfMounted(() {
      _filteredWorkers = filtered;
    });
  }

  void _applyJobFilters() {
    if (!mounted) return;
    final query = _searchController.text.toLowerCase().trim();
    final String allKey = 'All';
    if (_jobs.isEmpty && !_isLoading) {
      setStateIfMounted(() => _filteredJobs = []);
      return;
    }
    final List<Job> filtered = _jobs.where((job) {
      final statusMatch = (_filterSelectedJobStatus == allKey ||
          (job.status?.toLowerCase() ?? '') ==
              _filterSelectedJobStatus.toLowerCase());
      final searchMatch = query.isEmpty
          ? true
          : ((job.title?.toLowerCase() ?? '').contains(query) ||
              (job.description?.toLowerCase() ?? '').contains(query) ||
              (job.location?.toLowerCase() ?? '').contains(query));
      return statusMatch && searchMatch;
    }).toList();
    print(
        "DEBUG: Jobs filtered: ${filtered.length} results for query '$query', status '$_filterSelectedJobStatus'");
    setStateIfMounted(() {
      _filteredJobs = filtered;
    });
  }

  // --- Navigation ---
  void _navigateToCreateJob({String? preselectedWorkerId}) {
    Navigator.push(
            context,
            _createFadeRoute(
                CreateJobScreen(preselectedWorkerId: preselectedWorkerId)))
        .then((jobCreated) {
      if (jobCreated == true) _refreshData();
    });
  }

  void _navigateToWorkerDetails(Worker worker) {
    Navigator.push(
        context, _createFadeRoute(WorkerDetailScreen(worker: worker)));
  }

  void _navigateToJobDetails(Job job) {
    Navigator.push(context, _createFadeRoute(JobDetailScreen(job: job)))
        .then((_) => _refreshData());
  }

  void _navigateToCreateProfile() {
    Navigator.push(context, _createFadeRoute(const ProfessionalSetupScreen()))
        .then((profileUpdated) {
      if (profileUpdated == true) _determineUserTypeAndLoadData();
    });
  }

  void _navigateToNotifications() {
    Navigator.push(context, _createFadeRoute(const NotificationsScreen()));
  }

  void _navigateToHistory() {
    Navigator.push(context, _createFadeRoute(const JobHistoryScreen()));
  }

  Route _createFadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (c, a1, a2) => page,
      transitionsBuilder: (c, a1, a2, child) =>
          FadeTransition(opacity: a1, child: child),
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  // Placeholder methods for new AppBar actions
  // Renamed to avoid confusion with the main _determineUserTypeAndLoadData
  void _updateUserAfterLocaleChange() async {
    print('Loading user profile (after locale change)');
    await _determineUserTypeAndLoadData(); // Re-load data based on current user/locale
  }

  Future<void> _signOut() async {
    setState(() {
      showOverallLoader = true;
    });
    try {
      await _authService.signOut();
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      print("Error signing out: $e");
      rethrow;
    } finally {
      if (mounted) {
        setState(() {
          showOverallLoader = false;
        });
      }
    }
  }

  // --- UI Building Blocks ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDarkMode = theme.brightness == Brightness.dark;
    final appStrings =
        AppLocalizations.of(context); // Get localized strings safely

    // Ensure appStrings is available before building the UI
    if (appStrings == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
            child: CircularProgressIndicator(color: colorScheme.primary)),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateBackgroundAnimationBasedOnTheme();
    });

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
            child: CircularProgressIndicator(color: colorScheme.primary)),
      );
    }

    print(
        "DEBUG: HomeScreen build | userType: $_userType | FW: ${_filteredWorkers.length} | FJ: ${_filteredJobs.length} | isDark: $isDarkMode | Locale: ${appStrings.locale.languageCode}");

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar:
          _buildAppBar(theme, colorScheme, textTheme, isDarkMode, appStrings),
      body: Stack(
        // <-- WRAP WITH A STACK
        children: [
          // The original body content
          _buildAnimatedBackground(
            theme,
            isDarkMode,
            child: SafeArea(
                top: false,
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top +
                          (kToolbarHeight + 10)),
                  child: _buildBodyContent(
                      theme, colorScheme, textTheme, isDarkMode, appStrings),
                )),
          ),

          // --- ADD THE NEW OVERLAYS ---

          // The AI Chat Floating Button
          _buildChatToggleButton(colorScheme),

          if (_isAiServiceInitialized) // This check is important!
            AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOutCubic,
              top: 120,
              bottom: 90,
              right: _isChatPanelVisible ? 0 : -405,
              child: AiChatPanel(
                // --- THIS IS THE FIX ---
                // Give the panel the fully prepared AI service
                aiChatService: _aiChatService!,
                // ---------------------
                onClose: () {
                  setState(() {
                    _isChatPanelVisible = false;
                  });
                },
              ),
            ),

          // --- END OF NEW OVERLAYS ---
        ],
      ),
      floatingActionButton: _buildAnimatedFloatingActionButton(
          theme, colorScheme, textTheme, appStrings),
    );
  }

  Widget _buildChatToggleButton(ColorScheme colorScheme) {
    return Positioned(
      top: 180, // Adjust as needed
      right: 16,
      child: ScaleTransition(
        scale: _fabAnimationController, // Re-use existing FAB animation
        child: FloatingActionButton(
          mini: true, // Make it a bit smaller
          onPressed: !_isAiServiceInitialized
              ? null
              : () {
                  setState(() {
                    _isChatPanelVisible = !_isChatPanelVisible;
                  });
                },
          backgroundColor:
              !_isAiServiceInitialized ? Colors.grey : colorScheme.secondary,
          tooltip: "AI Assistant",
          elevation: 4.0,
          foregroundColor: colorScheme.onSecondary,
          child: const Icon(Icons.auto_awesome),
        ),
      ),
    );
  }

  Widget _buildAiSearchSuggestion(
      ColorScheme colorScheme, TextTheme textTheme, AppStrings appStrings) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return SizeTransition(
          sizeFactor: animation,
          axisAlignment: -1.0,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: !_showAiSearchSuggestion
          ? const SizedBox.shrink() // Show nothing if not a question
          : Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: OutlinedButton.icon(
                icon: Icon(Icons.auto_awesome,
                    size: 18, color: colorScheme.secondary),
                label: Text(
                  'askAiAboutIt', // Use localized string
                  style: textTheme.labelLarge
                      ?.copyWith(color: colorScheme.secondary),
                ),
                onPressed: () {
                  setState(() {
                    _isChatPanelVisible = true;
                    // The search query is already set in _searchQueryForAi
                  });
                },
                style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: colorScheme.secondary.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8)),
              ),
            ),
    );
  }

  Widget _buildAnimatedBackground(ThemeData theme, bool isDarkMode,
      {required Widget child}) {
    final List<List<Color>> activeGradients = isDarkMode
        ? _gentleAnimatedBgGradientsDark
        : _gentleAnimatedBgGradientsLight;
    return AnimatedContainer(
      duration: const Duration(seconds: 5),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: activeGradients[_currentGradientIndex],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: child,
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme, ColorScheme colorScheme,
      TextTheme textTheme, bool isDarkMode, AppStrings appStrings) {
    final appBarTheme = theme.appBarTheme;
    // AppBar background color based on theme with opacity
    Color appBarBg = (appBarTheme.backgroundColor ?? colorScheme.surface)
        .withOpacity(0.85 * _appBarOpacity);
    // Determine icon color for AppBar actions
    Color iconColor = theme.appBarTheme.iconTheme?.color ??
        (isDarkMode ? colorScheme.onSurface : colorScheme.onPrimary);

    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 10),
      child: AnimatedOpacity(
        duration: _animationDuration,
        opacity: _appBarOpacity.clamp(0.4, 1.0),
        child: ClipRect(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(
                sigmaX: 5.0 * (1 - _appBarOpacity),
                sigmaY: 5.0 * (1 - _appBarOpacity)),
            child: AppBar(
              backgroundColor: appBarBg, // Use calculated background
              elevation: appBarTheme.elevation ?? 0,
              scrolledUnderElevation: appBarTheme.scrolledUnderElevation ?? 0,
              titleSpacing: 16.0,
              title: _buildGreeting(textTheme, colorScheme, appStrings),
              actions: _buildAppBarActions(
                  theme, colorScheme, appStrings, isDarkMode, iconColor),
              iconTheme: appBarTheme.iconTheme, // Use theme's icon theme
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting(
      TextTheme textTheme, ColorScheme colorScheme, AppStrings appStrings) {
    String title = _userType == 'client'
        ? appStrings.findExpertsTitle
        : appStrings.yourJobFeedTitle;
    String? firstName =
        _currentUser?.name?.split(' ').first; // Null-aware access
    String welcomeMessage = firstName != null && firstName.isNotEmpty
        ? appStrings.helloUser(firstName)
        : title;
    TextStyle? greetingStyle = GoogleFonts.poppins(
      // Use GoogleFonts for greeting
      fontSize: textTheme.headlineSmall?.fontSize,
      fontWeight: FontWeight.w600,
      color: textTheme.headlineSmall?.color ?? colorScheme.onSurface,
      shadows: [
        Shadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2))
      ],
    );
    return FadeInLeft(
      delay: const Duration(milliseconds: 200),
      duration: _animationDuration,
      child: Text(
        welcomeMessage,
        style: greetingStyle,
      ),
    );
  }

  List<Widget> _buildAppBarActions(ThemeData theme, ColorScheme colorScheme,
      AppStrings appStrings, bool isDarkMode, Color iconColor) {
    // Pass iconColor

    List<Color> notificationGradient = [
      colorScheme.error,
      colorScheme.errorContainer ?? colorScheme.error.withOpacity(0.7)
    ];
    return [
      FadeInRight(
        delay: const Duration(milliseconds: 300),
        duration: _animationDuration,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAppBarAction(
                theme,
                colorScheme,
                notificationGradient,
                Icons.notifications_active_outlined,
                _navigateToNotifications,
                iconColor,
                notificationCount:
                    _unreadNotificationsCount, // <-- USE THE REAL COUNT HERE
                tooltip: appStrings.notificationTitle),
            _buildAppBarAction(
                theme,
                colorScheme,
                notificationGradient,
                Icons.history_edu_outlined,
                _navigateToHistory,
                iconColor, // Pass iconColor
                tooltip: appStrings.navHistory),
            IconButton(
              icon: Icon(
                isDarkMode ? Icons.wb_sunny_outlined : Icons.nightlight_round,
                color: iconColor, // Use provided iconColor
              ),
              tooltip: isDarkMode
                  ? appStrings.themeTooltipLight // Use appStrings
                  : appStrings.themeTooltipDark, // Use appStrings
              onPressed: () {
                try {
                  Provider.of<ThemeProvider>(context, listen: false)
                      .toggleTheme();
                } catch (e) {
                  print("Error accessing ThemeProvider: $e");
                  rethrow; // Use appStrings
                }
              },
            ),
            IconButton(
              icon: Icon(Icons.language,
                  color: iconColor), // Use provided iconColor
              tooltip: appStrings.languageToggleTooltip, // Use appStrings
              onPressed: () {
                try {
                  final localeProvider =
                      Provider.of<LocaleProvider>(context, listen: false);
                  final currentLocale = localeProvider.locale;
                  final nextLocale = currentLocale.languageCode == 'en'
                      ? const Locale('am')
                      : const Locale('en');
                  localeProvider.setLocale(nextLocale);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      _updateUserAfterLocaleChange(); // Call new method
                    }
                  });
                } catch (e) {
                  print("Error getting LocaleProvider: $e");
                  rethrow; // Use appStrings
                }
              },
            ),
            IconButton(
              icon: Icon(Icons.logout,
                  color: iconColor), // Use provided iconColor
              onPressed: showOverallLoader ? null : _signOut,
              tooltip: appStrings.generalLogout, // Use appStrings
            ),
            const SizedBox(width: 8),
          ],
        ),
      )
    ];
  }

  Widget _buildAppBarAction(
      ThemeData theme,
      ColorScheme colorScheme,
      List<Color> notificationGradient,
      IconData icon,
      VoidCallback onPressed,
      Color iconColor, // Added iconColor parameter
      {int? notificationCount,
      required String tooltip}) {
    final badgeTextColor =
        ThemeData.estimateBrightnessForColor(colorScheme.error) ==
                Brightness.dark
            ? Colors.white
            : Colors.black;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Center(
        child: IconButton(
          icon: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(icon, size: 26, color: iconColor.withOpacity(0.9)),
              if (notificationCount != null && notificationCount > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: BounceInDown(
                    delay: const Duration(milliseconds: 500),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                          gradient:
                              LinearGradient(colors: notificationGradient),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: colorScheme.surface.withOpacity(0.8),
                              width: 1.5)),
                      constraints:
                          const BoxConstraints(minWidth: 20, minHeight: 20),
                      child: Text(
                        '$notificationCount',
                        style: theme.textTheme.labelSmall?.copyWith(
                                color: badgeTextColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 10) ??
                            TextStyle(
                                color: badgeTextColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          onPressed: onPressed,
          splashRadius: 24,
          tooltip: tooltip,
          color: iconColor,
          splashColor: colorScheme.primary.withOpacity(0.2),
          highlightColor: colorScheme.primary.withOpacity(0.1),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }

  Widget _buildBodyContent(ThemeData theme, ColorScheme colorScheme,
      TextTheme textTheme, bool isDarkMode, AppStrings appStrings) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      switchInCurve: Curves.easeOutQuart,
      switchOutCurve: Curves.easeInQuart,
      transitionBuilder: (child, animation) {
        final oA = Tween<Offset>(
                begin: const Offset(0.0, 0.2), end: Offset.zero)
            .animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutQuart));
        final sA = Tween<double>(begin: 0.95, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutQuart));
        return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
                scale: sA, child: SlideTransition(position: oA, child: child)));
      },
      child: _isLoading
          ? _buildShimmerLoading(theme, colorScheme, isDarkMode)
          : _buildMainContent(
              theme, colorScheme, textTheme, isDarkMode, appStrings),
    );
  }

  Widget _buildMainContent(ThemeData theme, ColorScheme colorScheme,
      TextTheme textTheme, bool isDarkMode, AppStrings appStrings) {
    bool isEmpty = (_userType == 'client' && _filteredWorkers.isEmpty) ||
        (_userType == 'worker' && _filteredJobs.isEmpty);
    return LiquidPullToRefresh(
      key: ValueKey<String>("content_loaded_${_userType}_${theme.brightness}"),
      onRefresh: _refreshData,
      color: colorScheme.surfaceVariant, // Changed from surfaceContainerHighest
      backgroundColor: colorScheme.secondary,
      height: 60,
      animSpeedFactor: 1.5,
      showChildOpacityTransition: false,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
              key: const ValueKey("search_filter_header"),
              child: FadeInDown(
                  duration: _animationDuration,
                  child: _buildSearchAndFilterHeader(
                      theme, colorScheme, textTheme, isDarkMode, appStrings))),
          SliverToBoxAdapter(
              key: const ValueKey("featured_section"),
              child: _buildFeaturedSection(
                  theme, colorScheme, textTheme, isDarkMode, appStrings)),
          isEmpty
              ? SliverFillRemaining(
                  key: const ValueKey("empty_state_sliver"),
                  hasScrollBody: false,
                  child: _buildEmptyStateWidget(
                      theme, colorScheme, textTheme, appStrings),
                )
              : _buildContentGridSliver(theme, colorScheme, textTheme,
                  isDarkMode), // Cards handle their own context
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterHeader(ThemeData theme, ColorScheme colorScheme,
      TextTheme textTheme, bool isDarkMode, AppStrings appStrings) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
      // WRAP THE ROW WITH A COLUMN
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                  child: _buildSearchBar(
                      theme, colorScheme, textTheme, appStrings)),
              const SizedBox(width: 12),
              _buildFilterButton(theme, colorScheme, textTheme, isDarkMode),
            ],
          ),
          // CALL THE NEW WIDGET HERE
          _buildAiSearchSuggestion(colorScheme, textTheme, appStrings),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme, ColorScheme colorScheme,
      TextTheme textTheme, AppStrings appStrings) {
    final inputTheme = theme.inputDecorationTheme;
    final iconColor = theme.iconTheme.color ?? colorScheme.onSurfaceVariant;
    return Container(
      decoration: BoxDecoration(
          color: inputTheme.fillColor ??
              colorScheme.surfaceVariant
                  .withOpacity(0.8), // Changed from surfaceContainerHighest
          borderRadius: BorderRadius.circular(30.0),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(
                    theme.brightness == Brightness.dark ? 0.5 : 0.1),
                blurRadius: 12,
                spreadRadius: -4,
                offset: const Offset(0, 4))
          ]),
      child: TextField(
        controller: _searchController,
        style: textTheme.bodyLarge?.copyWith(fontSize: 15),
        decoration: InputDecoration(
          hintText: _userType == 'client'
              ? appStrings.searchHintProfessionals
              : appStrings.searchHintJobs,
          hintStyle: inputTheme.hintStyle ??
              textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.7)),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 18, right: 12),
            child: Icon(Icons.search_rounded, color: iconColor, size: 22),
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 0, minHeight: 0),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear_rounded, color: iconColor, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    if (_userType == 'client') {
                      _applyWorkerFilters();
                    } else {
                      _applyJobFilters();
                    }
                  },
                  splashRadius: 20,
                )
              : null,
          border: inputTheme.border ?? InputBorder.none,
          enabledBorder:
              inputTheme.enabledBorder ?? inputTheme.border ?? InputBorder.none,
          focusedBorder:
              inputTheme.focusedBorder ?? inputTheme.border ?? InputBorder.none,
          contentPadding: inputTheme.contentPadding ??
              const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }

  Widget _buildFilterButton(ThemeData theme, ColorScheme colorScheme,
      TextTheme textTheme, bool isDarkMode) {
    bool filtersActive = (_userType == 'client' &&
            (_filterSelectedLocation != 'All' ||
                _filterSelectedCategory != 'All')) ||
        (_userType == 'worker' && _filterSelectedJobStatus != 'All');
    Color iconSelectedColor = colorScheme.onSecondary;
    Color iconDefaultColor = colorScheme.onSurfaceVariant;
    List<Color> defaultGradient = isDarkMode
        ? [
            colorScheme.surfaceVariant,
            colorScheme.surface
          ] // Changed from surfaceContainerHighest
        : [
            theme.cardColor.withOpacity(0.8),
            theme.canvasColor.withOpacity(0.8)
          ];
    List<Color> activeGradient = [
      colorScheme.secondary,
      colorScheme.secondaryContainer ?? colorScheme.secondary.withOpacity(0.7)
    ];
    return AnimatedContainer(
      duration: _animationDuration,
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: filtersActive ? activeGradient : defaultGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: filtersActive
                    ? colorScheme.secondary.withOpacity(isDarkMode ? 0.4 : 0.3)
                    : Colors.black.withOpacity(isDarkMode ? 0.5 : 0.1),
                blurRadius: filtersActive ? 10 : 12,
                spreadRadius: filtersActive ? 1 : -4,
                offset: Offset(0, filtersActive ? 3 : 4))
          ]),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: () => _showFilterPanel(theme, colorScheme, textTheme),
          borderRadius: BorderRadius.circular(25),
          splashColor: colorScheme.primary.withOpacity(0.3),
          highlightColor: colorScheme.primary.withOpacity(0.15),
          child: Padding(
            padding: const EdgeInsets.all(13.0),
            child: Icon(
              filtersActive
                  ? Icons.filter_alt_rounded
                  : Icons.filter_list_rounded,
              color: filtersActive ? iconSelectedColor : iconDefaultColor,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedSection(ThemeData theme, ColorScheme colorScheme,
      TextTheme textTheme, bool isDarkMode, AppStrings appStrings) {
    bool hasFeatured = (_userType == 'client' && _featuredWorkers.isNotEmpty) ||
        (_userType == 'worker' && _featuredJobs.isNotEmpty);
    if (!hasFeatured) return const SizedBox.shrink();
    String title = _userType == 'client'
        ? appStrings.featuredPros
        : appStrings.featuredJobs;
    int itemCount =
        _userType == 'client' ? _featuredWorkers.length : _featuredJobs.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 12.0),
          child: FadeInLeft(
              duration: _animationDuration,
              delay: const Duration(milliseconds: 100),
              child: Text(title,
                  style: GoogleFonts.poppins(
                      fontSize: textTheme.titleMedium?.fontSize,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withOpacity(0.7)))),
        ),
        SizedBox(
          height: 180,
          child: CarouselSlider.builder(
            carouselController: _carouselController,
            itemCount: itemCount,
            itemBuilder: (context, index, realIndex) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                child: _userType == 'client'
                    ? FeaturedWorkerCard(
                        worker: _featuredWorkers[index],
                        onTap: () =>
                            _navigateToWorkerDetails(_featuredWorkers[index]),
                      )
                    : FeaturedJobCard(
                        // Now correctly using FeaturedJobCard
                        job: _featuredJobs[index],
                        onTap: () =>
                            _navigateToJobDetails(_featuredJobs[index]),
                      ),
              );
            },
            options: CarouselOptions(
              height: 180,
              viewportFraction: 0.65,
              enableInfiniteScroll: itemCount > 2,
              autoPlay: true,
              enlargeCenterPage: true,
              enlargeFactor: 0.2,
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildContentGridSliver(ThemeData theme, ColorScheme colorScheme,
      TextTheme textTheme, bool isDarkMode) {
    int crossAxisCount = MediaQuery.of(context).size.width > 700 ? 3 : 2;
    int itemCount =
        _userType == 'client' ? _filteredWorkers.length : _filteredJobs.length;
    return SliverPadding(
      key: ValueKey(
          'content_grid_data_${_userType}_${itemCount}_${theme.brightness}'),
      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 100, top: 4),
      sliver: AnimationLimiter(
        child: SliverMasonryGrid.count(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childCount: itemCount,
          itemBuilder: (context, index) {
            int delayMs = ((index ~/ crossAxisCount) * 100 +
                (index % crossAxisCount) * 50);
            return AnimationConfiguration.staggeredGrid(
              position: index,
              duration: const Duration(milliseconds: 500),
              columnCount: crossAxisCount,
              child: ScaleAnimation(
                delay: Duration(milliseconds: delayMs),
                curve: Curves.easeOutBack,
                child: FadeInAnimation(
                  delay: Duration(milliseconds: delayMs),
                  curve: Curves.easeOutCubic,
                  child: _userType == 'client'
                      ? UltimateGridWorkerCard(
                          worker: _filteredWorkers[index],
                          onTap: () =>
                              _navigateToWorkerDetails(_filteredWorkers[index]),
                          onBookNow: () => _navigateToCreateJob(
                              preselectedWorkerId: _filteredWorkers[index].id),
                        )
                      : UltimateGridJobCard(
                          // Now correctly using UltimateGridJobCard
                          job: _filteredJobs[index],
                          onTap: () =>
                              _navigateToJobDetails(_filteredJobs[index]),
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildShimmerLoading(
      ThemeData theme, ColorScheme colorScheme, bool isDarkMode) {
    int crossAxisCount = MediaQuery.of(context).size.width > 700 ? 3 : 2;
    Color shimmerBase = isDarkMode ? (Colors.grey[850]!) : (Colors.grey[300]!);
    Color shimmerHighlight =
        isDarkMode ? (Colors.grey[700]!) : (Colors.grey[100]!);
    // Get a fallback AppStrings if the real one isn't ready yet for the header
    final appStrings = AppLocalizations.of(context) ?? AppStringsEn();
    return CustomScrollView(
        key: ValueKey('shimmer_grid_${theme.brightness}'),
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
              child: FadeOut(
                  child: _buildSearchAndFilterHeader(theme, colorScheme,
                      theme.textTheme, isDarkMode, appStrings))),
          SliverToBoxAdapter(
              child: _buildFeaturedShimmer(theme, colorScheme, isDarkMode,
                  shimmerBase, shimmerHighlight)),
          SliverPadding(
            padding:
                const EdgeInsets.only(left: 12, right: 12, bottom: 100, top: 4),
            sliver: SliverMasonryGrid.count(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              itemBuilder: (context, index) => _buildGridShimmerItem(
                  theme, colorScheme, isDarkMode, shimmerBase, shimmerHighlight,
                  index: index),
              childCount: 6, // Show a fixed number of shimmer items
            ),
          ),
        ]);
  }

  Widget _buildFeaturedShimmer(ThemeData theme, ColorScheme colorScheme,
      bool isDarkMode, Color shimmerBase, Color shimmerHighlight) {
    final textTheme = theme.textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 12.0),
              child: Shimmer.fromColors(
                  baseColor: shimmerBase,
                  highlightColor: shimmerHighlight,
                  period: _shimmerDuration,
                  child: Container(
                      width: 150,
                      height: textTheme.titleMedium?.fontSize ?? 16,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4))))),
          SizedBox(
            height: 180,
            child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 3, // Show a fixed number of shimmer items
                padding: const EdgeInsets.only(left: 10),
                itemBuilder: (context, index) {
                  return Shimmer.fromColors(
                    baseColor: shimmerBase,
                    highlightColor: shimmerHighlight,
                    period: _shimmerDuration,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.65,
                      height: 170,
                      margin: const EdgeInsets.symmetric(horizontal: 6.0),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  );
                }),
          ),
        ],
      ),
    );
  }

  Widget _buildGridShimmerItem(ThemeData theme, ColorScheme colorScheme,
      bool isDarkMode, Color shimmerBase, Color shimmerHighlight,
      {required int index}) {
    // These values are rough estimates for shimmer box heights
    double cardHeight;
    double imageHeight;
    double titleHeight;
    double lineHeight;
    double buttonHeight = 36;
    double buttonWidth = 80;

    if (_userType == 'client') {
      // Worker card shimmer
      imageHeight = 100;
      titleHeight = 18;
      lineHeight = 12;
      cardHeight = imageHeight +
          titleHeight +
          (lineHeight * 5) +
          buttonHeight +
          (16 * 4) +
          12; // sum of elements + paddings
    } else {
      // Job card shimmer
      imageHeight = 0; // Jobs might not always have an image
      titleHeight = 18;
      lineHeight = 12;
      cardHeight =
          titleHeight + (lineHeight * 6) + buttonHeight + (16 * 3) + 12;
    }

    // Adjust cardHeight based on index to simulate staggered grid different heights
    if (index % 3 == 0)
      cardHeight += 20;
    else if (index % 3 == 1) cardHeight -= 15;
    cardHeight =
        cardHeight.clamp(200, 290); // Min/max height to prevent extreme values

    final pC = shimmerBase.withOpacity(0.9);

    return Shimmer.fromColors(
      baseColor: shimmerBase,
      highlightColor: shimmerHighlight,
      period: _shimmerDuration,
      child: Container(
        height: cardHeight,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24.0),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_userType == 'client')
              // Simulating worker image
              ClipRRect(
                borderRadius: BorderRadius.circular(20.0),
                child: Container(
                  height: imageHeight,
                  width: double.infinity,
                  color: pC,
                ),
              ),
            if (_userType == 'client') const SizedBox(height: 12),
            // Simulating title
            Container(
              height: titleHeight,
              width: _userType == 'client'
                  ? MediaQuery.of(context).size.width * 0.4
                  : double.infinity,
              decoration: BoxDecoration(
                color: pC,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            // Simulating meta-info lines
            Container(
              width: MediaQuery.of(context).size.width * 0.3,
              height: lineHeight,
              decoration: BoxDecoration(
                color: pC,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: MediaQuery.of(context).size.width * 0.2,
              height: lineHeight,
              decoration: BoxDecoration(
                color: pC,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            // Simulating description lines
            Container(
              width: double.infinity,
              height: lineHeight,
              decoration: BoxDecoration(
                color: pC,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              height: lineHeight,
              decoration: BoxDecoration(
                color: pC,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            if (_userType != 'client') ...[
              const SizedBox(height: 6),
              Container(
                width: MediaQuery.of(context).size.width * 0.4,
                height: lineHeight,
                decoration: BoxDecoration(
                  color: pC,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
            const Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                width: buttonWidth,
                height: buttonHeight,
                decoration: BoxDecoration(
                  color: pC,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateWidget(
    ThemeData theme,
    ColorScheme colorScheme,
    TextTheme textTheme,
    AppStrings appStrings,
  ) {
    IconData icon = _userType == 'client'
        ? Icons.person_search_outlined
        : Icons.find_in_page_outlined;
    String message = _userType == 'client'
        ? appStrings.emptyStateProfessionals
        : appStrings.emptyStateJobs;
    String details = appStrings.emptyStateDetails;

    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 90,
                color: colorScheme.onSurface.withOpacity(0.4),
              ),
              const SizedBox(height: 24),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  // Use GoogleFonts
                  fontSize: textTheme.titleLarge?.fontSize,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                details,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 35),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: Text(appStrings.refreshButton),
                onPressed: () => _refreshData(isInitialLoad: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.secondary.withOpacity(0.2),
                  foregroundColor: colorScheme.secondary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: BorderSide(
                      color: colorScheme.secondary.withOpacity(0.5),
                    ),
                  ),
                  textStyle: textTheme.labelLarge?.copyWith(
                    fontSize: 14,
                    color: colorScheme.secondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedFloatingActionButton(
    ThemeData theme,
    ColorScheme colorScheme,
    TextTheme textTheme,
    AppStrings appStrings,
  ) {
    bool isClient = _userType == 'client';
    final fabTheme = theme.floatingActionButtonTheme;
    final fabBackgroundColor =
        fabTheme.backgroundColor ?? colorScheme.secondary;
    final fabForegroundColor =
        fabTheme.foregroundColor ?? colorScheme.onSecondary;

    return ScaleTransition(
      scale: CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.elasticOut,
        reverseCurve: Curves.easeOutExpo,
      ),
      child: FadeTransition(
        opacity: _fabAnimationController,
        child: FloatingActionButton.extended(
          onPressed: isClient
              ? () => _navigateToCreateJob()
              : _navigateToCreateProfile,
          backgroundColor: fabBackgroundColor,
          foregroundColor: fabForegroundColor,
          elevation: fabTheme.elevation ?? 6.0,
          highlightElevation: fabTheme.highlightElevation ?? 12.0,
          shape: fabTheme.shape ??
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          icon: Padding(
            padding: const EdgeInsets.only(right: 6.0),
            child: Icon(
              isClient
                  ? Icons.post_add_rounded
                  : Icons.person_pin_circle_rounded,
              size: 24,
            ),
          ),
          label: Text(
            isClient ? appStrings.fabPostJob : appStrings.fabMyProfile,
            style: textTheme.labelLarge?.copyWith(
              fontSize: 16,
              color: fabForegroundColor,
              fontFamily: GoogleFonts.poppins().fontFamily, // Use GoogleFonts
            ),
          ), // Localized
          tooltip: isClient
              ? appStrings.fabPostJobTooltip
              : appStrings.fabMyProfileTooltip, // Localized
        ),
      ),
    );
  }

  void _showFilterPanel(
    ThemeData theme,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final appStrings = AppLocalizations.of(
      context,
    );
    if (appStrings == null) return;

    if (_userType == 'client') {
      _tempSelectedLocation = _filterSelectedLocation;
      _tempSelectedCategory = _filterSelectedCategory;
    } else {
      _tempSelectedJobStatus = _filterSelectedJobStatus;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      elevation: 0,
      builder: (modalContext) {
        final modalTheme = Theme.of(modalContext);
        final modalColorScheme = modalTheme.colorScheme;
        final modalTextTheme = modalTheme.textTheme;
        final modalAppStrings = AppLocalizations.of(
          modalContext,
        )!;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.65,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (_, controller) {
                return ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: modalColorScheme.surface.withOpacity(0.9),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 45,
                            height: 5,
                            margin: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: modalColorScheme.onSurface.withOpacity(
                                0.4,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20.0,
                              vertical: 8,
                            ),
                            child: Text(
                              modalAppStrings.filterOptionsTitle,
                              style: modalTextTheme.titleLarge?.copyWith(
                                  fontFamily: GoogleFonts.poppins()
                                      .fontFamily), // Use GoogleFonts
                            ),
                          ),
                          Divider(
                            color: modalTheme.dividerColor,
                            height: 1,
                            thickness: 1,
                          ),
                          Expanded(
                            child: ListView(
                              controller: controller,
                              padding: const EdgeInsets.all(20),
                              children: _userType == 'client'
                                  ? _buildClientFilterOptions(
                                      modalTheme,
                                      modalColorScheme,
                                      modalTextTheme,
                                      modalAppStrings,
                                      setModalState,
                                    )
                                  : _buildWorkerFilterOptions(
                                      modalTheme,
                                      modalColorScheme,
                                      modalTextTheme,
                                      modalAppStrings,
                                      setModalState,
                                    ),
                            ),
                          ),
                          Divider(
                            color: modalTheme.dividerColor,
                            height: 1,
                            thickness: 1,
                          ),
                          _buildFilterActionButtons(
                            modalTheme,
                            modalColorScheme,
                            modalTextTheme,
                            modalAppStrings,
                            setModalState,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  List<Widget> _buildClientFilterOptions(
    ThemeData theme,
    ColorScheme colorScheme,
    TextTheme textTheme,
    AppStrings appStrings,
    StateSetter setModalState,
  ) {
    return [
      _buildFilterSectionTitle(
        appStrings.filterCategory,
        textTheme,
        colorScheme,
      ),
      _buildChipGroup(
        theme,
        colorScheme,
        textTheme,
        _availableCategories,
        _tempSelectedCategory,
        (val) => setModalState(() => _tempSelectedCategory = val ?? 'All'),
      ),
      const SizedBox(height: 28),
      _buildFilterSectionTitle(
        appStrings.filterLocation,
        textTheme,
        colorScheme,
      ),
      _buildChipGroup(
        theme,
        colorScheme,
        textTheme,
        _locations,
        _tempSelectedLocation,
        (val) => setModalState(() => _tempSelectedLocation = val ?? 'All'),
      ),
      const SizedBox(height: 10),
    ];
  }

  List<Widget> _buildWorkerFilterOptions(
    ThemeData theme,
    ColorScheme colorScheme,
    TextTheme textTheme,
    AppStrings appStrings,
    StateSetter setModalState,
  ) {
    return [
      _buildFilterSectionTitle(
        appStrings.filterJobStatus,
        textTheme,
        colorScheme,
      ),
      _buildChipGroup(
        theme,
        colorScheme,
        textTheme,
        _jobStatuses,
        _tempSelectedJobStatus,
        (val) => setModalState(() => _tempSelectedJobStatus = val ?? 'All'),
      ),
      const SizedBox(height: 10),
    ];
  }

  String _getLocalizedJobStatus(String statusKey, AppStrings appStrings) {
    switch (statusKey.toLowerCase()) {
      case 'open':
        return appStrings.jobStatusOpen;
      case 'assigned':
        return appStrings.jobStatusAssigned;
      case 'completed':
        return appStrings.jobStatusCompleted;
      case 'all':
        return 'all'; // Use localized "All"
      default:
        return statusKey;
    }
  }

  Widget _buildFilterSectionTitle(
    String title,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Text(
        title,
        style: textTheme.titleSmall?.copyWith(
          color: colorScheme.onSurface.withOpacity(0.8),
          fontWeight: FontWeight.w600,
          fontFamily: GoogleFonts.poppins().fontFamily, // Use GoogleFonts
        ),
      ),
    );
  }

  Widget _buildChipGroup(
    ThemeData theme,
    ColorScheme colorScheme,
    TextTheme textTheme,
    List<String> items,
    String selectedValue,
    ValueChanged<String?> onSelected,
  ) {
    if (!items.contains(selectedValue) && selectedValue != 'All') {
      selectedValue = 'All';
    }
    final chipTheme = theme.chipTheme;
    final appStrings = AppLocalizations.of(
      context,
    )!;

    return Wrap(
      spacing: 10.0,
      runSpacing: 10.0,
      children: items.map((item) {
        bool isSelected = selectedValue == item;
        Color bgColor = isSelected
            ? (chipTheme.selectedColor ?? colorScheme.primary)
            : (chipTheme.backgroundColor ??
                colorScheme.surfaceVariant); // Use surfaceVariant
        Color labelColor = isSelected
            ? (chipTheme.secondaryLabelStyle?.color ?? colorScheme.onPrimary)
            : (chipTheme.labelStyle?.color ?? colorScheme.onSurfaceVariant);
        BorderSide borderSide = chipTheme.side ?? BorderSide.none;
        String displayItem = item;
        if (item == 'All') {
          displayItem = 'all';
        } else if (_jobStatuses.contains(item)) {
          displayItem = _getLocalizedJobStatus(item, appStrings);
        }

        return ChoiceChip(
          label: Text(displayItem),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) onSelected(item);
          },
          backgroundColor: chipTheme.backgroundColor ??
              colorScheme.surfaceVariant, // Use surfaceVariant
          selectedColor: chipTheme.selectedColor ?? colorScheme.primary,
          labelStyle: (chipTheme.labelStyle ?? textTheme.labelMedium)?.copyWith(
            color: labelColor,
            fontFamily: GoogleFonts.poppins().fontFamily, // Use GoogleFonts
          ),
          labelPadding: chipTheme.padding ??
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: chipTheme.shape ??
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: borderSide,
              ),
          elevation: chipTheme.elevation ?? (isSelected ? 2 : 0),
          pressElevation: chipTheme.pressElevation ?? 4,
        );
      }).toList(),
    );
  }

  Widget _buildFilterActionButtons(
    ThemeData theme,
    ColorScheme colorScheme,
    TextTheme textTheme,
    AppStrings appStrings,
    StateSetter setModalState,
  ) {
    final outlinedButtonStyle = theme.outlinedButtonTheme.style;
    final elevatedButtonStyle = theme.elevatedButtonTheme.style;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 20),
      decoration: BoxDecoration(
        color: colorScheme.surface.withOpacity(0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              theme.brightness == Brightness.dark ? 0.3 : 0.1,
            ),
            blurRadius: 8,
            spreadRadius: -4,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          OutlinedButton(
            onPressed: () {
              setModalState(() {
                if (_userType == 'client') {
                  _tempSelectedLocation = 'All';
                  _tempSelectedCategory = 'All';
                } else {
                  _tempSelectedJobStatus = 'All';
                }
              });
              if (mounted) _showSuccessSnackbar(appStrings.filtersResetSuccess);
            },
            style: outlinedButtonStyle,
            child: Text(appStrings.filterResetButton,
                style: GoogleFonts.poppins()), // Use GoogleFonts
          ),
          const Spacer(),
          ElevatedButton.icon(
            icon: const Icon(Icons.check_rounded, size: 18),
            label: Text(appStrings.filterApplyButton,
                style: GoogleFonts.poppins()), // Use GoogleFonts
            onPressed: () {
              setState(() {
                if (_userType == 'client') {
                  _filterSelectedLocation = _tempSelectedLocation;
                  _filterSelectedCategory = _tempSelectedCategory;
                  _applyWorkerFilters();
                } else {
                  _filterSelectedJobStatus = _tempSelectedJobStatus;
                  _applyJobFilters();
                }
              });
              Navigator.pop(context);
            },
            style: elevatedButtonStyle,
          ),
        ],
      ),
    );
  }

  // --- Utility Methods ---
  void _showErrorSnackbar(String message, {bool isCritical = false}) {
    if (!mounted) return;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isCritical ? Icons.error_outline : Icons.warning_amber_rounded,
            color: cs.onError, size: 20),
        const SizedBox(width: 12),
        Expanded(
            child: Text(message,
                style: tt.bodyMedium?.copyWith(
                    color: cs.onError,
                    fontFamily:
                        GoogleFonts.poppins().fontFamily))) // Use GoogleFonts
      ]),
      backgroundColor: cs.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      elevation: 6,
      duration: Duration(seconds: isCritical ? 6 : 4),
    ));
  }

  void _showSuccessSnackbar(String message) {
    if (!mounted) return;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final successColor = theme.brightness == Brightness.dark
        ? Colors.green[400]!
        : Colors.green[700]!;
    final onSuccessColor =
        theme.brightness == Brightness.dark ? Colors.black : Colors.white;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(Icons.check_circle_outline_rounded,
            color: onSuccessColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
            child: Text(message,
                style: tt.bodyMedium?.copyWith(
                    color: onSuccessColor,
                    fontFamily:
                        GoogleFonts.poppins().fontFamily))) // Use GoogleFonts
      ]),
      backgroundColor: successColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      elevation: 6,
      duration: const Duration(seconds: 2),
    ));
  }
} // End of _HomeScreenState

// ============================================================
//      Refactored Cards (Now with Localization Support & Enhanced UI)
// ============================================================

class UltimateGridWorkerCard extends StatelessWidget {
  final Worker worker;
  final VoidCallback onTap;
  final VoidCallback onBookNow;
  const UltimateGridWorkerCard({
    Key? key,
    required this.worker,
    required this.onTap,
    required this.onBookNow,
  }) : super(key: key);

  IconData _getProfessionIcon(String? p) {
    if (p == null) return Icons.construction_rounded;
    String pl = p.toLowerCase();
    if (pl.contains('plumb')) return Icons.water_drop_outlined;
    if (pl.contains('electric')) return Icons.flash_on_outlined;
    if (pl.contains('carpenter') || pl.contains('wood')) {
      return Icons.workspaces_rounded;
    }
    if (pl.contains('paint')) return Icons.format_paint_outlined;
    if (pl.contains('clean')) return Icons.cleaning_services_outlined;
    if (pl.contains('garden') || pl.contains('landscap')) {
      return Icons.grass_outlined;
    }
    if (pl.contains('handyman') || pl.contains('fix')) {
      return Icons.build_circle_outlined;
    }
    if (pl.contains('tech') || pl.contains('comput')) {
      return Icons.computer_outlined;
    }
    if (pl.contains('tutor') || pl.contains('teach')) {
      return Icons.school_outlined;
    }
    return Icons.engineering_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;
    double r = worker.rating ?? 0.0;
    Color rC = r >= 3.5 ? cs.secondary : cs.onSurface.withOpacity(0.6);
    Color aC = cs.secondary;
    final appStrings =
        AppLocalizations.of(context)!; // This correctly returns AppStrings

    String? displayImageUrl = worker.profileImage;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24.0),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor.withOpacity(0.9),
            borderRadius: BorderRadius.circular(24.0),
            border: Border.all(color: cs.outline.withOpacity(0.3), width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
                blurRadius: 15,
                spreadRadius: -5,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24.0),
              onTap: onTap,
              splashColor: aC.withOpacity(0.2),
              highlightColor: aC.withOpacity(0.1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Hero(
                        tag: 'worker_image_grid_${worker.id}',
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24.0),
                          ),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: CachedNetworkImage(
                              imageUrl: displayImageUrl ?? '',
                              fit: BoxFit.cover,
                              placeholder: (c, u) => Container(
                                color: cs.surfaceContainerHigh,
                                child: Icon(
                                  Icons.person_outline_rounded,
                                  size: 60,
                                  color: cs.onSurfaceVariant.withOpacity(0.5),
                                ),
                              ),
                              errorWidget: (c, u, e) => Container(
                                color: cs.surfaceContainerHigh,
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  size: 60,
                                  color: cs.onSurfaceVariant.withOpacity(0.5),
                                ),
                              ),
                              fadeInDuration: const Duration(milliseconds: 300),
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(24.0),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.1),
                                Colors.black.withOpacity(0.6),
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        left: 16,
                        right: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              worker.name ?? appStrings.workerDetailAnonymous,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.5),
                                    blurRadius: 4,
                                    offset: const Offset(1, 1),
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: rC.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star_rounded,
                                      color: rC.computeLuminance() > 0.5
                                          ? Colors.black
                                          : Colors.white,
                                      size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    r.toStringAsFixed(1),
                                    style: tt.labelMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: rC.computeLuminance() > 0.5
                                          ? Colors.black
                                          : Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProfessionAndPrice(
                            context, theme, cs, tt, appStrings),
                        const SizedBox(height: 8),
                        _buildStatsWrap(context, theme, cs, tt, aC, appStrings),
                        const SizedBox(height: 8),
                        _buildActionButtons(
                            context, theme, cs, tt, aC, appStrings),
                      ],
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

  // CORRECTED: Changed parameter type from AppLocalizations to AppStrings
  Widget _buildProfessionAndPrice(BuildContext context, ThemeData t,
      ColorScheme cs, TextTheme tt, AppStrings appStrings) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getProfessionIcon(worker.profession),
                size: 18,
                color: cs.onSurface.withOpacity(0.7),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  worker.profession ?? appStrings.generalN_A,
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurface.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          decoration: BoxDecoration(
            color: cs.tertiary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: cs.tertiary.withOpacity(0.6),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.attach_money, size: 14, color: cs.tertiary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  '${worker.priceRange ?? appStrings.workermoneyempty} birr',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // CORRECTED: Changed parameter type from AppLocalizations to AppStrings
  Widget _buildStatsWrap(
    BuildContext context,
    ThemeData t,
    ColorScheme cs,
    TextTheme tt,
    Color aC,
    AppStrings appStrings,
  ) {
    return Wrap(
      spacing: 12.0,
      runSpacing: 8.0,
      children: [
        _buildStatItem(
          t,
          Icons.location_on_outlined,
          worker.location ?? appStrings.generalN_A,
          cs.onSurface.withOpacity(0.7),
        ),
        if (worker.distance != null)
          _buildStatItem(
            t,
            Icons.social_distance_outlined,
            appStrings
                .workerCardDistanceAway(worker.distance!.toStringAsFixed(1)),
            cs.onSurface.withOpacity(0.7),
          ),
      ],
    );
  }

  Widget _buildStatItem(ThemeData t, IconData i, String txt, Color c) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(i, size: 14, color: c.withOpacity(0.9)),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            txt,
            style: t.textTheme.bodySmall?.copyWith(
              fontSize: 11.5,
              color: c.withOpacity(0.95),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // CORRECTED: Changed parameter type from AppLocalizations to AppStrings
  Widget _buildActionButtons(
    BuildContext context,
    ThemeData t,
    ColorScheme cs,
    TextTheme tt,
    Color aC,
    AppStrings appStrings,
  ) {
    Color oAC = aC.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.calendar_today_outlined, size: 16),
          label: Text(appStrings.workerCardHire),
          onPressed: onBookNow,
          style: t.elevatedButtonTheme.style?.copyWith(
            backgroundColor: MaterialStateProperty.all(aC),
            foregroundColor: MaterialStateProperty.all(oAC),
            textStyle: MaterialStateProperty.all(
              tt.labelLarge?.copyWith(
                  fontSize: 13.5,
                  color: oAC,
                  fontFamily: GoogleFonts.poppins().fontFamily),
            ),
            padding: MaterialStateProperty.all(
              const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            ),
            shape: MaterialStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }
}

// --- UltimateGridJobCard (Merged and Enhanced) ---
class UltimateGridJobCard extends StatelessWidget {
  final Job job;
  final VoidCallback onTap;
  const UltimateGridJobCard(
      {super.key, required this.job, required this.onTap});

  Color _getStatusColor(String? s, ColorScheme cs, bool isDark) {
    switch (s?.toLowerCase()) {
      case 'open':
        return isDark ? Colors.orange : const ui.Color.fromARGB(255, 18, 31, 2);
      case 'assigned':
        return cs.tertiary;
      case 'completed':
        return isDark
            ? Colors.greenAccent
            : const ui.Color.fromARGB(255, 15, 41, 16); // Default grey
      default:
        return const ui.Color.fromARGB(255, 142, 192, 4);
    }
  }

  IconData _getStatusIcon(String? s) {
    switch (s?.toLowerCase()) {
      case 'open':
        return Icons.lock_open_rounded;
      case 'assigned':
        return Icons.person_pin_circle_outlined;
      case 'completed':
        return Icons.check_circle_outline_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  String _getStatusText(String? s, AppStrings appStrings) {
    switch (s?.toLowerCase()) {
      case 'open':
        return appStrings.jobStatusOpen;
      case 'assigned':
        return appStrings.jobStatusAssigned;
      case 'completed':
        return appStrings.jobStatusCompleted;
      default:
        return s ?? appStrings.jobStatusUnknown;
    }
  }

  String _getTimeAgo(DateTime? dt, AppStrings appStrings) {
    if (dt == null) return appStrings.jobDateN_A;
    final Duration diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return appStrings.timeAgoJustNow;
    if (diff.inMinutes < 60) return appStrings.timeAgoMinute(diff.inMinutes);
    if (diff.inHours < 24) return appStrings.timeAgoHour(diff.inHours);
    if (diff.inDays < 7) return appStrings.timeAgoDay(diff.inDays);
    return appStrings.timeAgoWeek((diff.inDays / 7).floor());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;
    final appStrings = AppLocalizations.of(context)!;

    Color statusColor = _getStatusColor(
        job.status, cs, isDark); // Use cs from Theme.of(context)
    IconData statusIcon = _getStatusIcon(job.status);
    String statusText = _getStatusText(job.status, appStrings);
    String timeAgo = _getTimeAgo(job.createdAt, appStrings);
    String budget = job.budget != null
        ? appStrings.jobBudgetETB(job.budget.toStringAsFixed(0))
        : appStrings.generalN_A;
    Color cardBg = theme.cardColor;

    // Use first attachment as potential preview image, null if no attachments
    String? previewImageUrl =
        job.attachments.isNotEmpty ? job.attachments.first : null;
    bool hasImage = previewImageUrl != null &&
        (previewImageUrl.toLowerCase().contains('.jpg') ||
            previewImageUrl.toLowerCase().contains('.jpeg') ||
            previewImageUrl.toLowerCase().contains('.png') ||
            previewImageUrl.toLowerCase().contains('.gif'));

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20.0),
        border:
            Border.all(color: cs.outlineVariant.withOpacity(0.3), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(20.0),
          onTap: onTap,
          splashColor: statusColor.withOpacity(0.1),
          highlightColor: statusColor.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        job.title ?? appStrings.jobUntitled,
                        style: tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontFamily: GoogleFonts.poppins()
                                .fontFamily), // Use Google Fonts
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Chip(
                      avatar: Icon(statusIcon, size: 14, color: statusColor),
                      label: Text(statusText),
                      labelStyle: tt.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                          fontFamily: GoogleFonts.poppins()
                              .fontFamily), // Use Google FontsR
                      backgroundColor: cs.surfaceVariant.withOpacity(0.8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      visualDensity: VisualDensity.compact,
                      side: BorderSide.none,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (hasImage)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: CachedNetworkImage(
                        imageUrl: previewImageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (c, u) =>
                            Container(color: cs.surfaceContainer),
                        errorWidget: (c, u, e) => Container(
                            color: cs.surfaceContainer,
                            child: Center(
                                child: Icon(Icons.image_not_supported_outlined,
                                    color:
                                        cs.onSurfaceVariant.withOpacity(0.5)))),
                      ),
                    ),
                  ),
                if (hasImage) const SizedBox(height: 12),
                Text(
                  job.description ?? appStrings.jobNoDescription,
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  maxLines: hasImage ? 2 : 4,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildMetaItem(theme, Icons.attach_money, budget),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _buildMetaItem(theme, Icons.location_on_outlined,
                            job.location ?? appStrings.generalN_A)),
                  ],
                ),
                const SizedBox(height: 4),
                _buildMetaItem(theme, Icons.access_time, timeAgo),
                Align(
                  alignment: Alignment.bottomRight,
                  child: TextButton(
                      onPressed: onTap,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: Text(appStrings.jobCardView,
                          style: GoogleFonts.poppins())), // Use GoogleFonts
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetaItem(ThemeData theme, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            size: 14,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8)),
        Flexible(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontFamily:
                    GoogleFonts.poppins().fontFamily), // Use GoogleFonts
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// --- FeaturedWorkerCard (Enhanced) ---
class FeaturedWorkerCard extends StatelessWidget {
  final Worker worker;
  final VoidCallback onTap;
  const FeaturedWorkerCard({
    Key? key,
    required this.worker,
    required this.onTap,
  }) : super(key: key);

  IconData _getProfessionIcon(String? p) {
    if (p == null) return Icons.construction_rounded;
    String pl = p.toLowerCase();
    if (pl.contains('plumb')) return Icons.water_drop_outlined;
    if (pl.contains('electric')) return Icons.flash_on_outlined;
    if (pl.contains('carpenter') || pl.contains('wood')) {
      return Icons.workspaces_rounded;
    }
    if (pl.contains('paint')) return Icons.format_paint_outlined;
    if (pl.contains('clean')) return Icons.cleaning_services_outlined;
    if (pl.contains('garden') || pl.contains('landscap')) {
      return Icons.grass_outlined;
    }
    if (pl.contains('handyman') || pl.contains('fix')) {
      return Icons.build_circle_outlined;
    }
    if (pl.contains('tech') || pl.contains('comput')) {
      return Icons.computer_outlined;
    }
    if (pl.contains('tutor') || pl.contains('teach')) {
      return Icons.school_outlined;
    }
    return Icons.engineering_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;
    double r = worker.rating ?? 0.0;
    Color rC = r >= 4.0
        ? cs.secondary
        : (r >= 3.0
            ? (cs.tertiaryContainer ?? cs.primaryContainer)
            : cs.errorContainer ?? cs.error);
    Color rTC = r >= 4.0
        ? cs.onSecondary
        : (r >= 3.0
            ? (cs.onTertiaryContainer ?? cs.onPrimaryContainer)
            : cs.onErrorContainer ?? cs.onError);
    final appStrings = AppLocalizations.of(context)!;

    String? displayImageUrl = worker.profileImage;

    return Container(
      width: MediaQuery.of(context).size.width * 0.6,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          theme.cardColor,
          theme.cardColor.withOpacity(isDark ? 0.85 : 0.95)
        ], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: cs.outline.withOpacity(0.2), width: 0.8),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
              blurRadius: 10,
              spreadRadius: -4,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.0),
          onTap: onTap,
          splashColor: cs.primary.withOpacity(0.15),
          highlightColor: cs.primary.withOpacity(0.08),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Prominent Image Section (taking more space)
              Expanded(
                flex: 3, // Give more flex to the image
                child: Stack(
                  children: [
                    Hero(
                      tag: 'worker_image_featured_${worker.id}',
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16.0),
                        ),
                        child: SizedBox.expand(
                          // Expand to fill the parent
                          child: CachedNetworkImage(
                            imageUrl: displayImageUrl ?? '',
                            fit: BoxFit.cover,
                            placeholder: (c, u) => Container(
                                color: cs.surfaceContainerHighest,
                                child: Icon(Icons.person_outline_rounded,
                                    size: 40,
                                    color:
                                        cs.onSurfaceVariant.withOpacity(0.5))),
                            errorWidget: (c, u, e) => Container(
                                color: cs.surfaceContainerHighest,
                                child: Icon(Icons.broken_image_outlined,
                                    size: 40,
                                    color:
                                        cs.onSurfaceVariant.withOpacity(0.5))),
                          ),
                        ),
                      ),
                    ),
                    // Gradient overlay for text readability
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16.0),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.1),
                              Colors.black.withOpacity(0.6),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // Worker Name overlayed on the image
                    Positioned(
                      bottom: 8,
                      left: 12,
                      right: 12,
                      child: Text(
                        worker.name ?? appStrings.workerDetailAnonymous,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 4,
                              offset: const Offset(1, 1),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              // Details Section below the image

              Expanded(
                flex: 2, // Give less flex to details, making image bigger
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: SingleChildScrollView(
                    physics:
                        const AlwaysScrollableScrollPhysics(), // Ensure scroll physics for RefreshIndicator
                    padding: const EdgeInsets.all(0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(_getProfessionIcon(worker.profession),
                                      size: 15, color: cs.secondary),
                                  Flexible(
                                    child: Text(
                                      worker.profession ??
                                          appStrings.generalN_A,
                                      style: tt.bodySmall?.copyWith(
                                          color: cs.onSurface.withOpacity(0.7)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: rC.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star_rate_rounded,
                                      color: rTC, size: 13),
                                  Text(r.toStringAsFixed(1),
                                      style: tt.labelSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: rTC)),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Price Range
                        Container(
                          decoration: BoxDecoration(
                            color: cs.tertiary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: cs.tertiary.withOpacity(0.6),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.attach_money,
                                  size: 14, color: cs.tertiary),
                              Flexible(
                                child: Text(
                                  '${worker.priceRange ?? appStrings.workermoneyempty} birr',
                                  style: tt.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (worker.distance !=
                            null) // Only show distance if available
                          _buildMetaItem(
                            theme,
                            Icons
                                .social_distance_outlined, // Or Icons.near_me_outlined
                            appStrings.workerCardDistanceAway(
                                worker.distance!.toStringAsFixed(1)),
                            cs.onSurface.withOpacity(0.7),
                          ),
                      ],
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

  Widget _buildMetaItem(ThemeData t, IconData i, String txt, Color c) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(i, size: 13, color: c.withOpacity(0.9)), // Slightly smaller icon

        Flexible(
          child: Text(
            txt,
            style: t.textTheme.labelSmall?.copyWith(
              // Using labelSmall for smaller text
              fontSize: 11.5,
              color: c.withOpacity(0.95),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// --- FeaturedJobCard (Merged and Enhanced) ---
class FeaturedJobCard extends StatelessWidget {
  final Job job;
  final VoidCallback onTap;

  const FeaturedJobCard({super.key, required this.job, required this.onTap});

  Color _getStatusColor(String? s, ColorScheme cs, bool isDark) {
    switch (s?.toLowerCase()) {
      case 'open':
        return isDark ? Colors.orange : const ui.Color.fromARGB(255, 18, 31, 2);
      case 'assigned':
        return cs.tertiary;
      case 'completed':
        return isDark
            ? Colors.greenAccent
            : const ui.Color.fromARGB(255, 15, 41, 16);
      default:
        return cs.onSurface.withOpacity(0.5);
    }
  }

  String _getTimeAgo(DateTime? dt, AppStrings appStrings) {
    if (dt == null) return appStrings.jobDateN_A;
    final Duration diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return appStrings.timeAgoJustNow;
    if (diff.inMinutes < 60) return appStrings.timeAgoMinute(diff.inMinutes);
    if (diff.inHours < 24) return appStrings.timeAgoHour(diff.inHours);
    if (diff.inDays < 7) return appStrings.timeAgoDay(diff.inDays);
    return appStrings.timeAgoWeek((diff.inDays / 7).floor());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;
    final appStrings = AppLocalizations.of(context)!;

    Color statusColor =
        _getStatusColor(job.status, cs, theme.brightness == Brightness.dark);
    String timeAgo = _getTimeAgo(job.createdAt, appStrings);
    String budget = job.budget != null
        ? appStrings.jobBudgetETB(job.budget.toStringAsFixed(0))
        : appStrings.generalN_A;
    Color cardBg = theme.cardColor;

    String? previewImageUrl =
        job.attachments.isNotEmpty ? job.attachments.first : null;
    bool hasImage = previewImageUrl != null &&
        (previewImageUrl.toLowerCase().contains('.jpg') ||
            previewImageUrl.toLowerCase().contains('.jpeg') ||
            previewImageUrl.toLowerCase().contains('.png') ||
            previewImageUrl.toLowerCase().contains('.gif'));

    return Container(
      width: MediaQuery.of(context).size.width * 0.65,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.0),
        border:
            Border.all(color: cs.outlineVariant.withOpacity(0.3), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.0),
          onTap: onTap,
          splashColor: statusColor.withOpacity(0.1),
          highlightColor: statusColor.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        job.title ?? appStrings.jobUntitled,
                        style: tt.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontFamily: GoogleFonts.poppins()
                                .fontFamily), // Use Google Fonts
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (hasImage) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                            imageUrl: previewImageUrl!,
                            height: 40,
                            width: 40,
                            fit: BoxFit.cover,
                            placeholder: (c, u) => Container(
                                height: 40,
                                width: 40,
                                color: cs.surfaceContainerHigh),
                            errorWidget: (c, u, e) => Container(
                                height: 40,
                                width: 40,
                                color: cs.surfaceContainerHigh,
                                child: Icon(Icons.image_not_supported_outlined,
                                    size: 18,
                                    color:
                                        cs.onSurfaceVariant.withOpacity(0.5)))),
                      )
                    ]
                  ],
                ),
                Text(
                  job.description ?? appStrings.jobNoDescription,
                  style: tt.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant.withOpacity(0.9)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMetaItemFeatured(context, Icons.attach_money, budget),
                    Flexible(
                        child: _buildMetaItemFeatured(
                            context,
                            Icons.location_on_outlined,
                            job.location ?? appStrings.generalN_A)),
                  ],
                ),
                _buildMetaItemFeatured(context, Icons.access_time, timeAgo),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetaItemFeatured(
      BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            size: 13,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8)),
        Flexible(
          child: Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontFamily:
                    GoogleFonts.poppins().fontFamily), // Use GoogleFonts
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
