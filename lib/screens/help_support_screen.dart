import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  void _launchTelegram(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  void _callPhone(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contact Support',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Biruk Zewude'),
              subtitle: const Text('@biruk_zewude'),
              trailing: IconButton(
                icon: const Icon(Icons.telegram),
                onPressed: () => _launchTelegram('https://t.me/biruk_zewude'),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Gemechu'),
              subtitle: const Text('@gemechu_da'),
              trailing: IconButton(
                icon: const Icon(Icons.telegram),
                onPressed: () => _launchTelegram('https://t.me/gemechu_da'),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('Call Support'),
              subtitle: const Text('0708665727'),
              trailing: IconButton(
                icon: const Icon(Icons.call),
                onPressed: () => _callPhone('0708665727'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
