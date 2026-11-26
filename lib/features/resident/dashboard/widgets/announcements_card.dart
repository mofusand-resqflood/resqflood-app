import 'package:flutter/material.dart';
import '../../../../models/announcement.dart';
import '../../../../services/announcement_service.dart';

class AnnouncementsCard extends StatelessWidget {
  final AnnouncementService _service = AnnouncementService();

  AnnouncementsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Announcement>>(
      stream: _service.getLatestAnnouncements(),
      builder: (context, snapshot) {
        // 1. If waiting for network, try to show cached data
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildOfflineFallback(context);
        }

        // 2. If there is an error (offline), show cached data
        if (snapshot.hasError) {
          return Text('Database Error: ${snapshot.error}', style: const TextStyle(color: Colors.red));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('No announcements found in database.', style: TextStyle(color: Colors.grey));
        }

        // 3. If we have live data, show the latest one
        final latest = snapshot.data!.first;
        return _buildCard(
          context,
          title: latest.title,
          message: latest.message,
          author: latest.authorName,
          isOffline: false,
        );
      },
    );
  }

  // Widget to load from SharedPreferences if network fails
  Widget _buildOfflineFallback(BuildContext context) {
    return FutureBuilder<Announcement?>(
      future: _service.getCachedAnnouncement(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink(); // Or a small loading skeleton
        }

        if (snapshot.hasData) {
          final cached = snapshot.data!;
          return _buildCard(
            context,
            title: cached.title,
            message: cached.message,
            author: cached.authorName,
            isOffline: true, // Show an offline badge
          );
        }

        // Nothing in cache, nothing from network
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildCard(BuildContext context, {
    required String title,
    required String message,
    required String author,
    required bool isOffline,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'From Coordinators',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (isOffline) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(4)),
                child: const Text('Offline', style: TextStyle(color: Colors.white, fontSize: 10)),
              )
            ]
          ],
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 8),
                Text(message, style: const TextStyle(fontSize: 14, color: Colors.black87)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.campaign, size: 16, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text(author, style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.w500)),
                  ],
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}