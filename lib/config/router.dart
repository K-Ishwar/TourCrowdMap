import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tour_crowd_map/features/admin/admin_dashboard_screen.dart';
import 'package:tour_crowd_map/features/auth/login_screen.dart';
import 'package:tour_crowd_map/features/details/location_details_screen.dart';
import 'package:tour_crowd_map/features/home/home_screen.dart';
import 'package:tour_crowd_map/features/layout/main_layout.dart';
import 'package:tour_crowd_map/features/map/map_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return MainLayout(child: child);
      },
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/map',
          builder: (context, state) => const MapScreen(),
          routes: [
            GoRoute(
              path: '/map/:id', // Changed path from ':id' to '/map/:id'
              builder: (context, state) {
                final id = state.pathParameters['id'];
                return LocationDetailsScreen(id: id);
              },
            ),
            GoRoute(
              // Added new route for /admin
              path: '/admin',
              builder: (context, state) {
                return const AdminDashboardScreen();
              },
            ),
          ],
        ),
      ],
    ),
  ],
);
