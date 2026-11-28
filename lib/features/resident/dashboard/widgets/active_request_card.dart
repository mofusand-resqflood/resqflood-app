import 'package:flutter/material.dart';

import '../../../../core/app_routes.dart';
import '../../../../models/sos_request.dart';
import '../../../../services/tracking_service.dart';

class ActiveRequestCard extends StatefulWidget {
  const ActiveRequestCard({super.key, this.requestStream});

  @visibleForTesting
  final Stream<SosRequest?>? requestStream;

  @override
  State<ActiveRequestCard> createState() => _ActiveRequestCardState();
}

class _ActiveRequestCardState extends State<ActiveRequestCard> {
  late final Stream<SosRequest?> _requestStream;

  @override
  void initState() {
    super.initState();
    _requestStream =
        widget.requestStream ?? TrackingService.instance.watchActiveRequest();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SosRequest?>(
      stream: _requestStream,
      builder: (context, snapshot) {
        final request = snapshot.data;

        // No active request: do not render the card.
        if (request == null || !request.isActive) {
          return const SizedBox.shrink();
        }

        return Card(
          margin: EdgeInsets.zero,
          elevation: 1,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.blue.shade100),
          ),
          child: InkWell(
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.activeRequest);
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.emergency, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Active emergency request',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Icon(
                        Icons.local_shipping_outlined,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          request.statusLabel,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.blue.shade700),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text('Last-known ETA: ${request.etaLabel}'),
                      ),
                    ],
                  ),
                  if (request.isCached) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Showing last saved tracking information. '
                      'Live updates are temporarily unavailable.',
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'View request',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
