
import 'package:flutter/material.dart';

import '../../../core/app_routes.dart';
import '../../../models/sos_request.dart';
import '../../../services/sos_service.dart';

class SosFormScreen extends StatefulWidget {
  const SosFormScreen({super.key});

  @override
  State<SosFormScreen> createState() => _SosFormScreenState();
}

class _SosFormScreenState extends State<SosFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _peopleController = TextEditingController(text: '1');

  String _emergencyType = 'Flooding';
  bool _medicalEmergency = false;
  bool _isSubmitting = false;

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final request = SosRequest(
        emergencyType: _emergencyType,
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        peopleAffected: int.parse(_peopleController.text.trim()),
        medicalEmergency: _medicalEmergency,
        createdAt: DateTime.now(),
      );

      final requestId =
      await SosService.instance.submitRequest(request);

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        AppRoutes.sosConfirmation,
        arguments: requestId,
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to save your SOS request. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _descriptionController.dispose();
    _peopleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Emergency Help'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tell us what is happening',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Provide your details so the response team can '
                      'understand your situation.',
                ),
                const SizedBox(height: 24),

                const Text(
                  'Emergency type',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _emergencyType,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Flooding',
                      child: Text('Flooding'),
                    ),
                    DropdownMenuItem(
                      value: 'Trapped',
                      child: Text('Trapped'),
                    ),
                    DropdownMenuItem(
                      value: 'Medical emergency',
                      child: Text('Medical emergency'),
                    ),
                    DropdownMenuItem(
                      value: 'Other',
                      child: Text('Other'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _emergencyType = value;
                      });
                    }
                  },
                ),

                const SizedBox(height: 20),

                const Text(
                  'Your location',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    hintText: 'Enter your address or current location',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your location.';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                const Text(
                  'Number of people affected',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _peopleController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Enter number of people',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.people),
                  ),
                  validator: (value) {
                    final count = int.tryParse(value ?? '');

                    if (count == null || count < 1) {
                      return 'Enter a number of at least 1.';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                const Text(
                  'Additional details',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Describe your situation (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 12),

                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text(
                    'Medical assistance is needed',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  value: _medicalEmergency,
                  onChanged: (value) {
                    setState(() {
                      _medicalEmergency = value ?? false;
                    });
                  },
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitRequest,
                    icon: const Icon(Icons.sos),
                    label: Text(
                      _isSubmitting ? 'Saving request...' : 'SUBMIT SOS',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
