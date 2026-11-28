import 'package:flutter/material.dart';

import '../../../core/app_routes.dart';
import '../../../services/sos_service.dart';

class SosConfirmationScreen extends StatelessWidget {
  const SosConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    final submission = arguments is SosSubmissionResult ? arguments : null;
    final isQueued = submission?.isQueued ?? true;

    final title = isQueued
        ? 'SOS Request Saved on Device'
        : 'SOS Request Submitted';

    final message = isQueued
        ? 'Your request is saved on this device and is waiting to sync. '
              'Rescue services have not received it yet.'
        : 'Your request was submitted to the ResQFlood server. '
              'This does not guarantee that a responder has been assigned.';

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
                isQueued ? Icons.cloud_upload_outlined : Icons.check_circle,
                color: isQueued
                    ? Colors.orange.shade800
                    : Colors.green.shade700,
                size: 90,
              ),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              if (submission != null)
                Text(
                  isQueued
                      ? 'Local queue ID: ${submission.id}'
                      : 'Request ID: ${submission.id}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              const SizedBox(height: 16),
              const Text(
                'If you are in immediate danger, contact the official '
                'emergency services directly.',
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
