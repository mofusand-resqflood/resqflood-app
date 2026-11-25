import 'package:flutter_test/flutter_test.dart';
import 'package:resqflood_app/services/phone_auth_service.dart';

void main() {
  final authService = PhoneAuthService();

  group('validateMalaysianPhone', () {
    test('accepts standard Malaysian mobile number', () {
      expect(authService.validateMalaysianPhone('0123456789'), isNull);
    });

    test('accepts Malaysian number with +60 prefix', () {
      expect(authService.validateMalaysianPhone('+60123456789'), isNull);
    });

    test('accepts 011 number with 8 subscriber digits', () {
      expect(authService.validateMalaysianPhone('01112345678'), isNull);
    });

    test('rejects 011 number with insufficient digits', () {
      expect(authService.validateMalaysianPhone('0111234567'), isNotNull);
    });

    test('rejects empty input', () {
      expect(authService.validateMalaysianPhone(''), isNotNull);
    });

    test('rejects letters', () {
      expect(authService.validateMalaysianPhone('abcdefghij'), isNotNull);
    });

    test('rejects number that is too short', () {
      expect(authService.validateMalaysianPhone('012345'), isNotNull);
    });
  });

  group('formatMalaysianPhone', () {
    test('formats number starting with 0', () {
      expect(authService.formatMalaysianPhone('0123456789'), '+60123456789');
    });

    test('preserves +60 number', () {
      expect(authService.formatMalaysianPhone('+60123456789'), '+60123456789');
    });

    test('formats number with spaces and hyphens', () {
      expect(authService.formatMalaysianPhone('012-345 6789'), '+60123456789');
    });
  });
}
