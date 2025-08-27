import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart'; // Adjust path
import '../../services/app_string.dart'; // Adjust path
import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';
// Adjust path

// Route constants
const String homeRoute = '/home';
const String loginRoute = '/login';
const String professionalSetupRoute = '/professional-setup';

// Enums
enum RegistrationMethod { email, phone }

enum VerificationState { form, emailPending, phoneOtpPending }

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  // --- Services, Keys, Controllers ---
  final AuthService _authService = AuthService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController(
    text: "+251",
  );
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final TextEditingController _professionController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();

  // --- State ---
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String _userType = 'client';
  RegistrationMethod _selectedMethod = RegistrationMethod.email;
  VerificationState _currentPhase = VerificationState.form;
  bool _isCheckingVerification = false;
  bool _isSubmittingOtp = false;
  bool _isResending = false;
  Timer? _emailCheckTimer;
  String? _phoneVerificationId;
  int? _phoneResendToken;

  // --- Animation ---
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _emailCheckTimer?.cancel();
    _animController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _phoneController.dispose();
    _professionController.dispose();
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  // --- UTILITY ---
  String? _normalizeAndValidateEthiopianPhoneNumber(String phoneNumber) {
    final sanitized = phoneNumber.trim().replaceAll(RegExp(r'[\s-]'), '');

    // Regex to match valid Ethiopian phone number formats
    // - ^(\+251|0)?([79]\d{8})$
    //   - (\+251|0)?  : Optionally matches '+251' or '0' at the start.
    //   - ([79]\d{8})   : Captures the main 9 digits, which must start with 7 or 9.
    final regex = RegExp(r'^(?:\+251|0)?([79]\d{8})$');
    final match = regex.firstMatch(sanitized);

    if (match != null) {
      // The first capturing group contains the 9 digits (e.g., 911223344)
      final localPart = match.group(1);
      if (localPart != null) {
        return "+251$localPart"; // Always return the standardized E.164 format
      }
    }
    // If no match, it's an invalid format
    return null;
  }

  void _showSuccessSnackbar(String message) {
    if (!mounted) return;
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              color: theme.colorScheme.inversePrimary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: theme.colorScheme.inversePrimary),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
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

  void _showInfoSnackbar(String message) {
    if (!mounted) return;
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: theme.colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
              ),
            ),
          ],
        ),
        backgroundColor: theme.colorScheme.secondaryContainer,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // --- Error Message Getters ---
  String _getRegisterErrorMessage(String code, AppStrings appStrings) {
    switch (code) {
      case 'weak-password':
        return appStrings.registerErrorWeakPassword;
      case 'email-already-in-use':
        return appStrings.registerErrorEmailInUse;
      case 'invalid-email':
        return appStrings.registerErrorInvalidEmailRegister;
      default:
        return appStrings.registerErrorUnknown;
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

  String _getPhoneAuthErrorMessage(String code, AppStrings appStrings) {
    switch (code) {
      case 'invalid-phone-number':
        return "Invalid phone format.";
      /*Use AppString*/
      case 'too-many-requests':
        return "Too many attempts.";
      /*Use AppString*/
      case 'invalid-verification-code':
        return "Incorrect code.";
      /*Use AppString*/
      case 'session-expired':
        return "Code expired. Resend.";
      /*Use AppString*/
      default:
        return appStrings.errorActionFailed;
    }
  }

  // --- Navigation Logic ---
  void _navigateAfterVerification() {
    if (!mounted) return;
    // Decide final destination
    if (_userType == 'worker') {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(professionalSetupRoute, (route) => false);
    } else {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(homeRoute, (route) => false);
    }
  }

  // --- Registration/Verification Core Functions ---
  Future<void> _submitRegistration() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    if (_selectedMethod == RegistrationMethod.email) {
      await _registerWithEmail();
    } else {
      await _registerWithPhone();
    }
  }

  Future<void> _registerWithEmail() async {
    final appStrings = AppLocalizations.of(context)!;
    try {
      final uc = await _authService.createUserWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );
      final user = uc.user;
      if (user == null) throw Exception("!");
      if (!mounted) return;
      await _authService.createUserProfile(
        userId: user.uid,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        userType: _userType,
        profession: _userType == 'worker'
            ? _professionController.text.trim()
            : null,
        photoUrl: null,
      );
      if (!mounted) return;
      await _authService.sendEmailVerificationLink();
      if (!mounted) return;
      _showInfoSnackbar(appStrings.emailVerificationSent);
      setState(() {
        _currentPhase = VerificationState.emailPending;
        _isLoading = false;
      });
      _startEmailCheckTimer();
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackbar(_getRegisterErrorMessage(e.code, appStrings));
      }
    } catch (e, s) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackbar(appStrings.registerErrorUnknown);
      }
      print("Err: $e\n$s");
    }
  }

  Future<void> _registerWithPhone() async {
    final appStrings = AppLocalizations.of(context)!;

    // Validate and get the normalized phone number
    final String? fullNum = _normalizeAndValidateEthiopianPhoneNumber(
      _phoneController.text,
    );

    if (fullNum == null) {
      setState(() => _isLoading = false);
      _showErrorSnackbar(
        "Please enter a valid Ethiopian phone number.",
      ); // Use AppStrings
      return;
    }

    // The rest of your function remains the same, but you use `fullNum`
    try {
      await _authService.verifyPhoneNumber(
        phoneNumber: fullNum, // <-- USE THE NORMALIZED NUMBER HERE
        resendToken: null,
        verificationCompleted: (c) async =>
            await _signInWithPhoneCredential(c, appStrings),
        verificationFailed: (e) {
          if (mounted) {
            setState(() => _isLoading = false);
            _showErrorSnackbar(_getPhoneAuthErrorMessage(e.code, appStrings));
          }
        },
        codeSent: (id, token) {
          if (mounted) {
            setState(() {
              _phoneVerificationId = id;
              _phoneResendToken = token;
              _currentPhase = VerificationState.phoneOtpPending;
              _isLoading = false;
            });
            _otpFocusNode.requestFocus();
          }
        },
        codeAutoRetrievalTimeout: (id) {
          if (mounted) setState(() => _phoneVerificationId = id);
        },
        timeout: const Duration(seconds: 90),
      );
    } catch (e, s) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackbar(appStrings.errorActionFailed);
      }
      print('Err: $e\n$s');
    }
  }

  Future<void> _signInWithPhoneCredential(
    PhoneAuthCredential credential,
    AppStrings appStrings,
  ) async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _isSubmittingOtp = true;
      });
    }
    try {
      final uc = await _authService.signInWithCredential(credential);
      final user = uc.user;
      if (user == null) throw Exception("!");
      if (!mounted) return;
      await _authService.createUserProfile(
        userId: user.uid,
        name: _nameController.text.trim(),
        email: "",
        phone: user.phoneNumber ?? "+251${_phoneController.text.trim()}",
        userType: _userType,
        profession: _userType == 'worker'
            ? _professionController.text.trim()
            : null,
        photoUrl: null,
      );
      if (!mounted) return;
      _showSuccessSnackbar(appStrings.registerSuccess);
      _navigateAfterVerification();
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        _showErrorSnackbar(_getPhoneAuthErrorMessage(e.code, appStrings));
      }
    } catch (e, s) {
      if (mounted) _showErrorSnackbar(appStrings.registerErrorUnknown);
      print('Err: $e\n$s');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSubmittingOtp = false;
        });
      }
    }
  }

  Future<void> _submitOtp() async {
    final appStrings = AppLocalizations.of(context)!;
    final code = _otpController.text.trim();
    if (code.length != 6) {
      _showErrorSnackbar("Enter 6-digit code.");
      return;
    }
    if (_phoneVerificationId == null) {
      _showErrorSnackbar("Error. Resend.");
      return;
    }
    setState(() => _isSubmittingOtp = true);
    try {
      final cred = PhoneAuthProvider.credential(
        verificationId: _phoneVerificationId!,
        smsCode: code,
      );
      await _signInWithPhoneCredential(cred, appStrings);
    } on FirebaseAuthException {
      if (mounted) setState(() => _isSubmittingOtp = false);
    } catch (e) {
      if (mounted) setState(() => _isSubmittingOtp = false);
    }
  }

  void _startEmailCheckTimer() {
    _emailCheckTimer?.cancel();
    _emailCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && _currentPhase == VerificationState.emailPending) {
        _checkEmailVerifiedStatus(timer, isAutoCheck: true);
      } else {
        timer.cancel();
        _emailCheckTimer = null;
      }
    });
  }

  Future<void> _checkEmailVerifiedStatus(
    Timer? timer, {
    bool isAutoCheck = false,
  }) async {
    final appStrings = AppLocalizations.of(context)!;
    if (!isAutoCheck && mounted) setState(() => _isCheckingVerification = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        /*...*/
        return;
      }
      await user.reload();
      if (!mounted) {
        /*...*/
        return;
      }
      final refreshedUser = FirebaseAuth.instance.currentUser;
      if (refreshedUser == null) {
        /*...*/
        return;
      }
      if (refreshedUser.emailVerified) {
        timer?.cancel();
        _emailCheckTimer = null;
        if (mounted) {
          _showSuccessSnackbar(appStrings.emailVerifiedSuccess);
          _navigateAfterVerification(); /* NAVIGATE */
        }
      } else if (!isAutoCheck && mounted) {
        _showInfoSnackbar(appStrings.emailNotVerifiedYet);
      }
    } catch (e, s) {
      if (!isAutoCheck && mounted) {
        _showErrorSnackbar(appStrings.errorCheckingVerification);
      }
      print('Err: $e\n$s');
    } finally {
      if (!isAutoCheck && mounted) {
        setState(() => _isCheckingVerification = false);
      }
    }
  }

  Future<void> _resendCode() async {
    setState(() => _isResending = true);
    final appStrings = AppLocalizations.of(context)!;
    if (_currentPhase == VerificationState.emailPending) {
      try {
        await _authService.sendEmailVerificationLink();
        if (mounted) _showInfoSnackbar(appStrings.emailVerificationSent);
      } catch (e) {
        if (mounted) _showErrorSnackbar(appStrings.errorResendingEmail);
      } finally {
        if (mounted) setState(() => _isResending = false);
      }
    } else if (_currentPhase == VerificationState.phoneOtpPending) {
      String phone = _phoneController.text.trim();
      if (_normalizeAndValidateEthiopianPhoneNumber(phone) == null) {
        _showErrorSnackbar("Enter valid phone.");
        setState(() => _isResending = false);
        return;
      }
      final String fullNum = "+251$phone";
      try {
        await _authService.verifyPhoneNumber(
          phoneNumber: fullNum,
          resendToken: _phoneResendToken,
          verificationCompleted: (c) async =>
              await _signInWithPhoneCredential(c, appStrings),
          verificationFailed: (e) {
            if (mounted) {
              _showErrorSnackbar(_getPhoneAuthErrorMessage(e.code, appStrings));
              setState(() => _isResending = false);
            }
          },
          codeSent: (id, token) {
            if (mounted) {
              _showInfoSnackbar("New code sent.");
              setState(() {
                _phoneVerificationId = id;
                _phoneResendToken = token;
                _isResending = false;
              });
              _otpController.clear();
              _otpFocusNode.requestFocus();
            }
          },
          codeAutoRetrievalTimeout: (id) {
            if (mounted) setState(() => _isResending = false);
          },
          timeout: const Duration(seconds: 90),
        );
      } catch (e, s) {
        if (mounted) {
          _showErrorSnackbar(appStrings.errorResendingEmail);
          setState(() => _isResending = false);
        }
        print("Err: $e\n$s");
      }
    } else {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _handleGoogleSignUp() async {
    final appStrings = AppLocalizations.of(context)!;
    setState(() => _isGoogleLoading = true);
    try {
      final uc = await _authService.signInWithGoogle();
      if (uc != null && uc.user != null && mounted) {
        _showSuccessSnackbar(appStrings.registerSuccess);
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(homeRoute, (route) => false);
      } else if (mounted) {
        _showInfoSnackbar(appStrings.googleSignInCancelled);
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

  // ==================================================================
  // ---         BUILD METHOD & UI HELPER WIDGETS                 ---
  // ==================================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appStrings = AppLocalizations.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    if (appStrings == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    String appBarTitle;
    Widget bodyContent;
    List<Widget>? appBarActions;
    switch (_currentPhase) {
      // Decide UI based on phase
      case VerificationState.emailPending:
        appBarTitle = appStrings.verificationScreenTitle;
        bodyContent = _buildEmailVerificationContent(theme, appStrings);
        appBarActions = _buildVerificationActions(theme, appStrings);
        break;
      case VerificationState.phoneOtpPending:
        appBarTitle = "Enter OTP Code";
        bodyContent = _buildOtpInputContent(theme, appStrings);
        appBarActions = _buildVerificationActions(theme, appStrings);
        break;
      case VerificationState.form:
      default:
        appBarTitle = appStrings.registerTitle;
        bodyContent = _buildRegistrationForm(
          theme,
          colorScheme,
          isDarkMode,
          appStrings,
        );
        appBarActions = null;
        break;
    }

    // Build the Scaffold
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: colorScheme.onSurface,
        leading: _currentPhase == VerificationState.form
            ? BackButton(color: colorScheme.onSurface)
            : null,
        actions: [
          IconButton(
            icon: Icon(
              isDarkMode ? Icons.wb_sunny_outlined : Icons.nightlight_round,
              color: colorScheme.onSurfaceVariant,
            ),
            tooltip: isDarkMode
                ? appStrings.themeTooltipLight
                : appStrings.themeTooltipDark,
            onPressed: () {
              try {
                Provider.of<ThemeProvider>(
                  context,
                  listen: false,
                ).toggleTheme();
              } catch (e) {
                print("Error accessing ThemeProvider: $e");
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.language, color: colorScheme.onSurfaceVariant),
            tooltip: appStrings.languageToggleTooltip,
            onPressed: () {
              try {
                final localeProvider = Provider.of<LocaleProvider>(
                  context,
                  listen: false,
                );
                final nextLocale = localeProvider.locale.languageCode == 'en'
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: bodyContent,
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Header Widget ---
  Widget _buildHeader(ThemeData theme, AppStrings appStrings) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.primaryContainer.withOpacity(0.8),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 3,
              ),
            ],
          ),
          child: Icon(
            Icons.person_add_alt_1_rounded,
            size: 50,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          appStrings.registerTitle,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          appStrings.registerSubtitle,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // --- Email/Phone Toggle Buttons ---
  Widget _buildMethodSelector(ThemeData theme, AppStrings appStrings) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ToggleButtons(
            isSelected: [
              _selectedMethod == RegistrationMethod.email,
              _selectedMethod == RegistrationMethod.phone,
            ],
            onPressed: (index) {
              if (mounted) {
                setState(
                  () => _selectedMethod = RegistrationMethod.values[index],
                ); /*_formKey.currentState?.reset();*/
              }
            },
            borderRadius: BorderRadius.circular(8.0),
            selectedBorderColor: theme.colorScheme.primary,
            selectedColor: theme.colorScheme.onPrimary,
            fillColor: theme.colorScheme.primary,
            color: theme.colorScheme.onPrimaryContainer,
            borderColor: theme.colorScheme.outlineVariant,
            borderWidth: 1,
            constraints: BoxConstraints.expand(
              width: (constraints.maxWidth - 4) / 2,
              height: 40,
            ),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.email_outlined, size: 18),
                    SizedBox(width: 8),
                    Text("Email"),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.phone_android_outlined, size: 18),
                    SizedBox(width: 8),
                    Text("Phone"),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- Client/Worker Toggle Buttons ---

  Widget _buildUserTypeSelector(ThemeData theme, AppStrings appStrings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 10),
          child: Text(
            appStrings.registerUserTypePrompt,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _buildUserTypeCard(
                theme: theme,
                appStrings: appStrings,
                titleKey: 'registerUserTypeClient',
                icon: Icons.person_search_rounded,
                isSelected: _userType == 'client',
                onTap: () => setState(() => _userType = 'client'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildUserTypeCard(
                theme: theme,
                appStrings: appStrings,
                titleKey: 'registerUserTypeWorker',
                icon: Icons.construction_rounded,
                isSelected: _userType == 'worker',
                onTap: () => setState(() => _userType = 'worker'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserTypeCard({
    required ThemeData theme,
    required AppStrings appStrings,
    required String titleKey,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    String title = appStrings.getUserTypeDisplayName(titleKey);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Color.fromARGB(56, 6, 6, 149)
              : Color.fromARGB(0, 195, 174, 174),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant.withOpacity(0.5),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
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
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required AppStrings appStrings,
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    VoidCallback? onToggleVisibility,
  }) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(color: theme.colorScheme.onSurface),
      cursorColor: theme.colorScheme.primary,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: theme.colorScheme.primary),
        hintStyle: TextStyle(
          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
        ),
        prefixIcon: Icon(icon, color: theme.colorScheme.primary),
        suffixIcon: onToggleVisibility != null
            ? IconButton(
                icon: Icon(
                  obscureText
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: theme.colorScheme.primary.withOpacity(0.7),
                ),
                onPressed: onToggleVisibility,
              )
            : null,
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.outlineVariant.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 12,
        ),
      ),
      validator: validator,
    );
  }

  // --- Registration Form Builder ---
  Widget _buildRegistrationForm(
    ThemeData theme,
    colorScheme,
    isDarkMode,
    AppStrings appStrings,
  ) {
    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('registration_form'),
        children: [
          _buildHeader(theme, appStrings),
          const SizedBox(height: 20),
          _buildMethodSelector(theme, appStrings),
          _buildUserTypeSelector(theme, appStrings),
          const SizedBox(height: 20),
          _buildInputField(
            appStrings: appStrings,
            label: appStrings.registerFullNameLabel,
            hint: appStrings.registerFullNameHint,
            icon: Icons.person_outline_rounded,
            controller: _nameController,
            validator: (v) => v == null || v.trim().isEmpty
                ? appStrings.errorFieldRequired(
                    appStrings.registerFullNameLabel,
                  )
                : null,
          ),
          const SizedBox(height: 16),
          if (_selectedMethod == RegistrationMethod.phone) ...[
            _buildInputField(
              appStrings: appStrings,
              label: appStrings.registerPhoneLabel,
              hint: "e.g., 0912345678 or +251912345678", // More helpful hint
              icon: Icons.phone_android_rounded,
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return appStrings.errorFieldRequired(
                    appStrings.registerPhoneLabel,
                  );
                }
                // Use the new validation function
                if (_normalizeAndValidateEthiopianPhoneNumber(v) == null) {
                  return "Please enter a valid Ethiopian number"; // Use AppStrings
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
          ],
          if (_userType == 'worker') ...[
            _buildInputField(
              appStrings: appStrings,
              label: appStrings.registerProfessionLabel,
              hint: appStrings.registerProfessionHint,
              icon: Icons.work_outline_rounded,
              controller: _professionController,
              validator: (v) => v == null || v.trim().isEmpty
                  ? appStrings.registerErrorProfessionRequired
                  : null,
            ),
            const SizedBox(height: 16),
          ],
          if (_selectedMethod == RegistrationMethod.email) ...[
            _buildInputField(
              appStrings: appStrings,
              label: appStrings.loginEmailLabel,
              hint: appStrings.loginEmailHint,
              icon: Icons.alternate_email_rounded,
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return appStrings.errorFieldRequired(
                    appStrings.loginEmailLabel,
                  );
                }
                if (!RegExp(
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(v.trim())) {
                  return appStrings.registerErrorInvalidEmailRegister;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildInputField(
              appStrings: appStrings,
              label: appStrings.registerPhoneLabel,
              hint: "e.g., 0912345678 or +251912345678", // More helpful hint
              icon: Icons.phone_android_rounded,
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return appStrings.errorFieldRequired(
                    appStrings.registerPhoneLabel,
                  );
                }
                // Use the new validation function
                if (_normalizeAndValidateEthiopianPhoneNumber(v) == null) {
                  return "Please enter a valid Ethiopian number"; // Use AppStrings
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildInputField(
              appStrings: appStrings,
              label: appStrings.loginPasswordLabel,
              hint: appStrings.loginPasswordHint,
              icon: Icons.lock_outline_rounded,
              controller: _passwordController,
              obscureText: _obscurePassword,
              onToggleVisibility: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return appStrings.errorFieldRequired(
                    appStrings.loginPasswordLabel,
                  );
                }
                if (v.length < 6) return appStrings.errorPasswordShort;
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildInputField(
              appStrings: appStrings,
              label: appStrings.registerConfirmPasswordLabel,
              hint: appStrings.registerConfirmPasswordHint,
              icon: Icons.lock_person_outlined,
              controller: _confirmController,
              obscureText: _obscureConfirm,
              onToggleVisibility: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return appStrings.errorFieldRequired(
                    appStrings.registerConfirmPasswordLabel,
                  );
                }
                if (v != _passwordController.text) {
                  return appStrings.registerErrorPasswordMismatch;
                }
                return null;
              },
            ),
          ],
          if (_selectedMethod == RegistrationMethod.phone) ...[
            _buildInputField(
              appStrings: appStrings,
              label: appStrings.loginEmailLabel,
              hint: appStrings.loginEmailHint,
              icon: Icons.alternate_email_rounded,
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return appStrings.errorFieldRequired(
                    appStrings.loginEmailLabel,
                  );
                }
                if (!RegExp(
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(v.trim())) {
                  return appStrings.registerErrorInvalidEmailRegister;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildInputField(
              appStrings: appStrings,
              label: appStrings.loginPasswordLabel,
              hint: appStrings.loginPasswordHint,
              icon: Icons.lock_outline_rounded,
              controller: _passwordController,
              obscureText: _obscurePassword,
              onToggleVisibility: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return appStrings.errorFieldRequired(
                    appStrings.loginPasswordLabel,
                  );
                }
                if (v.length < 6) return appStrings.errorPasswordShort;
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildInputField(
              appStrings: appStrings,
              label: appStrings.registerConfirmPasswordLabel,
              hint: appStrings.registerConfirmPasswordHint,
              icon: Icons.lock_person_outlined,
              controller: _confirmController,
              obscureText: _obscureConfirm,
              onToggleVisibility: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return appStrings.errorFieldRequired(
                    appStrings.registerConfirmPasswordLabel,
                  );
                }
                if (v != _passwordController.text) {
                  return appStrings.registerErrorPasswordMismatch;
                }
                return null;
              },
            ),
          ],
          const SizedBox(height: 30),
          _buildSubmitButton(theme, appStrings),
          const SizedBox(height: 20),
          _buildDivider(theme, appStrings),
          const SizedBox(height: 20),
          _buildGoogleButton(theme, appStrings),
          const SizedBox(height: 30),
          _buildLoginLink(theme, appStrings),
        ],
      ),
    );
  }

  // --- Builds Email Verification Pending UI ---
  Widget _buildEmailVerificationContent(
    ThemeData theme,
    AppStrings appStrings,
  ) {
    final userEmail =
        FirebaseAuth.instance.currentUser?.email ?? appStrings.notAvailable;
    return Column(
      key: const ValueKey('verification_email_pending'),
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        Icon(
          Icons.mark_email_read_outlined,
          size: 80,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 30),
        Text(
          appStrings.verificationScreenHeader,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            appStrings.verificationScreenInfo.replaceAll('{email}', userEmail),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 40),
        ElevatedButton.icon(
          icon: _isCheckingVerification
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.refresh_rounded, size: 20),
          label: Text(
            _isCheckingVerification
                ? appStrings.checkingStatusButton
                : appStrings.checkVerificationButton,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          onPressed: _isCheckingVerification || _isResending
              ? null
              : () => _checkEmailVerifiedStatus(
                  _emailCheckTimer,
                  isAutoCheck: false,
                ),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
            elevation: 3,
          ),
        ),
        const SizedBox(height: 15),
        OutlinedButton.icon(
          icon: _isResending
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.outgoing_mail, size: 18),
          label: Text(
            _isResending
                ? appStrings.resendingButton
                : appStrings.resendEmailButton,
          ),
          onPressed: _isResending || _isCheckingVerification
              ? null
              : _resendCode,
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.secondary,
            side: BorderSide(
              color: theme.colorScheme.secondary.withOpacity(0.7),
            ),
            minimumSize: const Size(double.infinity, 45),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  // --- Builds Phone OTP Input UI ---
  Widget _buildOtpInputContent(ThemeData theme, AppStrings appStrings) {
    final phoneNumber = _phoneController.text.trim();
    final defaultPinTheme = PinTheme(
      width: 50,
      height: 55,
      textStyle: theme.textTheme.headlineSmall?.copyWith(
        color: theme.colorScheme.primary,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
    );
    return Column(
      key: const ValueKey('verification_otp_pending'),
      children: [
        const SizedBox(height: 20),
        Icon(Icons.sms_outlined, size: 80, color: theme.colorScheme.primary),
        const SizedBox(height: 20),
        Text(
          "Enter Code",
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            "Enter the 6-digit code sent to +251$phoneNumber",
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 30),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Pinput(
            length: 6,
            controller: _otpController,
            focusNode: _otpFocusNode,
            hapticFeedbackType: HapticFeedbackType.lightImpact,
            defaultPinTheme: defaultPinTheme,
            focusedPinTheme: defaultPinTheme.copyWith(
              decoration: defaultPinTheme.decoration!.copyWith(
                border: Border.all(color: theme.colorScheme.primary, width: 2),
              ),
            ),
            submittedPinTheme: defaultPinTheme.copyWith(
              decoration: defaultPinTheme.decoration!.copyWith(
                color: theme.colorScheme.primaryContainer.withOpacity(0.2),
              ),
            ),
            errorPinTheme: defaultPinTheme.copyWith(
              decoration: defaultPinTheme.decoration!.copyWith(
                border: Border.all(color: theme.colorScheme.error),
              ),
            ),
            onCompleted: (pin) => _submitOtp(),
          ),
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: _isSubmittingOtp || _isResending ? null : _submitOtp,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isSubmittingOtp
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text("Verify Phone Number"),
        ),
        TextButton(
          onPressed: _isResending || _isSubmittingOtp ? null : _resendCode,
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.secondary,
          ),
          child: Text(
            _isResending ? appStrings.resendingButton : "Resend Code",
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // --- AppBar Actions for Verification ---
  List<Widget> _buildVerificationActions(
    ThemeData theme,
    AppStrings appStrings,
  ) {
    return [
      IconButton(
        icon: Icon(
          Icons.logout,
          color:
              theme.appBarTheme.actionsIconTheme?.color ??
              theme.colorScheme.onSurfaceVariant,
        ),
        tooltip: appStrings.signOutButton,
        onPressed:
            (_isLoading ||
                _isCheckingVerification ||
                _isResending ||
                _isSubmittingOtp)
            ? null
            : () async {
                _emailCheckTimer?.cancel();
                /* <-- FIX: cancel correct timer */
                await _authService.signOut();
                if (mounted) {
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil(loginRoute, (route) => false);
                }
              },
      ),
      const SizedBox(width: 8),
    ];
  }

  // --- Submit Button for Form ---
  Widget _buildSubmitButton(ThemeData theme, AppStrings appStrings) {
    return ElevatedButton(
      onPressed: _isLoading || _isGoogleLoading ? null : _submitRegistration,
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
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(
              _selectedMethod == RegistrationMethod.email
                  ? appStrings.registerButton
                  : "Send Verification Code",
              /* Use AppStrings */ style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
    );
  }

  // --- "OR" Divider ---
  Widget _buildDivider(ThemeData theme, AppStrings appStrings) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "OR",
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  // --- Google Sign Up Button ---
  Widget _buildGoogleButton(ThemeData theme, AppStrings appStrings) {
    return OutlinedButton.icon(
      icon: _isGoogleLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const FaIcon(FontAwesomeIcons.google, size: 18),
      label: Text(appStrings.registerWithGoogle),
      onPressed: _isLoading || _isGoogleLoading ? null : _handleGoogleSignUp,
      style: OutlinedButton.styleFrom(
        foregroundColor: theme.colorScheme.primary,
        side: BorderSide(color: theme.colorScheme.outline),
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // --- Link to Login Screen ---
  Widget _buildLoginLink(ThemeData theme, AppStrings appStrings) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 24),
        child: RichText(
          text: TextSpan(
            text: appStrings.registerHaveAccount,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 15,
            ),
            children: [
              TextSpan(
                text: appStrings.registerSignInLink,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  decoration: TextDecoration.underline,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
