import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tour_crowd_map/features/home/firestore_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;

  // Pune Center
  static const CameraPosition _pune = CameraPosition(
    target: LatLng(18.5204, 73.8567),
    zoom: 12.0,
  );

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getLocations(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return const Center(child: Text('Error loading data'));

          final docs = snapshot.data?.docs ?? [];
          final markers = _createMarkersFromDocs(docs);

          return Row(
            children: [
              // List View (Side Panel on Desktop)
              if (isDesktop)
                SizedBox(
                  width: 400,
                  child: _buildSidePanel(context, firestoreService, docs),
                )
              else
                Expanded(
                  child: _buildMobileLayout(
                    context,
                    firestoreService,
                    docs,
                    markers,
                  ),
                ),

              // Map View (On Desktop)
              if (isDesktop)
                Expanded(
                  child: GoogleMap(
                    initialCameraPosition: _pune,
                    markers: markers,
                    onMapCreated: (controller) => _mapController = controller,
                    mapType: MapType.normal,
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (c) => _AddLocationDialog(service: firestoreService),
          );
        },
        child: const Icon(Icons.add_location_alt),
      ),
    );
  }

  Set<Marker> _createMarkersFromDocs(List<QueryDocumentSnapshot> docs) {
    return docs
        .map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final geo = data['location'] as GeoPoint?;

          if (geo == null) return null;

          final crowd = (data['crowdLevel'] as String? ?? 'moderate')
              .toLowerCase();
          double hue;

          if (crowd.contains('low')) {
            hue = BitmapDescriptor.hueGreen;
          } else if (crowd.contains('high')) {
            hue = BitmapDescriptor.hueRed;
          } else {
            hue = BitmapDescriptor.hueYellow; // Moderate/Medium
          }

          return Marker(
            markerId: MarkerId(doc.id),
            position: LatLng(geo.latitude, geo.longitude),
            infoWindow: InfoWindow(
              title: data['name'] ?? 'Unknown',
              snippet:
                  'Crowd: ${data['crowdLevel'] ?? 'N/A'} (Tap for details)',
              onTap: () {
                // Navigate to details
                context.go('/map/${doc.id}');
              },
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          );
        })
        .whereType<Marker>()
        .toSet();
  }

  Widget _buildMobileLayout(
    BuildContext context,
    FirestoreService service,
    List<QueryDocumentSnapshot> docs,
    Set<Marker> markers,
  ) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: _pune,
          markers: markers,
          onMapCreated: (controller) => _mapController = controller,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
        ),
        Positioned(
          bottom: 80,
          right: 16,
          child: FloatingActionButton.small(
            heroTag: 'list_toggle',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (c) => _buildSidePanel(context, service, docs),
              );
            },
            child: const Icon(Icons.list),
          ),
        ),
      ],
    );
  }

  Widget _buildSidePanel(
    BuildContext context,
    FirestoreService firestoreService,
    List<QueryDocumentSnapshot> data,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: const Border(right: BorderSide(color: Colors.grey)),
        color: Colors.white,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search locations...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
          ),
          Expanded(
            child: data.isEmpty
                ? const Center(child: Text('No places found'))
                : ListView.separated(
                    itemCount: data.length,
                    separatorBuilder: (c, i) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final doc = data[index];
                      final map = doc.data() as Map<String, dynamic>;

                      // Determine Color for icon in list too?
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
                        isThreeLine: true,
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: iconColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
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
                              _mapController?.animateCamera(
                                CameraUpdate.newLatLng(
                                  LatLng(geo.latitude, geo.longitude),
                                ),
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextButton.icon(
              onPressed: () async {
                await firestoreService.seedLocations();
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Data Seeded!')));
                }
              },
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Seed Sample Data (Dev Only)'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddLocationDialog extends StatefulWidget {
  final FirestoreService service;
  const _AddLocationDialog({required this.service});

  @override
  State<_AddLocationDialog> createState() => _AddLocationDialogState();
}

class _AddLocationDialogState extends State<_AddLocationDialog> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Location'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Location Name'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descCtrl,
            decoration: const InputDecoration(labelText: 'Description'),
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
            if (_nameCtrl.text.isNotEmpty) {
              widget.service.addLocation(_nameCtrl.text, _descCtrl.text);
              Navigator.pop(context);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
