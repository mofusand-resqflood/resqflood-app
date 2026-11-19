
import 'package:flutter/material.dart';

import '../../../core/app_routes.dart';

class SosConfirmationScreen extends StatelessWidget {
  const SosConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final requestId = ModalRoute.of(context)?.settings.arguments;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS Confirmation'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green.shade700,
                size: 90,
              ),
              const SizedBox(height: 24),
              const Text(
                'SOS Request Saved',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your emergency request has been saved on this device.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              if (requestId != null)
                Text(
                  'Request ID: $requestId',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              const SizedBox(height: 16),
              const Text(
                'This does not mean rescue services have received '
                    'your request. If you are in immediate danger, '
                    'contact the official emergency services directly.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.dashboard,
                          (route) => false,
                    );
                  },
                  child: const Text('Back to Home'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
