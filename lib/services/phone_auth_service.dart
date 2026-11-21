import 'package:supabase_flutter/supabase_flutter.dart';

class PhoneAuthService {
  SupabaseClient get _supabase => Supabase.instance.client;

  /// Normalizes Malaysian mobile numbers into E.164 format (+60...)
  String formatMalaysianPhone(String rawInput) {
    final digits = rawInput.replaceAll(RegExp(r'[\s\-()]'), '');

    if (digits.startsWith('+60')) {
      return digits;
    } else if (digits.startsWith('60')) {
      return '+$digits';
    } else if (digits.startsWith('0')) {
      return '+60${digits.substring(1)}';
    }

    return '+60$digits';
  }

  /// Validates Malaysian +60 mobile numbers.
  String? validateMalaysianPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    final cleaned = value.replaceAll(RegExp(r'[\s\-()]'), '');
    final normalized = cleaned.replaceFirst(RegExp(r'^\+?60'), '');

    if (!RegExp(r'^(?:0?1[02-9][0-9]{7}|0?11[0-9]{8})$').hasMatch(normalized)) {
      return 'Enter a valid +60 mobile number (e.g. 12-345 6789)';
    }

    return null;
  }

  /// Sends a 6-digit SMS OTP via Supabase Phone Auth.
  Future<void> sendOtp({
    required String phone,
    String? fullName,
    String? homeAddress,
    bool shouldCreateUser = true,
  }) async {
    final formattedPhone = formatMalaysianPhone(phone);

    await _supabase.auth.signInWithOtp(
      phone: formattedPhone,
      shouldCreateUser: shouldCreateUser,
      data: (fullName != null && homeAddress != null)
          ? {'full_name': fullName.trim(), 'address': homeAddress.trim()}
          : null,
    );
  }

  /// Verifies the OTP and inserts a new resident profile during sign-up.
  Future<AuthResponse> verifyOtp({
    required String phone,
    required String token,
    String? fullName,
    String? homeAddress,
  }) async {
    final formattedPhone = formatMalaysianPhone(phone);

    final response = await _supabase.auth.verifyOTP(
      type: OtpType.sms,
      phone: formattedPhone,
      token: token.trim(),
    );

    final user = response.user;

    if (user != null && fullName != null && homeAddress != null) {
      try {
        await _supabase.from('profiles').insert({
          'id': user.id,
          'full_name': fullName.trim(),
          'phone': formattedPhone,
          'address': homeAddress.trim(),
        });
      } catch (error) {
        // Prevent an authenticated session without a resident profile.
        try {
          await _supabase.auth.signOut();
        } catch (_) {
          // Preserve the original profile insertion error.
        }

        throw ProfileSaveException();
      }
    }
    return response;
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}

class ProfileSaveException implements Exception {}
