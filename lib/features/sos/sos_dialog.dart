import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

class SOSDialog extends StatelessWidget {
  const SOSDialog({super.key});

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      // In a real app we'd show an error
      debugPrint('Could not launch $phoneNumber');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.red.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 60,
              color: Colors.red,
            ).animate(onPlay: (c) => c.repeat()).shake(duration: 1000.ms),
            const SizedBox(height: 16),
            const Text(
              'EMERGENCY SOS',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Help is on the way. Tap to call immediately.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 24),

            // Buttons
            _buildSOSButton(
              context,
              label: 'POLICE (100)',
              icon: Icons.local_police,
              color: Colors.blue.shade800,
              onTap: () => _makePhoneCall('100'),
            ),
            const SizedBox(height: 12),
            _buildSOSButton(
              context,
              label: 'AMBULANCE (108)',
              icon: Icons.medical_services,
              color: Colors.red.shade700,
              onTap: () => _makePhoneCall('108'),
            ),
            const SizedBox(height: 12),
            _buildSOSButton(
              context,
              label: 'SHARE LIVE LOCATION',
              icon: Icons.share_location,
              color: Colors.green.shade700,
              onTap: () {
                // Mock Action
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Location shared with emergency contacts!'),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSOSButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
