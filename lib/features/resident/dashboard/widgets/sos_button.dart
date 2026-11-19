
import 'package:flutter/material.dart';

import '../../../../core/app_routes.dart';

class SosButton extends StatelessWidget {
  const SosButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 76,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.sosForm);
        },
        icon: const Icon(Icons.sos, size: 30),
        label: const Text(
          'SOS - REQUEST HELP',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade700,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          minimumSize: const Size(double.infinity, 76),
        ),
      ),
    );
  }
}
