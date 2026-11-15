
import 'package:flutter_test/flutter_test.dart';
import 'package:resqflood_app/models/household_profile.dart';

void main() {
  test('Household profile saves and reloads its values', () {
    const profile = HouseholdProfile(
      adults: 2,
      elderly: 1,
      children: 2,
      disabled: 1,
      medicalNotes: 'Requires wheelchair assistance',
    );

    final reloaded = HouseholdProfile.fromJson(profile.toJson());

    expect(reloaded.adults, 2);
    expect(reloaded.elderly, 1);
    expect(reloaded.children, 2);
    expect(reloaded.disabled, 1);
    expect(reloaded.medicalNotes, 'Requires wheelchair assistance');
  });
}
