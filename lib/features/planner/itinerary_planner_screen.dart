import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:tour_crowd_map/features/home/firestore_service.dart';

class ItineraryPlannerScreen extends StatefulWidget {
  const ItineraryPlannerScreen({super.key});

  @override
  State<ItineraryPlannerScreen> createState() => _ItineraryPlannerScreenState();
}

class _ItineraryPlannerScreenState extends State<ItineraryPlannerScreen> {
  String _preference = 'Peaceful'; // Peaceful, Popular, Balanced
  String _duration = 'Half Day'; // Half Day (3 places), Full Day (5 places)
  bool _isGenerating = false;
  List<Map<String, dynamic>> _itinerary = [];

  final FirestoreService _firestoreService = FirestoreService();

  Future<void> _generateItinerary() async {
    setState(() {
      _isGenerating = true;
      _itinerary = [];
    });

    // Simulate "AI" thinking time
    await Future.delayed(const Duration(seconds: 2));

    try {
      final snapshot = await _firestoreService.getLocations().first;
      final docs = snapshot.docs;

      List<Map<String, dynamic>> candidates = docs.map((d) {
        final data = d.data() as Map<String, dynamic>;
        return {...data, 'id': d.id};
      }).toList();

      // Algorithm
      candidates.sort((a, b) {
        final crowdA = (a['crowdLevel'] as String? ?? '').toLowerCase();
        final crowdB = (b['crowdLevel'] as String? ?? '').toLowerCase();

        int scoreA = 0;
        int scoreB = 0;

        // Scoring based on preference
        if (_preference == 'Peaceful') {
          if (crowdA.contains('low')) scoreA += 10;
          if (crowdA.contains('moderate')) scoreA += 5;

          if (crowdB.contains('low')) scoreB += 10;
          if (crowdB.contains('moderate')) scoreB += 5;
        } else if (_preference == 'Popular') {
          if (crowdA.contains('high')) scoreA += 10;
          if (crowdA.contains('moderate')) scoreA += 5;

          if (crowdB.contains('high')) scoreB += 10;
          if (crowdB.contains('moderate')) scoreB += 5;
        } else {
          // Balanced: Mix of moderate
          if (crowdA.contains('moderate')) scoreA += 10;
          if (crowdB.contains('moderate')) scoreB += 10;
        }

        return scoreB.compareTo(scoreA); // Descending score
      });

      int count = _duration == 'Half Day' ? 3 : 5;
      _itinerary = candidates.take(count).toList();
    } catch (e) {
      debugPrint('Error generating itinerary: $e');
    }

    if (mounted) {
      setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Itinerary Planner'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/map'),
        ),
      ),
      body: Row(
        children: [
          // Left Panel: Controls
          Container(
            width: 350,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                right: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.auto_awesome,
                  size: 48,
                  color: Colors.deepPurple,
                ),
                const SizedBox(height: 16),
                Text(
                  'Plan Your Day',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'Let AI find the best spots for you.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Preference
                Text(
                  'What kind of vibe?',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['Peaceful', 'Popular', 'Balanced'].map((pref) {
                    final selected = _preference == pref;
                    return ChoiceChip(
                      label: Text(pref),
                      selected: selected,
                      onSelected: (val) => setState(() => _preference = pref),
                      selectedColor: Colors.deepPurple.shade100,
                      labelStyle: TextStyle(
                        color: selected ? Colors.deepPurple : null,
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // Duration
                Text(
                  'How much time?',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['Half Day', 'Full Day'].map((dur) {
                    final selected = _duration == dur;
                    return ChoiceChip(
                      label: Text(dur),
                      selected: selected,
                      onSelected: (val) => setState(() => _duration = dur),
                      selectedColor: Colors.deepPurple.shade100,
                      labelStyle: TextStyle(
                        color: selected ? Colors.deepPurple : null,
                      ),
                    );
                  }).toList(),
                ),

                const Spacer(),

                ElevatedButton.icon(
                  onPressed: _isGenerating ? null : _generateItinerary,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: _isGenerating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.auto_fix_high),
                  label: Text(
                    _isGenerating ? 'GENERATING...' : 'GENERATE ITINERARY',
                  ),
                ),
              ],
            ),
          ),

          // Right Panel: Results
          Expanded(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: _itinerary.isEmpty && !_isGenerating
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.map_outlined,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Your itinerary will appear here',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(32),
                      itemCount: _itinerary.length,
                      itemBuilder: (context, index) {
                        final place = _itinerary[index];
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Timeline Node
                            Column(
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: const BoxDecoration(
                                    color: Colors.deepPurple,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                if (index != _itinerary.length - 1)
                                  Container(
                                    width: 2,
                                    height: 100,
                                    color: Colors.deepPurple.shade100,
                                  ),
                              ],
                            ),
                            const SizedBox(width: 24),
                            // Content
                            Expanded(
                              child:
                                  Card(
                                        elevation: 2,
                                        margin: const EdgeInsets.only(
                                          bottom: 24,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                place['name'] ?? '',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleLarge
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.history,
                                                    size: 16,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    place['category'] ?? '',
                                                    style: TextStyle(
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  Icon(
                                                    Icons.groups,
                                                    size: 16,
                                                    color: _getCrowdColor(
                                                      place['crowdLevel'],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    place['crowdLevel'] ?? '',
                                                    style: TextStyle(
                                                      color: _getCrowdColor(
                                                        place['crowdLevel'],
                                                      ),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                      .animate()
                                      .fadeIn(delay: (index * 200).ms)
                                      .slideX(),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCrowdColor(String? crowd) {
    if (crowd == null) return Colors.grey;
    final c = crowd.toLowerCase();
    if (c.contains('low')) return Colors.green;
    if (c.contains('moderate')) return Colors.orange;
    if (c.contains('high')) return Colors.red;
    return Colors.grey;
  }
}
