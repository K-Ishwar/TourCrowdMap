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
    _searchFocusNode.dispose();
    super.dispose();
  }

  // Focus node for search bar to control suggestion visibility
  final FocusNode _searchFocusNode = FocusNode();

  // State for category filtering
  String? _selectedCategory;
  final List<String> _categories = [
    'Historic',
    'Nature',
    'Religious',
    'Fort',
    'Hill Station',
    'Museum',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getLocations(),
        builder: (context, snapshot) {
          final locations = snapshot.data?.docs ?? [];

          // 1. Filter Logic
          final filteredLocations = locations.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = (data['name'] as String? ?? '').toLowerCase();
            final category = (data['category'] as String? ?? '');

            bool matchesSearch =
                _searchQuery.isEmpty ||
                name.contains(_searchQuery.toLowerCase());
            bool matchesCategory =
                _selectedCategory == null || category == _selectedCategory;

            return matchesSearch && matchesCategory;
          }).toList();

          // 2. Marker Visibility Logic
          final markers = filteredLocations
              .map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final geo = data['location'] as GeoPoint?;
                final crowd = data['crowdLevel'] as String? ?? 'Unknown';

                if (geo == null) return null;

                // DECISION: Show marker ONLY if:
                // 1. It is the currently selected location (always show selected)
                // 2. OR User is explicitly searching/filtering (Query not empty OR Category not null)
                final isSelected = _selectedLocationId == doc.id;
                final isFiltering =
                    _searchQuery.isNotEmpty || _selectedCategory != null;

                if (!isSelected && !isFiltering) {
                  return null; // Hide marker by default to keep map clean
                }

                Color color = Colors.grey;
                if (crowd.toLowerCase().contains('low')) {
                  color = Colors.green;
                } else if (crowd.toLowerCase().contains('moderate')) {
                  color = Colors.orange;
                } else if (crowd.toLowerCase().contains('high')) {
                  color = Colors.red;
                }

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
                      FocusScope.of(context).unfocus();
                    },
                    child: AnimatedContainer(
                      duration: 300.ms,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? Colors.blue
                              : Theme.of(context).dividerColor,
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

          return Stack(
            children: [
              // Map Layer
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: const LatLng(18.5204, 73.8567), // Pune
                  initialZoom: 11.0, // Zoom out slightly for district view
                  onTap: (tapPosition, point) {
                    if (_selectedLocationId != null) {
                      setState(() => _selectedLocationId = null);
                    }
                    FocusScope.of(context).unfocus();
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
                            // Same logic: only show heatmap circles if filtering or selected?
                            // Or maybe heatmap shows general density even without markers?
                            // Let's hide them too to match "Clean Map" philosophy unless asked.
                            // Actually, heatmaps are useful for "at a glance" crowd.
                            // I'll keep them visible if the toggle is ON, but filtered by the list.
                            final data = doc.data() as Map<String, dynamic>;
                            final geo = data['location'] as GeoPoint?;
                            final crowd = (data['crowdLevel'] as String? ?? '')
                                .toLowerCase();
                            if (geo == null) return null;

                            // If not filtering/selected, maybe don't show heatmap dots either?
                            // Let's stick to the list logic.
                            final isSelected = _selectedLocationId == doc.id;
                            final isFiltering =
                                _searchQuery.isNotEmpty ||
                                _selectedCategory != null;

                            if (!isSelected && !isFiltering) return null;

                            Color color = Colors.grey.withValues(alpha: 0.3);
                            if (crowd.contains('low')) {
                              color = Colors.green.withValues(alpha: 0.3);
                            }
                            if (crowd.contains('moderate')) {
                              color = Colors.orange.withValues(alpha: 0.3);
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
              ),

              // Heatmap Toggle
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

              // Admin Tools
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
                      backgroundColor: Theme.of(context).cardColor,
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
                    // Temporary Button to Load Pune Data
                    FloatingActionButton(
                      heroTag: 'seed_pune',
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      tooltip: 'Load Pune Data',
                      onPressed: () {
                        _firestoreService.seedPuneData();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Loading Pune District Tourist Places...',
                            ),
                          ),
                        );
                      },
                      child: const Icon(Icons.download),
                    ),
                  ],
                ),
              ),

              // Search Bar & Filter Chips
              Positioned(
                top: 16,
                left: 16,
                right: MediaQuery.of(context).size.width > 600 ? null : 70,
                width: MediaQuery.of(context).size.width > 600 ? 500 : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      elevation: 4,
                      color: Theme.of(context).cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        style: Theme.of(context).textTheme.bodyMedium,
                        decoration: InputDecoration(
                          hintText: 'Search Pune tourist places...',
                          hintStyle: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
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
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                      ),
                    ),

                    // Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: const Text('All'),
                              selected: _selectedCategory == null,
                              onSelected: (bool selected) {
                                setState(() {
                                  _selectedCategory = null;
                                  // 'All' functionally means 'Reset Category Filter'
                                  // BUT combined with 'Clean Map' logic, selecting 'All'
                                  // usually implies 'Show Everything'.
                                  // If _selectedCategory is null, and Query is empty, map is currently hidden.
                                  // We might need a special state or flag to "Show All" explicitly.
                                  // For now, let's allow 'All' to just clear the category filter.
                                  // Users can type or pick a specific category to see items.
                                });
                              },
                            ),
                          ),
                          ..._categories.map((category) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(category),
                                selected: _selectedCategory == category,
                                onSelected: (bool selected) {
                                  setState(() {
                                    _selectedCategory = selected
                                        ? category
                                        : null;
                                  });
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                    if (_searchQuery.isNotEmpty && filteredLocations.isNotEmpty)
                      Card(
                        elevation: 4,
                        margin: const EdgeInsets.only(top: 8),
                        color: Theme.of(context).cardColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: filteredLocations.length,
                            itemBuilder: (context, index) {
                              final doc = filteredLocations[index];
                              final data = doc.data() as Map<String, dynamic>;
                              final geo = data['location'] as GeoPoint?;

                              return ListTile(
                                leading: const Icon(
                                  Icons.place,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                                title: Text(
                                  data['name'] ?? 'Unknown',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                subtitle: Text(
                                  '${data['category'] ?? 'Place'} • ${data['crowdLevel'] ?? 'Unknown'} Crowd',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                onTap: () {
                                  if (geo != null) {
                                    setState(() {
                                      _selectedLocationId = doc.id;
                                      _searchQuery = '';
                                      _searchController.clear();
                                    });
                                    _mapController.move(
                                      LatLng(geo.latitude, geo.longitude),
                                      15,
                                    );
                                    FocusScope.of(context).unfocus();
                                  }
                                },
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Details Panel
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
          );
        },
      ),
    );
  }

  Widget _buildDetailsPanel() {
    return Card(
      margin: MediaQuery.of(context).size.width > 600
          ? const EdgeInsets.only(left: 16, bottom: 16)
          : EdgeInsets.zero,
      elevation: 8,
      color: Theme.of(context).cardColor,
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
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Location Details',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleMedium?.color,
                    ),
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
