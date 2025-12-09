// lib/screens/home/home_screen_web.dart

import 'dart:async';
import 'dart:ui' as ui; // Required for ImageFilter
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:animate_do/animate_do.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../models/worker.dart';
import '../../models/job.dart';
import '../../models/user.dart';
import '../../services/firebase_service.dart';
import '../../services/auth_service.dart';
import '../../services/app_string.dart';
import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';
import '../worker_detail_screen.dart';
import '../jobs/create_job_screen.dart';
import '../jobs/job_detail_screen.dart';
import '../notifications_screen.dart';
import '../chat_screen.dart';
import '../professional_setup_screen.dart';
import '../../services/ai_chat_service.dart';
import '../widgets/ai_chat_panel.dart';

// ============================================================
//               HomeScreenWeb Widget - Elite Web Experience
// ============================================================
class HomeScreenWeb extends StatefulWidget {
  const HomeScreenWeb({super.key});

  @override
  _HomeScreenWebState createState() => _HomeScreenWebState();
}

class _HomeScreenWebState extends State<HomeScreenWeb>
    with SingleTickerProviderStateMixin {
  // --- Constants for Responsive Design ---
  static const double _kMediumBreakpoint = 800.0;
  static const double _kLargeBreakpoint = 1200.0;
  static const double _kSidebarWidth = 280.0;

  // --- State Variables (Copied from Mobile, mostly unchanged) ---
  final FirebaseService _firebaseService = FirebaseService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  // FIX 3: Corrected the controller type to match the carousel_slider package.
  final CarouselSliderController _carouselController =
      CarouselSliderController();
  late AnimationController _fabAnimationController;

  bool _isLoading = true;
  String _userType = 'client';
  AppUser? _currentUser;
  int _currentGradientIndex = 0;
  Timer? _gradientTimer;

  List<Worker> _workers = [];
  List<Worker> _filteredWorkers = [];
  List<Worker> _featuredWorkers = [];
  List<Job> _jobs = [];
  List<Job> _filteredJobs = [];
  List<Job> _featuredJobs = [];

  String _filterSelectedLocation = 'All';
  String _filterSelectedCategory = 'All';
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
    'Other',
  ];
  List<String> _availableCategories = ['All'];
  String _filterSelectedJobStatus = 'All';
  final List<String> _jobStatuses = ['All', 'Open', 'Assigned', 'Completed'];
  final Set<String> _dynamicLocations = {'All'};
  StreamSubscription? _notificationsSubscription;
  int _unreadNotificationsCount = 0;

  double? _userLongitude;
  double? _userLatitude;

  final Duration _animationDuration = const Duration(milliseconds: 500);
  final Curve _animationCurve = Curves.easeInOutCubic;

  // --- Web-Specific State ---
  bool _isChatPanelVisible = false;
  String _searchQueryForAi = '';
  Timer? _aiSuggestionDebounce;
  bool _showAiSearchSuggestion = false;
  AiChatService? _aiChatService;
  bool _isAiServiceInitialized = false;
  bool _showOverallLoader = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Gradients (copied from mobile)
  static const List<List<Color>> _gentleAnimatedBgGradientsDark = [
    [Color(0xFF232526), Color(0xFF414345)],
    [Color(0xFF141E30), Color(0xFF243B55)],
    [Color(0xFF360033), Color(0xFF0B8793)],
    [Color(0xFF2E3141), Color(0xFF4E546A)],
    [Color(0xFF16222A), Color(0xFF3A6073)],
    [Color(0xFF3E404E), Color(0xFF646883)],
    [Color(0xFF0F2027), Color(0xFF2C5364)],
    [Color(0xFF1F1C2C), Color(0xFF928DAB)],
    [Color(0xFF2C3E50), Color(0xFF4CA1AF)],
    [Color(0xFF373B44), Color(0xFF4286f4)],
    [Color(0xFF1A2980), Color(0xFF26D0CE)],
    [Color(0xFF1D2B64), Color(0xFFF8CDDA)],
    [Color(0xFF0F0C29), Color(0xFF302B63)],
    [Color(0xFF000000), Color(0xFF434343)],
    [Color(0xFF1B1B2F), Color(0xFF16213E)],
    [Color(0xFF3A1C71), Color(0xFFD76D77)],
  ];
  static const List<List<Color>> _gentleAnimatedBgGradientsLight = [
    [Color(0xFFFFF9C4), Color(0xFFFFF59D)],
    [Color(0xFFFFF1F0), Color(0xFFC1C8E4)],
    [Color(0xFFB39DDB), Color(0xFF90CAF9)],
    [Color(0xFFFFE082), Color(0xFFFFC107)],
    [Color(0xFFFFF3E0), Color(0xFFF48FB1)],
    [Color(0xFFC5E1A5), Color(0xFF81C784)],
    [Color(0xFFFFF176), Color(0xFFFF8A65)],
    [Color(0xFFFFECB3), Color(0xFFFFAB91)],
    [Color(0xFFBBDEFB), Color(0xFF9FA8DA)],
    [Color(0xFFFFF59D), Color(0xFFF48FB1)],
    [Color(0xFFFFCDD2), Color(0xFFFFF9C4)],
    [Color(0xFFDCE775), Color(0xFFDCEDC8)],
  ];

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
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
    _scrollController.dispose();
    _fabAnimationController.dispose();
    _notificationsSubscription?.cancel();
    super.dispose();
  }

  // --- Core Logic & Data Fetching (Mostly Unchanged from Mobile) ---
  void setStateIfMounted(VoidCallback f) {
    if (mounted) setState(f);
  }

  Future<void> _getCurrentUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _userLatitude = position.latitude;
          _userLongitude = position.longitude;
        });
      }
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  Future<void> _listenForNotifications() async {
    await _notificationsSubscription?.cancel();
    final stream = await _firebaseService.getNotificationsStream(
      isArchived: false,
    );
    if (mounted) {
      _notificationsSubscription = stream.listen((notifications) {
        if (mounted) {
          final unreadCount = notifications
              .where((n) => (n['isRead'] as bool? ?? true) == false)
              .length;
          setStateIfMounted(() => _unreadNotificationsCount = unreadCount);
        }
      });
    }
  }

  void _startBackgroundAnimation() {
    if (!mounted) return;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final activeGradients = isDarkMode
        ? _gentleAnimatedBgGradientsDark
        : _gentleAnimatedBgGradientsLight;
    _gradientTimer?.cancel();
    _gradientTimer = Timer.periodic(const Duration(seconds: 12), (timer) {
      if (mounted) {
        setStateIfMounted(
          () => _currentGradientIndex =
              (_currentGradientIndex + 1) % activeGradients.length,
        );
      } else {
        timer.cancel();
      }
    });
  }

  void _updateBackgroundAnimationBasedOnTheme() {
    if (!mounted) return;
    _gradientTimer?.cancel();
    _startBackgroundAnimation();
  }

  void _onSearchChanged() {
    if (_aiSuggestionDebounce?.isActive ?? false) {
      _aiSuggestionDebounce!.cancel();
    }
    _aiSuggestionDebounce = Timer(const Duration(milliseconds: 750), () {
      final text = _searchController.text.trim();
      final isQuestion =
          text.isNotEmpty &&
          (text.endsWith('?') ||
              text.toLowerCase().startsWith('how') ||
              text.toLowerCase().startsWith('what') ||
              text.toLowerCase().startsWith('can i'));
      setStateIfMounted(() {
        _showAiSearchSuggestion = isQuestion;
        _searchQueryForAi = isQuestion ? text : '';
      });
    });
    _userType == 'client' ? _applyWorkerFilters() : _applyJobFilters();
  }

  Future<void> _determineUserTypeAndLoadData() async {
    if (!mounted) return;
    setStateIfMounted(() => _isLoading = true);
    await _getCurrentUserLocation();
    _fabAnimationController.forward();
    try {
      final userProfile = await _authService.getCurrentUserProfile();
      if (!mounted) return;
      setStateIfMounted(() {
        _currentUser = userProfile;
        _userType = userProfile?.role.toLowerCase() == 'worker'
            ? 'worker'
            : 'client';
      });
      await _refreshData(isInitialLoad: true);
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('please check your network.', isCritical: true);
      }
    } finally {
      Future.delayed(
        const Duration(milliseconds: 300),
        () => setStateIfMounted(() => _isLoading = false),
      );
    }
  }

  Future<void> _refreshData({bool isInitialLoad = false}) async {
    if (!mounted) return;
    if (_userLatitude == null || _userLongitude == null) {
      await _getCurrentUserLocation();
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
    } catch (e) {
      if (mounted) _showErrorSnackbar('Failed to refresh data.');
    } finally {
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) setStateIfMounted(() => _isLoading = false);
    }
  }

  Future<void> _loadWorkers() async {
    final workers = await _firebaseService.getWorkers();
    if (!mounted) return;
    if (_userLatitude != null && _userLongitude != null) {
      for (var worker in workers) {
        if (worker.latitude != null && worker.longitude != null) {
          worker.distance =
              Geolocator.distanceBetween(
                _userLatitude!,
                _userLongitude!,
                worker.latitude!,
                worker.longitude!,
              ) /
              1000.0;
        }
      }
    }
    _dynamicLocations.clear();
    _dynamicLocations.add('All');
    final Set<String> dynamicCategories = {'All', ..._baseCategories};
    for (var worker in workers) {
      if (worker.location.isNotEmpty) {
        _dynamicLocations.add(worker.location);
      }
      if (worker.profession.isNotEmpty) {
        dynamicCategories.add(worker.profession);
      }
    }
    final sortedLocations = _dynamicLocations.toList()..sort();
    final sortedCategories = dynamicCategories.toList()
      ..sort(
        (a, b) => a == 'All'
            ? -1
            : b == 'All'
            ? 1
            : a.compareTo(b),
      );
    // FIX 1: Explicitly type the list to avoid List<dynamic> error.
    final List<Worker> featured =
        (List.of(workers)
              ..sort((a, b) => (b.rating ?? 0.0).compareTo(a.rating ?? 0.0)))
            .take(5)
            .toList();
    setStateIfMounted(() {
      _workers = workers;
      _featuredWorkers = featured;
      _locations = sortedLocations;
      _availableCategories = sortedCategories;
      _applyWorkerFilters();
    });
    await _initializeAiService();
  }

  Future<void> _initializeAiService() async {
    _aiChatService = AiChatService();
    await _aiChatService!.initializePersonalizedChat();
    setStateIfMounted(() => _isAiServiceInitialized = true);
  }

  Future<void> _loadJobs() async {
    final jobs = await _firebaseService.getJobs();
    if (!mounted) return;
    // FIX 1: Explicitly type the list to avoid List<dynamic> error.
    final List<Job> featured =
        (jobs.where((j) => j.status.toLowerCase() == 'open').toList()..sort(
              (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
                a.createdAt ?? DateTime(0),
              ),
            ))
            .take(5)
            .toList();
    setStateIfMounted(() {
      _jobs = jobs;
      _featuredJobs = featured;
      _applyJobFilters();
    });
  }

  void _applyWorkerFilters() {
    final query = _searchController.text.toLowerCase().trim();
    setStateIfMounted(() {
      _filteredWorkers = _workers.where((worker) {
        final locationMatch =
            _filterSelectedLocation == 'All' ||
            worker.location.toLowerCase() ==
                _filterSelectedLocation.toLowerCase();
        final categoryMatch =
            _filterSelectedCategory == 'All' ||
            (worker.profession.toLowerCase() ?? '').contains(
              _filterSelectedCategory.toLowerCase(),
            );
        final searchMatch = query.isEmpty
            ? true
            : ((worker.name.toLowerCase() ?? '').contains(query) ||
                  (worker.profession.toLowerCase() ?? '').contains(query) ||
                  (worker.about.toLowerCase() ?? '').contains(query));
        return locationMatch && categoryMatch && searchMatch;
      }).toList();
    });
  }

  void _applyJobFilters() {
    final query = _searchController.text.toLowerCase().trim();
    setStateIfMounted(() {
      _filteredJobs = _jobs.where((job) {
        final statusMatch =
            _filterSelectedJobStatus == 'All' ||
            job.status.toLowerCase() == _filterSelectedJobStatus.toLowerCase();
        final searchMatch = query.isEmpty
            ? true
            : ((job.title.toLowerCase() ?? '').contains(query) ||
                  (job.description.toLowerCase() ?? '').contains(query));
        return statusMatch && searchMatch;
      }).toList();
    });
  }

  void _updateUserAfterLocaleChange() async {
    await _determineUserTypeAndLoadData();
  }

  Future<void> _signOut() async {
    setStateIfMounted(() => _showOverallLoader = true);
    try {
      await _authService.signOut();
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } finally {
      if (mounted) setStateIfMounted(() => _showOverallLoader = false);
    }
  }

  // --- Navigation (Unchanged from Mobile) ---
  void _navigateToCreateJob({String? preselectedWorkerId}) {
    Navigator.push(
      context,
      _createFadeRoute(
        CreateJobScreen(preselectedWorkerId: preselectedWorkerId),
      ),
    ).then((jobCreated) {
      if (jobCreated == true) _refreshData();
    });
  }

  void _navigateToUnifiedChatScreen({String? initialSelectedUserId}) =>
      Navigator.push(
        context,
        _createFadeRoute(
          UnifiedChatScreen(initialSelectedUserId: initialSelectedUserId),
        ),
      );
  void _navigateToWorkerDetails(Worker worker) => Navigator.push(
    context,
    _createFadeRoute(WorkerDetailScreen(worker: worker)),
  );
  void _navigateToJobDetails(Job job) => Navigator.push(
    context,
    _createFadeRoute(JobDetailScreen(job: job)),
  ).then((_) => _refreshData());
  void _navigateToCreateProfile() =>
      Navigator.push(
        context,
        _createFadeRoute(const ProfessionalSetupScreen()),
      ).then((profileUpdated) {
        if (profileUpdated == true) _determineUserTypeAndLoadData();
      });
  void _navigateToNotifications() =>
      Navigator.push(context, _createFadeRoute(const NotificationsScreen()));
  Route _createFadeRoute(Widget page) => PageRouteBuilder(
    pageBuilder: (c, a1, a2) => page,
    transitionsBuilder: (c, a1, a2, child) =>
        FadeTransition(opacity: a1, child: child),
    transitionDuration: const Duration(milliseconds: 300),
  );

  // --- Utility Methods (Unchanged) ---
  void _showErrorSnackbar(String message, {bool isCritical = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ============================================================
  //               PRIMARY BUILD METHOD FOR WEB
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appStrings = AppLocalizations.of(context);
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;

    final bool isLargeScreen = screenWidth > _kLargeBreakpoint;
    final bool isMediumScreen =
        screenWidth > _kMediumBreakpoint && screenWidth <= _kLargeBreakpoint;
    final bool isSmallScreen = screenWidth <= _kMediumBreakpoint;

    if (appStrings == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: true,
      appBar: _buildResponsiveAppBar(
        theme,
        colorScheme,
        appStrings,
        isSmallScreen,
      ),
      drawer: isSmallScreen
          ? _buildSidebar(theme, colorScheme, appStrings, isDrawer: true)
          : null,
      body: Stack(
        children: [
          _buildAnimatedBackground(theme),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isSmallScreen)
                _buildSidebar(theme, colorScheme, appStrings, isDrawer: false),
              Expanded(
                child: _buildMainContentArea(
                  theme,
                  colorScheme,
                  appStrings,
                  screenWidth,
                ),
              ),
            ],
          ),
          // --- AI Chat Panel Overlay ---
          if (_isAiServiceInitialized)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOutCubic,
              top: 0,
              bottom: 0,
              right: _isChatPanelVisible ? 0 : -450, // Increased width for web
              width: 450,
              child: AiChatPanel(
                aiChatService: _aiChatService!,
                onClose: () => setState(() => _isChatPanelVisible = false),
              ),
            ),
        ],
      ),
    );
  }

  // --- WEB-SPECIFIC UI BUILDERS ---

  PreferredSizeWidget _buildResponsiveAppBar(
    ThemeData theme,
    ColorScheme colorScheme,
    AppStrings appStrings,
    bool isSmallScreen,
  ) {
    String title = _userType == 'client'
        ? appStrings.findExpertsTitle
        : appStrings.yourJobFeedTitle;
    String? firstName = _currentUser?.name.split(' ').first;
    String welcomeMessage = firstName != null && firstName.isNotEmpty
        ? appStrings.helloUser(firstName)
        : title;

    return AppBar(
      backgroundColor: theme.colorScheme.surface.withOpacity(0.5),
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading:
          isSmallScreen, // Show hamburger only on small screens
      title: FadeInLeft(
        delay: const Duration(milliseconds: 200),
        duration: _animationDuration,
        child: Text(
          welcomeMessage,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
      ),
      actions: isSmallScreen
          ? _buildMobileAppBarActions(theme, colorScheme, appStrings)
          : null, // Actions only for mobile-like view
    );
  }

  // A simplified version for the narrow app bar
  List<Widget> _buildMobileAppBarActions(
    ThemeData theme,
    ColorScheme colorScheme,
    AppStrings appStrings,
  ) {
    return [
      IconButton(
        icon: Badge(
          label: Text('$_unreadNotificationsCount'),
          isLabelVisible: _unreadNotificationsCount > 0,
          child: const Icon(Icons.notifications_active_outlined),
        ),
        onPressed: _navigateToNotifications,
        tooltip: appStrings.notificationTitle,
      ),
      const SizedBox(width: 8),
    ];
  }

  Widget _buildSidebar(
    ThemeData theme,
    ColorScheme colorScheme,
    AppStrings appStrings, {
    required bool isDrawer,
  }) {
    final isDarkMode = theme.brightness == Brightness.dark;

    Widget content = Material(
      color: isDrawer
          ? theme.scaffoldBackgroundColor
          : theme.colorScheme.surface.withOpacity(0.3),
      child: Container(
        width: _kSidebarWidth,
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(
              color: theme.dividerColor.withOpacity(0.2),
              width: 1.0,
            ),
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildSidebarHeader(theme, colorScheme, appStrings),
                  const SizedBox(height: 20),
                  _buildSidebarActionItem(
                    icon: _userType == 'client'
                        ? Icons.chat_bubble_outline_rounded
                        : Icons.person_pin_circle_rounded,
                    // New AppString needed: sidebarMessages, sidebarMyProfile
                    text: _userType == 'client'
                        ? 'Messages'
                        : 'My Professional Profile',
                    onTap: _userType == 'client'
                        ? () => _navigateToUnifiedChatScreen()
                        : _navigateToCreateProfile,
                    theme: theme,
                  ),
                  if (_userType == 'client')
                    _buildSidebarActionItem(
                      icon: Icons.auto_awesome,
                      // New AppString needed: sidebarAiAssistant
                      text: 'AI Assistant',
                      onTap: () {
                        if (isDrawer) {
                          Navigator.pop(context); // Close drawer if open
                        }
                        setState(() => _isChatPanelVisible = true);
                      },
                      theme: theme,
                      isActive: _isChatPanelVisible,
                    ),
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 16.0,
                    ),
                    child: Divider(),
                  ),
                  _buildFilterSectionForSidebar(theme, colorScheme, appStrings),
                ],
              ),
            ),
            _buildSidebarFooter(theme, colorScheme, appStrings, isDarkMode),
          ],
        ),
      ),
    );

    return isDrawer
        ? Drawer(child: content)
        : ClipRect(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: content,
            ),
          );
  }

  Widget _buildSidebarHeader(
    ThemeData theme,
    ColorScheme colorScheme,
    AppStrings appStrings,
  ) {
    // FIX 2: Changed `profilePictureUrl` to `profileImage` to match the likely model structure.
    final String? profileImageUrl = _currentUser?.profileImage;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: profileImageUrl != null
                ? CachedNetworkImageProvider(profileImageUrl)
                : null,
            child: profileImageUrl == null ? const Icon(Icons.person) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentUser?.name ??
                      'Guest User', // New AppString: guestUser
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _currentUser?.email ?? '',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
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

  Widget _buildSidebarActionItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    required ThemeData theme,
    bool isActive = false,
  }) {
    final color = isActive
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Material(
        color: isActive
            ? theme.colorScheme.primary.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          splashColor: theme.colorScheme.primary.withOpacity(0.2),
          highlightColor: theme.colorScheme.primary.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Row(
              children: [
                Icon(icon, color: color.withOpacity(0.8), size: 22),
                const SizedBox(width: 20),
                Text(
                  text,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarFooter(
    ThemeData theme,
    ColorScheme colorScheme,
    AppStrings appStrings,
    bool isDarkMode,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Badge(
                  label: Text('$_unreadNotificationsCount'),
                  isLabelVisible: _unreadNotificationsCount > 0,
                  child: const Icon(Icons.notifications_active_outlined),
                ),
                onPressed: _navigateToNotifications,
                tooltip: appStrings.notificationTitle,
              ),
              IconButton(
                icon: Icon(
                  isDarkMode ? Icons.wb_sunny_outlined : Icons.nightlight_round,
                ),
                tooltip: isDarkMode
                    ? appStrings.themeTooltipLight
                    : appStrings.themeTooltipDark,
                onPressed: () => Provider.of<ThemeProvider>(
                  context,
                  listen: false,
                ).toggleTheme(),
              ),
              IconButton(
                icon: const Icon(Icons.language),
                tooltip: appStrings.languageToggleTooltip,
                onPressed: () {
                  final localeProvider = Provider.of<LocaleProvider>(
                    context,
                    listen: false,
                  );
                  localeProvider.setLocale(
                    localeProvider.locale.languageCode == 'en'
                        ? const Locale('am')
                        : const Locale('en'),
                  );
                  _updateUserAfterLocaleChange();
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: _showOverallLoader ? null : _signOut,
                tooltip: appStrings.generalLogout,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSectionForSidebar(
    ThemeData theme,
    ColorScheme colorScheme,
    AppStrings appStrings,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            appStrings.filterOptionsTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontFamily: GoogleFonts.poppins().fontFamily,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...(_userType == 'client'
              ? _buildClientFilterOptionsForSidebar(
                  theme,
                  colorScheme,
                  appStrings,
                )
              : _buildWorkerFilterOptionsForSidebar(
                  theme,
                  colorScheme,
                  appStrings,
                )),
          const SizedBox(height: 24),
          Row(
            children: [
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    if (_userType == 'client') {
                      _filterSelectedLocation = 'All';
                      _filterSelectedCategory = 'All';
                    } else {
                      _filterSelectedJobStatus = 'All';
                    }
                    _userType == 'client'
                        ? _applyWorkerFilters()
                        : _applyJobFilters();
                  });
                },
                child: Text(appStrings.filterResetButton),
              ),
              const Spacer(),
              // Apply happens instantly on web, so no apply button needed.
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildClientFilterOptionsForSidebar(
    ThemeData theme,
    ColorScheme colorScheme,
    AppStrings appStrings,
  ) {
    return [
      Text(appStrings.filterCategory, style: theme.textTheme.titleSmall),
      const SizedBox(height: 8),
      _buildChipGroupForSidebar(
        theme,
        colorScheme,
        _availableCategories,
        _filterSelectedCategory,
        (val) {
          setState(() => _filterSelectedCategory = val ?? 'All');
          _applyWorkerFilters();
        },
      ),
      const SizedBox(height: 20),
      Text(appStrings.filterLocation, style: theme.textTheme.titleSmall),
      const SizedBox(height: 8),
      _buildChipGroupForSidebar(
        theme,
        colorScheme,
        _locations,
        _filterSelectedLocation,
        (val) {
          setState(() => _filterSelectedLocation = val ?? 'All');
          _applyWorkerFilters();
        },
      ),
    ];
  }

  List<Widget> _buildWorkerFilterOptionsForSidebar(
    ThemeData theme,
    ColorScheme colorScheme,
    AppStrings appStrings,
  ) {
    return [
      Text(appStrings.filterJobStatus, style: theme.textTheme.titleSmall),
      const SizedBox(height: 8),
      _buildChipGroupForSidebar(
        theme,
        colorScheme,
        _jobStatuses,
        _filterSelectedJobStatus,
        (val) {
          setState(() => _filterSelectedJobStatus = val ?? 'All');
          _applyJobFilters();
        },
      ),
    ];
  }

  Widget _buildChipGroupForSidebar(
    ThemeData theme,
    ColorScheme colorScheme,
    List<String> items,
    String selectedValue,
    ValueChanged<String?> onSelected,
  ) {
    final appStrings = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: items.map((item) {
        bool isSelected = selectedValue == item;
        String displayItem = item;
        if (item == 'All') {
          displayItem = 'all'; // using appStrings.all if available
        } else if (_jobStatuses.contains(item)) {
          switch (item.toLowerCase()) {
            case 'open':
              displayItem = appStrings.jobStatusOpen;
              break;
            case 'assigned':
              displayItem = appStrings.jobStatusAssigned;
              break;
            case 'completed':
              displayItem = appStrings.jobStatusCompleted;
              break;
          }
        }
        return ChoiceChip(
          label: Text(displayItem),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) onSelected(item);
          },
          backgroundColor:
              theme.chipTheme.backgroundColor ?? colorScheme.surfaceContainerHighest,
          selectedColor: theme.chipTheme.selectedColor ?? colorScheme.primary,
          labelStyle: theme.chipTheme.labelStyle?.copyWith(
            color: isSelected
                ? colorScheme.onPrimary
                : colorScheme.onSurfaceVariant,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide.none,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAnimatedBackground(ThemeData theme) {
    final isDarkMode = theme.brightness == Brightness.dark;
    final activeGradients = isDarkMode
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
    );
  }

  Widget _buildMainContentArea(
    ThemeData theme,
    ColorScheme colorScheme,
    AppStrings appStrings,
    double screenWidth,
  ) {
    final bool isEmpty =
        (_userType == 'client' && _filteredWorkers.isEmpty) ||
        (_userType == 'worker' && _filteredJobs.isEmpty);
    int crossAxisCount;
    if (screenWidth > 1600) {
      crossAxisCount = 4;
    } else if (screenWidth > 1000) {
      crossAxisCount = 3;
    } else if (screenWidth > 600) {
      crossAxisCount = 2;
    } else {
      crossAxisCount = 1;
    }

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: colorScheme.primary),
      );
    }

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.only(
            top: kToolbarHeight + 40.0,
          ), // Space for AppBar
          sliver: SliverToBoxAdapter(
            child: _buildSearchHeader(theme, colorScheme, appStrings),
          ),
        ),
        SliverToBoxAdapter(
          child: _buildFeaturedSection(theme, colorScheme, appStrings),
        ),
        isEmpty
            ? SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(theme, colorScheme, appStrings),
              )
            : _buildContentGrid(theme, colorScheme, crossAxisCount),
      ],
    );
  }

  Widget _buildSearchHeader(
    ThemeData theme,
    ColorScheme colorScheme,
    AppStrings appStrings,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40.0, 16.0, 40.0, 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: theme.textTheme.bodyLarge?.copyWith(fontSize: 16),
                  decoration: InputDecoration(
                    hintText: _userType == 'client'
                        ? appStrings.searchHintProfessionals
                        : appStrings.searchHintJobs,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Icon(Icons.search_rounded),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: theme.cardColor.withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Manual Refresh Button for Web
              IconButton.filledTonal(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () => _refreshData(isInitialLoad: true),
                tooltip:
                    'Refresh Data', // New AppString needed: refreshDataTooltip
                iconSize: 24,
                padding: const EdgeInsets.all(16),
              ),
            ],
          ),
          // AI Search Suggestion
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SizeTransition(sizeFactor: animation, child: child),
            ),
            child: !_showAiSearchSuggestion
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: OutlinedButton.icon(
                      icon: Icon(
                        Icons.auto_awesome,
                        size: 18,
                        color: colorScheme.secondary,
                      ),
                      label: Text(
                        'Ask AI About It',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.secondary,
                        ),
                      ), // New AppString needed: askAiAboutIt
                      onPressed: () =>
                          setState(() => _isChatPanelVisible = true),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedSection(
    ThemeData theme,
    ColorScheme colorScheme,
    AppStrings appStrings,
  ) {
    final bool hasFeatured =
        (_userType == 'client' && _featuredWorkers.isNotEmpty) ||
        (_userType == 'worker' && _featuredJobs.isNotEmpty);
    if (!hasFeatured) return const SizedBox.shrink();

    int itemCount = _userType == 'client'
        ? _featuredWorkers.length
        : _featuredJobs.length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              _userType == 'client'
                  ? appStrings.featuredPros
                  : appStrings.featuredJobs,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
          const SizedBox(height: 16),
          CarouselSlider.builder(
            carouselController: _carouselController,
            itemCount: itemCount,
            itemBuilder: (context, index, realIndex) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: _userType == 'client'
                    ? FeaturedWorkerCard(
                        worker: _featuredWorkers[index],
                        onTap: () =>
                            _navigateToWorkerDetails(_featuredWorkers[index]),
                      )
                    : FeaturedJobCard(
                        job: _featuredJobs[index],
                        onTap: () =>
                            _navigateToJobDetails(_featuredJobs[index]),
                      ),
              );
            },
            options: CarouselOptions(
              height: 190,
              viewportFraction: 0.4,
              enableInfiniteScroll: itemCount > 2,
              autoPlay: true,
              enlargeCenterPage: true,
              enlargeFactor: 0.15,
              aspectRatio: 16 / 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentGrid(
    ThemeData theme,
    ColorScheme colorScheme,
    int crossAxisCount,
  ) {
    int itemCount = _userType == 'client'
        ? _filteredWorkers.length
        : _filteredJobs.length;
    return SliverPadding(
      padding: const EdgeInsets.only(left: 40, right: 40, bottom: 100, top: 20),
      sliver: AnimationLimiter(
        child: SliverMasonryGrid.count(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 24,
          crossAxisSpacing: 24,
          childCount: itemCount,
          itemBuilder: (context, index) {
            return AnimationConfiguration.staggeredGrid(
              position: index,
              duration: const Duration(milliseconds: 500),
              columnCount: crossAxisCount,
              child: ScaleAnimation(
                delay: Duration(milliseconds: (index % crossAxisCount) * 100),
                child: FadeInAnimation(
                  child: _userType == 'client'
                      ? UltimateGridWorkerCard(
                          worker: _filteredWorkers[index],
                          onTap: () =>
                              _navigateToWorkerDetails(_filteredWorkers[index]),
                          onBookNow: () => _navigateToCreateJob(
                            preselectedWorkerId: _filteredWorkers[index].id,
                          ),
                        )
                      : UltimateGridJobCard(
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

  Widget _buildEmptyState(
    ThemeData theme,
    ColorScheme colorScheme,
    AppStrings appStrings,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _userType == 'client'
                ? Icons.person_search_outlined
                : Icons.find_in_page_outlined,
            size: 100,
            color: colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(height: 24),
          Text(
            _userType == 'client'
                ? appStrings.emptyStateProfessionals
                : appStrings.emptyStateJobs,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(
            appStrings.emptyStateDetails,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
} // End of _HomeScreenWebState

// ===================================================================
//   CARD WIDGETS (Included for completeness - From Mobile Code)
// ===================================================================
// NOTE: These are the full implementations of the card widgets from your mobile code prompt.
// They are highly effective for web as well and are included here to make this file fully runnable.

class UltimateGridWorkerCard extends StatelessWidget {
  final Worker worker;
  final VoidCallback onTap;
  final VoidCallback onBookNow;
  const UltimateGridWorkerCard({
    super.key,
    required this.worker,
    required this.onTap,
    required this.onBookNow,
  });

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
    final appStrings = AppLocalizations.of(
      context,
    )!; // This correctly returns AppStrings

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
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: rC.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star_rounded,
                                    color: rC.computeLuminance() > 0.5
                                        ? Colors.black
                                        : Colors.white,
                                    size: 16,
                                  ),
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
                          context,
                          theme,
                          cs,
                          tt,
                          appStrings,
                        ),
                        const SizedBox(height: 8),
                        _buildStatsWrap(context, theme, cs, tt, aC, appStrings),
                        const SizedBox(height: 8),
                        _buildActionButtons(
                          context,
                          theme,
                          cs,
                          tt,
                          aC,
                          appStrings,
                        ),
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

  Widget _buildProfessionAndPrice(
    BuildContext context,
    ThemeData t,
    ColorScheme cs,
    TextTheme tt,
    AppStrings appStrings,
  ) {
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
            border: Border.all(color: cs.tertiary.withOpacity(0.6)),
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
            appStrings.workerCardDistanceAway(
              worker.distance!.toStringAsFixed(1),
            ),
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
            backgroundColor: WidgetStateProperty.all(aC),
            foregroundColor: WidgetStateProperty.all(oAC),
            textStyle: WidgetStateProperty.all(
              tt.labelLarge?.copyWith(
                fontSize: 13.5,
                color: oAC,
                fontFamily: GoogleFonts.poppins().fontFamily,
              ),
            ),
            padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            ),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }
}

class UltimateGridJobCard extends StatelessWidget {
  final Job job;
  final VoidCallback onTap;
  const UltimateGridJobCard({
    super.key,
    required this.job,
    required this.onTap,
  });

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
      job.status,
      cs,
      isDark,
    ); // Use cs from Theme.of(context)
    IconData statusIcon = _getStatusIcon(job.status);
    String statusText = _getStatusText(job.status, appStrings);
    String timeAgo = _getTimeAgo(job.createdAt, appStrings);
    String budget = appStrings.jobBudgetETB(job.budget.toStringAsFixed(0));
    Color cardBg = theme.cardColor;

    // Use first attachment as potential preview image, null if no attachments
    String? previewImageUrl = job.attachments.isNotEmpty
        ? job.attachments.first
        : null;
    bool hasImage =
        previewImageUrl != null &&
        (previewImageUrl.toLowerCase().contains('.jpg') ||
            previewImageUrl.toLowerCase().contains('.jpeg') ||
            previewImageUrl.toLowerCase().contains('.png') ||
            previewImageUrl.toLowerCase().contains('.gif'));

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: cs.outlineVariant.withOpacity(0.3),
          width: 0.8,
        ),
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
                          fontFamily: GoogleFonts.poppins().fontFamily,
                        ), // Use Google Fonts
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
                        fontFamily: GoogleFonts.poppins().fontFamily,
                      ), // Use Google FontsR
                      backgroundColor: cs.surfaceContainerHighest.withOpacity(0.8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
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
                        imageUrl: previewImageUrl,
                        fit: BoxFit.cover,
                        placeholder: (c, u) =>
                            Container(color: cs.surfaceContainer),
                        errorWidget: (c, u, e) => Container(
                          color: cs.surfaceContainer,
                          child: Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              color: cs.onSurfaceVariant.withOpacity(0.5),
                            ),
                          ),
                        ),
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
                      child: _buildMetaItem(
                        theme,
                        Icons.location_on_outlined,
                        job.location ?? appStrings.generalN_A,
                      ),
                    ),
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
                        horizontal: 12,
                        vertical: 4,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(
                      appStrings.jobCardView,
                      style: GoogleFonts.poppins(),
                    ),
                  ), // Use GoogleFonts
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
        Icon(
          icon,
          size: 14,
          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
        ),
        Flexible(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontFamily: GoogleFonts.poppins().fontFamily,
            ), // Use GoogleFonts
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class FeaturedWorkerCard extends StatelessWidget {
  final Worker worker;
  final VoidCallback onTap;
  const FeaturedWorkerCard({
    super.key,
    required this.worker,
    required this.onTap,
  });

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
        gradient: LinearGradient(
          colors: [
            theme.cardColor,
            theme.cardColor.withOpacity(isDark ? 0.85 : 0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: cs.outline.withOpacity(0.2), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 10,
            spreadRadius: -4,
            offset: const Offset(0, 4),
          ),
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
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    Hero(
                      tag: 'worker_image_featured_${worker.id}',
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16.0),
                        ),
                        child: SizedBox.expand(
                          child: CachedNetworkImage(
                            imageUrl: displayImageUrl ?? '',
                            fit: BoxFit.cover,
                            placeholder: (c, u) => Container(
                              color: cs.surfaceContainerHighest,
                              child: Icon(
                                Icons.person_outline_rounded,
                                size: 40,
                                color: cs.onSurfaceVariant.withOpacity(0.5),
                              ),
                            ),
                            errorWidget: (c, u, e) => Container(
                              color: cs.surfaceContainerHighest,
                              child: Icon(
                                Icons.broken_image_outlined,
                                size: 40,
                                color: cs.onSurfaceVariant.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
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
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
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
                                  Icon(
                                    _getProfessionIcon(worker.profession),
                                    size: 15,
                                    color: cs.secondary,
                                  ),
                                  Flexible(
                                    child: Text(
                                      worker.profession ??
                                          appStrings.generalN_A,
                                      style: tt.bodySmall?.copyWith(
                                        color: cs.onSurface.withOpacity(0.7),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: rC.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star_rate_rounded,
                                    color: rTC,
                                    size: 13,
                                  ),
                                  Text(
                                    r.toStringAsFixed(1),
                                    style: tt.labelSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: rTC,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: cs.tertiary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: cs.tertiary.withOpacity(0.6),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.attach_money,
                                size: 14,
                                color: cs.tertiary,
                              ),
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
                        if (worker.distance != null)
                          _buildMetaItem(
                            theme,
                            Icons.social_distance_outlined,
                            appStrings.workerCardDistanceAway(
                              worker.distance!.toStringAsFixed(1),
                            ),
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
        Icon(i, size: 13, color: c.withOpacity(0.9)),
        Flexible(
          child: Text(
            txt,
            style: t.textTheme.labelSmall?.copyWith(
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

    Color statusColor = _getStatusColor(
      job.status,
      cs,
      theme.brightness == Brightness.dark,
    );
    String timeAgo = _getTimeAgo(job.createdAt, appStrings);
    String budget = appStrings.jobBudgetETB(job.budget.toStringAsFixed(0));
    Color cardBg = theme.cardColor;

    String? previewImageUrl = job.attachments.isNotEmpty
        ? job.attachments.first
        : null;
    bool hasImage =
        previewImageUrl != null &&
        (previewImageUrl.toLowerCase().contains('.jpg') ||
            previewImageUrl.toLowerCase().contains('.jpeg') ||
            previewImageUrl.toLowerCase().contains('.png') ||
            previewImageUrl.toLowerCase().contains('.gif'));

    return Container(
      width: MediaQuery.of(context).size.width * 0.65,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: cs.outlineVariant.withOpacity(0.3),
          width: 0.8,
        ),
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
                          fontFamily: GoogleFonts.poppins().fontFamily,
                        ), // Use Google Fonts
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (hasImage) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: previewImageUrl,
                          height: 40,
                          width: 40,
                          fit: BoxFit.cover,
                          placeholder: (c, u) => Container(
                            height: 40,
                            width: 40,
                            color: cs.surfaceContainerHigh,
                          ),
                          errorWidget: (c, u, e) => Container(
                            height: 40,
                            width: 40,
                            color: cs.surfaceContainerHigh,
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              size: 18,
                              color: cs.onSurfaceVariant.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  job.description ?? appStrings.jobNoDescription,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant.withOpacity(0.9),
                  ),
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
                        job.location ?? appStrings.generalN_A,
                      ),
                    ),
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
    BuildContext context,
    IconData icon,
    String text,
  ) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 13,
          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
        ),
        Flexible(
          child: Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontFamily: GoogleFonts.poppins().fontFamily,
            ), // Use GoogleFonts
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
