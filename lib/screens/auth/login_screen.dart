import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:animate_do/animate_do.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart'; // <-- 1. ADDED for custom font
import 'package:provider/provider.dart';

// --- Your Project Imports ---
import '../../services/auth_service.dart';
import '../../services/app_string.dart';
import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final appStrings = AppLocalizations.of(context);
    if (appStrings == null) return;

    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      try {
        await _authService.signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
        if (!mounted) return;
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/home', (route) => false);
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          _showErrorSnackbar(_getLoginErrorMessage(e.code, appStrings));
        }
      } catch (e) {
        if (mounted) _showErrorSnackbar(appStrings.loginErrorUnknown);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final appStrings = AppLocalizations.of(context);
    if (appStrings == null) return;
    setState(() => _isGoogleLoading = true);
    try {
      final userCredential = await _authService.signInWithGoogle();
      if (userCredential != null && userCredential.user != null) {
        if (!mounted) return;
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/home', (route) => false);
      } else {
        if (mounted) {
          _showInfoSnackbar(appStrings.googleSignInCancelled);
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        _showErrorSnackbar(_getLoginErrorMessage(e.code, appStrings));
      }
    } catch (e) {
      if (mounted) _showErrorSnackbar(appStrings.loginErrorGoogleSignIn);
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
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

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          Icon(Icons.error_outline_rounded,
              color: theme.colorScheme.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
              child: Text(message,
                  style: TextStyle(color: theme.colorScheme.onErrorContainer)))
        ]),
        backgroundColor: theme.colorScheme.errorContainer,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)));
  }

  void _showInfoSnackbar(String message) {
    if (!mounted) return;
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          Icon(Icons.info_outline_rounded,
              color: theme.colorScheme.onSecondaryContainer),
          const SizedBox(width: 10),
          Expanded(
              child: Text(message,
                  style:
                      TextStyle(color: theme.colorScheme.onSecondaryContainer)))
        ]),
        backgroundColor: theme.colorScheme.secondaryContainer,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appStrings = AppLocalizations.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    if (appStrings == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // --- CHANGE: No AppBar here ---
      body: Stack(
        // <-- 2. WRAPPED in a Stack for floating controls
        children: [
          // Main content with gradient background
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.surface,
                  colorScheme.surfaceContainerLowest
                ],
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 32.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FadeInDown(
                            duration: const Duration(milliseconds: 500),
                            child: _buildHeader(theme, appStrings)),
                        const SizedBox(height: 40),
                        FadeInUp(
                            delay: const Duration(milliseconds: 100),
                            child: _buildEmailField(theme, appStrings)),
                        const SizedBox(height: 20),
                        FadeInUp(
                            delay: const Duration(milliseconds: 200),
                            child: _buildPasswordField(theme, appStrings)),
                        const SizedBox(height: 15),
                        FadeInUp(
                            delay: const Duration(milliseconds: 300),
                            child: _buildForgotPasswordLink(theme, appStrings)),
                        const SizedBox(height: 30),
                        FadeInUp(
                            delay: const Duration(milliseconds: 400),
                            child: _buildLoginButton(theme, appStrings)),
                        const SizedBox(height: 20),
                        FadeInUp(
                            delay: const Duration(milliseconds: 500),
                            child: _buildDivider(theme, appStrings)),
                        const SizedBox(height: 20),
                        FadeInUp(
                            delay: const Duration(milliseconds: 600),
                            child: _buildGoogleButton(theme, appStrings)),
                        const SizedBox(height: 40),
                        FadeInUp(
                            delay: const Duration(milliseconds: 700),
                            child: _buildRegisterLink(theme, appStrings)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // --- CHANGE: ADDED Floating Controls ---
          _buildFloatingControls(theme, colorScheme, isDarkMode, appStrings),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  /// Builds the floating controls for theme and language.
  Widget _buildFloatingControls(ThemeData theme, ColorScheme colorScheme,
      bool isDarkMode, AppStrings appStrings) {
    return Positioned(
      top: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    isDarkMode
                        ? Icons.wb_sunny_outlined
                        : Icons.nightlight_round,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  tooltip: isDarkMode
                      ? appStrings.themeTooltipLight
                      : appStrings.themeTooltipDark,
                  onPressed: () {
                    try {
                      Provider.of<ThemeProvider>(context, listen: false)
                          .toggleTheme();
                    } catch (e) {
                      print("Error accessing ThemeProvider: $e");
                    }
                  },
                ),
                IconButton(
                  icon:
                      Icon(Icons.language, color: colorScheme.onSurfaceVariant),
                  tooltip: appStrings.languageToggleTooltip,
                  onPressed: () {
                    try {
                      final localeProvider =
                          Provider.of<LocaleProvider>(context, listen: false);
                      final nextLocale =
                          localeProvider.locale.languageCode == 'en'
                              ? const Locale('am')
                              : const Locale('en');
                      localeProvider.setLocale(nextLocale);
                    } catch (e) {
                      print("Error getting LocaleProvider: $e");
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// --- CHANGE: A new stylish header with your company name ---
  Widget _buildHeader(ThemeData theme, AppStrings appStrings) {
    return Column(
      children: [
        FadeInDown(
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              // Use Poppins font for the logo
              style: GoogleFonts.poppins(
                textStyle: theme.textTheme.displaySmall,
                fontWeight: FontWeight.w800, // Extra bold for impact
              ),
              children: [
                TextSpan(
                  text: 'GB',
                  style: TextStyle(
                      color: theme
                          .colorScheme.primary), // First part in primary color
                ),
                TextSpan(
                  text: appStrings.appName,
                  style: TextStyle(
                      color: theme.colorScheme
                          .onSurface), // Second part in default text color
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        FadeInDown(
          delay: const Duration(milliseconds: 200),
          child: Text(
            appStrings.loginWelcome, // Changed to a more direct welcome message
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField(ThemeData theme, AppStrings appStrings) {
    return TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        style: TextStyle(color: theme.colorScheme.onSurface),
        cursorColor: theme.colorScheme.primary,
        decoration: InputDecoration(
            labelText: appStrings.loginEmailLabel,
            hintText: appStrings.loginEmailHint,
            prefixIcon: Icon(Icons.alternate_email_rounded,
                color: theme.colorScheme.primary),
            filled: true,
            fillColor:
                theme.colorScheme.surfaceContainerHighest.withOpacity(0.6),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: theme.colorScheme.outlineVariant.withOpacity(0.3))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: theme.colorScheme.primary, width: 1.5)),
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: theme.colorScheme.error, width: 1.5)),
            focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: theme.colorScheme.error, width: 2))),
        validator: (value) {
          if (value == null || value.isEmpty) return appStrings.loginEmailHint;
          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
            return appStrings.loginErrorInvalidEmail;
          }
          return null;
        });
  }

  Widget _buildPasswordField(ThemeData theme, AppStrings appStrings) {
    return TextFormField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        style: TextStyle(color: theme.colorScheme.onSurface),
        cursorColor: theme.colorScheme.primary,
        decoration: InputDecoration(
            labelText: appStrings.loginPasswordLabel,
            hintText: appStrings.loginPasswordHint,
            prefixIcon: Icon(Icons.lock_outline_rounded,
                color: theme.colorScheme.primary),
            suffixIcon: IconButton(
                icon:
                    Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: theme.colorScheme.primary.withOpacity(0.7)),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword)),
            filled: true,
            fillColor:
                theme.colorScheme.surfaceContainerHighest.withOpacity(0.6),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: theme.colorScheme.outlineVariant.withOpacity(0.3))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: theme.colorScheme.primary, width: 1.5)),
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: theme.colorScheme.error, width: 1.5)),
            focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.error, width: 2))),
        validator: (value) => value == null || value.isEmpty ? appStrings.loginPasswordHint : null);
  }

  Widget _buildForgotPasswordLink(ThemeData theme, AppStrings appStrings) {
    return Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const ForgotPasswordScreen())),
          child: Text(appStrings.loginForgotPassword,
              style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600)),
        ));
  }

  Widget _buildLoginButton(ThemeData theme, AppStrings appStrings) {
    return ElevatedButton(
      onPressed: _isLoading || _isGoogleLoading ? null : _login,
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        elevation: 3,
      ),
      child: _isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
          : Text(appStrings.loginButton,
              style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8)),
    );
  }

  Widget _buildDivider(ThemeData theme, AppStrings appStrings) {
    return Row(children: [
      Expanded(
          child: Divider(
              color: theme.colorScheme.outlineVariant.withOpacity(0.5))),
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text("login".toUpperCase(),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
      Expanded(
          child: Divider(
              color: theme.colorScheme.outlineVariant.withOpacity(0.5))),
    ]);
  }

  Widget _buildGoogleButton(ThemeData theme, AppStrings appStrings) {
    return OutlinedButton.icon(
      icon: _isGoogleLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2))
          : const FaIcon(FontAwesomeIcons.google, size: 18),
      label: Text(appStrings.loginWithGoogle),
      onPressed: _isLoading || _isGoogleLoading ? null : _handleGoogleSignIn,
      style: OutlinedButton.styleFrom(
        foregroundColor: theme.colorScheme.primary,
        side: BorderSide(color: theme.colorScheme.outline),
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle:
            theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildRegisterLink(ThemeData theme, AppStrings appStrings) {
    return Center(
        child: Padding(
            padding: const EdgeInsets.only(top: 24),
            child: RichText(
                text: TextSpan(
                    text: appStrings.loginNoAccount,
                    style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 15),
                    children: [
                  TextSpan(
                      text: appStrings.loginSignUpLink,
                      style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          decoration: TextDecoration.underline),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const RegisterScreen())))
                ]))));
  }
}
