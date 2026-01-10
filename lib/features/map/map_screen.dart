import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:tour_crowd_map/features/home/firestore_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final FirestoreService _firestoreService = FirestoreService();
  bool _showHeatmap = false;

  static const LatLng _puneCenter = LatLng(18.5204, 73.8567);

  @override
  Widget build(BuildContext context) {
    // Responsive Layout
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            // Desktop: Split View
            return Row(
              children: [
                SizedBox(width: 400, child: _buildLocationList(context)),
                Expanded(child: _buildMap(context)),
              ],
            );
          } else {
            // Mobile: Stack
            return Stack(
              children: [
                _buildMap(context),
                DraggableScrollableSheet(
                  initialChildSize: 0.4,
                  minChildSize: 0.2,
                  maxChildSize: 0.8,
                  builder: (context, scrollController) {
                    return Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 10),
                        ],
                      ),
                      child: _buildLocationList(context, scrollController),
                    );
                  },
                ),
              ],
            );
          }
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'admin',
            backgroundColor: Colors.blueGrey.shade900,
            foregroundColor: Colors.white,
            onPressed: () => context.push('/admin'),
            child: const Icon(Icons.admin_panel_settings),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.small(
            heroTag: 'simulate',
            backgroundColor: Colors.purple.shade900,
            foregroundColor: Colors.white,
            onPressed: () {
              _firestoreService.simulateLiveUpdates();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Simulating Live Data Update...')),
              );
            },
            child: const Icon(Icons.auto_awesome),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            onPressed: () {
              _firestoreService.seedLocations();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Seeding sample data...')),
              );
            },
            child: const Icon(Icons.dataset),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getLocations(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];

        return Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _puneCenter,
                initialZoom: 13.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.tour_crowd_map',
                ),
                if (_showHeatmap)
                  CircleLayer(
                    circles: docs
                        .map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final geo = data['location'] as GeoPoint?;
                          if (geo == null) return null;

                          final crowd = (data['crowdLevel'] as String? ?? '')
                              .toLowerCase();
                          Color color = Colors.yellow; // Moderate default
                          if (crowd.contains('low'))
                            color = Colors.blue;
                          else if (crowd.contains('high'))
                            color = Colors.red;

                          return CircleMarker(
                            point: LatLng(geo.latitude, geo.longitude),
                            color: color.withOpacity(0.3),
                            borderStrokeWidth: 0,
                            useRadiusInMeter: true,
                            radius: 500, // 500m radius for heatmap
                          );
                        })
                        .whereType<CircleMarker>()
                        .toList(),
                  ),
                MarkerLayer(
                  markers: docs
                      .map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final geo = data['location'] as GeoPoint?;
                        if (geo == null) return null;

                        final crowd = (data['crowdLevel'] as String? ?? '')
                            .toLowerCase();
                        Color color = Colors.orange;
                        if (crowd.contains('low'))
                          color = Colors.green;
                        else if (crowd.contains('high'))
                          color = Colors.red;

                        return Marker(
                          point: LatLng(geo.latitude, geo.longitude),
                          width: 40,
                          height: 40,
                          child: GestureDetector(
                            onTap: () => context.go('/map/${doc.id}'),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: color, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withOpacity(0.4),
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                              child: Icon(Icons.place, color: color, size: 24),
                            ),
                          ),
                        );
                      })
                      .whereType<Marker>()
                      .toList(),
                ),
              ],
            ),
            // Heatmap Toggle Button
            Positioned(
              top: 16,
              right: 16,
              child: FloatingActionButton.small(
                heroTag: 'heatmap_toggle',
                backgroundColor: Colors.white,
                onPressed: () {
                  setState(() {
                    _showHeatmap = !_showHeatmap;
                  });
                },
                child: Icon(
                  Icons.layers,
                  color: _showHeatmap ? Colors.deepPurple : Colors.grey,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLocationList(
    BuildContext context, [
    ScrollController? scrollController,
  ]) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Explore Places',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search locations...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
              ),
            ],
          ),
        ),

        // List from Firestore
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestoreService.getLocations(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final data = snapshot.data?.docs ?? [];

              if (data.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No places found',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                controller: scrollController,
                itemCount: data.length,
                separatorBuilder: (c, i) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final doc = data[index];
                  final map = doc.data() as Map<String, dynamic>;

                  final crowd = (map['crowdLevel'] as String? ?? '')
                      .toLowerCase();
                  Color iconColor = Colors.orange;
                  if (crowd.contains('low'))
                    iconColor = Colors.green;
                  else if (crowd.contains('high'))
                    iconColor = Colors.red;

                  return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: iconColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: iconColor.withOpacity(0.3),
                            ),
                          ),
                          child: Icon(Icons.place, color: iconColor),
                        ),
                        title: Text(
                          map['name'] ?? 'Unnamed',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              map['description'] ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.people,
                                  size: 12,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Crowd: ${map['crowdLevel'] ?? 'Unknown'}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: iconColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        onTap: () {
                          context.go('/map/${doc.id}');
                        },
                        trailing: IconButton(
                          icon: const Icon(Icons.my_location, size: 18),
                          onPressed: () {
                            final geo = map['location'] as GeoPoint?;
                            if (geo != null) {
                              _mapController.move(
                                LatLng(geo.latitude, geo.longitude),
                                15.0,
                              );
                            }
                          },
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 300.ms, delay: (50 * index).ms)
                      .slideX(begin: -0.1, end: 0);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
