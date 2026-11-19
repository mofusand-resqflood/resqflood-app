import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resqflood/features/resident/auth/otp_verify_screen.dart';
import 'package:resqflood/features/resident/auth/sign_up_screen.dart';

void main() {
  group('Resident Sign Up & OTP Verification Tests', () {
    testWidgets('OTP screen enforces 6-digit validation and 60s resend timer',
            (WidgetTester tester) async {
          await tester.pumpWidget(
            const MaterialApp(
              home: OtpVerifyScreen(
                phone: '+60123456789',
                fullName: 'Afina Test',
              ),
            ),
          );

          // 1. Verify 60-second timer starts active
          expect(find.text('Resend code in 60s'), findsOneWidget);

          // 2. Submit with fewer than 6 digits -> shows validation error
          await tester.enterText(find.byKey(const Key('otp_input_field')), '123');
          await tester.tap(find.byKey(const Key('verify_otp_button')));
          await tester.pump();

          expect(find.text('Please enter the 6-digit OTP code.'), findsOneWidget);

          // 3. Advance clock by 60 seconds -> Resend button becomes active
          await tester.pump(const Duration(seconds: 60));
          expect(find.text('Resend OTP'), findsOneWidget);
        });

    testWidgets('Sign Up screen renders input fields and submit button',
            (WidgetTester tester) async {
          await tester.pumpWidget(
            const MaterialApp(
              home: SignUpScreen(),
            ),
          );

          expect(find.byType(TextFormField), findsAtLeastNWidgets(2));
          expect(find.byType(ElevatedButton), findsOneWidget);
        });
  });
}