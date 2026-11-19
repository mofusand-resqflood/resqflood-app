import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/household_profile.dart';
import '../models/resident_profile.dart';

class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Save the household profile belonging to a resident.
  Future<void> saveResidentProfile(ResidentProfile profile) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Please sign in before saving your profile.');
    }

    if (profile.id != user.id) {
      throw Exception('The profile does not belong to the signed-in user.');
    }

    await _supabase.from('profiles').upsert({
      'id': profile.id,
      ...profile.householdProfile.toJson(),
    });
  }

  // Load the profile belonging to the signed-in resident.
  Future<ResidentProfile?> loadResidentProfile() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Please sign in before loading your profile.');
    }

    final data = await _supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (data == null) {
      return null;
    }

    return ResidentProfile(
      id: user.id,
      householdProfile: HouseholdProfile.fromJson(data),
    );
  }
}
