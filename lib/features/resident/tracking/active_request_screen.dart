import 'package:flutter/material.dart';

import '../../../models/sos_request.dart';
import '../../../services/tracking_service.dart';

class ActiveRequestScreen extends StatefulWidget {
  const ActiveRequestScreen({super.key});

  @override
  State<ActiveRequestScreen> createState() => _ActiveRequestScreenState();
}

class _ActiveRequestScreenState extends State<ActiveRequestScreen> {
  late final Stream<SosRequest?> _requestStream;

  @override
  void initState() {
    super.initState();
    _requestStream = TrackingService.instance.watchActiveRequest();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Active Request')),
      body: StreamBuilder<SosRequest?>(
        stream: _requestStream,
        builder: (context, snapshot) {
          final request = snapshot.data;

          if (snapshot.hasError && request == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Unable to check your request. '
                  'Retrying automatically...',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (request == null || !request.isActive) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'You do not have an active emergency request.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final lastUpdated = request.updatedAt ?? request.createdAt;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Icon(Icons.emergency, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              const Text(
                'Your request is being tracked',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CURRENT STATUS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        request.statusLabel,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(height: 28),
                      const Text(
                        'LAST-KNOWN ETA',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        request.etaLabel,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(height: 28),
                      Text(
                        'Last updated: ${lastUpdated.toLocal()}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (request.isCached) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'This is the last saved information. '
                          'Live updates are temporarily unavailable.',
                          style: TextStyle(color: Colors.deepOrange),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Keep your phone available so you can receive updates '
                'from the response team.',
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
      ),
    );
  }
}
