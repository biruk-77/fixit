import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui; // Required for ImageFilter
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:animate_do/animate_do.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../widgets/ai_chat_panel.dart';

// --- Models, Services, Screens & Localization ---
import '../../models/worker.dart';
import '../../models/job.dart';
import '../../models/user.dart';
import '../../services/firebase_service.dart';
import '../../services/auth_service.dart';
import '../../services/app_string.dart';
import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';
import '../../screens/worker_detail_screen.dart';
import '../../screens/jobs/create_job_screen.dart';
import '../../screens/jobs/job_detail_screen.dart';
import '../../screens/notifications_screen.dart';
import '../../screens/chat_screen.dart';
import '../../screens/professional_setup_screen.dart';
import '../../services/ai_chat_service.dart';

import '../../screens/home_screen.dart'
    show
        UltimateGridWorkerCard,
        UltimateGridJobCard,
        FeaturedWorkerCard,
        FeaturedJobCard;

// ============================================================
//               HomeScreenWeb Widget - Desktop/Web UI
// ============================================================
class HomeScreenWeb extends StatefulWidget {
  const HomeScreenWeb({super.key});

  @override
  _HomeScreenWebState createState() => _HomeScreenWebState();
}

class _HomeScreenWebState extends State<HomeScreenWeb>
    with SingleTickerProviderStateMixin {
  // --- ALL STATE AND LOGIC IS IDENTICAL TO THE MOBILE VERSION ---
  final FirebaseService _firebaseService = FirebaseService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final CarouselController _carouselController =
      CarouselController(); // Correct controller type
  late AnimationController _fabAnimationController;

  bool _isLoading = true;
  String _userType = 'client';
  AppUser? _currentUser;
  int _currentGradientIndex = 0;
  Timer? _gradientTimer;
  bool showOverallLoader = false;
  int _navIndex = 0;

  List<Worker> _workers = [];
  List<Worker> _filteredWorkers = [];
  List<Worker> _featuredWorkers = [];
  List<Job> _jobs = [];
  List<Job> _filteredJobs = [];
  List<Job> _featuredJobs = [];

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
    'Other',
  ];
  List<String> _availableCategories = ['All'];
  String _filterSelectedJobStatus = 'All';
  String _tempSelectedJobStatus = 'All';
  final List<String> _jobStatuses = ['All', 'Open', 'Assigned', 'Completed'];
  final Set<String> _dynamicLocations = {'All'};
  StreamSubscription? _notificationsSubscription;
  int _unreadNotificationsCount = 0;

  double? _userLongitude;
  double? _userLatitude;

  final Duration _shimmerDuration = const Duration(milliseconds: 1500);
  final Duration _animationDuration = const Duration(milliseconds: 450);
  bool _isChatPanelVisible = false;
  String _searchQueryForAi = '';
  Timer? _aiSuggestionDebounce;
  bool _showAiSearchSuggestion = false;
  AiChatService? _aiChatService;
  bool _isAiServiceInitialized = false;

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
    _notificationsSubscription?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _fabAnimationController.dispose();
    _aiSuggestionDebounce?.cancel();
    super.dispose();
  }

  // --- PASTE ALL YOUR LOGIC METHODS FROM THE MOBILE FILE HERE ---
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
        "Location permissions are permanently denied, we cannot request permissions.",
      );
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
      }
    } catch (e) {
      print("Error getting location: $e");
      if (mounted)
        _showErrorSnackbar(
          "Could not get your location. Distances won't be available.",
        );
    }
  }

  Future<void> _listenForNotifications() async {
    await _notificationsSubscription?.cancel();
    final stream = await _firebaseService.getNotificationsStream(
      isArchived: false,
    );
    if (mounted) {
      _notificationsSubscription = stream.listen(
        (notifications) {
          if (mounted) {
            final unreadCount = notifications.where((notif) {
              final isRead = notif['isRead'] as bool?;
              return isRead == false;
            }).length;
            setState(() => _unreadNotificationsCount = unreadCount);
          }
        },
        onError: (error) {
          print("Error listening to notifications for badge: $error");
          if (mounted) setState(() => _unreadNotificationsCount = 0);
        },
      );
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
        if ((Theme.of(context).brightness == Brightness.dark) != isDarkMode) {
          _updateBackgroundAnimationBasedOnTheme();
          timer.cancel();
          return;
        }
        setState(
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
    setState(() => _currentGradientIndex = 0);
    _startBackgroundAnimation();
  }

  void _scrollListener() {
    /* Not needed for web header, but kept for other potential uses */
  }
  void _onSearchChanged() {
    if (!mounted) return;
    _aiSuggestionDebounce?.cancel();
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
    if (_userType == 'client')
      _applyWorkerFilters();
    else
      _applyJobFilters();
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
        _userType = userProfile?.role?.toLowerCase() == 'worker'
            ? 'worker'
            : 'client';
      });
      _filterSelectedLocation = _tempSelectedLocation = 'All';
      _filterSelectedCategory = _tempSelectedCategory = 'All';
      _filterSelectedJobStatus = _tempSelectedJobStatus = 'All';
      await _refreshData(isInitialLoad: true);
    } catch (e, s) {
      print('FATAL ERROR: $e\n$s');
      if (mounted)
        _showErrorSnackbar(
          AppLocalizations.of(context)?.snackErrorLoadingProfile ??
              'Error loading profile.',
          isCritical: true,
        );
      setStateIfMounted(() => _userType = 'client');
    } finally {
      if (mounted)
        Future.delayed(
          const Duration(milliseconds: 300),
          () => setStateIfMounted(() => _isLoading = false),
        );
    }
  }

  Future<void> _refreshData({bool isInitialLoad = false}) async {
    if (!mounted) return;
    if (_userLatitude == null || _userLongitude == null)
      await _getCurrentUserLocation();
    if (isInitialLoad || !_isLoading)
      setStateIfMounted(() => _isLoading = true);
    try {
      if (_userType == 'client')
        await _loadWorkers();
      else
        await _loadJobs();
    } catch (e, s) {
      print('ERROR: $e\n$s');
      if (mounted)
        _showErrorSnackbar(
          AppLocalizations.of(context)?.snackErrorLoading ??
              'Failed to refresh.',
        );
    } finally {
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) setStateIfMounted(() => _isLoading = false);
    }
  }

  void setStateIfMounted(VoidCallback f) {
    if (mounted) setState(f);
  }

  void _loadUserProfileAfterLocaleChange() async {
    if (!mounted) return;
    final strings = AppLocalizations.of(context);
    try {
      final userData = await _firebaseService.getCurrentUserProfile();
      if (mounted) setState(() => _currentUser = userData);
    } catch (e) {
      if (mounted)
        _showErrorSnackbar(
          '${strings?.snackErrorLoadingProfile ?? 'Error:'} $e',
        );
    }
  }

  Future<void> _loadWorkers() async {
    try {
      final workers = await _firebaseService.getWorkers();
      if (!mounted) return;
      if (_userLatitude != null && _userLongitude != null) {
        for (var worker in workers) {
          if (worker.latitude != null && worker.longitude != null)
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
      _dynamicLocations.clear();
      _dynamicLocations.add('All');
      final Set<String> dynamicCategories = {'All', ..._baseCategories};
      for (var worker in workers) {
        if (worker.location != null && worker.location!.isNotEmpty)
          _dynamicLocations.add(worker.location!);
        if (worker.profession != null && worker.profession!.isNotEmpty) {
          bool isBase = _baseCategories.any(
            (b) =>
                b != 'All' &&
                worker.profession!.toLowerCase().contains(b.toLowerCase()),
          );
          if (!isBase &&
              !_baseCategories.contains(worker.profession!) &&
              worker.profession!.trim().isNotEmpty)
            dynamicCategories.add(worker.profession!);
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
      List<Worker> sortedByRating = List.from(workers)
        ..sort((a, b) => (b.rating ?? 0.0).compareTo(a.rating ?? 0.0));
      setStateIfMounted(() {
        _workers = workers;
        _featuredWorkers = sortedByRating.take(5).toList();
        _locations = sortedLocations;
        _availableCategories = sortedCategories;
        _applyWorkerFilters();
      });
      await _initializeAiService();
    } catch (e, s) {
      if (mounted)
        _showErrorSnackbar(
          AppLocalizations.of(context)?.snackErrorLoading ??
              "Error fetching professionals.",
          isCritical: true,
        );
      setStateIfMounted(() {
        _workers = [];
        _featuredWorkers = [];
        _filteredWorkers = [];
      });
    }
  }

  Future<void> _initializeAiService() async {
    _aiChatService = AiChatService();
    await _aiChatService!.initializePersonalizedChat();
    setState(() => _isAiServiceInitialized = true);
  }

  Future<void> _loadJobs() async {
    try {
      final jobs = await _firebaseService.getJobs();
      if (!mounted) return;
      List<Job> openJobs =
          jobs.where((j) => j.status?.toLowerCase() == 'open').toList()..sort(
            (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
              a.createdAt ?? DateTime(0),
            ),
          );
      setStateIfMounted(() {
        _jobs = jobs;
        _featuredJobs = openJobs.take(5).toList();
        _applyJobFilters();
      });
    } catch (e, s) {
      if (mounted)
        _showErrorSnackbar(
          AppLocalizations.of(context)?.snackErrorLoading ??
              "Error fetching jobs.",
          isCritical: true,
        );
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
    setStateIfMounted(() {
      _filteredWorkers = _workers.where((worker) {
        final locMatch =
            _filterSelectedLocation == 'All' ||
            (worker.location?.toLowerCase() ?? '') ==
                _filterSelectedLocation.toLowerCase();
        final catMatch =
            _filterSelectedCategory == 'All' ||
            (worker.profession?.toLowerCase() ?? '').contains(
              _filterSelectedCategory.toLowerCase(),
            );
        final searchMatch = query.isEmpty
            ? true
            : ((worker.name?.toLowerCase() ?? '').contains(query) ||
                  (worker.profession?.toLowerCase() ?? '').contains(query) ||
                  (worker.location?.toLowerCase() ?? '').contains(query) ||
                  (worker.skills?.any(
                        (s) => (s?.toLowerCase() ?? '').contains(query),
                      ) ??
                      false) ||
                  (worker.about?.toLowerCase() ?? '').contains(query));
        return locMatch && catMatch && searchMatch;
      }).toList();
    });
  }

  void _applyJobFilters() {
    if (!mounted) return;
    final query = _searchController.text.toLowerCase().trim();
    setStateIfMounted(() {
      _filteredJobs = _jobs.where((job) {
        final statusMatch =
            _filterSelectedJobStatus == 'All' ||
            (job.status?.toLowerCase() ?? '') ==
                _filterSelectedJobStatus.toLowerCase();
        final searchMatch = query.isEmpty
            ? true
            : ((job.title?.toLowerCase() ?? '').contains(query) ||
                  (job.description?.toLowerCase() ?? '').contains(query) ||
                  (job.location?.toLowerCase() ?? '').contains(query));
        return statusMatch && searchMatch;
      }).toList();
    });
  }

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

  void _navigateToUnifiedChatScreen({String? initialSelectedUserId}) {
    Navigator.push(
      context,
      _createFadeRoute(
        UnifiedChatScreen(initialSelectedUserId: initialSelectedUserId),
      ),
    );
  }

  void _navigateToWorkerDetails(Worker worker) {
    Navigator.push(
      context,
      _createFadeRoute(WorkerDetailScreen(worker: worker)),
    );
  }

  void _navigateToJobDetails(Job job) {
    Navigator.push(
      context,
      _createFadeRoute(JobDetailScreen(job: job)),
    ).then((_) => _refreshData());
  }

  void _navigateToCreateProfile() {
    Navigator.push(
      context,
      _createFadeRoute(const ProfessionalSetupScreen()),
    ).then((profileUpdated) {
      if (profileUpdated == true) _determineUserTypeAndLoadData();
    });
  }

  void _navigateToNotifications() {
    Navigator.push(context, _createFadeRoute(const NotificationsScreen()));
  }

  Route _createFadeRoute(Widget page) => PageRouteBuilder(
    pageBuilder: (c, a1, a2) => page,
    transitionsBuilder: (c, a1, a2, child) =>
        FadeTransition(opacity: a1, child: child),
    transitionDuration: const Duration(milliseconds: 300),
  );
  void _updateUserAfterLocaleChange() async {
    await _determineUserTypeAndLoadData();
  }

  Future<void> _signOut() async {
    setState(() => showOverallLoader = true);
    try {
      await _authService.signOut();
      if (mounted)
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      rethrow;
    } finally {
      if (mounted) setState(() => showOverallLoader = false);
    }
  }

  void _showFilterPanel(
    ThemeData theme,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final appStrings = AppLocalizations.of(context);
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
      builder: (modalContext) {
        final modalTheme = Theme.of(modalContext);
        final modalColorScheme = modalTheme.colorScheme;
        final modalTextTheme = modalTheme.textTheme;
        final modalAppStrings = AppLocalizations.of(modalContext)!;
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
                                fontFamily: GoogleFonts.poppins().fontFamily,
                              ),
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
  ) => [
    _buildFilterSectionTitle(appStrings.filterCategory, textTheme, colorScheme),
    _buildChipGroup(
      theme,
      colorScheme,
      textTheme,
      _availableCategories,
      _tempSelectedCategory,
      (val) => setModalState(() => _tempSelectedCategory = val ?? 'All'),
    ),
    const SizedBox(height: 28),
    _buildFilterSectionTitle(appStrings.filterLocation, textTheme, colorScheme),
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
  List<Widget> _buildWorkerFilterOptions(
    ThemeData theme,
    ColorScheme colorScheme,
    TextTheme textTheme,
    AppStrings appStrings,
    StateSetter setModalState,
  ) => [
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
  String _getLocalizedJobStatus(String statusKey, AppStrings appStrings) {
    switch (statusKey.toLowerCase()) {
      case 'open':
        return appStrings.jobStatusOpen;
      case 'assigned':
        return appStrings.jobStatusAssigned;
      case 'completed':
        return appStrings.jobStatusCompleted;
      case 'all':
        return appStrings.all;
      default:
        return statusKey;
    }
  }

  Widget _buildFilterSectionTitle(
    String title,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 14.0),
    child: Text(
      title,
      style: textTheme.titleSmall?.copyWith(
        color: colorScheme.onSurface.withOpacity(0.8),
        fontWeight: FontWeight.w600,
        fontFamily: GoogleFonts.poppins().fontFamily,
      ),
    ),
  );
  Widget _buildChipGroup(
    ThemeData theme,
    ColorScheme colorScheme,
    TextTheme textTheme,
    List<String> items,
    String selectedValue,
    ValueChanged<String?> onSelected,
  ) {
    final appStrings = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 10.0,
      runSpacing: 10.0,
      children: items.map((item) {
        bool isSelected = selectedValue == item;
        String displayItem = (item == 'All')
            ? appStrings.all
            : (_jobStatuses.contains(item)
                  ? _getLocalizedJobStatus(item, appStrings)
                  : item);
        return ChoiceChip(
          label: Text(displayItem),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) onSelected(item);
          },
          backgroundColor: colorScheme.surfaceVariant,
          selectedColor: colorScheme.primary,
          labelStyle: (theme.chipTheme.labelStyle ?? textTheme.labelMedium)
              ?.copyWith(
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
                fontFamily: GoogleFonts.poppins().fontFamily,
              ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: isSelected ? 2 : 0,
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
  ) => Container(
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
              } else
                _tempSelectedJobStatus = 'All';
            });
            if (mounted) _showSuccessSnackbar(appStrings.filtersResetSuccess);
          },
          style: theme.outlinedButtonTheme.style,
          child: Text(
            appStrings.filterResetButton,
            style: GoogleFonts.poppins(),
          ),
        ),
        const Spacer(),
        ElevatedButton.icon(
          icon: const Icon(Icons.check_rounded, size: 18),
          label: Text(
            appStrings.filterApplyButton,
            style: GoogleFonts.poppins(),
          ),
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
          style: theme.elevatedButtonTheme.style,
        ),
      ],
    ),
  );
  void _showErrorSnackbar(String message, {bool isCritical = false}) {
    if (!mounted) return;
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isCritical ? Icons.error_outline : Icons.warning_amber_rounded,
              color: cs.onError,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: cs.onError,
                  fontFamily: GoogleFonts.poppins().fontFamily,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: cs.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: isCritical ? 6 : 4),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    if (!mounted) return;
    final theme = Theme.of(context);
    final successColor = theme.brightness == Brightness.dark
        ? Colors.green[400]!
        : Colors.green[700]!;
    final onSuccessColor = theme.brightness == Brightness.dark
        ? Colors.black
        : Colors.white;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              color: onSuccessColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: onSuccessColor,
                  fontFamily: GoogleFonts.poppins().fontFamily,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ============================================================
  //               WEB/DESKTOP BUILD METHOD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final appStrings = AppLocalizations.of(context);

    if (appStrings == null || _isLoading) {
      return Scaffold(
        backgroundColor: isDarkMode
            ? const Color(0xFF232526)
            : const Color(0xFFFFF9C4),
        body: Center(
          child: CircularProgressIndicator(color: theme.colorScheme.primary),
        ),
      );
    }

    return _buildAnimatedBackground(
      isDarkMode,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Row(
              children: [
                _buildWebNavigationRail(theme, appStrings),
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Colors.white12,
                ),
                Expanded(
                  child: _buildWebContentArea(theme, appStrings, isDarkMode),
                ),
              ],
            ),
            if (_isAiServiceInitialized) // AI Panel Overlay
              AnimatedPositioned(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOutCubic,
                top: 20,
                bottom: 20,
                right: _isChatPanelVisible ? 20 : -410,
                child: AiChatPanel(
                  aiChatService: _aiChatService!,
                  onClose: () => setState(() => _isChatPanelVisible = false),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- WEB-SPECIFIC WIDGETS ---

  Widget _buildWebNavigationRail(ThemeData theme, AppStrings appStrings) {
    return NavigationRail(
      selectedIndex: _navIndex,
      onDestinationSelected: _onNavItemTapped,
      minWidth: 90,
      labelType: NavigationRailLabelType.all,
      backgroundColor: theme.colorScheme.surface.withOpacity(0.3),
      indicatorColor: theme.colorScheme.primaryContainer,
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: FloatingActionButton(
          elevation: 0,
          onPressed: () {},
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          child: const Icon(Icons.flash_on_rounded),
        ),
      ),
      trailing: Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _signOut,
              tooltip: appStrings.generalLogout,
            ),
          ),
        ),
      ),
      destinations: [
        const NavigationRailDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: Text('Home'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.chat_bubble_outline),
          selectedIcon: Icon(Icons.chat_bubble),
          label: Text('Chat'),
        ),
        NavigationRailDestination(
          icon: Badge(
            label: Text(_unreadNotificationsCount.toString()),
            isLabelVisible: _unreadNotificationsCount > 0,
            child: const Icon(Icons.notifications_outlined),
          ),
          selectedIcon: Badge(
            label: Text(_unreadNotificationsCount.toString()),
            isLabelVisible: _unreadNotificationsCount > 0,
            child: const Icon(Icons.notifications),
          ),
          label: const Text('Alerts'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: Text('Profile'),
        ),
      ],
    );
  }

  void _onNavItemTapped(int index) {
    setState(() => _navIndex = index);
    switch (index) {
      case 0:
        break; // Home
      case 1:
        _navigateToUnifiedChatScreen();
        break; // Chat
      case 2:
        _navigateToNotifications();
        break; // Notifications
      case 3:
        if (_userType == 'worker') _navigateToCreateProfile();
        break; // Profile
    }
  }

  Widget _buildWebContentArea(
    ThemeData theme,
    AppStrings appStrings,
    bool isDarkMode,
  ) {
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        return LiquidPullToRefresh(
          onRefresh: _refreshData,
          color: colorScheme.surfaceVariant,
          backgroundColor: colorScheme.secondary,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildWebHeader(theme, appStrings),
              SliverToBoxAdapter(
                child: FadeInDown(
                  duration: _animationDuration,
                  child: _buildSearchAndFilterHeader(
                    theme,
                    colorScheme,
                    textTheme,
                    isDarkMode,
                    appStrings,
                  ),
                ),
              ),
              if ((_userType == 'client' && _featuredWorkers.isNotEmpty) ||
                  (_userType == 'worker' && _featuredJobs.isNotEmpty))
                SliverToBoxAdapter(
                  child: _buildFeaturedSection(
                    theme,
                    colorScheme,
                    textTheme,
                    appStrings,
                    constraints,
                  ),
                ),

              (_userType == 'client' && _filteredWorkers.isEmpty) ||
                      (_userType == 'worker' && _filteredJobs.isEmpty)
                  ? SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyStateWidget(
                        theme,
                        colorScheme,
                        textTheme,
                        appStrings,
                      ),
                    )
                  : _buildContentGridSliver(constraints),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWebHeader(ThemeData theme, AppStrings appStrings) {
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;
    final iconColor = isDarkMode
        ? colorScheme.onSurface
        : colorScheme.onSurface;

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(40, 40, 40, 10),
      sliver: SliverToBoxAdapter(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildGreeting(theme.textTheme, colorScheme, appStrings),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_userType == 'client' && _isAiServiceInitialized)
                  IconButton(
                    icon: const Icon(Icons.auto_awesome_outlined),
                    tooltip: "AI Assistant",
                    onPressed: () => setState(
                      () => _isChatPanelVisible = !_isChatPanelVisible,
                    ),
                    color: iconColor,
                  ),
                IconButton(
                  icon: Icon(
                    isDarkMode
                        ? Icons.wb_sunny_outlined
                        : Icons.nightlight_round,
                  ),
                  tooltip: isDarkMode
                      ? appStrings.themeTooltipLight
                      : appStrings.themeTooltipDark,
                  onPressed: () => Provider.of<ThemeProvider>(
                    context,
                    listen: false,
                  ).toggleTheme(),
                  color: iconColor,
                ),
                IconButton(
                  icon: const Icon(Icons.language),
                  tooltip: appStrings.languageToggleTooltip,
                  onPressed: () {
                    final lp = Provider.of<LocaleProvider>(
                      context,
                      listen: false,
                    );
                    lp.setLocale(
                      lp.locale.languageCode == 'en'
                          ? const Locale('am')
                          : const Locale('en'),
                    );
                    _updateUserAfterLocaleChange();
                  },
                  color: iconColor,
                ),
                if (_userType == 'client')
                  Padding(
                    padding: const EdgeInsets.only(left: 12.0),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text('createJob'),
                      onPressed: _navigateToCreateJob,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- SHARED & ADAPTIVE UI COMPONENTS ---

  Widget _buildAnimatedBackground(bool isDarkMode, {required Widget child}) {
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
      child: child,
    );
  }

  Widget _buildGreeting(
    TextTheme textTheme,
    ColorScheme colorScheme,
    AppStrings appStrings,
  ) {
    String? firstName = _currentUser?.name?.split(' ').first;
    String welcomeMessage = firstName != null && firstName.isNotEmpty
        ? appStrings.helloUser(firstName)
        : (_userType == 'client'
              ? appStrings.findExpertsTitle
              : appStrings.yourJobFeedTitle);

    return FadeInLeft(
      delay: const Duration(milliseconds: 200),
      duration: _animationDuration,
      child: Text(
        welcomeMessage,
        style: GoogleFonts.poppins(
          fontSize: textTheme.headlineMedium?.fontSize,
          fontWeight: FontWeight.bold,
          color: textTheme.headlineMedium?.color ?? colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterHeader(
    ThemeData theme,
    ColorScheme colorScheme,
    TextTheme textTheme,
    bool isDarkMode,
    AppStrings appStrings,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _buildSearchBar(
                  theme,
                  colorScheme,
                  textTheme,
                  appStrings,
                ),
              ),
              const SizedBox(width: 12),
              _buildFilterButton(theme, colorScheme, textTheme, isDarkMode),
            ],
          ),
          _buildAiSearchSuggestion(colorScheme, textTheme, appStrings),
        ],
      ),
    );
  }

  Widget _buildSearchBar(
    ThemeData theme,
    ColorScheme colorScheme,
    TextTheme textTheme,
    AppStrings appStrings,
  ) => Container(
    decoration: BoxDecoration(
      color:
          theme.inputDecorationTheme.fillColor ??
          theme.colorScheme.surfaceVariant.withOpacity(0.8),
      borderRadius: BorderRadius.circular(30.0),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(
            theme.brightness == Brightness.dark ? 0.5 : 0.1,
          ),
          blurRadius: 12,
          spreadRadius: -4,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: TextField(
      controller: _searchController,
      style: textTheme.bodyLarge?.copyWith(fontSize: 15),
      decoration: InputDecoration(
        hintText: _userType == 'client'
            ? appStrings.searchHintProfessionals
            : appStrings.searchHintJobs,
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 18, right: 12),
          child: Icon(Icons.search_rounded, size: 22),
        ),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 20),
                onPressed: () {
                  _searchController.clear();
                  if (_userType == 'client')
                    _applyWorkerFilters();
                  else
                    _applyJobFilters();
                },
              )
            : null,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 15,
        ),
      ),
    ),
  );
  Widget _buildFilterButton(
    ThemeData theme,
    ColorScheme colorScheme,
    TextTheme textTheme,
    bool isDarkMode,
  ) {
    bool filtersActive =
        (_userType == 'client' &&
            (_filterSelectedLocation != 'All' ||
                _filterSelectedCategory != 'All')) ||
        (_userType == 'worker' && _filterSelectedJobStatus != 'All');
    Color iconColor = filtersActive
        ? colorScheme.onSecondary
        : colorScheme.onSurfaceVariant;
    List<Color> gradient = filtersActive
        ? [
            colorScheme.secondary,
            colorScheme.secondaryContainer ??
                colorScheme.secondary.withOpacity(0.7),
          ]
        : [colorScheme.surfaceVariant, theme.cardColor];
    return AnimatedContainer(
      duration: _animationDuration,
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: filtersActive
                ? colorScheme.secondary.withOpacity(0.4)
                : Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: () => _showFilterPanel(theme, colorScheme, textTheme),
          borderRadius: BorderRadius.circular(25),
          child: Padding(
            padding: const EdgeInsets.all(13.0),
            child: Icon(
              filtersActive
                  ? Icons.filter_alt_rounded
                  : Icons.filter_list_rounded,
              color: iconColor,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAiSearchSuggestion(
    ColorScheme colorScheme,
    TextTheme textTheme,
    AppStrings appStrings,
  ) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 300),
    transitionBuilder: (child, animation) => SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(opacity: animation, child: child),
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
                appStrings.workerDetailChat,
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.secondary,
                ),
              ),
              onPressed: () => setStateIfMounted(() {
                _isChatPanelVisible = true;
              }),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colorScheme.secondary.withOpacity(0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
  );

  Widget _buildFeaturedSection(
    ThemeData theme,
    ColorScheme colorScheme,
    TextTheme textTheme,
    AppStrings appStrings,
    BoxConstraints constraints,
  ) {
    String title = _userType == 'client'
        ? appStrings.featuredPros
        : appStrings.featuredJobs;
    int itemCount = _userType == 'client'
        ? _featuredWorkers.length
        : _featuredJobs.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(40.0, 16.0, 40.0, 12.0),
          child: FadeInLeft(
            duration: _animationDuration,
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: textTheme.titleLarge?.fontSize,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
        ),
        CarouselSlider.builder(
          carouselController: _carouselController as CarouselSliderController?,
          itemCount: itemCount,
          itemBuilder: (context, index, realIndex) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: _userType == 'client'
                ? FeaturedWorkerCard(
                    worker: _featuredWorkers[index],
                    onTap: () =>
                        _navigateToWorkerDetails(_featuredWorkers[index]),
                  )
                : FeaturedJobCard(
                    job: _featuredJobs[index],
                    onTap: () => _navigateToJobDetails(_featuredJobs[index]),
                  ),
          ),
          options: CarouselOptions(
            height: 200,
            viewportFraction: (constraints.maxWidth > 1200) ? 0.25 : 0.3,
            enableInfiniteScroll: itemCount > 3,
            autoPlay: true,
            enlargeCenterPage: true,
            enlargeFactor: 0.15,
            padEnds: false,
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildContentGridSliver(BoxConstraints constraints) {
    // Responsive column count for web
    final double contentWidth = constraints.maxWidth;
    int crossAxisCount = (contentWidth < 900)
        ? 2
        : (contentWidth < 1400 ? 3 : 4);
    int itemCount = _userType == 'client'
        ? _filteredWorkers.length
        : _filteredJobs.length;

    return SliverPadding(
      padding: const EdgeInsets.only(left: 40, right: 40, bottom: 100, top: 4),
      sliver: AnimationLimiter(
        child: SliverMasonryGrid.count(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          childCount: itemCount,
          itemBuilder: (context, index) => AnimationConfiguration.staggeredGrid(
            position: index,
            duration: const Duration(milliseconds: 500),
            columnCount: crossAxisCount,
            child: ScaleAnimation(
              curve: Curves.easeOutBack,
              child: FadeInAnimation(
                curve: Curves.easeOutCubic,
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
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyStateWidget(
    ThemeData theme,
    ColorScheme colorScheme,
    TextTheme textTheme,
    AppStrings appStrings,
  ) => FadeInUp(
    duration: const Duration(milliseconds: 500),
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _userType == 'client'
                  ? Icons.person_search_outlined
                  : Icons.find_in_page_outlined,
              size: 90,
              color: colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 24),
            Text(
              _userType == 'client'
                  ? appStrings.emptyStateProfessionals
                  : appStrings.emptyStateJobs,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: textTheme.titleLarge?.fontSize,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              appStrings.emptyStateDetails,
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
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
