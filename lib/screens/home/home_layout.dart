import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

// IMPORTANT: Make sure these import paths are correct for your project structure!
import '../home_screen.dart';
import 'home_screen_web.dart';

/// This widget acts as a dispatcher.
/// It checks the platform at compile-time and shows the appropriate
/// home screen UI (mobile or web).
class HomeLayout extends StatelessWidget {
  const HomeLayout({super.key});

  @override
  Widget build(BuildContext context) {
    // kIsWeb is a compile-time constant.
    // This is the most efficient way to build completely different UIs
    // for web and mobile.
    if (kIsWeb) {
      // If the app is running on the web, show the web-optimized screen.
      return const HomeScreenWeb();
    } else {
      // Otherwise (on Android, iOS, etc.), show the mobile screen.
      return const HomeScreen();
    }
  }
}
