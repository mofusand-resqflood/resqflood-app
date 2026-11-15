
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../models/household_profile.dart';
import '../../../../services/profile_service.dart';
import 'widgets/household_profile_form.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final ProfileService _profileService = ProfileService();

  HouseholdProfile _householdProfile = const HouseholdProfile();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadHouseholdProfile();
  }

  Future<void> _loadHouseholdProfile() async {
    // A new resident who is not signed in starts with an empty form.
    if (Supabase.instance.client.auth.currentUser == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final profile = await _profileService.loadHouseholdProfile();

      if (!mounted) return;

      setState(() {
        _householdProfile = profile ?? const HouseholdProfile();
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
    setState(() {
      _isSaving = true;
    });

    try {
      await _profileService.saveHouseholdProfile(_householdProfile);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Household profile saved successfully!'),
        ),
      );
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
      appBar: AppBar(
        title: const Text('Your household'),
      ),
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
              FilledButton(
                onPressed:
                _isSaving ? null : _saveHouseholdProfile,
                child: Text(
                  _isSaving
                      ? 'Saving...'
                      : 'Save Household Profile',
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
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
