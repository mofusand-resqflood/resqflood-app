import 'package:flutter/material.dart';

import '../../../../services/connectivity_service.dart';
import '../../../../services/local_database.dart';
import '../../../../services/offline_queue_service.dart';
import 'widgets/network_status_banner.dart';
import 'widgets/quick_actions_grid.dart';
import 'widgets/sos_button.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ConnectivityService _connectivityService = ConnectivityService();
  final OfflineQueueService _queueService = OfflineQueueService.instance;

  late final Stream<bool> _connectionStream;
  late final Stream<int> _queueCountStream;

  int _initialQueueCount = 0;

  @override
  void initState() {
    super.initState();

    _connectionStream = _connectivityService.connectionStream;
    _queueCountStream = _queueService.queueCountStream;

    _loadInitialQueueCount();
  }

  Future<void> _loadInitialQueueCount() async {
    final count = await LocalDatabase.instance.getQueuedCount();

    if (mounted) {
      setState(() {
        _initialQueueCount = count;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home'), centerTitle: false),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "We're here for you",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Stay informed and get help when you need it.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 20),

              StreamBuilder<bool>(
                stream: _connectionStream,
                initialData: false,
                builder: (context, connectionSnapshot) {
                  return StreamBuilder<int>(
                    stream: _queueCountStream,
                    initialData: _initialQueueCount,
                    builder: (context, queueSnapshot) {
                      return NetworkStatusBanner(
                        isOnline: connectionSnapshot.data ?? false,
                        queuedCount: queueSnapshot.data ?? _initialQueueCount,
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 24),

              const SosButton(),

              const SizedBox(height: 24),

              const Text(
                'Quick actions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              const QuickActionsGrid(),

              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'If the situation is not critical, '
                        'please proceed to your nearest PPS '
                        '(temporary relief centre).',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
