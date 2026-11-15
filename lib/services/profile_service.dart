
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/household_profile.dart';

class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Save or update the household profile.
  Future<void> saveHouseholdProfile(
      HouseholdProfile household,
      ) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Please sign in before saving your profile.');
    }

    await _supabase.from('profiles').upsert({
      'id': user.id,
      ...household.toJson(),
    });
  }

  // Load the household profile of the signed-in resident.
  Future<HouseholdProfile?> loadHouseholdProfile() async {
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

    return HouseholdProfile.fromJson(data);
  }
}
