import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              // Navigate to login screen or splash
            },
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('No user signed in.'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _ProfileHeader(user),
                  const SizedBox(height: 20),
                  _InfoTile(title: 'Display Name', value: user.displayName),
                  _InfoTile(title: 'Email', value: user.email),
                  _InfoTile(title: 'Phone Number', value: user.phoneNumber),
                  _InfoTile(
                    title: 'Email Verified',
                    value: user.emailVerified ? 'Yes' : 'No',
                  ),
                  _InfoTile(title: 'UID', value: user.uid),
                  _InfoTile(
                    title: 'Account Created',
                    value: user.metadata.creationTime
                        ?.toLocal()
                        .toString()
                        .split('.')[0],
                  ),
                  _InfoTile(
                    title: 'Last Sign-In',
                    value: user.metadata.lastSignInTime
                        ?.toLocal()
                        .toString()
                        .split('.')[0],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      user.sendEmailVerification();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Verification email sent.'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.mark_email_unread),
                    label: const Text('Send Verification Email'),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final User user;

  const _ProfileHeader(this.user);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage: user.photoURL != null
              ? NetworkImage(user.photoURL!)
              : const AssetImage('assets/avatar_placeholder.png')
                    as ImageProvider,
          backgroundColor: Colors.grey[300],
        ),
        const SizedBox(height: 10),
        Text(
          user.displayName ?? 'Anonymous',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String title;
  final String? value;

  const _InfoTile({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Text(value ?? 'Not set'),
      leading: const Icon(Icons.info_outline),
    );
  }
}
