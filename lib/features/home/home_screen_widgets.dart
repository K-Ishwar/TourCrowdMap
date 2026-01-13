import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:tour_crowd_map/features/home/firestore_service.dart';

class LiveCrowdTicker extends StatelessWidget {
  const LiveCrowdTicker({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirestoreService().getLocations(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white70,
                ),
              ),
            );
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const SizedBox();

          return ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final name = data['name'] ?? 'Unknown';
              final status = data['crowdLevel'] ?? 'Unknown';

              Color statusColor = Colors.grey;
              if (status.toString().toLowerCase().contains('low')) {
                statusColor = Colors.greenAccent;
              } else if (status.toString().toLowerCase().contains('high')) {
                statusColor = Colors.redAccent;
              } else if (status.toString().toLowerCase().contains('moderate')) {
                statusColor = Colors.orangeAccent;
              }

              return ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 10, color: statusColor),
                        const SizedBox(width: 8),
                        Text(
                          '$name: $status',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: (200 * index).ms).slideX();
            },
          );
        },
      ),
    );
  }
}

class TrendingCarousel extends StatelessWidget {
  const TrendingCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirestoreService().getLocations(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No trending places yet.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          // In a real app, query for "trending" or specific criteria.
          // Here we just take the first 5 locations.
          final places = docs.take(10).toList();

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            scrollDirection: Axis.horizontal,
            itemCount: places.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final doc = places[index];
              final data = doc.data() as Map<String, dynamic>;
              final id = doc.id;
              final name = data['name'] ?? 'Unknown';
              final imageUrl = data['imageUrl'];
              final category = data['category'] ?? 'General';
              final crowdLevel = data['crowdLevel'] ?? 'Unknown';

              return GestureDetector(
                onTap: () {
                  // Navigate to details via Map path
                  context.push('/map/$id');
                },
                child:
                    Container(
                          width: 180,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.grey.shade900, // Fallback color
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Image
                              if (imageUrl != null)
                                Positioned.fill(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const Center(
                                            child: Icon(
                                              Icons.broken_image,
                                              color: Colors.white54,
                                            ),
                                          ),
                                    ),
                                  ),
                                ),

                              // Gradient overlay
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: 0.8),
                                      ],
                                      stops: const [0.3, 1.0],
                                    ),
                                  ),
                                ),
                              ),

                              // Content
                              Positioned(
                                bottom: 16,
                                left: 16,
                                right: 16,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.category,
                                          color: Colors.white70,
                                          size: 12,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            category,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Status Badge
                              Positioned(
                                top: 12,
                                right: 12,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: 5,
                                      sigmaY: 5,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                      child: Text(
                                        crowdLevel,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(delay: (200 + index * 50).ms)
                        .slideX(begin: 0.1),
              );
            },
          );
        },
      ),
    );
  }
}
