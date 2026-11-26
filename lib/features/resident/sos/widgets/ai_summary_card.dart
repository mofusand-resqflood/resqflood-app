import 'package:flutter/material.dart';

import '../../../../services/ai_service.dart';

class AiSummaryCard extends StatefulWidget {
  final SosAiExtraction extraction;
  final bool isConfirmed;
  final ValueChanged<SosAiExtraction> onConfirm;
  final VoidCallback onManualFallback;

  const AiSummaryCard({
    super.key,
    required this.extraction,
    required this.isConfirmed,
    required this.onConfirm,
    required this.onManualFallback,
  });

  @override
  State<AiSummaryCard> createState() => _AiSummaryCardState();
}

class _AiSummaryCardState extends State<AiSummaryCard> {
  late TextEditingController _peopleController;
  late TextEditingController _summaryController;
  late String _selectedHelpType;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _syncControllers(widget.extraction);
  }

  @override
  void didUpdateWidget(covariant AiSummaryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.extraction != widget.extraction) {
      _syncControllers(widget.extraction);
      _isEditing = false;
    }
  }

  void _syncControllers(SosAiExtraction data) {
    _peopleController = TextEditingController(
      text: data.peopleCount.toString(),
    );
    _summaryController = TextEditingController(text: data.summary);
    _selectedHelpType = data.helpType;
  }

  @override
  void dispose() {
    _peopleController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  void _handleConfirm() {
    final parsedCount = int.tryParse(_peopleController.text.trim());
    if (parsedCount == null || parsedCount < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least 1 person affected.'),
        ),
      );
      return;
    }

    final updated = SosAiExtraction(
      peopleCount: parsedCount,
      helpType: _selectedHelpType,
      summary: _summaryController.text.trim().isEmpty
          ? widget.extraction.summary
          : _summaryController.text.trim(),
    );

    setState(() {
      _isEditing = false;
    });

    widget.onConfirm(updated);
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isConfirmed
        ? Colors.green.shade600
        : Colors.blue.shade700;
    final bgColor = widget.isConfirmed
        ? Colors.green.shade50
        : Colors.blue.shade50;

    return Card(
      elevation: 0,
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  widget.isConfirmed ? Icons.check_circle : Icons.auto_awesome,
                  color: borderColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.isConfirmed
                        ? 'AI Details Confirmed'
                        : 'AI Summary & Auto-Filled Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: borderColor,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _isEditing = !_isEditing;
                    });
                  },
                  icon: Icon(_isEditing ? Icons.close : Icons.edit, size: 18),
                  label: Text(_isEditing ? 'Cancel' : 'Edit'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_isEditing) ...[
              const Text(
                'Help Type',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedHelpType,
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                items: SosAiExtraction.allowedHelpTypes
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
                      _selectedHelpType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              const Text(
                'Number of People',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _peopleController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.people),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Situation Summary',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _summaryController,
                maxLines: 2,
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ] else ...[
              _InfoRow(
                icon: Icons.support_agent,
                label: 'Help Type',
                value: _selectedHelpType,
              ),
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.people,
                label: 'People Affected',
                value: '${_peopleController.text} person(s)',
              ),
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.summarize,
                label: 'Summary',
                value: _summaryController.text,
              ),
            ],

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _handleConfirm,
                    icon: const Icon(Icons.check),
                    label: Text(
                      widget.isConfirmed
                          ? 'Update Confirmed Details'
                          : 'Confirm & Auto-Fill',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Center(
              child: TextButton(
                onPressed: widget.onManualFallback,
                child: const Text('Switch to manual form instead'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.black87),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black87, fontSize: 14),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
