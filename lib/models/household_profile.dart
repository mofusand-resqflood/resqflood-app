class HouseholdProfile {
  final int adults;
  final int elderly;
  final int children;
  final int disabled;
  final String medicalNotes;
  final String mobilityNotes;

  const HouseholdProfile({
    this.adults = 0,
    this.elderly = 0,
    this.children = 0,
    this.disabled = 0,
    this.medicalNotes = '',
    this.mobilityNotes = '',
  }) : assert(adults >= 0),
       assert(elderly >= 0),
       assert(children >= 0),
       assert(disabled >= 0);

  Map<String, dynamic> toJson() {
    return {
      'adults': adults,
      'elderly': elderly,
      'children': children,
      'disabled': disabled,
      'medical_notes': medicalNotes.trim(),
      'mobility_notes': mobilityNotes.trim(),
    };
  }

  factory HouseholdProfile.fromJson(Map<String, dynamic> json) {
    return HouseholdProfile(
      adults: (json['adults'] as num?)?.toInt() ?? 0,
      elderly: (json['elderly'] as num?)?.toInt() ?? 0,
      children: (json['children'] as num?)?.toInt() ?? 0,
      disabled: (json['disabled'] as num?)?.toInt() ?? 0,
      medicalNotes: json['medical_notes'] as String? ?? '',
      mobilityNotes: json['mobility_notes'] as String? ?? '',
    );
  }
}
