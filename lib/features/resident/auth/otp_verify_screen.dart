import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/phone_auth_service.dart';

class OtpVerifyArgs {
  final String phone;
  final String? fullName;
  final String? homeAddress;
  final bool isSignUp;

  const OtpVerifyArgs({
    required this.phone,
    this.fullName,
    this.homeAddress,
    this.isSignUp = false,
  });
}

class OtpVerifyScreen extends StatefulWidget {
  final OtpVerifyArgs? args;

  const OtpVerifyScreen({super.key, this.args});

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _authService = PhoneAuthService();

  bool _isVerifying = false;
  bool _isResending = false;

  OtpVerifyArgs get _resolvedArgs {
    if (widget.args != null) return widget.args!;
    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    if (routeArgs is OtpVerifyArgs) return routeArgs;
    if (routeArgs is Map<String, dynamic>) {
      return OtpVerifyArgs(
        phone: routeArgs['phone'] as String? ?? '',
        fullName: routeArgs['fullName'] as String?,
        homeAddress: routeArgs['homeAddress'] as String?,
        isSignUp: routeArgs['isSignUp'] as bool? ?? false,
      );
    }
    return const OtpVerifyArgs(phone: '');
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    if (!_formKey.currentState!.validate()) return;

    final data = _resolvedArgs;
    setState(() => _isVerifying = true);

    try {
      await _authService.verifyOtp(
        phone: data.phone,
        token: _otpController.text.trim(),
        fullName: data.isSignUp ? data.fullName : null,
        homeAddress: data.isSignUp ? data.homeAddress : null,
      );

      if (!mounted) return;
      // AuthGate listens to onAuthStateChange and automatically switches
      // from WelcomeScreen to ResidentShell once we return to the root route.
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification failed: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _handleResend() async {
    final data = _resolvedArgs;
    setState(() => _isResending = true);

    try {
      await _authService.sendOtp(
        phone: data.phone,
        fullName: data.fullName,
        homeAddress: data.homeAddress,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('New verification code sent to ${data.phone}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to resend OTP: $e')),
      );
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _resolvedArgs;

    return Scaffold(
      appBar: AppBar(title: const Text('Verify Phone Number')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Enter Verification Code',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter the 6-digit SMS code sent to ${data.phone}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  autofocus: true,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    fontSize: 24,
                    letterSpacing: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    hintText: '••••••',
                    counterText: '',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length != 6) {
                      return 'Please enter the 6-digit OTP code';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 56)),
                  onPressed: _isVerifying ? null : _handleVerify,
                  child: _isVerifying
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text('Verify & Continue'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _isResending ? null : _handleResend,
                  child: Text(
                    _isResending
                        ? 'Resending code...'
                        : 'Didn\'t receive a code? Resend OTP',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}