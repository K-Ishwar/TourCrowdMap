import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:tour_crowd_map/features/home/firestore_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isAuthenticated = false;
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  int _selectedIndex = 0;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void dispose() {
    _idController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return _buildLoginScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Authority Command Center'),
        backgroundColor: Colors.blueGrey.shade900,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: 'Return to App',
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            backgroundColor: Colors.blueGrey.shade50,
            indicatorColor: Colors.blueAccent.withValues(alpha: 0.2),
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Monitor'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.pie_chart_outline),
                selectedIcon: Icon(Icons.pie_chart),
                label: Text('Analytics'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.place_outlined),
                selectedIcon: Icon(Icons.place),
                label: Text('Places'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Config'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: Container(color: Colors.white, child: _buildCurrentTab()),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginScreen() {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade900,
      body: Center(
        child: SingleChildScrollView(
          child: Card(
            margin: const EdgeInsets.all(24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: 400,
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.security, size: 64, color: Colors.blueGrey),
                  const SizedBox(height: 24),
                  Text(
                    'Admin Access',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey.shade800,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _idController,
                    decoration: const InputDecoration(
                      labelText: 'Admin ID',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    onSubmitted: (_) => _attemptLogin(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _attemptLogin,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Login'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.go('/'),
                    child: const Text('Return to Home'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _attemptLogin() {
    if (_idController.text.trim() == 'Admin' &&
        _passController.text == 'Sonu Don') {
      setState(() {
        _isAuthenticated = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Invalid Credentials'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildCurrentTab() {
    switch (_selectedIndex) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return _buildAnalyticsTab();
      case 2:
        return _buildPlacesTab();
      case 3:
        return _buildSettingsTab();
      default:
        return _buildOverviewTab();
    }
  }

  // --- TAB 1: OVERVIEW (Monitor) - Compact Layout ---
  Widget _buildOverviewTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Compact Header & Stats
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.blueGrey.shade50,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Live Monitor',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey.shade800,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, color: Colors.green, size: 8),
                        const SizedBox(width: 4),
                        Text(
                          'Online',
                          style: TextStyle(
                            color: Colors.green.shade800,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Compact Stats Row
              StreamBuilder<QuerySnapshot>(
                stream: _firestoreService.getLocations(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox();
                  final docs = snapshot.data!.docs;
                  final highCount = docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    return (data['crowdLevel'] as String? ?? '')
                        .toLowerCase()
                        .contains('high');
                  }).length;
                  final modCount = docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    return (data['crowdLevel'] as String? ?? '')
                        .toLowerCase()
                        .contains('moderate');
                  }).length;

                  return Row(
                    children: [
                      Expanded(
                        child: _CompactStatCard(
                          'Total',
                          '${docs.length}',
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _CompactStatCard(
                          'Moderate',
                          '$modCount',
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _CompactStatCard(
                          'Critical',
                          '$highCount',
                          Colors.red,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),

        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Live Alerts Feed',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
        ),

        // Expanded Alerts List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestoreService.getLocations(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data?.docs ?? [];
              final alerts = docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final crowd = (data['crowdLevel'] as String? ?? '')
                    .toLowerCase();
                return crowd.contains('high');
              }).toList();

              if (alerts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 48,
                        color: Colors.green.shade200,
                      ),
                      const SizedBox(height: 8),
                      const Text('No critical alerts currently active.'),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: alerts.length,
                itemBuilder: (context, index) {
                  final doc = alerts[index];
                  final data = doc.data() as Map<String, dynamic>;

                  return Card(
                    elevation: 1,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.red.shade100),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      leading: const Icon(
                        Icons.warning_amber,
                        color: Colors.red,
                      ),
                      title: Text(
                        data['name'] ?? 'Unknown',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Capacity limits reached! Current: ${data['crowdLevel']}',
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                      trailing: ElevatedButton(
                        onPressed: () => context.push('/map/${doc.id}'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade50,
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          minimumSize: const Size(60, 32),
                        ),
                        child: const Text(
                          'View',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ).animate().fadeIn().slideX();
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // --- TAB 2: ANALYTICS - Real Pie Chart ---
  Widget _buildAnalyticsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'Real-time Crowd Distribution',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestoreService.getLocations(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;
              int high = 0;
              int mod = 0;
              int low = 0;

              for (var doc in docs) {
                final data = doc.data() as Map<String, dynamic>;
                final level = (data['crowdLevel'] as String? ?? '')
                    .toLowerCase();
                if (level.contains('high')) {
                  high++;
                } else if (level.contains('moderate')) {
                  mod++;
                } else {
                  low++;
                }
              }

              if (docs.isEmpty) {
                return const Center(child: Text('No data available'));
              }

              return Row(
                children: [
                  // Chart
                  Expanded(
                    flex: 2,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: [
                          PieChartSectionData(
                            color: Colors.green,
                            value: low.toDouble(),
                            title: '$low',
                            radius: 50,
                            titleStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            color: Colors.orange,
                            value: mod.toDouble(),
                            title: '$mod',
                            radius: 60,
                            titleStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            color: Colors.red,
                            value: high.toDouble(),
                            title: '$high',
                            radius: 70,
                            titleStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Legend
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _LegendItem(
                          color: Colors.red,
                          text: 'High Traffic ($high)',
                        ),
                        const SizedBox(height: 12),
                        _LegendItem(
                          color: Colors.orange,
                          text: 'Moderate ($mod)',
                        ),
                        const SizedBox(height: 12),
                        _LegendItem(
                          color: Colors.green,
                          text: 'Low / Normal ($low)',
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // --- TAB 3: PLACES - Working CRUD ---
  Widget _buildPlacesTab() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showLocationDialog(context);
        },
        label: const Text('Add Place'),
        icon: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getLocations(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: NetworkImage(
                      data['imageUrl'] ?? 'https://via.placeholder.com/150',
                    ),
                    onBackgroundImageError: (exception, stackTrace) {},
                  ),
                  title: Text(data['name'] ?? 'No Name'),
                  subtitle: Text(
                    '${data['category']} • Cap: ${data['maxCapacity'] ?? "N/A"}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showLocationDialog(context, doc: doc),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          // Confirm Delete
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Place?'),
                              content: Text(
                                'Are you sure you want to delete "${data['name']}"?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    _firestoreService.deleteLocation(doc.id);
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Deleted successfully'),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- TAB 4: SETTINGS ---
  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'System Configuration',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 24),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.tune, color: Colors.blueGrey),
                    SizedBox(width: 12),
                    Text(
                      'Crowd Thresholds',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Divider(height: 32),
                Text(
                  'Define the capacity percentage that triggers alert levels.',
                ),
                SizedBox(height: 24),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Moderate > (%)',
                    border: OutlineInputBorder(),
                    hintText: '50',
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'High > (%)',
                    border: OutlineInputBorder(),
                    hintText: '80',
                  ),
                ),
                SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: null,
                    child: Text('Save Changes'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Helper Functions
  void _showLocationDialog(
    BuildContext context, {
    DocumentSnapshot? doc,
  }) async {
    final isEdit = doc != null;
    final data = isEdit ? doc.data() as Map<String, dynamic> : {};

    final nameController = TextEditingController(text: data['name'] ?? '');
    final categoryController = TextEditingController(
      text: data['category'] ?? '',
    );
    final imgController = TextEditingController(text: data['imageUrl'] ?? '');
    final descController = TextEditingController(
      text: data['description'] ?? '',
    );
    final capController = TextEditingController(
      text: (data['maxCapacity'] ?? '').toString(),
    );

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Edit Location' : 'Add New Location'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category (Historic, Nature, etc.)',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: capController,
                decoration: const InputDecoration(labelText: 'Max Capacity'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: imgController,
                decoration: const InputDecoration(labelText: 'Image URL'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final newData = {
                'name': nameController.text,
                'category': categoryController.text,
                'maxCapacity': int.tryParse(capController.text) ?? 1000,
                'imageUrl': imgController.text,
                'description': descController.text,
                'crowdLevel':
                    data['crowdLevel'] ?? 'Low', // Preserve or default
              };

              if (isEdit) {
                _firestoreService.updateLocation(doc.id, newData);
              } else {
                _firestoreService.addLocation(newData);
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isEdit ? 'Updated' : 'Added successfully'),
                ),
              );
            },
            child: Text(isEdit ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }
}

class _CompactStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _CompactStatCard(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;
  const _LegendItem({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 16, height: 16, color: color),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
