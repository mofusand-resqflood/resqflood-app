
import 'package:flutter/material.dart';

class NetworkStatusBanner extends StatelessWidget {
  const NetworkStatusBanner({
    super.key,
    required this.isOnline,
    required this.queuedCount,
  });

  final bool isOnline;
  final int queuedCount;

  @override
  Widget build(BuildContext context) {
    final Color statusColor =
    isOnline ? Colors.green.shade700 : Colors.red.shade700;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isOnline ? Icons.wifi : Icons.wifi_off,
            color: statusColor,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  queuedCount == 0
                      ? 'No items waiting to send'
                      : '$queuedCount items waiting to send',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
