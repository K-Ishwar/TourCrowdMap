import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Colors.white,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                    Icons.map_outlined,
                    size: 100,
                    color: Theme.of(context).colorScheme.primary,
                  )
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .scale(delay: 200.ms), // Animate Icon
              const SizedBox(height: 24),
              Text(
                'TourCrowdMap',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ).animate().fadeIn(delay: 400.ms).moveY(begin: 20, end: 0),
              const SizedBox(height: 16),
              Text(
                'Avoid crowds. Explore smartly.',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey.shade700,
                ),
              ).animate().fadeIn(delay: 600.ms).moveY(begin: 20, end: 0),
              const SizedBox(height: 48),
              FilledButton.icon(
                    onPressed: () => context.go('/map'),
                    icon: const Icon(Icons.explore),
                    label: const Text('Start Exploring'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 800.ms)
                  .scale()
                  .shimmer(
                    delay: 1500.ms,
                    duration: 1000.ms,
                  ), // Shimmer effect on button
            ],
          ),
        ),
      ),
    );
  }
}
