import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tour_crowd_map/features/auth/auth_service.dart';

class MainLayout extends StatelessWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final theme = Theme.of(context);
    final route = GoRouterState.of(context).uri.toString();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.map_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'TourCrowdMap',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        elevation: 1,
        backgroundColor: Colors.white,
        actions: [
          _NavBarItem(
            label: 'Home',
            icon: Icons.home_filled,
            isSelected: route == '/',
            onTap: () => context.go('/'),
          ),
          _NavBarItem(
            label: 'Map',
            icon: Icons.map,
            isSelected: route.startsWith('/map'),
            onTap: () => context.go('/map'),
          ),
          const SizedBox(width: 16),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: const Icon(Icons.logout, color: Colors.grey),
              tooltip: 'Logout',
              onPressed: () async {
                await auth.signOut();
                if (context.mounted) context.go('/login');
              },
            ),
          ),
        ],
      ),
      body: child,
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isSelected ? theme.colorScheme.primary : Colors.grey.shade600;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
