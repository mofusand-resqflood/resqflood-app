import 'package:flutter/material.dart';
import '../../../core/app_routes.dart';
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
            Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 40, color: Colors.blue),
                    SizedBox(height: 8),
                    Text('Evacuation Route Map', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    Text('(Map integration coming in a future update)', style: TextStyle(fontSize: 12, color: Colors.blue)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 2. SHELTERS
            const OpenSheltersList(),

            const SizedBox(height: 24),

            // 3. ROADS
            const BlockedRoadsList(),

            const SizedBox(height: 32),

            // 4. REPORT BUTTON
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.reportBlockedRoad);
                },
                icon: const Icon(Icons.add_road),
                label: const Text('Report a Blocked Road'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}