import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  final ScrollController _controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy and Security')),
      body: SingleChildScrollView(
        controller: _controller,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                'Privacy Policy',
                style: GoogleFonts.roboto(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'This app is designed to provide a secure and private experience for all users. '
                'We do not collect any personal information, and all data is stored securely on our servers. '
                'We use industry-standard encryption to protect all data transmitted between the app and our servers.',
                style: GoogleFonts.roboto(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Text(
                'Security',
                style: GoogleFonts.roboto(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'All data transmitted between the app and our servers is encrypted using industry-standard encryption. '
                'We use secure servers and follow best practices for securing our systems and data.',
                style: GoogleFonts.roboto(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Text(
                'Terms of Service',
                style: GoogleFonts.roboto(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'By using this app, you agree to our terms of service. '
                'These terms may be updated from time to time, and it is your responsibility to review them regularly.',
                style: GoogleFonts.roboto(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

