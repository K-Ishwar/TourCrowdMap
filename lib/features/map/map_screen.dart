import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:tour_crowd_map/features/details/location_details_screen.dart';
import 'package:tour_crowd_map/features/home/firestore_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final FirestoreService _firestoreService = FirestoreService();
  bool _showHeatmap = false;

  // State for search and selection
  String _searchQuery = '';
  String? _selectedLocationId;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Full Screen Map
          StreamBuilder<QuerySnapshot>(
            stream: _firestoreService.getLocations(),
            builder: (context, snapshot) {
              final locations = snapshot.data?.docs ?? [];

              // Filter locations based on search
              final filteredLocations = locations.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = (data['name'] as String? ?? '').toLowerCase();
                return name.contains(_searchQuery.toLowerCase());
              }).toList();

              // Update markers
              final markers = filteredLocations
                  .map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final geo = data['location'] as GeoPoint?;
                    final crowd = data['crowdLevel'] as String? ?? 'Unknown';

                    if (geo == null) return null;

                    Color color = Colors.grey;
                    if (crowd.toLowerCase().contains('low')) {
                      color = Colors.green;
                    } else if (crowd.toLowerCase().contains('moderate')) {
                      color = Colors.orange;
                    } else if (crowd.toLowerCase().contains('high')) {
                      color = Colors.red;
                    }

                    final isSelected = _selectedLocationId == doc.id;

                    return Marker(
                      point: LatLng(geo.latitude, geo.longitude),
                      width: isSelected ? 60 : 40,
                      height: isSelected ? 60 : 40,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedLocationId = doc.id;
                          });
                          _mapController.move(
                            LatLng(geo.latitude, geo.longitude),
                            15,
                          );
                        },
                        child: AnimatedContainer(
                          duration: 300.ms,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.blue : Colors.white,
                              width: isSelected ? 3 : 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.location_on,
                            color: color,
                            size: isSelected ? 36 : 24,
                          ),
                        ),
                      ),
                    );
                  })
                  .whereType<Marker>()
                  .toList();

              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: const LatLng(18.5204, 73.8567), // Pune
                  initialZoom: 13.0,
                  onTap: (tapPosition, point) {
                    if (_selectedLocationId != null) {
                      setState(() => _selectedLocationId = null);
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.tour_crowd_map',
                  ),
                  if (_showHeatmap)
                    CircleLayer(
                      circles: filteredLocations
                          .map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final geo = data['location'] as GeoPoint?;
                            final crowd = (data['crowdLevel'] as String? ?? '')
                                .toLowerCase();
                            if (geo == null) return null;

                            Color color = Colors.blue.withValues(alpha: 0.3);
                            if (crowd.contains('moderate')) {
                              color = Colors.yellow.withValues(alpha: 0.3);
                            }
                            if (crowd.contains('high')) {
                              color = Colors.red.withValues(alpha: 0.3);
                            }

                            return CircleMarker(
                              point: LatLng(geo.latitude, geo.longitude),
                              color: color,
                              radius: 500,
                              useRadiusInMeter: true,
                            );
                          })
                          .whereType<CircleMarker>()
                          .toList(),
                    ),
                  MarkerLayer(markers: markers),
                ],
              );
            },
          ),

          // 2. Heatmap Toggle (Top Right)
          Positioned(
            top: 16,
            right: 16,
            child: FloatingActionButton.small(
              backgroundColor: Colors.white,
              foregroundColor: _showHeatmap ? Colors.blue : Colors.grey,
              child: const Icon(Icons.layers),
              onPressed: () => setState(() => _showHeatmap = !_showHeatmap),
            ),
          ),

          // 3. Admin Tools (Bottom Right)
          Positioned(
            bottom: 32,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'admin',
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blueGrey.shade900,
                  onPressed: () => context.push('/admin'),
                  child: const Icon(Icons.admin_panel_settings),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.small(
                  heroTag: 'simulate',
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.purple.shade900,
                  onPressed: () {
                    _firestoreService.simulateLiveUpdates();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Simulating Live Data Update...'),
                      ),
                    );
                  },
                  child: const Icon(Icons.auto_awesome),
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'seed',
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue,
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
          ),

          // 4. Search Bar (Top Left)
          Positioned(
            top: 16,
            left: 16,
            right: MediaQuery.of(context).size.width > 600 ? null : 70,
            width: MediaQuery.of(context).size.width > 600 ? 400 : null,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search locations...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
          ),

          // 5. Details Panel (Left Side Overlay)
          if (_selectedLocationId != null)
            Positioned(
              top: MediaQuery.of(context).size.width > 600 ? 80 : null,
              bottom: 0,
              left: 0,
              right: MediaQuery.of(context).size.width > 600 ? null : 0,
              width: MediaQuery.of(context).size.width > 600 ? 400 : null,
              height: MediaQuery.of(context).size.width > 600
                  ? null
                  : MediaQuery.of(context).size.height * 0.45,
              child: _buildDetailsPanel(),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailsPanel() {
    return Card(
      margin: MediaQuery.of(context).size.width > 600
          ? const EdgeInsets.only(left: 16, bottom: 16)
          : EdgeInsets.zero,
      elevation: 8,
      shape: MediaQuery.of(context).size.width > 600
          ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
          : const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
      child: ClipRRect(
        borderRadius: MediaQuery.of(context).size.width > 600
            ? BorderRadius.circular(12)
            : const BorderRadius.vertical(top: Radius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey.shade100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Location Details',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _selectedLocationId = null),
                  ),
                ],
              ),
            ),
            Expanded(
              child: LocationDetailsScreen(
                id: _selectedLocationId,
                isEmbedded: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
