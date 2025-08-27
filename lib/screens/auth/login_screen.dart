// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

// UI & Animation Packages
import 'package:animate_do/animate_do.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:video_player/video_player.dart';
// --- CORRECTED IMPORTS to match your pubspec.yaml ---
import 'package:animate_gradient/animate_gradient.dart'; // Using your package
import 'package:haptic_feedback/haptic_feedback.dart'; // Using your package

// Local Imports
import '../../services/auth_service.dart';
import '../../services/app_string.dart';
import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

//======================================================================================
// ARCHITECTURE: THE VIEWMODEL
//======================================================================================
enum ViewState { idle, loading, googleLoading, error }

class LoginViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  TextEditingController get emailController => _emailController;
  TextEditingController get passwordController => _passwordController;

  ViewState _state = ViewState.idle;
  ViewState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void _setState(ViewState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<bool> loginWithEmail(AppStrings appStrings) async {
    _setState(ViewState.loading);
    try {
      await _authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );
      _setState(ViewState.idle);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getLoginErrorMessage(e.code, appStrings);
      _setState(ViewState.error);
      return false;
    } catch (e) {
      _errorMessage = appStrings.loginErrorUnknown;
      _setState(ViewState.error);
      return false;
    }
  }

  Future<bool> signInWithGoogle(AppStrings appStrings) async {
    _setState(ViewState.googleLoading);
    try {
      final userCredential = await _authService.signInWithGoogle();
      if (userCredential != null && userCredential.user != null) {
        _setState(ViewState.idle);
        return true;
      }
      _setState(ViewState.idle);
      return false; // User cancelled
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getLoginErrorMessage(e.code, appStrings);
      _setState(ViewState.error);
      return false;
    } catch (e) {
      _errorMessage = appStrings.loginErrorGoogleSignIn;
      _setState(ViewState.error);
      return false;
    }
  }

  String _getLoginErrorMessage(String code, AppStrings appStrings) {
    switch (code) {
      case 'user-not-found':
        return appStrings.loginErrorUserNotFound;
      case 'wrong-password':
        return appStrings.loginErrorWrongPassword;
      case 'invalid-email':
        return appStrings.loginErrorInvalidEmail;
      case 'user-disabled':
        return appStrings.loginErrorUserDisabled;
      case 'too-many-requests':
        return appStrings.loginErrorTooManyRequests;
      case 'invalid-credential':
        return appStrings.loginErrorWrongPassword;
      case 'account-exists-with-different-credential':
        return appStrings.googleSignInAccountExists;
      default:
        return appStrings.loginErrorUnknown;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

//======================================================================================
// ENTRY POINT: The Main Widget
//======================================================================================
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LoginViewModel(),
      child: const _LoginScreenContent(),
    );
  }
}

class _LoginScreenContent extends StatefulWidget {
  const _LoginScreenContent();

  @override
  _LoginScreenContentState createState() => _LoginScreenContentState();
}

class _LoginScreenContentState extends State<_LoginScreenContent> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final viewModel = Provider.of<LoginViewModel>(context, listen: false);
    viewModel.addListener(() {
      if (viewModel.state == ViewState.error) {
        _showErrorSnackbar(
          viewModel.errorMessage ?? "An unknown error occurred.",
        );
      }
    });
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: theme.colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: theme.colorScheme.onErrorContainer),
              ),
            ),
          ],
        ),
        backgroundColor: theme.colorScheme.errorContainer,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }

  Future<void> _handleLogin(Future<bool> Function() loginFunction) async {
    // For email/password, first validate the form.
    if (_formKey.currentState != null && !_formKey.currentState!.validate()) {
      final viewModel = Provider.of<LoginViewModel>(context, listen: false);
      // Ensure we only block form validation for the specific email login function.
      if (loginFunction == viewModel.loginWithEmail) {
        return;
      }
    }

    // --- CORRECTED HAPTIC FEEDBACK call to match your package ---
    if (await Haptics.canVibrate()) {
      await Haptics.vibrate(HapticsType.light);
    }

    final success = await loginFunction();
    if (success) {
      if (await Haptics.canVibrate()) {
        await Haptics.vibrate(HapticsType.success);
      }
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appStrings = AppLocalizations.of(context);
    if (appStrings == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          const double webBreakpoint = 900.0;
          final bool isWebView = constraints.maxWidth > webBreakpoint;

          return Form(
            key: _formKey,
            child: isWebView
                ? _WebLayout(onLogin: _handleLogin)
                : _MobileLayout(onLogin: _handleLogin),
          );
        },
      ),
    );
  }
}

//======================================================================================
// EXPERIENCE 1: WEB - "The Digital Flagship Store"
//======================================================================================
class _WebLayout extends StatefulWidget {
  final Future<void> Function(Future<bool> Function()) onLogin;
  const _WebLayout({required this.onLogin});

  @override
  _WebLayoutState createState() => _WebLayoutState();
}

class _WebLayoutState extends State<_WebLayout> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        VideoPlayerController.networkUrl(
            Uri.parse(
              'https://videos.pexels.com/video-files/3209828/3209828-hd_1920_1080_25fps.mp4',
            ),
          )
          ..initialize().then((_) {
            _controller.setLooping(true);
            _controller.setVolume(0.0);
            _controller.play();
            setState(() {});
          });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 6,
          child: Container(
            color: Colors.black,
            child: Stack(
              children: [
                if (_controller.value.isInitialized)
                  SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _controller.value.size.width,
                        height: _controller.value.size.height,
                        child: VideoPlayer(_controller),
                      ),
                    ),
                  ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.9),
                        Colors.black.withOpacity(0.2),
                      ],
                    ),
                  ),
                ),
                const _ShowcasePanel(),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Stack(
              children: [
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 60),
                    child: _FormPanel(onLogin: widget.onLogin),
                  ),
                ),
                const _FloatingControls(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ShowcasePanel extends StatelessWidget {
  const _ShowcasePanel();

  @override
  Widget build(BuildContext context) {
    final appStrings = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(60.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer.fromColors(
            baseColor: Theme.of(context).colorScheme.primary,
            highlightColor: Colors.yellow.shade200,
            child: Text(
              "GB WORKS",
              style: GoogleFonts.poppins(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const _AnimatedHeadline(),
          const SizedBox(height: 20),
          FadeInUp(
            from: 20,
            delay: const Duration(milliseconds: 200),
            child: Text(
              appStrings.appTagline,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

//======================================================================================
// EXPERIENCE 2: MOBILE - "The Personal Gateway"
//======================================================================================
class _MobileLayout extends StatelessWidget {
  final Future<void> Function(Future<bool> Function()) onLogin;
  const _MobileLayout({required this.onLogin});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // --- CORRECTED WIDGET to match your `animate_gradient` package ---
    return AnimateGradient(
      primaryColors: [
        theme.brightness == Brightness.dark
            ? const Color(0xFF1a237e)
            : const Color(0xFF82b1ff),
        theme.scaffoldBackgroundColor,
        theme.brightness == Brightness.dark
            ? const Color(0xFF424242)
            : Colors.white,
      ],
      secondaryColors: [
        theme.scaffoldBackgroundColor,
        theme.brightness == Brightness.dark
            ? const Color(0xFF424242)
            : Colors.white,
        theme.brightness == Brightness.dark
            ? const Color(0xFF1a237e)
            : const Color(0xFF82b1ff),
      ],
      duration: const Duration(seconds: 5),
      child: Stack(
        children: [
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: _FormPanel(onLogin: onLogin),
              ),
            ),
          ),
          const _FloatingControls(),
        ],
      ),
    );
  }
}

//======================================================================================
// SHARED UI COMPONENTS
//======================================================================================
class _FormPanel extends StatelessWidget {
  final Future<void> Function(Future<bool> Function()) onLogin;
  const _FormPanel({required this.onLogin});

  @override
  Widget build(BuildContext context) {
    final appStrings = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final viewModel = Provider.of<LoginViewModel>(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FadeInDown(child: _buildHeader(theme, appStrings)),
        const SizedBox(height: 40),
        FadeInUp(
          from: 20,
          delay: const Duration(milliseconds: 100),
          child: _CustomTextFormField(
            controller: viewModel.emailController,
            labelText: appStrings.loginEmailLabel,
            icon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return appStrings.loginEmailHint;
              }
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value)) {
                return appStrings.loginErrorInvalidEmail;
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 20),
        FadeInUp(
          from: 20,
          delay: const Duration(milliseconds: 200),
          child: const _PasswordField(),
        ),
        const SizedBox(height: 10),
        FadeInUp(
          from: 20,
          delay: const Duration(milliseconds: 300),
          child: _buildForgotPasswordLink(context, theme, appStrings),
        ),
        const SizedBox(height: 30),
        FadeInUp(
          from: 20,
          delay: const Duration(milliseconds: 400),
          child: _LoginButton(
            onPressed: () =>
                onLogin(() => viewModel.loginWithEmail(appStrings)),
          ),
        ),
        const SizedBox(height: 25),
        FadeInUp(
          from: 20,
          delay: const Duration(milliseconds: 500),
          child: _buildDivider(theme, appStrings),
        ),
        const SizedBox(height: 25),
        FadeInUp(
          from: 20,
          delay: const Duration(milliseconds: 600),
          child: _GoogleButton(
            onPressed: () =>
                onLogin(() => viewModel.signInWithGoogle(appStrings)),
          ),
        ),
        const SizedBox(height: 50),
        FadeInUp(
          from: 20,
          delay: const Duration(milliseconds: 700),
          child: _buildRegisterLink(context, theme, appStrings),
        ),
      ],
    );
  }
}

class _PasswordField extends StatefulWidget {
  const _PasswordField();
  @override
  __PasswordFieldState createState() => __PasswordFieldState();
}

class __PasswordFieldState extends State<_PasswordField> {
  bool _obscurePassword = true;
  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<LoginViewModel>(context, listen: false);
    final appStrings = AppLocalizations.of(context)!;
    return _CustomTextFormField(
      controller: viewModel.passwordController,
      labelText: appStrings.loginPasswordLabel,
      icon: Icons.lock_outline_rounded,
      obscureText: _obscurePassword,
      suffixIcon: IconButton(
        icon: Icon(
          _obscurePassword
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: Theme.of(context).iconTheme.color?.withOpacity(0.6),
        ),
        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
      ),
      validator: (value) =>
          value == null || value.isEmpty ? appStrings.loginPasswordHint : null,
    );
  }
}

class _CustomTextFormField extends StatefulWidget {
  const _CustomTextFormField({
    required this.controller,
    required this.labelText,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.keyboardType,
  });
  final TextEditingController controller;
  final String labelText;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  @override
  __CustomTextFormFieldState createState() => __CustomTextFormFieldState();
}

class __CustomTextFormFieldState extends State<_CustomTextFormField> {
  bool _isHovered = false;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: TextFormField(
          controller: widget.controller,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          decoration: InputDecoration(
            labelText: widget.labelText,
            prefixIcon: Icon(widget.icon),
            suffixIcon: widget.suffixIcon,
          ),
          validator: widget.validator,
        ),
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({required this.onPressed});
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LoginViewModel>();
    final appStrings = AppLocalizations.of(context)!;
    final bool isLoading = viewModel.state == ViewState.loading;
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: isLoading
            ? const _PulsingLoader()
            : Text(appStrings.loginButton.toUpperCase()),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.onPressed});
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LoginViewModel>();
    final appStrings = AppLocalizations.of(context)!;
    final bool isLoading = viewModel.state == ViewState.googleLoading;
    return OutlinedButton.icon(
      icon: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const FaIcon(FontAwesomeIcons.google, size: 18),
      label: Text(appStrings.loginWithGoogle),
      onPressed: isLoading ? null : onPressed,
    );
  }
}

class _PulsingLoader extends StatelessWidget {
  const _PulsingLoader();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }
}

class _AnimatedHeadline extends StatefulWidget {
  const _AnimatedHeadline();
  @override
  _AnimatedHeadlineState createState() => _AnimatedHeadlineState();
}

class _AnimatedHeadlineState extends State<_AnimatedHeadline> {
  int _currentIndex = 0;
  List<String> _headlines = [];
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load headlines here to access context
    final appStrings = AppLocalizations.of(context)!;
    _headlines = [
      appStrings.headline1,
      appStrings.headline2,
      appStrings.headline3,
      appStrings.headline4,
    ];
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() => _currentIndex = (_currentIndex + 1) % _headlines.length);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_headlines.isEmpty)
      return const SizedBox.shrink(); // Guard against empty list

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: Text(
        _headlines[_currentIndex],
        key: ValueKey<int>(_currentIndex),
        style: GoogleFonts.poppins(
          fontSize: 52,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          height: 1.2,
        ),
      ),
    );
  }
}

class _FloatingControls extends StatelessWidget {
  const _FloatingControls();
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final appStrings = AppLocalizations.of(context)!;
    return Positioned(
      top: 20,
      right: 20,
      child: SafeArea(
        child: FadeIn(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    themeProvider.isDarkMode
                        ? Icons.wb_sunny_outlined
                        : Icons.nightlight_round,
                  ),
                  tooltip: themeProvider.isDarkMode
                      ? appStrings.themeTooltipLight
                      : appStrings.themeTooltipDark,
                  onPressed: () => themeProvider.toggleTheme(),
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
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildHeader(ThemeData theme, AppStrings appStrings) {
  return Column(
    children: [
      RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: GoogleFonts.poppins(
            textStyle: theme.textTheme.displaySmall,
            fontWeight: FontWeight.w800,
          ),
          children: [
            TextSpan(
              text: 'GB ',
              style: TextStyle(color: theme.colorScheme.primary),
            ),
            TextSpan(
              text: appStrings.appName,
              style: TextStyle(color: theme.colorScheme.onBackground),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Text(
        appStrings.loginWelcome,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );
}

Widget _buildForgotPasswordLink(
  BuildContext context,
  ThemeData theme,
  AppStrings appStrings,
) {
  return Align(
    alignment: Alignment.centerRight,
    child: TextButton(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
      ),
      child: Text(
        appStrings.loginForgotPassword,
        style: TextStyle(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

Widget _buildDivider(ThemeData theme, AppStrings appStrings) {
  return Row(
    children: [
      Expanded(child: Divider(color: theme.dividerColor)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Text(
          appStrings.orDivider,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      Expanded(child: Divider(color: theme.dividerColor)),
    ],
  );
}

Widget _buildRegisterLink(
  BuildContext context,
  ThemeData theme,
  AppStrings appStrings,
) {
  return Center(
    child: RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        text: appStrings.loginNoAccount,
        style: TextStyle(
          color: theme.colorScheme.onSurfaceVariant,
          fontSize: 14,
        ),
        children: [
          TextSpan(
            text: " ${appStrings.loginSignUpLink}",
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const RegisterScreen()),
              ),
          ),
        ],
      ),
    ),
  );
}
