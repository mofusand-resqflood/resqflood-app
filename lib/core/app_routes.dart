import 'package:flutter/material.dart';

import '../features/resident/auth/otp_verify_screen.dart';
import '../features/resident/auth/sign_in_screen.dart';
import '../features/resident/auth/household_profile_screen.dart';
import '../features/resident/auth/sign_up_screen.dart';
import '../features/resident/auth/welcome_screen.dart';
import '../features/resident/sos/sos_form_screen.dart';
import '../features/resident/sos/sos_confirmation_screen.dart';
import '../features/resident/dashboard/dashboard_screen.dart';
import '../features/resident/resident_shell.dart';

class AppRoutes {
  AppRoutes._();

  // Authentication
  static const String welcome = '/welcome';
  static const String signUp = '/sign-up';
  static const String signIn = '/sign-in';
  static const String otp = '/otp';
  static const String householdProfile = '/household-profile';

  // Main resident navigation
  static const String shell = '/shell';
  static const String resident = '/resident';
  static const String dashboard = '/dashboard';

  // Request help (SOS)
  static const String sosForm = '/sos';
  static const String sosConfirmation = '/sos/confirmation';

  // Active request tracking
  static const String activeRequest = '/tracking/active-request';
  static const String shelterQrPass = '/tracking/shelter-qr-pass';

  // Nearby
  static const String nearby = '/nearby';
  static const String reportBlockedRoad = '/nearby/report-blocked-road';

  // Chatbot and saved emergency topics
  static const String chatbotTab = '/chatbot';
  static const String chatbot = '/chatbot/ask';
  static const String savedTopics = '/chatbot/saved-topics';
  static const String topicDetail = '/chatbot/topic-detail';

  // Offline and sync
  static const String syncStatus = '/offline/sync-status';
  static const String smsUpdate = '/offline/sms-update';
  static const String downloadMyArea = '/offline/download-my-area';

  // Profile and settings
  static const String profile = '/profile';
  static const String householdEdit = '/profile/household';
  static const String emergencyContacts = '/profile/emergency-contacts';
  static const String accessibilitySettings = '/profile/accessibility-settings';

  /// Named routes used by MaterialApp in main.dart.
  ///
  /// Routes for screens that are not implemented yet lead to a placeholder.
  /// Replace those builders with the real screen widgets as their Jira stories
  /// are implemented.
  static final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
    // Implemented screens
    welcome: (_) => const WelcomeScreen(),
    signUp: (_) => const SignUpScreen(),
    signIn: (_) => const SignInScreen(),
    shell: (_) => const ResidentShell(),
    resident: (_) => const ResidentShell(),

    // Resident screens to be implemented by their assigned Jira stories
    otp: (_) => const OtpVerifyScreen(),
    householdProfile: (_) => const HouseholdProfileScreen(),
    dashboard: (_) => const DashboardScreen(),
    sosForm: (_) => const SosFormScreen(),
    sosConfirmation: (_) => const SosConfirmationScreen(),
    activeRequest: _placeholder('Active rescue request'),
    shelterQrPass: _placeholder('Shelter QR pass'),
    nearby: _placeholder('Help around you'),
    reportBlockedRoad: _placeholder('Report a blocked road'),
    chatbotTab: _placeholder('Ask ResQFlood'),
    chatbot: _placeholder('Ask the AI assistant'),
    savedTopics: _placeholder('Saved emergency topics'),
    topicDetail: _placeholder('Emergency topic details'),
    syncStatus: _placeholder('Sync status'),
    smsUpdate: _placeholder('Emergency SMS update'),
    downloadMyArea: _placeholder('Download my area'),
    profile: _placeholder('Resident profile'),
    householdEdit: (_) => const HouseholdProfileScreen(),
    emergencyContacts: _placeholder('Emergency contacts'),
    accessibilitySettings: _placeholder('Accessibility settings'),
  };

  static WidgetBuilder _placeholder(String title) {
    return (_) => _RoutePlaceholderScreen(title: title);
  }
}

class _RoutePlaceholderScreen extends StatelessWidget {
  const _RoutePlaceholderScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'This screen is a placeholder. Its feature will be implemented '
            'in its assigned Jira story.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
