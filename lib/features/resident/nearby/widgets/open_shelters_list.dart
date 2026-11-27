import 'package:flutter/material.dart';

import '../../../../models/shelter.dart';
import '../../../../services/nearby_service.dart';

class OpenSheltersList extends StatelessWidget {
  const OpenSheltersList({super.key});

  @override
  Widget build(BuildContext context) {
    final service = NearbyService();

    return StreamBuilder<List<Shelter>>(
      stream: service.getOpenShelters(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          // Offline Fallback
          return FutureBuilder<List<Shelter>>(
            future: service.getCachedShelters(),
            builder: (context, cacheSnapshot) {
              if (cacheSnapshot.hasData && cacheSnapshot.data!.isNotEmpty) {
                return _buildList(
                  context,
                  cacheSnapshot.data!,
                  isOffline: true,
                );
              }
              return const Text('No shelters available offline.');
            },
          );
        }

        return _buildList(context, snapshot.data!, isOffline: false);
      },
    );
  }

  Widget _buildList(
    BuildContext context,
    List<Shelter> shelters, {
    required bool isOffline,
  }) {
    if (shelters.isEmpty) return const Text('No open shelters found nearby.');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Open Shelters',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (isOffline) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Offline',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: shelters.length,
          itemBuilder: (context, index) {
            final shelter = shelters[index];
            final capacityRatio = shelter.capacity > 0
                ? (shelter.currentOccupancy / shelter.capacity)
                : 0.0;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shelter.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      shelter.address,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // 👇 THIS SHOWS THE DISTANCE 👇
                    if (shelter.distance != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.directions_car,
                            size: 14,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${(shelter.distance! / 1000).toStringAsFixed(1)} km away',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 12),

                    // Capacity Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${shelter.freePlaces} free places',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '${shelter.currentOccupancy}/${shelter.capacity}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: capacityRatio,
                      backgroundColor: Colors.grey.shade300,
                      color: capacityRatio > 0.8 ? Colors.red : Colors.green,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
