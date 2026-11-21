import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/household_profile.dart';
import '../../../models/resident_profile.dart';
import '../../../services/profile_service.dart';
import 'widgets/household_profile_form.dart';

class HouseholdProfileScreen extends StatefulWidget {
  const HouseholdProfileScreen({super.key});

  @override
  State<HouseholdProfileScreen> createState() => _HouseholdProfileScreenState();
}

class _HouseholdProfileScreenState extends State<HouseholdProfileScreen> {
  final ProfileService _profileService = ProfileService();

  HouseholdProfile _householdProfile = const HouseholdProfile();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isAuthenticated = false;

  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();

    final auth = Supabase.instance.client.auth;
    _isAuthenticated = auth.currentUser != null;

    _authSubscription = auth.onAuthStateChange.listen((authState) {
      if (!mounted) return;

      setState(() {
        _isAuthenticated = authState.session != null;
      });
    });

    if (_isAuthenticated) {
      _loadHouseholdProfile();
    } else {
      _isLoading = false;
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadHouseholdProfile() async {
    try {
      final resident = await _profileService.loadResidentProfile();

      if (!mounted) return;

      setState(() {
        _householdProfile =
            resident?.householdProfile ?? const HouseholdProfile();
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load household profile: $error')),
      );
    }
  }

  void _updateHouseholdProfile(HouseholdProfile profile) {
    setState(() {
      _householdProfile = profile;
    });
  }

  Future<void> _saveHouseholdProfile() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null || !_isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in before saving your household profile.'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final residentProfile = ResidentProfile(
        id: user.id,
        householdProfile: _householdProfile,
      );

      await _profileService.saveResidentProfile(residentProfile);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Household profile saved successfully!')),
      );

      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save household profile: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your household')),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Your household',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tell us about the people in your household '
                      'so we can better understand your assistance needs.',
                    ),
                    const SizedBox(height: 24),
                    HouseholdProfileForm(
                      initialValue: _householdProfile,
                      onChanged: _updateHouseholdProfile,
                    ),
                    const SizedBox(height: 24),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your information matters',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Your household information can help responders '
                              'understand your assistance during a flood emergency.',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (!_isAuthenticated) ...[
                      const Text(
                        'Please sign in to save your household profile. '
                        'Your current form details will remain available '
                        'while you stay on this screen.',
                        style: TextStyle(color: Colors.orange),
                      ),
                      const SizedBox(height: 8),
                    ],
                    FilledButton(
                      onPressed: _isSaving || !_isAuthenticated
                          ? null
                          : _saveHouseholdProfile,
                      child: Text(
                        _isSaving ? 'Saving...' : 'Save Household Profile',
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                      },
                      child: const Text('Skip'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
