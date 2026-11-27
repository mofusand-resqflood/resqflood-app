import 'package:flutter/material.dart';

import '../../../../models/blocked_road.dart';
import '../../../../services/blocked_road_service.dart';

class BlockedRoadsList extends StatelessWidget {
  const BlockedRoadsList({super.key});

  @override
  Widget build(BuildContext context) {
    final service = BlockedRoadService(); // 👈 INSIDE BUILD METHOD

    return StreamBuilder<List<BlockedRoad>>(
      stream: service.getVerifiedRoads(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final roads = snapshot.data ?? [];
        if (roads.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Blocked Roads',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: roads.length,
              itemBuilder: (context, index) {
                final road = roads[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: Colors.red.shade50,
                  child: ListTile(
                    leading: const Icon(Icons.warning, color: Colors.red),
                    title: Text(
                      road.roadName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(road.note),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
