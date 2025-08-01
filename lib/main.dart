import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:line_icons/line_icons.dart';
import 'package:flutter_telebirr/flutter_telebirr.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/jobs/create_job_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/job_history_screen.dart';
import 'screens/professional_setup_screen.dart';
import 'screens/jobs/job_dashboard_screen.dart';
import 'screens/professional_setup_edit.dart';
import 'services/auth_service.dart';
import 'services/app_string.dart';

import 'theme/light_colors.dart';

import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Supabase.initialize(
    url: 'https://sitvpubcpqjsypqmnfem.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNpdHZwdWJjcHFqc3lwcW1uZmVtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ2MzQwNzAsImV4cCI6MjA2MDIxMDA3MH0.92WtPxdEFtVXn2PRUZKineYg13BY0FH8fLtyIqtAAaE', // YOUR ANON KEY
  );
  TelebirrPayment.instance.configure(
    publicKey:
        'MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQC/ZcoOng1sJZ4CegopQVCw3HYqqVRLEudgT+dDpS8fRVy7zBgqZunju2VRCQuHeWs7yWgc9QGd4/8kRSLY+jlvKNeZ60yWcqEY+eKyQMmcjOz2Sn41fcVNgF+HV3DGiV4b23B6BCMjnpEFIb9d99/TsjsFSc7gCPgfl2yWDxE/Y1B2tVE6op2qd63YsMVFQGdre/CQYvFJENpQaBLMq4hHyBDgluUXlF0uA1X7UM0ZjbFC6ZIB/Hn1+pl5Ua8dKYrkVaecolmJT/s7c/+/1JeN+ja8luBoONsoODt2mTeVJHLF9Y3oh5rI+IY8HukIZJ1U6O7/JcjH3aRJTZagXUS9AgMBAAECggEBALBIBx8JcWFfEDZFwuAWeUQ7+VX3mVx/770kOuNx24HYt718D/HV0avfKETHqOfA7AQnz42EF1Yd7Rux1ZO0e3unSVRJhMO4linT1XjJ9ScMISAColWQHk3wY4va/FLPqG7N4L1w3BBtdjIc0A2zRGLNcFDBlxl/CVDHfcqD3CXdLukm/friX6TvnrbTyfAFicYgu0+UtDvfxTL3pRL3u3WTkDvnFK5YXhoazLctNOFrNiiIpCW6dJ7WRYRXuXhz7C0rENHyBtJ0zura1WD5oDbRZ8ON4v1KV4QofWiTFXJpbDgZdEeJJmFmt5HIi+Ny3P5n31WwZpRMHGeHrV23//0CgYEA+2/gYjYWOW3JgMDLX7r8fGPTo1ljkOUHuH98H/a/lE3wnnKKx+2ngRNZX4RfvNG4LLeWTz9plxR2RAqqOTbX8fj/NA/sS4mru9zvzMY1925FcX3WsWKBgKlLryl0vPScq4ejMLSCmypGz4VgLMYZqT4NYIkU2Lo1G1MiDoLy0CcCgYEAwt77exynUhM7AlyjhAA2wSINXLKsdFFF1u976x9kVhOfmbAutfMJPEQWb2WXaOJQMvMpgg2rU5aVsyEcuHsRH/2zatrxrGqLqgxaiqPz4ELINIh1iYK/hdRpr1vATHoebOv1wt8/9qxITNKtQTgQbqYci3KV1lPsOrBAB5S57nsCgYAvw+cagS/jpQmcngOEoh8I+mXgKEET64517DIGWHe4kr3dO+FFbc5eZPCbhqgxVJ3qUM4LK/7BJq/46RXBXLvVSfohR80Z5INtYuFjQ1xJLveeQcuhUxdK+95W3kdBBi8lHtVPkVsmYvekwK+ukcuaLSGZbzE4otcn47kajKHYDQKBgDbQyIbJ+ZsRw8CXVHu2H7DWJlIUBIS3s+CQ/xeVfgDkhjmSIKGX2to0AOeW+S9MseiTE/L8a1wY+MUppE2UeK26DLUbH24zjlPoI7PqCJjl0DFOzVlACSXZKV1lfsNEeriC61/EstZtgezyOkAlSCIH4fGr6tAeTU349Bnt0RtvAoGBAObgxjeH6JGpdLz1BbMj8xUHuYQkbxNeIPhH29CySn0vfhwg9VxAtIoOhvZeCfnsCRTj9OZjepCeUqDiDSoFznglrKhfeKUndHjvg+9kiae92iI6qJudPCHMNwP8wMSphkxUqnXFR3lr9A765GA980818UWZdrhrjLKtIIZdh+X1',
    appId: 'c4182ef8-9249-458a-985e-06d191f4d505',
    appKey: 'fad0f06383c6297f545876694b974599',
    notifyUrl: '...',
    shortCode: '...',
    merchantDisplayName: 'fixit95',
    mode: Mode.test,
    testUrl: "...",
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FixIt', // Can be localized later

      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // English
        Locale('am', ''), // Amharic
        Locale('om', ''), // Oromo
      ],
      locale: localeProvider.locale,
      // ----------------------------------------------------

      // --- Theme Setup ---
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: themeProvider.themeMode,

      // -----------------
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/home': (context) => const MainScreen(),
        '/login': (context) => const LoginScreen(),
        '/professional-setup': (context) => const ProfessionalSetupScreen(),
        '/professional-edit': (context) => const ProfessionalHubScreen(),
        '/jobs': (context) => const JobDashboardScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/post-job': (context) => const CreateJobScreen(),
        '/history': (context) => const JobHistoryScreen(),
      },
    );
  }
}

// ============================================================
//                 AUTH WRAPPER
// ============================================================
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    final appStrings = AppLocalizations.of(context); // Get strings safely

    return FutureBuilder<bool>(
      future: Future(() => authService.isUserLoggedIn()),
      builder: (context, snapshot) {
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
        if (snapshot.hasError) {
          print('Error in AuthWrapp FutureBuilder: ${snapshot.error}');
          // Consider showing a generic error screen
          return const LoginScreen();
        }
        final bool isLoggedIn = snapshot.data ?? false;
        print("AuthWrapper: User logged in = $isLoggedIn");
        return isLoggedIn ? const MainScreen() : const LoginScreen();
      },
    );
  }
}

// ============================================================
//                 THEME TOGGLE BUTTON
// ============================================================
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final appStrings = AppLocalizations.of(context);

    return IconButton(
      icon: Icon(
        themeProvider.isDarkMode
            ? Icons.light_mode_outlined
            : Icons.dark_mode_outlined,
      ),
      tooltip: themeProvider.isDarkMode
          ? appStrings?.themeTooltipLight ?? 'Switch to Light Mode'
          : appStrings?.themeTooltipDark ?? 'Switch to Dark Mode',
      color: Theme.of(context).appBarTheme.iconTheme?.color,
      onPressed: () =>
          Provider.of<ThemeProvider>(context, listen: false).toggleTheme(),
    );
  }
}

// ============================================================
//      NEW LANGUAGE POPUP MENU BUTTON WIDGET
// ============================================================
class LanguagePopupMenuButton extends StatelessWidget {
  const LanguagePopupMenuButton({super.key});

  // Helper map for display names
  static const Map<String, String> _languageOptions = {
    'en': 'English',
    'am': 'አማርኛ', // Amharic
  };

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.read<LocaleProvider>();
    final currentLocaleCode = localeProvider.locale.languageCode;
    final theme = Theme.of(context); // Get theme for styling

    return PopupMenuButton<String>(
      icon: Icon(
        Icons.translate_rounded,
        color:
            theme.appBarTheme.actionsIconTheme?.color ??
            theme.appBarTheme.iconTheme?.color,
      ), // Use AppBar icon color
      tooltip:
          AppLocalizations.of(context)?.languageToggleTooltip ??
          "Change Language", // Localized tooltip
      onSelected: (String languageCode) {
        localeProvider.setLocale(Locale(languageCode));
      },
      itemBuilder: (BuildContext context) {
        // Build menu items for each supported language
        return _languageOptions.entries.map((entry) {
          final code = entry.key;
          final name = entry.value;
          final bool isSelected = code == currentLocaleCode;

          return PopupMenuItem<String>(
            value: code,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_rounded, color: theme.colorScheme.primary),
              ],
            ),
          );
        }).toList();
      },
      // Optional: Style the popup menu itself
      color:
          theme.popupMenuTheme.color ??
          theme.cardColor, // Use themed popup background
      shape:
          theme.popupMenuTheme.shape ??
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: theme.popupMenuTheme.elevation ?? 4.0,
    );
  }
}

// ============================================================
//                 MAIN SCREEN WIDGET
// ============================================================
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  String? _userType;
  bool _isLoading = true;
  final AuthService _authService = AuthService();

  List<Widget> _screens = [];
  List<GButton> _navItems = [];
  List<String> _screenTitles = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _determineUserTypeAndInitialize();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-initialize UI when locale changes (or theme, etc.) if not loading
    if (!_isLoading && mounted) {
      _initializeScreensAndNavItems();
    }
  }

  Future<void> _determineUserTypeAndInitialize() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final userProfile = await _authService.getCurrentUserProfile();
      if (!mounted) return;
      _userType = (userProfile?.role == 'worker') ? 'professional' : 'client';

      _initializeScreensAndNavItems();
    } catch (e, s) {
      if (!mounted) return;
      print('MainScreen Error: Determining user type failed: $e\n$s');
      _userType = 'client';
      _initializeScreensAndNavItems(); // Use fallback
      final appStrings = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            appStrings?.snackErrorLoadingProfile ?? 'Error loading user data.',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _initializeScreensAndNavItems() {
    final appStrings = AppLocalizations.of(context);
    _userType ??= 'client'; 
    if (appStrings == null) {
      print(
        "MainScreen Warning: AppLocalizations was null during init. Using fallbacks.",
      );
      _initializeWithFallbackKeys();
      return;
    }

    // Use localized strings now that they are available
    if (_userType == 'professional') {
      _screens = [
        const HomeScreen(),
        const ProfileScreen(),
        const JobDashboardScreen(),
        const ProfessionalHubScreen(),
      ];
      _navItems = [
        GButton(icon: LineIcons.briefcase, text: appStrings.navFeed),
        GButton(icon: LineIcons.user, text: appStrings.navProfile),
        GButton(icon: LineIcons.syncIcon, text: appStrings.navMyJobs),
        GButton(icon: LineIcons.edit, text: appStrings.navSetup),
      ];
      _screenTitles = [
        appStrings.appBarJobFeed,
        appStrings.appBarMyProfile,
        appStrings.appBarMyJobs,
        appStrings.appBarProfileSetup,
      ];
    } else {
      // Client
      _screens = [
        const HomeScreen(),
        const CreateJobScreen(),
        const ProfileScreen(),
        const JobDashboardScreen(),
      ];
      _navItems = [
        GButton(icon: LineIcons.home, text: appStrings.navHome),
        GButton(icon: LineIcons.plusCircle, text: appStrings.navPostJob),
        GButton(icon: LineIcons.user, text: appStrings.navProfile),
        GButton(icon: LineIcons.history, text: appStrings.navHistory),
      ];
      _screenTitles = [
        appStrings.appBarHome,
        appStrings.appBarPostNewJob,
        appStrings.appBarMyProfile,
        appStrings.appBarJobHistory,
      ];
    }

    if (mounted && _selectedIndex >= _screens.length) {
      _selectedIndex = 0;
    } 
    print(
      "MainScreen: Initialized UI for $_userType with locale ${appStrings.locale.languageCode}.",
    );
  }

  void _initializeWithFallbackKeys() {
    _userType ??= 'client';
    if (_userType == 'professional') {
      _screens = [
        const HomeScreen(),
        const ProfileScreen(),
        const JobDashboardScreen(),
        const ProfessionalSetupScreen(),
      ];
      _navItems = [
        const GButton(icon: LineIcons.briefcase, text: 'Feed'),
        const GButton(icon: LineIcons.user, text: 'Profile'),
        const GButton(icon: LineIcons.syncIcon, text: 'My Jobs'),
        const GButton(icon: LineIcons.edit, text: 'Setup'),
      ];
      _screenTitles = ['Job Feed', 'My Profile', 'My Jobs', 'Profile Setup'];
    } else {
      _screens = [
        const HomeScreen(),
        const CreateJobScreen(),
        const ProfileScreen(),
        const JobDashboardScreen(),
      ];
      _navItems = [
        const GButton(icon: LineIcons.home, text: 'Home'),
        const GButton(icon: LineIcons.plusCircle, text: 'Post Job'),
        const GButton(icon: LineIcons.user, text: 'Profile'),
        const GButton(icon: LineIcons.history, text: 'jobs'),
      ];
      _screenTitles = ['Home', 'Post New Job', 'My Profile', 'jobs'];
    }
    print("MainScreen: Initialized UI for $_userType with FALLBACK keys.");
    if (mounted && _selectedIndex >= _screens.length) {
      _selectedIndex = 0; 
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;
    final appStrings = AppLocalizations.of(context);

    if (_isLoading || appStrings == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
      );
    }
    if (_screens.isEmpty || _navItems.isEmpty || _screenTitles.isEmpty) {
      print(
        "MainScreen: Re-initializing UI in build (maybe strings became ready).",
      );
      _initializeScreensAndNavItems();
      if (_screens.isEmpty || _navItems.isEmpty || _screenTitles.isEmpty) {
        print(
          "MainScreen Build ERROR: Screen lists STILL empty. Critical error.",
        );
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(title: Text(appStrings.errorGeneric)),
          body: Center(child: Text(appStrings.errorGeneric)),
        );
      }
    }

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color:
              theme.bottomNavigationBarTheme.backgroundColor ??
              colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
              blurRadius: 10,
              spreadRadius: -2,
              offset: const Offset(0, -3),
            ),
          ],
          border: Border(
            top: BorderSide(color: theme.dividerColor, width: 0.5),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            child: GNav(
              rippleColor: colorScheme.primary.withOpacity(0.15),
              hoverColor: colorScheme.primary.withOpacity(0.08),
              gap: 8,
              activeColor:
                  theme.bottomNavigationBarTheme.selectedItemColor ??
                  colorScheme.primary,
              iconSize: 24,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor: colorScheme.primary.withOpacity(
                isDarkMode ? 0.15 : 0.1,
              ),
              color:
                  theme.bottomNavigationBarTheme.unselectedItemColor ??
                  colorScheme.onSurface.withOpacity(0.6),
              tabs: _navItems, // These have localized text now
              selectedIndex: _selectedIndex,
              onTabChange: (index) {
                if (index < _screens.length && mounted) {
                  setState(() => _selectedIndex = index);
                } else if (mounted) {
                  print(
                    "Error: GNav index out of bounds! Index: $index, Screen count: ${_screens.length}",
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
