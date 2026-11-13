import 'package:flutter/material.dart';

import '../../../core/app_routes.dart';
import '../../../l10n/app_localizations.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t.appTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 8),
              Text(t.welcomeTagline, textAlign: TextAlign.center),
              const SizedBox(height: 48),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 56)),
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.signUp),
                child: Text(t.signUp),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 56)),
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.signIn),
                child: Text(t.signIn),
              ),
            ],
          ),
        ),
      ),
    );
  }
}