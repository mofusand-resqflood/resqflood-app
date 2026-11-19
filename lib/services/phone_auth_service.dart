import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class PhoneAuthException implements Exception {
  final String message;
  PhoneAuthException(this.message);

  @override
  String toString() => message;
}

class PhoneAuthService {
  final SupabaseClient _supabase;

  PhoneAuthService({SupabaseClient? client})
      : _supabase = client ?? Supabase.instance.client;

  /// Sends a 6-digit SMS OTP to the given E.164 phone number (e.g., +60123456789)
  Future<void> sendOtp({
    required String phone,
    String? fullName,
  }) async {
    try {
      await _supabase.auth.signInWithOtp(
        phone: phone,
        data: fullName != null && fullName.isNotEmpty
            ? {'full_name': fullName}
            : null,
      );
    } on SocketException {
      throw PhoneAuthException('No internet connection. Please check your network.');
    } on AuthException catch (e) {
      throw PhoneAuthException(_mapAuthError(e.message));
    } catch (_) {
      throw PhoneAuthException('Failed to send OTP. Please try again.');
    }
  }

  /// Verifies the 6-digit OTP and creates/updates the profiles row (id = auth user id)
  Future<AuthResponse> verifyOtpAndCreateProfile({
    required String phone,
    required String token,
    String? fullName,
  }) async {
    try {
      final response = await _supabase.auth.verifyOTP(
        phone: phone,
        token: token,
        type: OtpType.sms,
      );

      final user = response.user;
      if (user != null) {
        await _supabase.from('profiles').upsert({
          'id': user.id,
          'phone': phone,
          if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      return response;
    } on SocketException {
      throw PhoneAuthException('No internet connection. Please check your network.');
    } on AuthException catch (e) {
      throw PhoneAuthException(_mapAuthError(e.message));
    } catch (_) {
      throw PhoneAuthException('Verification failed. Please try again.');
    }
  }

  /// Maps raw Supabase errors to user-friendly messages
  String _mapAuthError(String rawMessage) {
    final msg = rawMessage.toLowerCase();
    if (msg.contains('expired')) {
      return 'OTP code has expired. Please tap Resend OTP.';
    }
    if (msg.contains('invalid') || msg.contains('token')) {
      return 'Invalid OTP code. Please check the 6 digits and try again.';
    }
    if (msg.contains('network') || msg.contains('socket') || msg.contains('host')) {
      return 'No internet connection. Please check your network.';
    }
    return rawMessage;
  }
}