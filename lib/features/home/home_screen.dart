import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:tour_crowd_map/features/home/home_screen_widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.black.withValues(alpha: 0.2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.map_outlined, color: Colors.white),
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
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.2),
                  child: TextButton(
                    onPressed: () => context.push('/admin'),
                    child: const Text(
                      'Admin Portal',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
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
                      Colors.black.withValues(alpha: 0.4),
                      Colors.black.withValues(alpha: 0.2),
                      Colors.black.withValues(alpha: 0.8),
                    ],
                    stops: const [0.0, 0.5, 1.0],
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
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.tealAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.tealAccent.withValues(alpha: 0.3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.tealAccent.withValues(alpha: 0.1),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.rocket_launch,
                              size: 16,
                              color: Colors.tealAccent,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Google Hackathon Project',
                              style: TextStyle(
                                color: Colors.tealAccent,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn().slideX(),
                      const SizedBox(height: 24),
                      const Text(
                        'Discover Places.\nDodge Crowds.',
                        style: TextStyle(
                          fontSize: 56,
                          height: 1.0,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -2,
                        ),
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
                      const SizedBox(height: 24),
                      Text(
                        'Your intelligent companion for smarter travel.\nReal-time heatmaps, AI itinerary planning, and accurate crowd forecasts.',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white.withValues(alpha: 0.9),
                          height: 1.6,
                        ),
                      ).animate().fadeIn(delay: 400.ms),
                      const SizedBox(height: 32),

                      // Live Crowd Ticker
                      const LiveCrowdTicker(),

                      const SizedBox(height: 32),
                      FilledButton.icon(
                            onPressed: () => context.go('/map'),
                            icon: const Icon(Icons.explore),
                            label: const Text('Start Exploring Now'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.tealAccent,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 22,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 15,
                              shadowColor: Colors.tealAccent.withValues(
                                alpha: 0.4,
                              ),
                            ),
                          )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .shimmer(delay: 2000.ms, duration: 1000.ms)
                          .animate() // Reset animation controller for other effects
                          .fadeIn(delay: 600.ms)
                          .scale(),
                    ],
                  ),
                ),

                const SizedBox(height: 60),

                // Trending Carousel
                Padding(
                  padding: const EdgeInsets.only(left: 24, bottom: 24),
                  child: Text(
                    'Trending Now 🔥',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                ),
                const TrendingCarousel(),

                const SizedBox(height: 60),

                // Features Grid
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Powerful Features',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Roboto', // Assuming default font
                        ),
                      ).animate().fadeIn(delay: 500.ms),
                      const SizedBox(height: 24),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          // Responsive Grid
                          int crossAxisCount = constraints.maxWidth > 900
                              ? 4
                              : constraints.maxWidth > 600
                              ? 2
                              : 1;

                          return GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: crossAxisCount,
                            childAspectRatio: 1.3,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                            children: [
                              _FeatureCard(
                                icon: Icons.layers_outlined,
                                color: Colors.blueAccent,
                                title: 'Live Heatmaps',
                                desc:
                                    'Visualise real-time crowd density on the map.',
                                delay: 0,
                              ),
                              _FeatureCard(
                                icon: Icons.auto_awesome_outlined,
                                color: Colors.purpleAccent,
                                title: 'AI Assistant',
                                desc:
                                    'Context-aware chat for personalized plans.',
                                delay: 100,
                              ),
                              _FeatureCard(
                                icon: Icons.bar_chart_outlined,
                                color: Colors.orangeAccent,
                                title: 'Crowd Forecasts',
                                desc:
                                    'Predictive analytics for upcoming hours.',
                                delay: 200,
                              ),
                              _FeatureCard(
                                icon: Icons.notifications_active_outlined,
                                color: Colors.redAccent,
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
                        child: Column(
                          children: [
                            const Divider(color: Colors.white24),
                            const SizedBox(height: 16),
                            Text(
                              'Developed by CodeXcle Team',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                letterSpacing: 1,
                              ),
                            ),
                          ],
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.1),
                Colors.white.withValues(alpha: 0.05),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                desc,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: delay.ms).slideY(begin: 0.1, end: 0);
  }
}
