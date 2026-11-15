
import 'package:flutter/material.dart';

class ResidentShell extends StatefulWidget {
  const ResidentShell({super.key});

  @override
  State<ResidentShell> createState() => _ResidentShellState();
}

class _ResidentShellState extends State<ResidentShell> {
  int _selectedIndex = 0;

  // Temporary count until the offline queue service is integrated.
  final int _queueCount = 0;

  static const Color paleMint = Color(0xFFE5F3EE);
  static const Color borderMint = Color(0xFFD0E7DE);

  late final List<Widget> _pages = [
    const _TabPlaceholder(title: 'Home', icon: Icons.home_outlined),
    const _TabPlaceholder(title: 'Track', icon: Icons.route_outlined),
    const _TabPlaceholder(title: 'Nearby', icon: Icons.location_on_outlined),
    const _TabPlaceholder(
      title: 'Assistant',
      icon: Icons.chat_bubble_outline,
    ),
    _ProfilePlaceholder(queueCount: _queueCount),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: paleMint,
        indicatorColor: borderMint,
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route),
            label: 'Track',
          ),
          NavigationDestination(
            icon: Icon(Icons.location_on_outlined),
            selectedIcon: Icon(Icons.location_on),
            label: 'Nearby',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Assistant',
          ),
          NavigationDestination(
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
  const _TabPlaceholder({
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: const Color(0xFF164E48)),
          const SizedBox(height: 16),
          Text(
            '$title Tab',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ],
      ),
    );
  }
}

class _ProfilePlaceholder extends StatelessWidget {
  const _ProfilePlaceholder({required this.queueCount});

  final int queueCount;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.person_outline,
            size: 64,
            color: Color(0xFF164E48),
          ),
          const SizedBox(height: 16),
          Text(
            'Profile Tab',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sync, color: Color(0xFF164E48)),
                  const SizedBox(width: 12),
                  const Text('Sync Status'),
                  const SizedBox(width: 16),
                  Badge(
                    label: Text('$queueCount'),
                    child: const Icon(Icons.cloud_upload_outlined),
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
