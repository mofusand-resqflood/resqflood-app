import 'package:flutter/material.dart';
import 'widgets/open_shelters_list.dart';
import 'widgets/blocked_roads_list.dart';

class NearbyScreen extends StatelessWidget {
  const NearbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nearby')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OpenSheltersList(),
            const SizedBox(height: 24),
            BlockedRoadsList(),
          ],
        ),
      ),
    );
  }
}
