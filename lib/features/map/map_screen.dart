import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:tour_crowd_map/features/details/location_details_screen.dart';
import 'package:tour_crowd_map/features/home/firestore_service.dart';
import 'package:tour_crowd_map/features/chatbot/chat_screen.dart';
import 'package:tour_crowd_map/features/sos/sos_dialog.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final FirestoreService _firestoreService = FirestoreService();
  bool _showHeatmap = false;
  LatLng? _currentLocation; // My Location

  // State for search and selection
  final String _searchQuery = '';
  String? _selectedLocationId;
  final TextEditingController _searchController = TextEditingController();

  // Forecast State
  bool _showForecast = false;
  double _forecastHour = 10.0;
  List<Map<String, dynamic>> _forecastData = [];
  bool _isLoadingForecast = false;

  // Amenities & Layers State
  bool _showAmenities = false;
  String _currentMapStyle = 'default'; // 'default', 'satellite'
  bool _showTransport = false;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    // Get position with high accuracy
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  // Removed duplicate _updateForecast definition from here.
  // It is correctly defined further down using getForecastForHour if applicable or via getForecast.
  // Wait, the one below used `getForecastForHour` which is WRONG. This one uses `getForecast`.
  // So I should actually KEEP this one (lines 34-45) and remove the other one.
  // But wait, the bottom one was the one I saw in the error message as "already defined".
  // Let's keep THIS one (lines 34-45) and remove the other one.
  Future<void> _updateForecast() async {
    setState(() => _isLoadingForecast = true);
    final data = await _firestoreService.getForecast(
      TimeOfDay(hour: _forecastHour.round(), minute: 0),
    );
    if (mounted) {
      setState(() {
        _forecastData = data;
        _isLoadingForecast =
            false; // Fixed type error (was assigning to List previously? No, just logic)
      });
    }
  }

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
  bool _isToolsOpen = false;

  // Method to update forecast data
  // Removed duplicate/incorrect _updateForecast method.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getLocations(),
        builder: (context, snapshot) {
          // Unified Data Source Logic
          // We convert everything to a List of Maps to handle both Live (Stream) and Forecast (Future) data uniformally.
          List<Map<String, dynamic>> allLocationsData = [];

          if (_showForecast) {
            allLocationsData = _forecastData;
          } else {
            final docs = snapshot.data?.docs ?? [];
            allLocationsData = docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return {...data, 'id': doc.id};
            }).toList();
          }

          // 1. Filter Logic
          final filteredLocations = allLocationsData.where((data) {
            final name = (data['name'] as String? ?? '').toLowerCase();
            final category = (data['category'] as String? ?? '');

            bool matchesSearch =
                _searchController.text.isEmpty ||
                name.contains(_searchController.text.toLowerCase());
            bool matchesCategory =
                _selectedCategory == null || category == _selectedCategory;

            return matchesSearch && matchesCategory;
          }).toList();

          // 2. Marker Visibility Logic
          final markers = <Marker>[];

          for (var data in filteredLocations) {
            final geo = data['location'] as GeoPoint?;
            final crowd = data['crowdLevel'] as String? ?? 'Unknown';
            final id = data['id'] as String;
            final name = data['name'] as String? ?? '';

            if (geo == null) continue;

            // Main Location Marker Logic
            final isSelected = _selectedLocationId == id;
            final isFiltering =
                _searchQuery.isNotEmpty || _selectedCategory != null;

            // Show main marker if selected, filtering, or any "Layer" is active
            bool showMainMarker =
                isSelected || isFiltering || _showHeatmap || _showForecast;
            // Note: Original logic hid markers by default to keep map clean.
            // If NO layers are active and NOT searching/selecting, we skip main marker

            if (showMainMarker) {
              Color color = Colors.grey;
              if (crowd.toLowerCase().contains('low')) {
                color = Colors.green;
              } else if (crowd.toLowerCase().contains('moderate')) {
                color = Colors.orange;
              } else if (crowd.toLowerCase().contains('high')) {
                color = Colors.red;
              }

              Color borderColor = isSelected
                  ? Colors.blue
                  : Theme.of(context).dividerColor;
              double borderWidth = isSelected ? 3 : 2;

              if (_showHeatmap || isSelected || _showForecast) {
                if (crowd.toLowerCase().contains('low')) {
                  borderColor = Colors.green;
                  color = Colors.green;
                } else if (crowd.toLowerCase().contains('moderate')) {
                  borderColor = Colors.orange;
                  color = Colors.orange;
                } else if (crowd.toLowerCase().contains('high')) {
                  borderColor = Colors.red;
                  color = Colors.red;
                }
              }

              markers.add(
                Marker(
                  point: LatLng(geo.latitude, geo.longitude),
                  width: 120,
                  height: 90,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedLocationId = id;
                          });
                          _mapController.move(
                            LatLng(geo.latitude, geo.longitude),
                            15,
                          );
                          FocusScope.of(context).unfocus();
                        },
                        child: AnimatedContainer(
                          duration: 300.ms,
                          width: isSelected ? 48 : 36,
                          height: isSelected ? 48 : 36,
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: borderColor,
                              width: borderWidth,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: borderColor.withValues(alpha: 0.4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.location_on,
                            color: color,
                            size: isSelected ? 30 : 20,
                          ),
                        ),
                      ),
                      if (showMainMarker)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).cardColor.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: borderColor.withValues(alpha: 0.5),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(
                                context,
                              ).textTheme.bodySmall?.color,
                            ),
                            maxLines: 1,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }

            // Amenities Markers (Simulated near the location)
            if (_showAmenities) {
              // 1. Parking (North East)
              markers.add(
                Marker(
                  point: LatLng(geo.latitude + 0.0005, geo.longitude + 0.0005),
                  width: 30,
                  height: 30,
                  child: const Icon(
                    Icons.local_parking,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
              );
              // 2. Cafe (South East)
              markers.add(
                Marker(
                  point: LatLng(geo.latitude - 0.0005, geo.longitude + 0.0005),
                  width: 30,
                  height: 30,
                  child: const Icon(
                    Icons.local_cafe,
                    color: Colors.brown,
                    size: 24,
                  ),
                ),
              );
              // 3. Restroom (North West)
              markers.add(
                Marker(
                  point: LatLng(geo.latitude + 0.0005, geo.longitude - 0.0005),
                  width: 30,
                  height: 30,
                  child: const Icon(Icons.wc, color: Colors.cyan, size: 24),
                ),
              );
            }

            // Transport Markers (Simulated)
            if (_showTransport) {
              markers.add(
                Marker(
                  point: LatLng(geo.latitude + 0.001, geo.longitude + 0.001),
                  width: 30,
                  height: 30,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(blurRadius: 2, color: Colors.black26),
                      ],
                    ),
                    child: const Icon(
                      Icons.directions_bus,
                      color: Colors.indigo,
                      size: 20,
                    ),
                  ),
                ),
              );
            }

            // Current Location Marker
            if (_currentLocation != null) {
              markers.add(
                Marker(
                  point: _currentLocation!,
                  width: 40,
                  height: 40,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.my_location,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              );
            }
          }

          return Stack(
            children: [
              // Map Layer
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: const LatLng(18.5204, 73.8567), // Pune
                  initialZoom: 11.0,
                  onTap: (tapPosition, point) {
                    if (_selectedLocationId != null) {
                      setState(() => _selectedLocationId = null);
                    }
                    FocusScope.of(context).unfocus();
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: _currentMapStyle == 'satellite'
                        ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.tour_crowd_map',
                    tileProvider: NetworkTileProvider(),
                  ),
                  // Removed confusing CircleLayer
                  MarkerLayer(markers: markers),
                ],
              ),

              // Layers Menu (Top Right)
              Positioned(
                top: 16,
                right: 16,
                child: FloatingActionButton.small(
                  heroTag: 'layers_menu_top',
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  tooltip: 'Map Layers',
                  onPressed: () => _showLayersMenu(context),
                  child: const Icon(Icons.layers),
                ),
              ),

              // Persistent Search Bar & SOS (Compact)
              Positioned(
                top: 40,
                left: 16,
                width: 320,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 16),
                                const Icon(Icons.search, color: Colors.grey),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    decoration: const InputDecoration(
                                      hintText: 'Search...',
                                      border: InputBorder.none,
                                    ),
                                    onChanged: (val) => setState(() {}),
                                  ),
                                ),
                                if (_searchController.text.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () => setState(
                                      () => _searchController.clear(),
                                    ),
                                  ),
                                const SizedBox(width: 8),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // SOS Button
                        FloatingActionButton(
                          heroTag: 'sos_fab_top',
                          backgroundColor: Colors.red,
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => const SOSDialog(),
                            );
                          },
                          child: const Text(
                            'SOS',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ).animate().shake(
                          delay: 2.seconds,
                          duration: 1.seconds,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Filter Dropdown (Separate Pill)
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          hint: const Text('Filter by Category'),
                          isExpanded: true,
                          icon: const Icon(
                            Icons.filter_list,
                            color: Colors.indigo,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          onChanged: (val) =>
                              setState(() => _selectedCategory = val),
                          items:
                              [
                                'All Categories',
                                'Historic',
                                'Nature',
                                'Religious',
                                'Fort',
                                'Hill Station',
                              ].map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value == 'All Categories'
                                      ? null
                                      : value,
                                  child: Text(
                                    value,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Persistent "Live Low Crowd" Insights Card (Hide during Forecast)
              if (!_showForecast)
                Positioned(
                  bottom: 32,
                  left: 16,
                  width: 300,
                  child: Builder(
                    builder: (context) {
                      final lowCrowdLocations = allLocationsData.where((data) {
                        final crowd = (data['crowdLevel'] as String? ?? '')
                            .toLowerCase();
                        return crowd.contains('low');
                      }).toList();

                      if (lowCrowdLocations.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return Card(
                        elevation: 8,
                        color: Theme.of(
                          context,
                        ).cardColor.withValues(alpha: 0.95),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.nature_people,
                                    color: Colors.green,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Peaceful Spots Now',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${lowCrowdLocations.length} found',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 180),
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: lowCrowdLocations.length,
                                itemBuilder: (context, index) {
                                  final data = lowCrowdLocations[index];
                                  final geo = data['location'] as GeoPoint;

                                  return ListTile(
                                    dense: true,
                                    visualDensity: VisualDensity.compact,
                                    title: Text(
                                      data['name'] ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: const Text(
                                      'Low Crowd',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.green,
                                      ),
                                    ),
                                    trailing: const Icon(
                                      Icons.directions,
                                      size: 16,
                                      color: Colors.blue,
                                    ),
                                    onTap: () {
                                      _mapController.move(
                                        LatLng(geo.latitude, geo.longitude),
                                        15,
                                      );
                                      setState(() {
                                        _selectedLocationId = data['id'];
                                        // Auto-show heatmap for context
                                        _showHeatmap = true;
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

              // Search Results (Moved to Bottom to be ON TOP of Z-Index)
              if (_searchController.text.isNotEmpty)
                Positioned(
                  top: 150, // Below Search + SOS + Filter
                  left: 16,
                  width: 320,
                  child: Card(
                    elevation: 4,
                    color: Theme.of(context).cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: filteredLocations.length,
                        itemBuilder: (context, index) {
                          final data = filteredLocations[index];
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
                            onTap: () {
                              if (geo != null) {
                                setState(() {
                                  _selectedLocationId = data['id'];
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
                ),

              // Tools Speed Dial (Replaces Cluttered Admin Column)
              Positioned(
                bottom: 32,
                right: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Location Button (Always Visible, separate)
                    if (_currentLocation != null) ...[
                      FloatingActionButton.small(
                        heroTag: 'my_location_btn',
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onPressed: () {
                          _mapController.move(_currentLocation!, 15);
                        },
                        child: const Icon(Icons.my_location),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Speed Dial Options
                    if (_isToolsOpen) ...[
                      // Admin
                      FloatingActionButton.small(
                            heroTag: 'admin_fab',
                            backgroundColor: Colors.blueGrey.shade800,
                            foregroundColor: Colors.white,
                            tooltip: 'Admin Panel',
                            onPressed: () => context.push('/admin'),
                            child: const Icon(Icons.security),
                          )
                          .animate()
                          .slideY(begin: 1.0, end: 0, duration: 200.ms)
                          .fadeIn(),
                      const SizedBox(height: 12),

                      // Simulate (Dev)
                      FloatingActionButton.small(
                            heroTag: 'simulate_fab',
                            backgroundColor: Colors.orange.shade800,
                            foregroundColor: Colors.white,
                            tooltip: 'Simulate Live Updates',
                            onPressed: () {
                              _firestoreService.simulateLiveUpdates();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('⚡ Simulating crowd surge...'),
                                ),
                              );
                            },
                            child: const Icon(Icons.bolt),
                          )
                          .animate()
                          .slideY(begin: 1.0, end: 0, duration: 250.ms)
                          .fadeIn(),
                      const SizedBox(height: 12),

                      // Forecast Toggle
                      FloatingActionButton.small(
                            heroTag: 'forecast_fab',
                            backgroundColor: _showForecast
                                ? Colors.deepPurpleAccent
                                : Colors.white,
                            foregroundColor: _showForecast
                                ? Colors.white
                                : Colors.deepPurple,
                            tooltip: 'Crowd Forecast',
                            onPressed: () {
                              setState(() {
                                _showForecast = !_showForecast;
                                if (_showForecast) {
                                  _showHeatmap = true;
                                  _updateForecast();
                                } else {
                                  _showHeatmap = false;
                                }
                              });
                            },
                            child: const Icon(Icons.query_stats),
                          )
                          .animate()
                          .slideY(begin: 1.0, end: 0, duration: 300.ms)
                          .fadeIn(),
                      const SizedBox(height: 12),

                      // Planner
                      FloatingActionButton.small(
                            heroTag: 'planner_fab',
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.indigo,
                            tooltip: 'Itinerary Planner',
                            onPressed: () => context.push('/planner'),
                            child: const Icon(Icons.route),
                          )
                          .animate()
                          .slideY(begin: 1.0, end: 0, duration: 350.ms)
                          .fadeIn(),
                      const SizedBox(height: 12),

                      // Chat Bot
                      FloatingActionButton.small(
                            heroTag: 'chat_fab',
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blue,
                            tooltip: 'Tour Assistant',
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.7,
                                  child: const ChatScreen(),
                                ),
                              );
                            },
                            child: const Icon(Icons.chat_bubble_outline),
                          )
                          .animate()
                          .slideY(begin: 1.0, end: 0, duration: 400.ms)
                          .fadeIn(),
                      const SizedBox(height: 12),
                    ],

                    // Main Toggle Button
                    FloatingActionButton(
                      heroTag: 'tools_menu_toggle',
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      onPressed: () {
                        setState(() {
                          _isToolsOpen = !_isToolsOpen;
                        });
                      },
                      child: Icon(
                        _isToolsOpen ? Icons.close : Icons.grid_view_rounded,
                      ),
                    ).animate().rotate(
                      begin: 0,
                      end: _isToolsOpen ? 0.25 : 0,
                      alignment: Alignment.center,
                    ),
                  ],
                ),
              ),

              // Forecast Slider Card
              if (_showForecast)
                Positioned(
                  bottom: 24,
                  left: 16,
                  right: 16,
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 500),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.psychology,
                                    color: Colors.deepPurple,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Crowd Prediction',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.deepPurple,
                                        ),
                                  ),
                                ],
                              ),
                              Text(
                                '${_forecastHour.round()}:00',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_isLoadingForecast)
                            const LinearProgressIndicator()
                          else
                            Slider(
                              value: _forecastHour,
                              min: 6,
                              max: 22,
                              divisions: 16,
                              label: '${_forecastHour.round()}:00',
                              activeColor: Colors.deepPurple,
                              onChanged: (value) {
                                setState(() {
                                  _forecastHour = value;
                                });
                              },
                              onChangeEnd: (value) {
                                _updateForecast(); // Fetch new data logic on release
                              },
                            ),
                          const Text(
                            'Drag to see predicted crowds at different times',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
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

  void _showLayersMenu(BuildContext menuContext) {
    showModalBottomSheet(
      context: menuContext,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext innerContext, StateSetter setSheetState) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(innerContext).cardColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Map Type',
                      style: Theme.of(innerContext).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _MapTypeCard(
                            label: 'Default',
                            icon: Icons.map,
                            isSelected: _currentMapStyle == 'default',
                            onTap: () {
                              setSheetState(() => _currentMapStyle = 'default');
                              setState(() => _currentMapStyle = 'default');
                              Navigator.pop(innerContext);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MapTypeCard(
                            label: 'Satellite',
                            icon: Icons.satellite_alt,
                            isSelected: _currentMapStyle == 'satellite',
                            onTap: () {
                              setSheetState(
                                () => _currentMapStyle = 'satellite',
                              );
                              setState(() => _currentMapStyle = 'satellite');
                              Navigator.pop(innerContext);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Map Details',
                      style: Theme.of(innerContext).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('Crowd Heatmap'),
                      secondary: const Icon(Icons.layers, color: Colors.blue),
                      value: _showHeatmap,
                      onChanged: (val) {
                        setSheetState(() => _showHeatmap = val);
                        setState(() => _showHeatmap = val);
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Nearby Amenities'),
                      secondary: const Icon(
                        Icons.storefront,
                        color: Colors.teal,
                      ),
                      value: _showAmenities,
                      onChanged: (val) {
                        setSheetState(() => _showAmenities = val);
                        setState(() => _showAmenities = val);
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Public Transport'),
                      secondary: const Icon(
                        Icons.directions_bus,
                        color: Colors.indigo,
                      ),
                      value: _showTransport,
                      onChanged: (val) {
                        setSheetState(() => _showTransport = val);
                        setState(() => _showTransport = val);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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

class _MapTypeCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _MapTypeCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.blue : Colors.grey),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.blue : Colors.grey.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
