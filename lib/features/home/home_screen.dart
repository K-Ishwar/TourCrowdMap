import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.map_outlined, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'TourCrowdMap',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.push('/admin'),
            child: const Text(
              'Admin Portal',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          // Background with Image and Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(
                    'https://images.unsplash.com/photo-1501785888041-af3ef285b470?q=80&w=2070&auto=format&fit=crop',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.black.withValues(alpha: 0.4),
                      Colors.white,
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // Main Scrollable Content
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 120), // Spacing for AppBar
                // Hero Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.tealAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.tealAccent.withValues(alpha: 0.5),
                          ),
                        ),
                        child: const Text(
                          '🚀 Google Hackathon Project',
                          style: TextStyle(
                            color: Colors.tealAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ).animate().fadeIn().slideX(),
                      const SizedBox(height: 16),
                      const Text(
                        'Discover Places.\nDodge Crowds.',
                        style: TextStyle(
                          fontSize: 48,
                          height: 1.1,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -1,
                        ),
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
                      const SizedBox(height: 16),
                      Text(
                        'Your intelligent companion for smarter travel.\nReal-time heatmaps, AI itinerary planning, and accurate crowd forecasts.',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white.withValues(alpha: 0.9),
                          height: 1.5,
                        ),
                      ).animate().fadeIn(delay: 400.ms),
                      const SizedBox(height: 32),
                      FilledButton.icon(
                            onPressed: () => context.go('/map'),
                            icon: const Icon(Icons.explore),
                            label: const Text('Start Exploring Now'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 20,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 10,
                              shadowColor: Colors.teal.withValues(alpha: 0.5),
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 600.ms)
                          .scale()
                          .shimmer(delay: 1500.ms, duration: 1000.ms),
                    ],
                  ),
                ),

                const SizedBox(height: 80),

                // Features Grid
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Powerful Features',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey.shade900,
                        ),
                      ),
                      const SizedBox(height: 24),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          // Responsive Grid
                          int crossAxisCount = constraints.maxWidth > 600
                              ? 4
                              : 1;
                          if (constraints.maxWidth > 900) {
                            crossAxisCount = 4;
                          } else if (constraints.maxWidth > 600) {
                            crossAxisCount = 2;
                          }

                          return GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: crossAxisCount,
                            childAspectRatio: 1.5,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            children: [
                              _FeatureCard(
                                icon: Icons.layers,
                                color: Colors.blue,
                                title: 'Live Heatmaps',
                                desc:
                                    'Visualise real-time crowd density on the map.',
                                delay: 0,
                              ),
                              _FeatureCard(
                                icon: Icons.auto_awesome,
                                color: Colors.purple,
                                title: 'AI Assistant',
                                desc:
                                    'Context-aware chat for personalized plans.',
                                delay: 100,
                              ),
                              _FeatureCard(
                                icon: Icons.bar_chart,
                                color: Colors.orange,
                                title: 'Crowd Forecasts',
                                desc:
                                    'Predictive analytics for upcoming hours.',
                                delay: 200,
                              ),
                              _FeatureCard(
                                icon: Icons.notifications_active,
                                color: Colors.red,
                                title: 'Smart Alerts',
                                desc:
                                    'Get notified about critical crowd levels.',
                                delay: 300,
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 48),

                      // Footer
                      Center(
                        child: Text(
                          'Developed by CodeXcle Team',
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String desc;
  final int delay;

  const _FeatureCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.desc,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    ).animate().fadeIn(delay: delay.ms).slideY(begin: 0.2);
  }
}
