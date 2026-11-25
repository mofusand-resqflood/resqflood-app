import 'package:flutter/material.dart';

import '../../../../core/app_routes.dart';

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  static const List<_QuickAction> _actions = [
    _QuickAction(
      title: 'Photo depth',
      subtitle: 'Report flood depth',
      icon: Icons.water,
      color: Colors.blue,
      route: null,
    ),
    _QuickAction(
      title: 'Nearby shelters',
      subtitle: 'Find a safe place',
      icon: Icons.home_work,
      color: Colors.teal,
      route: AppRoutes.nearby,
    ),
    _QuickAction(
      title: 'Report a road',
      subtitle: 'Report blocked roads',
      icon: Icons.block,
      color: Colors.orange,
      route: AppRoutes.reportBlockedRoad,
    ),
    _QuickAction(
      title: 'Ask Bantu',
      subtitle: 'Get emergency guidance',
      icon: Icons.chat,
      color: Colors.purple,
      route: AppRoutes.chatbot,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.35,
      ),
      itemBuilder: (context, index) {
        final action = _actions[index];

        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              if (action.route != null) {
                Navigator.pushNamed(context, action.route!);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Flood depth reporting is coming soon.'),
                  ),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(action.icon, color: action.color, size: 30),
                  const SizedBox(height: 8),
                  Text(
                    action.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    action.subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11),
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

class _QuickAction {
  const _QuickAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? route;
}
