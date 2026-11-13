import 'package:flutter/material.dart';

import '../features/resident/auth/sign_in_screen.dart';
import '../features/resident/auth/sign_up_screen.dart';

class AppRoutes {
  static const welcome = '/welcome';
  static const signUp = '/sign-up';
  static const signIn = '/sign-in';
  static const otp = '/otp';
  static const shell = '/shell';

  // Add one line per screen as you build it.
  // Do not import a file that is still empty.
  static final Map<String, WidgetBuilder> routes = {
    signUp: (_) => const SignUpScreen(),
    signIn: (_) => const SignInScreen(),
  };
}