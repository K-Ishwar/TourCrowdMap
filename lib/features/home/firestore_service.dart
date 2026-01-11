import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getLocations() {
    return _db
        .collection('locations')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Reviews Subcollection
  Stream<QuerySnapshot> getReviews(String locationId) {
    return _db
        .collection('locations')
        .doc(locationId)
        .collection('reviews')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> addReview(
    String locationId,
    String userName,
    double rating,
    String comment,
  ) async {
    await _db
        .collection('locations')
        .doc(locationId)
        .collection('reviews')
        .add({
          'userName': userName,
          'rating': rating,
          'comment': comment,
          'timestamp': FieldValue.serverTimestamp(),
        });
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

  // Generate simulated forecast based on time and category
  Future<List<Map<String, dynamic>>> getForecast(TimeOfDay time) async {
    final snapshot = await _db.collection('locations').get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      final category = (data['category'] as String? ?? '').toLowerCase();

      String predictedLoad = 'Low';
      final hour = time.hour;

      // Heuristic Logic
      if (category == 'historic') {
        if (hour >= 10 && hour <= 17) {
          predictedLoad = 'High';
        } else if (hour > 17 && hour < 20) {
          predictedLoad = 'Moderate';
        }
      } else if (category == 'nature' || category == 'hill station') {
        if (hour >= 6 && hour <= 9) {
          predictedLoad = 'Moderate'; // Morning walkers
        } else if (hour >= 16 && hour <= 19) {
          predictedLoad = 'High'; // Sunset
        }
      } else if (category == 'religious') {
        if (hour >= 8 && hour <= 12) {
          predictedLoad = 'High'; // Morning Aarti
        } else if (hour >= 18 && hour <= 21) {
          predictedLoad = 'High'; // Evening Aarti
        } else {
          predictedLoad = 'Moderate';
        }
      } else if (category == 'fort') {
        if (hour >= 7 && hour <= 11) {
          predictedLoad = 'High'; // Trekkers
        }
      }

      // Create a copy of data with modified crowd level
      final newData = Map<String, dynamic>.from(data);
      newData['crowdLevel'] = predictedLoad;
      newData['id'] = doc.id; // Ensure ID is preserved for logic
      // Also inject the predicted time for UI context if needed
      newData['forecastTime'] =
          '${time.hour}:${time.minute.toString().padLeft(2, '0')}';

      return newData;
    }).toList();
  }

  Future<void> reportCrowd(String id, String level) async {
    // In a real app, we might want to store this in a 'reports' subcollection
    // and use a Cloud Function to aggregate. For now, we trust the user.
    await updateCrowdLevel(id, level);
  }

  Future<void> addLocation(Map<String, dynamic> data) async {
    await _db.collection('locations').add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateLocation(String id, Map<String, dynamic> data) async {
    await _db.collection('locations').doc(id).update({
      ...data,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteLocation(String id) async {
    await _db.collection('locations').doc(id).delete();
  }

  // Seed comprehensive Pune District data
  Future<void> seedPuneData() async {
    final locationsRef = _db.collection('locations');

    // 1. Delete ALL existing documents to prevent duplicates
    final existingDocs = await locationsRef.get();
    final deleteBatch = _db.batch();
    for (var doc in existingDocs.docs) {
      deleteBatch.delete(doc.reference);
    }
    await deleteBatch.commit();

    // 2. Add new data
    final batch = _db.batch();
    final puneLocations = [
      // Historic Places
      {
        'name': 'Shaniwar Wada',
        'category': 'Historic',
        'crowdLevel': 'High',
        'location': const GeoPoint(18.5195, 73.8553),
        'description': 'The seat of the Peshwas of the Maratha Empire.',
        'imageUrl': 'https://picsum.photos/seed/ShaniwarWada/800/600',
      },
      {
        'name': 'Aga Khan Palace',
        'category': 'Historic',
        'crowdLevel': 'Moderate',
        'location': const GeoPoint(18.5524, 73.9015),
        'description':
            'Served as a prison for Mahatma Gandhi during the Freedom struggle.',
        'imageUrl': 'https://picsum.photos/seed/AgaKhanPalace/800/600',
      },
      {
        'name': 'Lal Mahal',
        'category': 'Historic',
        'crowdLevel': 'Moderate',
        'location': const GeoPoint(18.5173, 73.8555),
        'description':
            'Reconstructed 17th-century palace where Shivaji Maharaj lived.',
        'imageUrl': 'https://picsum.photos/seed/LalMahal/800/600',
      },
      {
        'name': 'Shinde Chhatri',
        'category': 'Historic',
        'crowdLevel': 'Low',
        'location': const GeoPoint(18.5020, 73.8967),
        'description':
            'Memorial dedicated to the 18th-century military leader Mahadji Shinde.',
        'imageUrl': 'https://picsum.photos/seed/ShindeChhatri/800/600',
      },
      {
        'name': 'Pataleshwar Cave Temple',
        'category': 'Historic',
        'crowdLevel': 'Low',
        'location': const GeoPoint(18.5276, 73.8436),
        'description': 'Rock-cut cave temple from the 8th century.',
        'imageUrl': 'https://picsum.photos/seed/Pataleshwar/800/600',
      },
      {
        'name': 'Vishrambaug Wada',
        'category': 'Historic',
        'crowdLevel': 'Moderate',
        'location': const GeoPoint(18.5135, 73.8533),
        'description': 'Fine mansion situated at central Pune built in 1807.',
        'imageUrl': 'https://picsum.photos/seed/VishrambaugWada/800/600',
      },
      {
        'name': 'Nana Wada',
        'category': 'Historic',
        'crowdLevel': 'Low',
        'location': const GeoPoint(18.5177, 73.8569),
        'description': 'Wada of Nana Phadnavis, a peshwa minister.',
        'imageUrl': 'https://picsum.photos/seed/NanaWada/800/600',
      },
      {
        'name': 'Tribal Museum',
        'category': 'Historic',
        'crowdLevel': 'Low',
        'location': const GeoPoint(18.5348, 73.8821),
        'description':
            'Dedicated to the culture of tribal communities in Maharashtra.',
        'imageUrl': 'https://picsum.photos/seed/TribalMuseum/800/600',
      },

      // Nature & Scenic Spots
      {
        'name': 'Khadakwasla Dam',
        'category': 'Nature',
        'crowdLevel': 'High',
        'location': const GeoPoint(18.4414, 73.7635),
        'description': 'Popular spot for sunset views and street food.',
        'imageUrl': 'https://picsum.photos/seed/Khadakwasla/800/600',
      },
      {
        'name': 'Mulshi Dam',
        'category': 'Nature',
        'crowdLevel': 'Moderate',
        'location': const GeoPoint(18.5283, 73.4682),
        'description': 'Major dam on the Mula river nestled in the Sahyadris.',
        'imageUrl': 'https://picsum.photos/seed/MulshiDam/800/600',
      },
      {
        'name': 'Pawna Lake',
        'category': 'Nature',
        'crowdLevel': 'High',
        'location': const GeoPoint(18.6657, 73.5041),
        'description': 'Artificial lake known for camping and paragliding.',
        'imageUrl': 'https://picsum.photos/seed/PawnaLake/800/600',
      },
      {
        'name': 'Saras Baug',
        'category': 'Nature',
        'crowdLevel': 'High',
        'location': const GeoPoint(18.5009, 73.8509),
        'description':
            'Landmark garden with a Ganpati temple in the middle of a lake.',
        'imageUrl': 'https://picsum.photos/seed/SarasBaug/800/600',
      },
      {
        'name': 'Vetal Tekdi',
        'category': 'Nature',
        'crowdLevel': 'Moderate',
        'location': const GeoPoint(18.5249, 73.8152),
        'description':
            'The highest point in Pune city limits, popular for morning walks.',
        'imageUrl': 'https://picsum.photos/seed/VetalTekdi/800/600',
      },
      {
        'name': 'Rajiv Gandhi Zoological Park',
        'category': 'Nature',
        'crowdLevel': 'Moderate',
        'location': const GeoPoint(18.4526, 73.8617),
        'description': 'Zoo and snake park located in Katraj.',
        'imageUrl': 'https://picsum.photos/seed/KatrajZoo/800/600',
      },
      {
        'name': 'Panshet Dam',
        'category': 'Nature',
        'crowdLevel': 'Moderate',
        'location': const GeoPoint(18.4087, 73.6121),
        'description': 'Scenic dam offering water sports and boating.',
        'imageUrl': 'https://picsum.photos/seed/Panshet/800/600',
      },
      {
        'name': 'Okayama Friendship Garden',
        'category': 'Nature',
        'crowdLevel': 'Low',
        'location': const GeoPoint(18.4925, 73.8344),
        'description':
            'Japanese style garden, also known as Pu La Deshpande Udyan.',
        'imageUrl': 'https://picsum.photos/seed/OkayamaGarden/800/600',
      },

      // Religious Places
      {
        'name': 'Dagdusheth Halwai Ganpati',
        'category': 'Religious',
        'crowdLevel': 'High',
        'location': const GeoPoint(18.5164, 73.8560),
        'description': 'Famous Ganesh temple visited by thousands of pilgrims.',
        'imageUrl': 'https://picsum.photos/seed/Dagdusheth/800/600',
      },
      {
        'name': 'Bhimashankar',
        'category': 'Religious',
        'crowdLevel': 'Moderate',
        'location': const GeoPoint(19.0725, 73.5358),
        'description': 'A Jyotirlinga shrine located 127 km from Pune.',
        'imageUrl': 'https://picsum.photos/seed/Bhimashankar/800/600',
      },
      {
        'name': 'Jejuri',
        'category': 'Religious',
        'crowdLevel': 'High',
        'location': const GeoPoint(18.2755, 74.1534),
        'description':
            'Main temple of Lord Khandoba, famous for turmeric scattering.',
        'imageUrl': 'https://picsum.photos/seed/Jejuri/800/600',
      },
      {
        'name': 'Alandi',
        'category': 'Religious',
        'crowdLevel': 'Moderate',
        'location': const GeoPoint(18.6750, 73.8968),
        'description': 'Samadhi place of Saint Dnyaneshwar.',
        'imageUrl': 'https://picsum.photos/seed/Alandi/800/600',
      },
      {
        'name': 'Dehu',
        'category': 'Religious',
        'crowdLevel': 'Moderate',
        'location': const GeoPoint(18.7188, 73.7668),
        'description': 'Abode of Saint Tukaram Maharaj.',
        'imageUrl': 'https://picsum.photos/seed/Dehu/800/600',
      },
      {
        'name': 'Chatushrungi Mata Temple',
        'category': 'Religious',
        'crowdLevel': 'Moderate',
        'location': const GeoPoint(18.5385, 73.8320),
        'description': 'Hilltop temple dedicated to Goddess Chatushrungi.',
        'imageUrl': 'https://picsum.photos/seed/Chatushrungi/800/600',
      },
      {
        'name': 'ISKCON NVCC Pune',
        'category': 'Religious',
        'crowdLevel': 'Moderate',
        'location': const GeoPoint(18.4552, 73.8837),
        'description': 'New Vedic Cultural Centre of ISKCON.',
        'imageUrl': 'https://picsum.photos/seed/ISKCONPune/800/600',
      },
      {
        'name': 'Theur (Chintamani)',
        'category': 'Religious',
        'crowdLevel': 'Moderate',
        'location': const GeoPoint(18.5286, 74.0483),
        'description': 'One of the eight Ashtavinayak temples.',
        'imageUrl': 'https://picsum.photos/seed/Theur/800/600',
      },
      {
        'name': 'Morgaon (Mayureshwar)',
        'category': 'Religious',
        'crowdLevel': 'Moderate',
        'location': const GeoPoint(18.2796, 74.3146),
        'description': 'First of the Ashtavinayak temples.',
        'imageUrl': 'https://picsum.photos/seed/Morgaon/800/600',
      },
      {
        'name': 'Ranjangaon (Mahaganapati)',
        'category': 'Religious',
        'crowdLevel': 'High',
        'location': const GeoPoint(18.7562, 74.2443),
        'description': 'Eighth Ashtavinayak temple dedicated to Mahaganapati.',
        'imageUrl': 'https://picsum.photos/seed/Ranjangaon/800/600',
      },
      {
        'name': 'Ozar (Vighnahar)',
        'category': 'Religious',
        'crowdLevel': 'Moderate',
        'location': const GeoPoint(19.1864, 73.9483),
        'description': 'Ashtavinayak temple on the banks of Kukadi River.',
        'imageUrl': 'https://picsum.photos/seed/Ozar/800/600',
      },
      {
        'name': 'Lenyadri (Girijatmaj)',
        'category': 'Religious',
        'crowdLevel': 'Moderate',
        'location': const GeoPoint(19.2435, 73.8863),
        'description': 'Rock-cut Buddhist caves converted to Ganesha temple.',
        'imageUrl': 'https://picsum.photos/seed/Lenyadri/800/600',
      },

      // Forts
      {
        'name': 'Sinhagad Fort',
        'category': 'Fort',
        'crowdLevel': 'High',
        'location': const GeoPoint(18.3663, 73.7559),
        'description': 'Hill fortress known for the Battle of Sinhagad.',
        'imageUrl': 'https://picsum.photos/seed/Sinhagad/800/600',
      },
      {
        'name': 'Shivneri Fort',
        'category': 'Fort',
        'crowdLevel': 'Moderate',
        'location': const GeoPoint(19.2017, 73.8567),
        'description': 'Birthplace of Chhatrapati Shivaji Maharaj.',
        'imageUrl': 'https://picsum.photos/seed/Shivneri/800/600',
      },
      {
        'name': 'Lohagad Fort',
        'category': 'Fort',
        'crowdLevel': 'Moderate',
        'location': const GeoPoint(18.7180, 73.4796),
        'description': 'Iron Fort, part of the Western Ghats.',
        'imageUrl': 'https://picsum.photos/seed/Lohagad/800/600',
      },
      {
        'name': 'Visapur Fort',
        'category': 'Fort',
        'crowdLevel': 'Moderate',
        'location': const GeoPoint(18.7214, 73.4894),
        'description': 'Hill fort near Visapur village.',
        'imageUrl': 'https://picsum.photos/seed/Visapur/800/600',
      },
      {
        'name': 'Torna Fort',
        'category': 'Fort',
        'crowdLevel': 'Moderate',
        'location': const GeoPoint(18.2818, 73.6136),
        'description': 'The first fort captured by Shivaji Maharaj.',
        'imageUrl': 'https://picsum.photos/seed/Torna/800/600',
      },
      {
        'name': 'Rajgad Fort',
        'category': 'Fort',
        'crowdLevel': 'Low',
        'location': const GeoPoint(18.2469, 73.6811),
        'description': 'Former capital of the Maratha Empire.',
        'imageUrl': 'https://picsum.photos/seed/Rajgad/800/600',
      },
      {
        'name': 'Tikona Fort',
        'category': 'Fort',
        'crowdLevel': 'Low',
        'location': const GeoPoint(18.6318, 73.5085),
        'description': 'Dominant hill fortress in Maval.',
        'imageUrl': 'https://picsum.photos/seed/Tikona/800/600',
      },
      {
        'name': 'Tung Fort',
        'category': 'Fort',
        'crowdLevel': 'Low',
        'location': const GeoPoint(18.6534, 73.4589),
        'description': 'Hill fort known for its sharp, conical peak.',
        'imageUrl': 'https://picsum.photos/seed/Tung/800/600',
      },
      {
        'name': 'Korigad Fort',
        'category': 'Fort',
        'crowdLevel': 'Low',
        'location': const GeoPoint(18.6253, 73.3853),
        'description': 'Fort located about 20km south of Lonavala.',
        'imageUrl': 'https://picsum.photos/seed/Korigad/800/600',
      },

      // Hill Stations
      {
        'name': 'Lonavala',
        'category': 'Hill Station',
        'crowdLevel': 'High',
        'location': const GeoPoint(18.7515, 73.4005),
        'description':
            'Famous hill station popular for chikki and monsoon views.',
        'imageUrl': 'https://picsum.photos/seed/Lonavala/800/600',
      },
      {
        'name': 'Khandala',
        'category': 'Hill Station',
        'crowdLevel': 'High',
        'location': const GeoPoint(18.7618, 73.3768),
        'description': 'Hill station nearby Lonavala.',
        'imageUrl': 'https://picsum.photos/seed/Khandala/800/600',
      },
      {
        'name': 'Lavasa',
        'category': 'Hill Station',
        'crowdLevel': 'Moderate',
        'location': const GeoPoint(18.4069, 73.5074),
        'description': 'Private, planned city built near Pune.',
        'imageUrl': 'https://picsum.photos/seed/Lavasa/800/600',
      },
      {
        'name': 'Tamhini Ghat',
        'category': 'Hill Station',
        'crowdLevel': 'Moderate',
        'location': const GeoPoint(18.4485, 73.4182),
        'description':
            'Mountain passage famous for scenic waterfalls in monsoon.',
        'imageUrl': 'https://picsum.photos/seed/Tamhini/800/600',
      },
      {
        'name': 'Malshej Ghat',
        'category': 'Hill Station',
        'crowdLevel': 'Moderate',
        'location': const GeoPoint(19.3396, 73.7742),
        'description': 'Mountain pass in the Western Ghats range.',
        'imageUrl': 'https://picsum.photos/seed/Malshej/800/600',
      },
      {
        'name': 'Bhor',
        'category': 'Hill Station',
        'crowdLevel': 'Low',
        'location': const GeoPoint(18.1504, 73.8450),
        'description':
            'Town with historical significance and film shoot locations.',
        'imageUrl': 'https://picsum.photos/seed/Bhor/800/600',
      },
    ];

    for (var loc in puneLocations) {
      final id = (loc['name'] as String).toLowerCase().replaceAll(' ', '_');
      final docRef = locationsRef.doc(id);
      batch.set(docRef, {
        ...loc,
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Future<void> seedLocations() async {
    await seedPuneData();
  }

  Future<void> simulateLiveUpdates() async {
    final snapshot = await _db.collection('locations').get();
    final random = DateTime.now().millisecondsSinceEpoch;

    // Quick random generator logic
    final levels = ['Low', 'Moderate', 'High'];

    for (var doc in snapshot.docs) {
      // Pick random level
      final newLevel = levels[(random + doc.id.hashCode) % 3];
      await doc.reference.update({
        'crowdLevel': newLevel,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }
  }
}
