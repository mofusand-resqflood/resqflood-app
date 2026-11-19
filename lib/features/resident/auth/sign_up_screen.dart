import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/phone_auth_service.dart';
import 'otp_verify_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _authService = PhoneAuthService();

  bool _isLoading = false;
  String? _errorMessage;

  /// Normalizes Malaysian mobile numbers into E.164 format (e.g., 0123456789 -> +60123456789)
  String _formatToE164(String input) {
    final cleaned = input.replaceAll(RegExp(r'[\s\-()]'), '');
    if (cleaned.startsWith('+')) return cleaned;
    if (cleaned.startsWith('60')) return '+$cleaned';
    if (cleaned.startsWith('0')) return '+60${cleaned.substring(1)}';
    return '+60$cleaned';
  }

  Future<void> _handleSendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final fullName = _nameController.text.trim();
    final formattedPhone = _formatToE164(_phoneController.text.trim());

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.sendOtp(
        phone: formattedPhone,
        fullName: fullName,
      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerifyScreen(
            phone: formattedPhone,
            fullName: fullName,
          ),
        ),
      );
    } on PhoneAuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resident Sign Up')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Create your ResQFlood resident account',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              TextFormField(
                key: const Key('signup_name_field'),
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'e.g. Ahmad Bin Ali',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your full name.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('signup_phone_field'),
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s\-]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'e.g. +60123456789 or 0123456789',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your phone number.';
                  }
                  final digits = value.replaceAll(RegExp(r'\D'), '');
                  if (digits.length < 9 || digits.length > 15) {
                    return 'Please enter a valid phone number.';
                  }
                  return null;
                },
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  key: const Key('signup_error_text'),
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                key: const Key('signup_submit_button'),
                onPressed: _isLoading ? null : _handleSendOtp,
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text('Send OTP'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}