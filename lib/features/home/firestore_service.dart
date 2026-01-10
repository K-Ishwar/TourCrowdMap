import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getLocations() {
    return _db
        .collection('locations')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<DocumentSnapshot> getLocationById(String id) {
    return _db.collection('locations').doc(id).snapshots();
  }

  Future<void> updateCrowdLevel(String id, String newLevel) async {
    await _db.collection('locations').doc(id).update({
      'crowdLevel': newLevel,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addLocation(String name, String description) async {
    await _db.collection('locations').add({
      'name': name,
      'description': description,
      'crowdLevel': 'moderate',
      'bestTimeToVisit': 'Morning',
      'createdAt': FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  Future<void> seedLocations() async {
    final List<Map<String, dynamic>> puneLocations = [
      {
        'name': 'Shaniwar Wada',
        'description': 'Historical fortification in the city of Pune.',
        'crowdLevel': 'High',
        'bestTimeToVisit': 'Morning (9 AM - 11 AM)',
        'location': const GeoPoint(18.5196, 73.8554),
      },
      {
        'name': 'Sinhagad Fort',
        'description':
            'A hill fortress located to the southwest of the city of Pune.',
        'crowdLevel': 'Moderate',
        'bestTimeToVisit': 'Monsoon or Winter Mornings',
        'location': const GeoPoint(18.3663, 73.7559),
      },
      {
        'name': 'Aga Khan Palace',
        'description': 'Built by Sultan Muhammed Shah Aga Khan III in Pune.',
        'crowdLevel': 'Low',
        'bestTimeToVisit': 'Afternoon (3 PM - 5 PM)',
        'location': const GeoPoint(18.5524, 73.9015),
      },
      {
        'name': 'Dagdusheth Halwai Ganpati',
        'description': 'A Hindu God Ganesh temple in Pune.',
        'crowdLevel': 'Very High',
        'bestTimeToVisit': 'Early Morning (6 AM - 8 AM)',
        'location': const GeoPoint(18.5163, 73.8561),
      },
      {
        'name': 'Katraj Zoo',
        'description': 'Rajiv Gandhi Zoological Park.',
        'crowdLevel': 'High',
        'bestTimeToVisit': 'Morning (10 AM)',
        'location': const GeoPoint(18.4529, 73.8589),
      },
      {
        'name': 'PL Deshpande Garden',
        'description': 'Okayama Friendship Garden.',
        'crowdLevel': 'Moderate',
        'bestTimeToVisit': 'Evening (5 PM)',
        'location': const GeoPoint(18.4908, 73.8341),
      },
      {
        'name': 'Parvati Hill',
        'description':
            'Hillock with temples, one of the most scenic locations in Pune.',
        'crowdLevel': 'Low',
        'bestTimeToVisit': 'Sunrise or Sunset',
        'location': const GeoPoint(18.4965, 73.8468),
      },
      {
        'name': 'Taljai Tekdi',
        'description': 'A hill and wildlife reserve.',
        'crowdLevel': 'Moderate',
        'bestTimeToVisit': 'Morning (6 AM - 9 AM)',
        'location': const GeoPoint(18.4870, 73.8480),
      },
    ];

    final batch = _db.batch();
    for (var loc in puneLocations) {
      final docRef = _db.collection('locations').doc();
      batch.set(docRef, {
        ...loc,
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
}
