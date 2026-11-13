import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/resident/auth/welcome_screen.dart';
import '../features/resident/resident_shell.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Supabase.instance.client.auth;
    return StreamBuilder<AuthState>(
      stream: auth.onAuthStateChange,
      builder: (context, _) {
        // currentSession is read from the phone, so it works offline.
        return auth.currentSession == null
            ? const WelcomeScreen()
            : const ResidentShell();
      },
    );
  }
}