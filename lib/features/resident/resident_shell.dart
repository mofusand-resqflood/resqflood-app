import 'dart:async';
import 'package:flutter/material.dart';

import 'profile/profile_screen.dart';

import '../../services/offline_queue_service.dart';
import 'dashboard/dashboard_screen.dart'; // 👈 MAKE SURE THIS IMPORT IS HERE
import 'nearby/nearby_screen.dart';       // 👈 MAKE SURE THIS IMPORT IS HERE

class ResidentShell extends StatefulWidget {
  const ResidentShell({super.key});

  @override
  State<ResidentShell> createState() => _ResidentShellState();
}

class _ResidentShellState extends State<ResidentShell> {
  int _selectedIndex = 0;
  int _queueCount = 0;

  late final StreamSubscription<int> _queueCountSubscription;

  @override
  void initState() {
    super.initState();

    final queueService = OfflineQueueService.instance;

    _queueCountSubscription = queueService.queueCountStream.listen((count) {
      if (mounted) {
        setState(() {
          _queueCount = count;
        });
      }
    });

    unawaited(queueService.refreshQueueCount());
  }

  @override
  void dispose() {
    unawaited(_queueCountSubscription.cancel());
    super.dispose();
  }

  List<Widget> get _pages => [
    const DashboardScreen(), // 👈 REMOVED THE DUPLICATE COMMENT
    const NearbyScreen(),    // 👈 REMOVED THE DUPLICATE COMMENT
    const _TabPlaceholder(title: 'Ask', icon: Icons.chat_bubble_outline),
    _SyncTab(queueCount: _queueCount),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        backgroundColor: colors.surfaceContainerHighest,
        indicatorColor: colors.secondaryContainer,
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.location_on_outlined),
            selectedIcon: Icon(Icons.location_on),
            label: 'Nearby',
          ),
          const NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Ask',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _queueCount > 0,
              label: Text('$_queueCount'),
              child: const Icon(Icons.sync_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: _queueCount > 0,
              label: Text('$_queueCount'),
              child: const Icon(Icons.sync),
            ),
            label: 'Sync',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _TabPlaceholder extends StatelessWidget {
  const _TabPlaceholder({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: colors.primary),
          const SizedBox(height: 16),
          Text('$title Tab', style: Theme.of(context).textTheme.headlineSmall),
        ],
      ),
    );
  }
}

class _SyncTab extends StatelessWidget {
  const _SyncTab({required this.queueCount});

  final int queueCount;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sync, size: 64, color: colors.primary),
          const SizedBox(height: 16),
          Text('Sync Tab', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    queueCount == 0
                        ? Icons.cloud_done_outlined
                        : Icons.cloud_upload_outlined,
                    color: colors.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    queueCount == 0
                        ? 'All data synced'
                        : '$queueCount item(s) waiting to sync',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}