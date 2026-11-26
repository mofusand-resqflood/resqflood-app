import 'package:flutter/material.dart';

class ReportBlockedRoadScreen extends StatelessWidget {
  const ReportBlockedRoadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Blocked Road')),
      body: const Center(
        child: Text('Report Form will go here (Assigned to another ticket)'),
      ),
    );
  }
}
