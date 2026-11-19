import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'otp_verify_screen.dart';
import 'sign_up_screen.dart'; // Added so the user can navigate to Sign Up

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _notice; // Added to show the "No account found" message

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();

    // 1. Validate format (E.164-ish: '+' then 10-15 digits)
    if (!RegExp(r'^\+\d{10,15}$').hasMatch(phone)) {
      setState(() {
        _notice = 'Enter your number in international format, e.g. +60123450001.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _notice = null; // Clear previous errors
    });

    try {
      // 2. Send OTP but DO NOT create a new user
      await Supabase.instance.client.auth.signInWithOtp(
        phone: phone,
        shouldCreateUser: false,
      );

      if (!mounted) return;

      // Navigate to OTP Screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpVerifyScreen(phoneNumber: phone),
        ),
      );
    } on AuthException catch (error) {
      if (!mounted) return;

      final message = error.message.toLowerCase();

      // 3. Catch the specific "user not found" error and show a friendly message
      setState(() {
        _notice = message.contains('signup') || message.contains('not allowed')
            ? 'No account found for this number. Sign up first.'
            : error.message;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: '+60123456789',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Show the notice (error or sign up link) if it exists
            if (_notice != null) ...[
              Text(
                _notice!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // If it's the "No account" error, show the Sign Up button
              if (_notice!.contains('Sign up first'))
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignUpScreen(),
                      ),
                    );
                  },
                  child: const Text('Go to Sign up'),
                ),
              const SizedBox(height: 12),
            ],

            // 4. Fixed-size spinner and FilledButton (M3)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _isLoading ? null : _sendOtp,
                child: _isLoading
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text('Send OTP'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}