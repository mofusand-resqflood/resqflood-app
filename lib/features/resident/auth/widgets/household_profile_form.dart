import 'package:flutter/material.dart';

import '../../../../models/household_profile.dart';

class HouseholdProfileForm extends StatefulWidget {
  final HouseholdProfile initialValue;
  final ValueChanged<HouseholdProfile>? onChanged;

  const HouseholdProfileForm({
    super.key,
    this.initialValue = const HouseholdProfile(),
    this.onChanged,
  });

  @override
  State<HouseholdProfileForm> createState() => _HouseholdProfileFormState();
}

class _HouseholdProfileFormState extends State<HouseholdProfileForm> {
  late int _adults;
  late int _elderly;
  late int _children;
  late int _disabled;

  late final TextEditingController _medicalNotesController;
  late final TextEditingController _mobilityNotesController;

  static const Color darkTeal = Color(0xFF164E48);
  static const Color paleMint = Color(0xFFE5F3EE);
  static const Color borderMint = Color(0xFFD0E7DE);

  @override
  void initState() {
    super.initState();

    _adults = widget.initialValue.adults;
    _elderly = widget.initialValue.elderly;
    _children = widget.initialValue.children;
    _disabled = widget.initialValue.disabled;

    _medicalNotesController = TextEditingController(
      text: widget.initialValue.medicalNotes,
    );

    _mobilityNotesController = TextEditingController(
      text: widget.initialValue.mobilityNotes,
    );

    _medicalNotesController.addListener(_notifyChanged);
    _mobilityNotesController.addListener(_notifyChanged);
  }

  @override
  void didUpdateWidget(covariant HouseholdProfileForm oldWidget) {
    super.didUpdateWidget(oldWidget);

    _adults = widget.initialValue.adults;
    _elderly = widget.initialValue.elderly;
    _children = widget.initialValue.children;
    _disabled = widget.initialValue.disabled;

    if (_medicalNotesController.text != widget.initialValue.medicalNotes) {
      _medicalNotesController.removeListener(_notifyChanged);
      _medicalNotesController.text = widget.initialValue.medicalNotes;
      _medicalNotesController.addListener(_notifyChanged);
    }

    if (_mobilityNotesController.text != widget.initialValue.mobilityNotes) {
      _mobilityNotesController.removeListener(_notifyChanged);
      _mobilityNotesController.text = widget.initialValue.mobilityNotes;
      _mobilityNotesController.addListener(_notifyChanged);
    }
  }

  @override
  void dispose() {
    _medicalNotesController.removeListener(_notifyChanged);
    _mobilityNotesController.removeListener(_notifyChanged);
    _medicalNotesController.dispose();
    _mobilityNotesController.dispose();
    super.dispose();
  }

  void _notifyChanged() {
    widget.onChanged?.call(
      HouseholdProfile(
        adults: _adults,
        elderly: _elderly,
        children: _children,
        disabled: _disabled,
        medicalNotes: _medicalNotesController.text.trim(),
        mobilityNotes: _mobilityNotesController.text.trim(),
      ),
    );
  }

  void _updateCount(String category, int change) {
    setState(() {
      if (category == 'Adults') {
        _adults = (_adults + change).clamp(0, 999).toInt();
      } else if (category == 'Elderly') {
        _elderly = (_elderly + change).clamp(0, 999).toInt();
      } else if (category == 'Children') {
        _children = (_children + change).clamp(0, 999).toInt();
      } else if (category == 'Disabled') {
        _disabled = (_disabled + change).clamp(0, 999).toInt();
      }
    });

    _notifyChanged();
  }

  Widget _buildCounter(String title, String description, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: darkTeal,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            onPressed: count > 0 ? () => _updateCount(title, -1) : null,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: darkTeal,
            ),
            icon: const Icon(Icons.remove),
          ),
          SizedBox(
            width: 32,
            child: Text(
              '$count',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: darkTeal,
              ),
            ),
          ),
          IconButton.filledTonal(
            onPressed: count < 999 ? () => _updateCount(title, 1) : null,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: darkTeal,
            ),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesField({
    required String title,
    required String description,
    required String hint,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: darkTeal,
          ),
        ),
        const SizedBox(height: 6),
        Text(description, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: paleMint,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderMint),
          ),
          child: TextField(
            controller: controller,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: Colors.white,
              alignLabelWithHint: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: borderMint),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: borderMint),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: darkTeal, width: 1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Household Members',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: darkTeal,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'How many people belong to each group?',
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: paleMint,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderMint),
          ),
          child: Column(
            children: [
              _buildCounter('Adults', 'Age 18–59', _adults),
              const Divider(color: borderMint),
              _buildCounter('Elderly', 'Age 60 and above', _elderly),
              const Divider(color: borderMint),
              _buildCounter('Children', 'Below age 18', _children),
              const Divider(color: borderMint),
              _buildCounter(
                'Disabled',
                'People requiring additional support',
                _disabled,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildNotesField(
          title: 'Medical Notes',
          description:
              'Include medical conditions, allergies, or medication needs.',
          hint: 'Enter medical information here...',
          controller: _medicalNotesController,
        ),
        const SizedBox(height: 24),
        _buildNotesField(
          title: 'Mobility Notes',
          description: 'Include mobility difficulties or special assistance requirements.',
          hint: 'Enter mobility information here...',
          controller: _mobilityNotesController,
        ),
      ],
    );
  }
}
