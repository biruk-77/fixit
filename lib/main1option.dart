// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:line_icons/line_icons.dart';
// Needed if AppThemes uses it directly (optional here if only used in AppThemes)
import 'package:flutter_telebirr/flutter_telebirr.dart';
import 'package:provider/provider.dart';

// --- Firebase Options ---
import 'firebase_options.dart';

// --- Screen Imports (Adjust paths if necessary) ---
import 'screens/home_screen.dart';
import 'screens/jobs/create_job_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/job_history_screen.dart';
import 'screens/professional_setup_screen.dart';
import 'screens/jobs/job_dashboard_screen.dart';

// --- Service Imports (Adjust paths if necessary) ---
import 'services/auth_service.dart';

// --- Theme Imports ---
// Import the file that defines the ThemeData objects

// Import the color files if needed directly (usually not needed here if only AppThemes uses them)
// import 'theme/dark_colors.dart';
import 'theme/light_colors.dart';

// --- Provider Import ---
import 'providers/theme_provider.dart';

// ============================================================
//                 MAIN FUNCTION
// ============================================================
void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // --- Telebirr Configuration (REMEMBER to use your ACTUAL keys!) ---
  TelebirrPayment.instance.configure(
    publicKey:
        'MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQC/ZcoOng1sJZ4CegopQVCw3HYqqVRLEudgT+dDpS8fRVy7zBgqZunju2VRCQuHeWs7yWgc9QGd4/8kRSLY+jlvKNeZ60yWcqEY+eKyQMmcjOz2Sn41fcVNgF+HV3DGiV4b23B6BCMjnpEFIb9d99/TsjsFSc7gCPgfl2yWDxE/Y1B2tVE6op2qd63YsMVFQGdre/CQYvFJENpQaBLMq4hHyBDgluUXlF0uA1X7UM0ZjbFC6ZIB/Hn1+pl5Ua8dKYrkVaecolmJT/s7c/+/1JeN+ja8luBoONsoODt2mTeVJHLF9Y3oh5rI+IY8HukIZJ1U6O7/JcjH3aRJTZagXUS9AgMBAAECggEBALBIBx8JcWFfEDZFwuAWeUQ7+VX3mVx/770kOuNx24HYt718D/HV0avfKETHqOfA7AQnz42EF1Yd7Rux1ZO0e3unSVRJhMO4linT1XjJ9ScMISAColWQHk3wY4va/FLPqG7N4L1w3BBtdjIc0A2zRGLNcFDBlxl/CVDHfcqD3CXdLukm/friX6TvnrbTyfAFicYgu0+UtDvfxTL3pRL3u3WTkDvnFK5YXhoazLctNOFrNiiIpCW6dJ7WRYRXuXhz7C0rENHyBtJ0zura1WD5oDbRZ8ON4v1KV4QofWiTFXJpbDgZdEeJJmFmt5HIi+Ny3P5n31WwZpRMHGeHrV23//0CgYEA+2/gYjYWOW3JgMDLX7r8fGPTo1ljkOUHuH98H/a/lE3wnnKKx+2ngRNZX4RfvNG4LLeWTz9plxR2RAqqOTbX8fj/NA/sS4mru9zvzMY1925FcX3WsWKBgKlLryl0vPScq4ejMLSCmypGz4VgLMYZqT4NYIkU2Lo1G1MiDoLy0CcCgYEAwt77exynUhM7AlyjhAA2wSINXLKsdFFF1u976x9kVhOfmbAutfMJPEQWb2WXaOJQMvMpgg2rU5aVsyEcuHsRH/2zatrxrGqLqgxaiqPz4ELINIh1iYK/hdRpr1vATHoebOv1wt8/9qxITNKtQTgQbqYci3KV1lPsOrBAB5S57nsCgYAvw+cagS/jpQmcngOEoh8I+mXgKEET64517DIGWHe4kr3dO+FFbc5eZPCbhqgxVJ3qUM4LK/7BJq/46RXBXLvVSfohR80Z5INtYuFjQ1xJLveeQcuhUxdK+95W3kdBBi8lHtVPkVsmYvekwK+ukcuaLSGZbzE4otcn47kajKHYDQKBgDbQyIbJ+ZsRw8CXVHu2H7DWJlUUBIS3s+CQ/xeVfgDkhjmSIKGX2to0AOeW+S9MseiTE/L8a1wY+MUppE2UeK26DLUbH24zjlPoI7PqCJjl0DFOzVlACSXZKV1lfsNEeriC61/EstZtgezyOkAlSCIH4fGr6tAeTU349Bnt0RtvAoGBAObgxjeH6JGpdLz1BbMj8xUHuYQkbxNeIPhH29CySn0vfhwg9VxAtIoOhvZeCfnsCRTj9OZjepCeUqDiDSoFznglrKhfeKUndHjvg+9kiae92iI6qJudPCHMNwP8wMSphkxUqnXFR3lr9A765GA980818UWZdrhrjLKtIIZdh+X1', // Replace with actual key
    appId: 'c4182ef8-9249-458a-985e-06d191f4d505', // Replace with actual ID
    appKey: 'fad0f06383c6297f545876694b974599', // Replace with actual key
    notifyUrl:
        'https://developerportal.ethiotelebirr.et:38443/apiaccess/payment/gateway', // Replace with your actual URL
    shortCode: '76830', // Replace with actual code
    merchantDisplayName: 'fixit95',
    mode: Mode.test, // Use Mode.production for live
    testUrl:
        "https://app.ethiotelecom.et:8080/server_test_back_url", // Only needed for Mode.test
  );

  // Run the app, wrapped in the ChangeNotifierProvider for theme management
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

// ============================================================
//                 MY APP WIDGET (Root)
// ============================================================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to the ThemeProvider to get the current theme mode
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      debugShowCheckedModeBanner: false, // Hides the debug banner
      title: 'FixIt',

      // Provide the theme definitions from AppThemes
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,

      // Control the active theme using the provider's state
      themeMode: themeProvider.themeMode,

      // Initial route when the app starts
      initialRoute: '/',

      // Define the app's navigation routes
      routes: {
        '/': (context) => const AuthWrapper(),
        '/home': (context) => const MainScreen(),
        '/login': (context) => const LoginScreen(),
        '/professional-setup': (context) => const ProfessionalSetupScreen(),
        '/jobs': (context) => const JobDashboardScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/post-job': (context) => const CreateJobScreen(),
        '/history': (context) =>
            const JobHistoryScreen(), // Added route example
        // Add other routes here if needed
      },
    );
  }
}

// ============================================================
//                 AUTH WRAPPER (Handles routing based on login state)
// ============================================================
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    // Use FutureBuilder to handle the async nature of checking login state
    // Wrap the synchronous check in a Future for compatibility
    return FutureBuilder<bool>(
      future: Future(() => authService.isUserLoggedIn()),
      builder: (context, snapshot) {
        // Show loading indicator while checking
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          );
        }

        // Handle potential errors during the check
        if (snapshot.hasError) {
          print('Error in AuthWrapper FutureBuilder: ${snapshot.error}');
          // Optionally show a dedicated error screen
          return const LoginScreen(); // Fallback to login on error
        }

        // Get the login status (default to false if data is null)
        final bool isLoggedIn = snapshot.data ?? false;
        print("AuthWrapper: User logged in = $isLoggedIn"); // Debug log

        // Navigate based on login status
        if (isLoggedIn) {
          return const MainScreen(); // User is logged in, show main app
        } else {
          return const LoginScreen(); // User is not logged in, show login
        }
      },
    );
  }
}

// ============================================================
//                 THEME TOGGLE BUTTON WIDGET
// ============================================================
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to the ThemeProvider for changes
    final themeProvider = context.watch<ThemeProvider>();

    return IconButton(
      // Display icon based on the current theme mode
      icon: Icon(
        themeProvider.isDarkMode
            ? Icons.light_mode_outlined // Show sun icon in dark mode
            : Icons.dark_mode_outlined, // Show moon icon in light mode
      ),
      // Tooltip explains the button's action
      tooltip: themeProvider.isDarkMode
          ? 'Switch to Light Mode'
          : 'Switch to Dark Mode',
      // Use the AppBar's icon color from the current theme
      color: Theme.of(context).appBarTheme.iconTheme?.color,
      // When pressed, call the toggle method in the ThemeProvider
      onPressed: () {
        // Use listen: false because this widget doesn't need to rebuild *when clicking*
        // The theme change will cause MyApp -> MaterialApp to rebuild, applying the theme
        Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
      },
    );
  }
}

// ============================================================
//                 MAIN SCREEN WIDGET (Scaffold, Nav, AppBar)
// ============================================================
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  String? _userType; // User role (client or professional)
  bool _isLoading = true; // Tracks loading state for user profile
  final AuthService _authService = AuthService();

  // Lists to hold the screens, navigation items, and titles based on user type
  List<Widget> _screens = [];
  List<GButton> _navItems = [];
  List<String> _screenTitles = [];

  @override
  void initState() {
    super.initState();
    // Initialize user type and screens after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Check if the widget is still in the tree
        _determineUserTypeAndInitialize();
      }
    });
  }

  // Fetches user profile and initializes UI elements accordingly
  Future<void> _determineUserTypeAndInitialize() async {
    // Prevent state updates if widget is disposed
    if (!mounted) return;

    // Set loading state
    setState(() => _isLoading = true);

    try {
      // Get user profile data
      final userProfile = await _authService.getCurrentUserProfile();

      // Check mount status again after async operation
      if (!mounted) return;

      // Determine user type based on profile data
      if (userProfile != null) {
        final determinedType =
            userProfile.role == 'worker' ? 'professional' : 'client';
        print("MainScreen: Determined user type: $determinedType");
        _userType = determinedType;
      } else {
        // Handle cases where profile or role is missing (should ideally not happen if auth is robust)
        print(
            "MainScreen Warning: User profile or role is null, defaulting to client.");
        _userType = 'client'; // Set a sensible default
      }

      // Initialize screens, nav items, and titles based on the determined type
      _initializeScreensAndNavItems();
      // Update loading state
      setState(() => _isLoading = false);
    } catch (e, s) {
      // Catch error and stack trace
      if (!mounted) return; // Check again
      print('MainScreen Error: Determining user type failed: $e\n$s');
      setState(() {
        _userType = 'client'; // Fallback to default on error
        _initializeScreensAndNavItems(); // Initialize with default
        _isLoading = false;
      });
      // Show an error message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading user data. Please restart.',
              style: TextStyle(color: Theme.of(context).colorScheme.onError)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  // Initializes screen list, navigation items, and titles based on _userType
  // !! CRITICAL !! Screens added to `_screens` MUST NOT build their own Scaffold/AppBar.
  void _initializeScreensAndNavItems() {
    // Ensure _userType is not null
    if (_userType == null) {
      print("MainScreen Error: _initialize called with null userType!");
      _userType = 'client'; // Set a default if initialization failed earlier
    }

    if (_userType == 'professional') {
      _screens = [
        const HomeScreen(), // Should return body content ONLY
        const ProfileScreen(), // Should return body content ONLY
        const JobDashboardScreen(), // Should return body content ONLY
        const ProfessionalSetupScreen(), // Should return body content ONLY
      ];
      _navItems = [
        const GButton(icon: LineIcons.briefcase, text: 'Feed'),
        const GButton(icon: LineIcons.user, text: 'Profile'),
        const GButton(icon: LineIcons.syncIcon, text: 'My Jobs'),
        const GButton(icon: LineIcons.edit, text: 'Setup'),
      ];
      _screenTitles = ['Job Feed', 'My Profile', 'My Jobs', 'Profile Setup'];
    } else {
      // Default to client if type is not professional
      _screens = [
        const HomeScreen(), // Should return body content ONLY
        const CreateJobScreen(), // Should return body content ONLY
        const ProfileScreen(), // Should return body content ONLY
        const JobHistoryScreen(), // Should return body content ONLY
      ];
      _navItems = [
        const GButton(icon: LineIcons.home, text: 'Home'),
        const GButton(icon: LineIcons.plusCircle, text: 'Post Job'),
        const GButton(icon: LineIcons.user, text: 'Profile'),
        const GButton(icon: LineIcons.history, text: 'History'),
      ];
      _screenTitles = ['Home', 'Post New Job', 'My Profile', 'Job History'];
    }

    // Ensure selected index is valid after lists are updated
    if (_selectedIndex >= _screens.length) {
      _selectedIndex = 0;
    }
    print("MainScreen: Initialized UI for $_userType.");
  }

  @override
  Widget build(BuildContext context) {
    // Get theme data for styling based on current mode (light/dark)
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    // --- Loading State UI ---
    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
      );
    }

    // --- Error/Empty State UI (if initialization failed) ---
    if (_screens.isEmpty || _navItems.isEmpty || _screenTitles.isEmpty) {
      print(
          "MainScreen Build Warning: Screen lists are empty. Showing error state.");
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(title: const Text("Error"), elevation: 0),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: colorScheme.error, size: 60),
                const SizedBox(height: 20),
                Text(
                  'Could not load app sections.\nPlease check your connection or restart the app.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // --- Main UI Structure ---
    return Scaffold(
      // AppBar displayed consistently across all main sections
      appBar: AppBar(
        // Title changes based on the selected screen
        title: Text(
          _selectedIndex < _screenTitles.length
              ? _screenTitles[_selectedIndex]
              : 'FixIt', // Fallback title
          style: theme.appBarTheme.titleTextStyle, // Use theme's title style
        ),
        centerTitle: true, // Optionally center the title
        elevation: theme.appBarTheme.elevation, // Use theme's elevation
        backgroundColor:
            theme.appBarTheme.backgroundColor, // Use theme's background
        // Actions appear on the right side of the AppBar
        actions: const [
          // Include the theme toggle button
          ThemeToggleButton(),
          SizedBox(width: 10), // Add some trailing space
        ],
      ),

      // Body uses IndexedStack to efficiently switch between screens
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens, // The list of screen widgets
      ),

      // Bottom Navigation Bar using GNav
      bottomNavigationBar: Container(
        // Styling the container holding the GNav bar
        decoration: BoxDecoration(
          color: theme.bottomNavigationBarTheme.backgroundColor ??
              colorScheme.surface,
          boxShadow: [
            // Subtle shadow for depth
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.4 : 0.1),
              blurRadius: 15,
              spreadRadius: -3,
              offset: const Offset(0, -4), // Shadow comes from top
            ),
          ],
          border: Border(
            // Subtle top border line
            top: BorderSide(
              color: theme.dividerColor,
              width: 0.5,
            ),
          ),
        ),
        // SafeArea ensures content is not obscured by system UI (like notch or home bar)
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            child: GNav(
              // Styling GNav using the current theme
              rippleColor: colorScheme.primary.withOpacity(0.2),
              hoverColor: colorScheme.primary.withOpacity(0.1),
              gap: 8, // Space between icon and text
              activeColor: theme.bottomNavigationBarTheme.selectedItemColor ??
                  colorScheme.primary,
              iconSize: 24,
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12), // Padding within each nav item
              duration: const Duration(milliseconds: 400), // Animation duration
              tabBackgroundColor: colorScheme.primary.withOpacity(
                  isDarkMode ? 0.15 : 0.1), // Background of the active tab
              color: theme.bottomNavigationBarTheme.unselectedItemColor ??
                  colorScheme.onSurface
                      .withOpacity(0.6), // Color of inactive icons/text
              tabs: _navItems, // The list of GButton items
              selectedIndex: _selectedIndex, // Currently selected tab index
              // Callback when a tab is tapped
              onTabChange: (index) {
                // Update the selected index if it's valid
                if (index < _screens.length) {
                  setState(() => _selectedIndex = index);
                } else {
                  // Log error if index is out of bounds (shouldn't happen with GNav usually)
                  print(
                      "Error: GNav index out of bounds! Index: $index, Screen count: ${_screens.length}");
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}