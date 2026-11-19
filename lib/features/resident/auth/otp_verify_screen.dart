import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/phone_auth_service.dart';

class OtpVerifyScreen extends StatefulWidget {
  final String phone;
  final String? fullName;

  const OtpVerifyScreen({
    super.key,
    required this.phone,
    this.fullName,
  });

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  final _otpController = TextEditingController();
  final _authService = PhoneAuthService();

  Timer? _timer;
  int _secondsRemaining = 60;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _secondsRemaining = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() => _secondsRemaining = 0);
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  Future<void> _handleVerify() async {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      setState(() => _errorMessage = 'Please enter the 6-digit OTP code.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.verifyOtpAndCreateProfile(
        phone: widget.phone,
        token: code,
        fullName: widget.fullName,
      );
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/resident/home', (_) => false);
    } on PhoneAuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleResend() async {
    if (_secondsRemaining > 0 || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.sendOtp(
        phone: widget.phone,
        fullName: widget.fullName,
      );
      _startResendTimer();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A new OTP code has been sent.')),
      );
    } on PhoneAuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Enter the 6-digit code sent to ${widget.phone}'),
            const SizedBox(height: 16),
            TextField(
              key: const Key('otp_input_field'),
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                hintText: '------',
                border: OutlineInputBorder(),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                key: const Key('otp_error_text'),
                style: const TextStyle(color: Colors.red),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              key: const Key('verify_otp_button'),
              onPressed: _isLoading ? null : _handleVerify,
              child: _isLoading
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Text('Verify & Create Account'),
            ),
            const SizedBox(height: 12),
            TextButton(
              key: const Key('resend_otp_button'),
              onPressed: _secondsRemaining == 0 && !_isLoading ? _handleResend : null,
              child: Text(
                _secondsRemaining > 0
                    ? 'Resend code in ${_secondsRemaining}s'
                    : 'Resend OTP',
              ),
            ),
          ],
        ),
      ),
    );
  }
}