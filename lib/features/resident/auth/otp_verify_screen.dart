import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OtpVerifyScreen extends StatefulWidget {
  final String phoneNumber;
  const OtpVerifyScreen({super.key, required this.phoneNumber});

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;

  Future<void> _verifyOtp() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client.auth.verifyOTP(
        phone: widget.phoneNumber,
        token: _otpController.text.trim(),
        type: OtpType.sms,
      );

      if (response.session != null) {
        // Success! Just pop back to the root (AuthGate).
        // AuthGate will automatically detect the session and route the user
        // to the Dashboard (or the NoProfileScreen if they are new).
        if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid OTP: ${e.message}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter OTP')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'OTP'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _verifyOtp,
              child: _isLoading ? const CircularProgressIndicator() : const Text('Verify'),
            ),
          ],
        ),
      ),
    );
  }
}