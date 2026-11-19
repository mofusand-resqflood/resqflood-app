import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/resident/auth/sign_up_screen.dart';
import '../features/resident/auth/welcome_screen.dart';
import '../features/resident/resident_shell.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _cachedUserId;
  Future<Map<String, dynamic>?>? _cachedProfile;

  /// One query per signed-in user, reused across rebuilds.
  Future<Map<String, dynamic>?> _profileFor(String userId) {
    if (_cachedUserId != userId || _cachedProfile == null) {
      _cachedUserId = userId;
      _cachedProfile = Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .maybeSingle();
    }
    return _cachedProfile!;
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    setState(() {
      _cachedUserId = null;
      _cachedProfile = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Supabase.instance.client.auth;

    return StreamBuilder<AuthState>(
      stream: auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SplashScreen();
        }

        final session = snapshot.data?.session ?? auth.currentSession;

        if (session == null) {
          return const WelcomeScreen();
        }

        return FutureBuilder<Map<String, dynamic>?>(
          future: _profileFor(session.user.id),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const _SplashScreen();
            }

            if (profileSnapshot.hasError) {
              return _AuthErrorScreen(onSignOut: _signOut);
            }

            final profile = profileSnapshot.data;

            if (profile == null) {
              return NoProfileScreen(
                phone: session.user.phone ?? '',
                onUseAnotherNumber: _signOut,
              );
            }

            final role = profile['role'] as String? ?? 'resident';

            switch (role) {
              case 'first_responder':
              case 'shelter_manager':
                return _RolePlaceholder(role: role, onSignOut: _signOut);
              default:
                return const ResidentShell();
            }
          },
        );
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _AuthErrorScreen extends StatelessWidget {
  const _AuthErrorScreen({required this.onSignOut});

  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 56),
              const SizedBox(height: 16),
              const Text(
                'We could not load your profile. Check your connection and try again.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: onSignOut,
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NoProfileScreen extends StatelessWidget {
  const NoProfileScreen({
    super.key,
    required this.phone,
    required this.onUseAnotherNumber,
  });

  final String phone;
  final Future<void> Function() onUseAnotherNumber;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('No account found')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.person_search, size: 64),
            const SizedBox(height: 24),
            Text(
              phone.isEmpty
                  ? 'This phone number is not registered yet.'
                  : 'No account found for $phone.',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Create a household profile to start using ResQFlood.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SignUpScreen(),
                  ),
                );
              },
              child: const Text('Sign up'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onUseAnotherNumber,
              child: const Text('Use a different number'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RolePlaceholder extends StatelessWidget {
  const _RolePlaceholder({required this.role, required this.onSignOut});

  final String role;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(role == 'shelter_manager' ? 'Shelter Manager' : 'Responder'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: onSignOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Text(
          '${role.replaceAll('_', ' ')} home is coming soon.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}