import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/app_routes.dart';
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
  final _addressController = TextEditingController();
  final _authService = PhoneAuthService();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }
    if (value.trim().length < 3) {
      return 'Full name must be at least 3 characters';
    }
    return null;
  }

  String? _validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Home address is required';
    }
    if (value.trim().length < 10) {
      return 'Please enter a complete home address';
    }
    return null;
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final fullName = _nameController.text.trim();
    final formattedPhone =
    _authService.formatMalaysianPhone(_phoneController.text.trim());
    final homeAddress = _addressController.text.trim();

    try {
      await _authService.sendOtp(
        phone: formattedPhone,
        fullName: fullName,
        homeAddress: homeAddress,
      );

      if (!mounted) return;
      Navigator.pushNamed(
        context,
        AppRoutes.otp,
        arguments: OtpVerifyArgs(
          phone: formattedPhone,
          fullName: fullName,
          homeAddress: homeAddress,
          isSignUp: true,
        ),
      );
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
          content: Text('Failed to send OTP: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Create Resident Account',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your details below. We will send a 6-digit SMS code to verify your +60 number.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    hintText: 'e.g. Ahmad bin Abdullah',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateName,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number *',
                    prefixText: '+60 ',
                    hintText: '12-345 6789',
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: _authService.validateMalaysianPhone,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Home Address *',
                    hintText: 'No. 12, Jalan Kempas, 81200 Johor Bahru, Johor',
                    prefixIcon: Icon(Icons.home_outlined),
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateAddress,
                ),
                const SizedBox(height: 28),
                FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 56)),
                  onPressed: _isLoading ? null : _handleSignUp,
                  child: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text('Send Verification Code'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}