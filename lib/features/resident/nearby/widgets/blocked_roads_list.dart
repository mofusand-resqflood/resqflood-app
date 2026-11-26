import 'package:flutter/material.dart';
import '../../../../models/blocked_road.dart';
import '../../../../services/blocked_road_service.dart';

class BlockedRoadsList extends StatelessWidget {
  const BlockedRoadsList({super.key});

  // Helper to format the time nicely
  String _getTimeAgo(DateTime? date) {
    if (date == null) return 'Recently';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final _service = BlockedRoadService();

    return StreamBuilder<List<BlockedRoad>>(
      stream: _service.getVerifiedRoads(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final roads = snapshot.data ?? [];
        if (roads.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Text('No blocked roads reported recently.', style: TextStyle(color: Colors.grey)),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Blocked Roads', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.red.shade200),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.warning_amber_rounded, color: Colors.red),
                    title: Text(road.roadName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(road.note),
                        const SizedBox(height: 4),
                        Text(
                          'Verified ${_getTimeAgo(road.verifiedAt)}',
                          style: TextStyle(fontSize: 11, color: Colors.red.shade700, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
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