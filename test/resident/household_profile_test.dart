import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resqflood_app/models/household_profile.dart';
import 'package:resqflood_app/features/resident/auth/widgets/household_profile_form.dart';

void main() {
  group('HouseholdProfile model', () {
    test('converts to JSON and back with all fields', () {
      const profile = HouseholdProfile(
        adults: 2,
        elderly: 1,
        children: 3,
        disabled: 1,
        medicalNotes: 'Asthma and allergies',
        mobilityNotes: 'Requires wheelchair access',
      );

      final restored = HouseholdProfile.fromJson(profile.toJson());

      expect(restored.adults, 2);
      expect(restored.elderly, 1);
      expect(restored.children, 3);
      expect(restored.disabled, 1);
      expect(restored.medicalNotes, 'Asthma and allergies');
      expect(restored.mobilityNotes, 'Requires wheelchair access');
    });

    test('uses default values when JSON keys are missing', () {
      final profile = HouseholdProfile.fromJson({});

      expect(profile.adults, 0);
      expect(profile.elderly, 0);
      expect(profile.children, 0);
      expect(profile.disabled, 0);
      expect(profile.medicalNotes, '');
      expect(profile.mobilityNotes, '');
    });
  });

  group('HouseholdProfileForm', () {
    testWidgets('counter tap emits an updated profile', (tester) async {
      final updates = <HouseholdProfile>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HouseholdProfileForm(onChanged: updates.add),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pump();

      expect(updates, isNotEmpty);
      expect(updates.last.adults, 1);
    });

    testWidgets(
      'preserves trailing spaces when parent rebuilds after notes change',
      (tester) async {
        var profile = const HouseholdProfile();

        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                return Scaffold(
                  body: SingleChildScrollView(
                    child: HouseholdProfileForm(
                      initialValue: profile,
                      onChanged: (updatedProfile) {
                        setState(() {
                          profile = updatedProfile;
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        );

        final medicalField = find.byType(TextField).at(0);
        await tester.ensureVisible(medicalField);
        await tester.enterText(medicalField, 'Needs medication ');
        await tester.pump();

        expect(profile.medicalNotes, 'Needs medication ');
        expect(
          tester.widget<TextField>(medicalField).controller!.text,
          'Needs medication ',
        );

        final mobilityField = find.byType(TextField).at(1);
        await tester.ensureVisible(mobilityField);
        await tester.enterText(mobilityField, 'Needs wheelchair ');
        await tester.pump();

        expect(profile.mobilityNotes, 'Needs wheelchair ');
        expect(
          tester.widget<TextField>(mobilityField).controller!.text,
          'Needs wheelchair ',
        );
      },
    );

    testWidgets('medical notes text change emits updated profile', (
      tester,
    ) async {
      final updates = <HouseholdProfile>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HouseholdProfileForm(onChanged: updates.add),
            ),
          ),
        ),
      );

      final medicalField = find.byType(TextField).at(0);
      await tester.ensureVisible(medicalField);
      await tester.enterText(medicalField, 'Requires daily medication');

      expect(updates.last.medicalNotes, 'Requires daily medication');
    });

    testWidgets('mobility notes text change emits updated profile', (
      tester,
    ) async {
      final updates = <HouseholdProfile>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HouseholdProfileForm(onChanged: updates.add),
            ),
          ),
        ),
      );

      final mobilityField = find.byType(TextField).at(1);
      await tester.ensureVisible(mobilityField);
      await tester.enterText(mobilityField, 'Needs wheelchair assistance');

      expect(updates.last.mobilityNotes, 'Needs wheelchair assistance');
    });
  });
}
