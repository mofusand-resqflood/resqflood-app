import 'package:flutter/material.dart';

import '../../../core/app_routes.dart';
import '../../../models/sos_request.dart';
import '../../../services/ai_service.dart';
import '../../../services/sos_service.dart';
import 'widgets/ai_summary_card.dart';

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

  static const List<String> _helpTypes = [
    'Evacuation',
    'Walking Support',
    'Water Inside House',
    'Flooding',
    'Trapped',
    'Medical emergency',
    'Other',
  ];

  String _emergencyType = 'Evacuation';
  bool _medicalEmergency = false;
  bool _isSubmitting = false;

  // AI extraction state
  bool _isAnalyzing = false;
  SosAiExtraction? _aiExtraction;
  bool _aiConfirmed = false;
  String? _aiFallbackMessage;
  bool _showManualFields = true;

  Future<void> _analyzeWithAi() async {
    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please describe what is happening first.'),
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isAnalyzing = true;
      _aiFallbackMessage = null;
      _aiConfirmed = false;
    });

    try {
      final result = await AiService.instance.extractSosInfo(description);

      if (!mounted) return;

      setState(() {
        _aiExtraction = result;
        _emergencyType = result.helpType;
        _peopleController.text = result.peopleCount.toString();
        _showManualFields = false;
      });
    } on AiExtractionException catch (e) {
      if (!mounted) return;

      setState(() {
        _aiExtraction = null;
        _aiConfirmed = false;
        _aiFallbackMessage = e.message;
        _showManualFields = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  void _handleAiConfirmed(SosAiExtraction confirmed) {
    setState(() {
      _aiExtraction = confirmed;
      _aiConfirmed = true;
      _emergencyType = confirmed.helpType;
      _peopleController.text = confirmed.peopleCount.toString();
      if (confirmed.helpType == 'Walking Support') {
        _medicalEmergency = true;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('AI details confirmed and applied to your SOS request.'),
      ),
    );
  }

  void _switchToManualFallback() {
    setState(() {
      _showManualFields = true;
      _aiConfirmed = false;
    });
  }

  Future<void> _submitRequest() async {
    if (_aiExtraction != null && !_aiConfirmed && !_showManualFields) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please confirm the AI summary details or switch to manual form before submitting.',
          ),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final finalDescription = (_aiConfirmed && _aiExtraction != null)
          ? '${_aiExtraction!.summary}\n\nOriginal note: ${_descriptionController.text.trim()}'
          : _descriptionController.text.trim();

      final request = SosRequest(
        emergencyType: _emergencyType,
        description: finalDescription,
        location: _locationController.text.trim(),
        peopleAffected: int.parse(_peopleController.text.trim()),
        medicalEmergency: _medicalEmergency,
        createdAt: DateTime.now(),
      );

      final requestId = await SosService.instance.submitRequest(request);

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
      appBar: AppBar(title: const Text('Request Emergency Help')),
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
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Describe your situation in Bahasa Melayu or English. '
                      'AI can auto-fill the help type and number of people for you.',
                ),
                const SizedBox(height: 20),

                const Text(
                  'Describe your situation',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText:
                    'e.g. Air naik paras pinggang, ada 4 orang termasuk warga emas perlukan bantuan pindah',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isAnalyzing ? null : _analyzeWithAi,
                    icon: _isAnalyzing
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Icon(Icons.auto_awesome),
                    label: Text(
                      _isAnalyzing
                          ? 'Analyzing with AI...'
                          : 'Auto-Fill Details with AI',
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),

                if (_aiFallbackMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade400),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange.shade800),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _aiFallbackMessage!,
                            style: TextStyle(
                              color: Colors.orange.shade900,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (_aiExtraction != null && !_showManualFields) ...[
                  const SizedBox(height: 16),
                  AiSummaryCard(
                    extraction: _aiExtraction!,
                    isConfirmed: _aiConfirmed,
                    onConfirm: _handleAiConfirmed,
                    onManualFallback: _switchToManualFallback,
                  ),
                ],

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

                if (_showManualFields) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Help / Emergency type',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _emergencyType,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: _helpTypes
                        .map(
                          (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      ),
                    )
                        .toList(),
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
                ],

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
