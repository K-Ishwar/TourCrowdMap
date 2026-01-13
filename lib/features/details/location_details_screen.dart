import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:tour_crowd_map/features/details/crowd_chart.dart';
import 'package:tour_crowd_map/features/home/firestore_service.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationDetailsScreen extends StatelessWidget {
  final String? id;
  final bool isEmbedded; // New flag

  const LocationDetailsScreen({
    super.key,
    required this.id,
    this.isEmbedded = false,
  });

  @override
  Widget build(BuildContext context) {
    if (id == null) {
      return const Center(child: Text('Select a location to see details'));
    }

    final firestoreService = FirestoreService();

    // If embedded, we return just the body content, basically.
    // Or we modify the scaffold.
    // Let's keep Scaffold but hide AppBar if isEmbedded.

    return Scaffold(
      backgroundColor: Colors.transparent, // Transparent for embedding
      appBar: isEmbedded
          ? null
          : AppBar(
              title: const Text('Location Details'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/map');
                  }
                },
              ),
            ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: firestoreService.getLocationById(id!),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                'Location details not available.',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final name = data['name'] ?? 'Unknown Location';
          final description = data['description'] ?? 'No description provided.';
          final crowdLevel = data['crowdLevel'] ?? 'Unknown';
          final category =
              data['category'] as String? ?? 'General'; // Get Category
          final imageUrl = data['imageUrl'] as String?;
          final lastUpdatedTimestamp = data['lastUpdated'] as Timestamp?;

          // Smart Suggestion Logic
          String bestTime = data['bestTimeToVisit'] ?? '';
          if (bestTime.isEmpty || bestTime == 'Not specified') {
            bestTime = _calculateBestTime(category);
          }

          String lastUpdatedStr = 'Never';
          if (lastUpdatedTimestamp != null) {
            lastUpdatedStr = DateFormat.yMMMd().add_jm().format(
              lastUpdatedTimestamp.toDate(),
            );
          }

          // Determine Color
          Color statusColor = Colors.grey;
          if (crowdLevel.toString().toLowerCase().contains('low')) {
            statusColor = Colors.green;
          } else if (crowdLevel.toString().toLowerCase().contains('high')) {
            statusColor = Colors.red;
          } else if (crowdLevel.toString().toLowerCase().contains('moderate')) {
            statusColor = Colors.orange;
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (imageUrl != null && imageUrl.isNotEmpty)
                  Stack(
                    children: [
                      Image.network(
                        imageUrl,
                        height: 250,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 250,
                            color: Colors.grey.shade200,
                            child: Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 250,
                            color: Colors.grey.shade300,
                            child: const Center(
                              child: Icon(
                                Icons.broken_image,
                                size: 50,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),
                      // Gradient Overlay for text readability if needed later,
                      // but for now just the image.
                    ],
                  )
                else
                  Container(
                    height: 250,
                    color: Colors.grey.shade300,
                    child: Center(
                      child: Icon(
                        Icons.image,
                        size: 50,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ).animate().fadeIn().moveX(),
                      const SizedBox(height: 16),

                      // Crowd Level Card
                      _InfoCard(
                        title: 'Current Crowd Level',
                        value: crowdLevel,
                        icon: Icons.groups,
                        color: statusColor,
                      ).animate().fadeIn(delay: 200.ms).slideX(),

                      const SizedBox(height: 12),

                      // Smart Visit Suggestion
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade50, Colors.white],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.auto_awesome,
                                color: Colors.blue,
                                size: 28,
                              ),
                            ).animate().shimmer(
                              delay: 1000.ms,
                              duration: 1500.ms,
                            ), // Shimmer Icon
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Smart Suggestion',
                                    style: TextStyle(
                                      color: Colors.blue.shade800,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Best time to visit:\n$bestTime',
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Based on past crowd trends',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 400.ms).slideX(),

                      const SizedBox(height: 12),

                      // Last Updated
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.update,
                              size: 20,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Last Updated: $lastUpdatedStr',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Popular Times Chart (Visual Analytics)
                      const CrowdChart().animate().fadeIn(delay: 600.ms),

                      const SizedBox(height: 24),

                      // --- User Reviews Section ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Community Reviews',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _showAddReviewDialog(
                              context,
                              firestoreService,
                              id!,
                            ),
                            icon: const Icon(Icons.rate_review),
                            label: const Text('Write Review'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      StreamBuilder<QuerySnapshot>(
                        stream: firestoreService.getReviews(id!),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return const Text('Error loading reviews');
                          }
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final reviews = snapshot.data?.docs ?? [];
                          if (reviews.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).dividerColor.withValues(alpha: 0.5),
                                ),
                              ),
                              child: const Center(
                                child: Text(
                                  "No reviews yet. Be the first!",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            );
                          }

                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: reviews.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final data =
                                  reviews[index].data() as Map<String, dynamic>;
                              final rating =
                                  (data['rating'] as num?)?.toDouble() ?? 0.0;
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 14,
                                          backgroundColor:
                                              Colors.deepPurple.shade100,
                                          child: Text(
                                            (data['userName'] as String? ??
                                                    'U')[0]
                                                .toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.deepPurple,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          data['userName'] ?? 'Anonymous',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const Spacer(),
                                        Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                          size: 16,
                                        ),
                                        Text(
                                          rating.toStringAsFixed(1),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      data['comment'] ?? '',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // Get Directions Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _launchMaps(data['location'] as GeoPoint?);
                          },
                          icon: const Icon(Icons.directions),
                          label: const Text('GET DIRECTIONS'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: 700.ms),

                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),

                      const SizedBox(height: 16),

                      // Overcrowding Warning
                      if (crowdLevel.toString().toLowerCase().contains(
                        'high',
                      )) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            border: Border.all(color: Colors.red),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.red,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'This place is overcrowded.\nTry visiting later.',
                                      style: TextStyle(
                                        color: Colors.red.shade900,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Nearby Suggestions
                        const Text(
                          'Nearby Less Crowded Places',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        StreamBuilder<QuerySnapshot>(
                          stream: firestoreService.getLocations(),
                          builder: (context, suggestionsSnapshot) {
                            if (!suggestionsSnapshot.hasData) {
                              return const SizedBox();
                            }

                            final currentGeo = data['location'] as GeoPoint?;
                            if (currentGeo == null) {
                              return const Text(
                                'Location data unavailable for suggestions.',
                              );
                            }

                            // Filter and Sort
                            final allDocs = suggestionsSnapshot.data!.docs;
                            final suggestions = allDocs.where((doc) {
                              if (doc.id == id) {
                                return false; // Exclude current
                              }
                              final d = doc.data() as Map<String, dynamic>;
                              final hasLocation = d['location'] != null;
                              final isLow = (d['crowdLevel'] as String? ?? '')
                                  .toLowerCase()
                                  .contains('low');
                              return isLow && hasLocation;
                            }).toList();

                            // Simple distance sort
                            // Simple distance sort
                            suggestions.sort((a, b) {
                              final dataA = a.data() as Map<String, dynamic>;
                              final dataB = b.data() as Map<String, dynamic>;

                              final locA = dataA['location'] as GeoPoint?;
                              final locB = dataB['location'] as GeoPoint?;

                              if (locA == null || locB == null) return 0;

                              final distA =
                                  (locA.latitude - currentGeo.latitude).abs() +
                                  (locA.longitude - currentGeo.longitude).abs();
                              final distB =
                                  (locB.latitude - currentGeo.latitude).abs() +
                                  (locB.longitude - currentGeo.longitude).abs();
                              return distA.compareTo(distB);
                            });

                            if (suggestions.isEmpty) {
                              return const Text(
                                'No nearby low-crowd locations found.',
                                style: TextStyle(color: Colors.grey),
                              );
                            }

                            return Column(
                              children: suggestions.take(3).map((doc) {
                                final d = doc.data() as Map<String, dynamic>;
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: const Icon(
                                      Icons.place,
                                      color: Colors.green,
                                    ),
                                    title: Text(d['name'] ?? ''),
                                    subtitle: const Text(
                                      'Crowd: Low',
                                      style: TextStyle(color: Colors.green),
                                    ),
                                    trailing: const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                    ),
                                    onTap: () => context.push(
                                      '/map/${doc.id}',
                                    ), // Use push to stack
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                      ],

                      Text(
                        'About',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.5,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _showReportDialog(context, firestoreService, id!),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.edit_location_alt),
                          label: const Text(
                            'REPORT CROWD STATUS',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showReportDialog(
    BuildContext context,
    FirestoreService service,
    String docId,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Update Crowd Status',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'What is the current crowd level?',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                _CrowdOption(
                  label: 'Low',
                  color: Colors.green,
                  onTap: () => _updateCrowd(context, service, docId, 'Low'),
                ),
                const SizedBox(height: 12),
                _CrowdOption(
                  label: 'Moderate',
                  color: Colors.orange,
                  onTap: () =>
                      _updateCrowd(context, service, docId, 'Moderate'),
                ),
                const SizedBox(height: 12),
                _CrowdOption(
                  label: 'High',
                  color: Colors.red,
                  onTap: () => _updateCrowd(context, service, docId, 'High'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _updateCrowd(
    BuildContext context,
    FirestoreService service,
    String docId,
    String level,
  ) async {
    Navigator.pop(context); // Close bottom sheet
    try {
      await service.updateCrowdLevel(docId, level);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Crowd level updated to $level'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _launchMaps(GeoPoint? location) async {
    if (location == null) return;
    // Use the 'dir' (directions) action to open navigation mode directly
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${location.latitude},${location.longitude}&travelmode=driving',
    );
    // Alternatively, for native intent: 'google.navigation:q=${location.latitude},${location.longitude}'

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch $url');
    }
  }

  Future<void> _showAddReviewDialog(
    BuildContext context,
    FirestoreService service,
    String docId,
  ) async {
    final commentController = TextEditingController();
    double rating = 5.0;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Write a Review'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('How was your experience?'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () => setState(() => rating = index + 1.0),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  labelText: 'Comment',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (commentController.text.isNotEmpty) {
                  service.addReview(
                    docId,
                    'User${DateTime.now().millisecond}', // Simulated User
                    rating,
                    commentController.text,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  String _calculateBestTime(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('nature') || cat.contains('hill station')) {
      return 'Early Morning (6 AM - 8 AM)\n(Peaceful Sunrise)';
    } else if (cat.contains('historic') || cat.contains('fort')) {
      return 'Weekdays, Morning (9 AM - 11 AM)\n(Avoid School Trips)';
    } else if (cat.contains('religious') || cat.contains('temple')) {
      return 'Afternoon (1 PM - 4 PM)\n(Post-Aarti Lull)';
    } else if (cat.contains('market') || cat.contains('shopping')) {
      return 'Morning (11 AM) or Late Night';
    }
    return 'Weekdays (Tue-Thu) to avoid rush';
  }
}

class _CrowdOption extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _CrowdOption({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
              ),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
