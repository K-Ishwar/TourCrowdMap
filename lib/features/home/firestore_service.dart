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
      },
      {
        'name': 'Aga Khan Palace',
        'category': 'Historic',
        'crowdLevel': 'Moderate',
        'location': const GeoPoint(18.5524, 73.9015),
        'description':
            'Served as a prison for Mahatma Gandhi during the Freedom struggle.',
      },
      {
        'name': 'Lal Mahal',
        'category': 'Historic',
        'crowdLevel': 'Moderate',
        'location': const GeoPoint(18.5173, 73.8555),
        'description':
            'Reconstructed 17th-century palace where Shivaji Maharaj lived.',
      },
      {
        'name': 'Shinde Chhatri',
        'category': 'Historic',
        'crowdLevel': 'Low',
        'location': const GeoPoint(18.5020, 73.8967),
        'description':
            'Memorial dedicated to the 18th-century military leader Mahadji Shinde.',
      },
      {
        'name': 'Pataleshwar Cave Temple',
        'category': 'Historic',
        'crowdLevel': 'Low',
        'location': const GeoPoint(18.5276, 73.8436),
        'description': 'Rock-cut cave temple from the 8th century.',
      },
      {
        'name': 'Vishrambaug Wada',
        'category': 'Historic',
        'crowdLevel': 'Moderate',
        'location': const GeoPoint(18.5135, 73.8533),
        'description': 'Fine mansion situated at central Pune built in 1807.',
      },
      {
        'name': 'Nana Wada',
        'category': 'Historic',
        'crowdLevel': 'Low',
        'location': const GeoPoint(18.5177, 73.8569),
        'description': 'Wada of Nana Phadnavis, a peshwa minister.',
      },
      {
        'name': 'Tribal Museum',
        'category': 'Historic',
        'crowdLevel': 'Low',
        'location': const GeoPoint(18.5348, 73.8821),
        'description':
            'Dedicated to the culture of tribal communities in Maharashtra.',
      },

      // Nature & Scenic Spots
      {
        'name': 'Khadakwasla Dam',
        'category': 'Nature',
        'crowdLevel': 'High',
        'location': const GeoPoint(18.4414, 73.7635),
        'description': 'Popular spot for sunset views and street food.',
      },
      {
        'name': 'Mulshi Dam',
        'category': 'Nature',
        'crowdLevel': 'Moderate',
        'location': const GeoPoint(18.5283, 73.4682),
        'description': 'Major dam on the Mula river nestled in the Sahyadris.',
      },
      {
        'name': 'Pawna Lake',
        'category': 'Nature',
        'crowdLevel': 'High',
        'location': const GeoPoint(18.6657, 73.5041),
        'description': 'Artificial lake known for camping and paragliding.',
      },
      {
        'name': 'Saras Baug',
        'category': 'Nature',
        'crowdLevel': 'High',
        'location': const GeoPoint(18.5009, 73.8509),
        'description':
            'Landmark garden with a Ganpati temple in the middle of a lake.',
      },
      {
        'name': 'Vetal Tekdi',
        'category': 'Nature',
        'crowdLevel': 'Moderate',
        'location': const GeoPoint(18.5249, 73.8152),
        'description':
            'The highest point in Pune city limits, popular for morning walks.',
      },
      {
        'name': 'Rajiv Gandhi Zoological Park',
        'category': 'Nature',
        'crowdLevel': 'Moderate',
        'location': const GeoPoint(18.4526, 73.8617),
        'description': 'Zoo and snake park located in Katraj.',
      },
      {
        'name': 'Panshet Dam',
        'category': 'Nature',
        'crowdLevel': 'Moderate',
        'location': const GeoPoint(18.4087, 73.6121),
        'description': 'Scenic dam offering water sports and boating.',
      },
      {
        'name': 'Okayama Friendship Garden',
        'category': 'Nature',
        'crowdLevel': 'Low',
        'location': const GeoPoint(18.4925, 73.8344),
        'description':
            'Japanese style garden, also known as Pu La Deshpande Udyan.',
      },

      // Religious Places
      {
        'name': 'Dagdusheth Halwai Ganpati',
        'category': 'Religious',
        'crowdLevel': 'High',
        'location': const GeoPoint(18.5164, 73.8560),
        'description': 'Famous Ganesh temple visited by thousands of pilgrims.',
      },
      {
        'name': 'Bhimashankar',
        'category': 'Religious',
        'crowdLevel': 'Moderate',
        'location': const GeoPoint(19.0725, 73.5358),
        'description': 'A Jyotirlinga shrine located 127 km from Pune.',
      },
      {
        'name': 'Jejuri',
        'category': 'Religious',
        'crowdLevel': 'High',
        'location': const GeoPoint(18.2755, 74.1534),
        'description':
            'Main temple of Lord Khandoba, famous for turmeric scattering.',
      },
      {
        'name': 'Alandi',
        'category': 'Religious',
        'crowdLevel': 'Moderate',
        'location': const GeoPoint(18.6750, 73.8968),
        'description': 'Samadhi place of Saint Dnyaneshwar.',
      },
      {
        'name': 'Dehu',
        'category': 'Religious',
        'crowdLevel': 'Moderate',
        'location': const GeoPoint(18.7188, 73.7668),
        'description': 'Abode of Saint Tukaram Maharaj.',
      },
      {
        'name': 'Chatushrungi Mata Temple',
        'category': 'Religious',
        'crowdLevel': 'Moderate',
        'location': const GeoPoint(18.5385, 73.8320),
        'description': 'Hilltop temple dedicated to Goddess Chatushrungi.',
      },
      {
        'name': 'ISKCON NVCC Pune',
        'category': 'Religious',
        'crowdLevel': 'Moderate',
        'location': const GeoPoint(18.4552, 73.8837),
        'description': 'New Vedic Cultural Centre of ISKCON.',
      },
      {
        'name': 'Theur (Chintamani)',
        'category': 'Religious',
        'crowdLevel': 'Moderate',
        'location': const GeoPoint(18.5286, 74.0483),
        'description': 'One of the eight Ashtavinayak temples.',
      },
      {
        'name': 'Morgaon (Mayureshwar)',
        'category': 'Religious',
        'crowdLevel': 'Moderate',
        'location': const GeoPoint(18.2796, 74.3146),
        'description': 'First of the Ashtavinayak temples.',
      },
      {
        'name': 'Ranjangaon (Mahaganapati)',
        'category': 'Religious',
        'crowdLevel': 'High',
        'location': const GeoPoint(18.7562, 74.2443),
        'description': 'Eighth Ashtavinayak temple dedicated to Mahaganapati.',
      },
      {
        'name': 'Ozar (Vighnahar)',
        'category': 'Religious',
        'crowdLevel': 'Moderate',
        'location': const GeoPoint(19.1864, 73.9483),
        'description': 'Ashtavinayak temple on the banks of Kukadi River.',
      },
      {
        'name': 'Lenyadri (Girijatmaj)',
        'category': 'Religious',
        'crowdLevel': 'Moderate',
        'location': const GeoPoint(19.2435, 73.8863),
        'description': 'Rock-cut Buddhist caves converted to Ganesha temple.',
      },

      // Forts
      {
        'name': 'Sinhagad Fort',
        'category': 'Fort',
        'crowdLevel': 'High',
        'location': const GeoPoint(18.3663, 73.7559),
        'description': 'Hill fortress known for the Battle of Sinhagad.',
      },
      {
        'name': 'Shivneri Fort',
        'category': 'Fort',
        'crowdLevel': 'Moderate',
        'location': const GeoPoint(19.2017, 73.8567),
        'description': 'Birthplace of Chhatrapati Shivaji Maharaj.',
      },
      {
        'name': 'Lohagad Fort',
        'category': 'Fort',
        'crowdLevel': 'Moderate',
        'location': const GeoPoint(18.7180, 73.4796),
        'description': 'Iron Fort, part of the Western Ghats.',
      },
      {
        'name': 'Visapur Fort',
        'category': 'Fort',
        'crowdLevel': 'Moderate',
        'location': const GeoPoint(18.7214, 73.4894),
        'description': 'Hill fort near Visapur village.',
      },
      {
        'name': 'Torna Fort',
        'category': 'Fort',
        'crowdLevel': 'Moderate',
        'location': const GeoPoint(18.2818, 73.6136),
        'description': 'The first fort captured by Shivaji Maharaj.',
      },
      {
        'name': 'Rajgad Fort',
        'category': 'Fort',
        'crowdLevel': 'Low',
        'location': const GeoPoint(18.2469, 73.6811),
        'description': 'Former capital of the Maratha Empire.',
      },
      {
        'name': 'Tikona Fort',
        'category': 'Fort',
        'crowdLevel': 'Low',
        'location': const GeoPoint(18.6318, 73.5085),
        'description': 'Dominant hill fortress in Maval.',
      },
      {
        'name': 'Tung Fort',
        'category': 'Fort',
        'crowdLevel': 'Low',
        'location': const GeoPoint(18.6534, 73.4589),
        'description': 'Hill fort known for its sharp, conical peak.',
      },
      {
        'name': 'Korigad Fort',
        'category': 'Fort',
        'crowdLevel': 'Low',
        'location': const GeoPoint(18.6253, 73.3853),
        'description': 'Fort located about 20km south of Lonavala.',
      },

      // Hill Stations
      {
        'name': 'Lonavala',
        'category': 'Hill Station',
        'crowdLevel': 'High',
        'location': const GeoPoint(18.7515, 73.4005),
        'description':
            'Famous hill station popular for chikki and monsoon views.',
      },
      {
        'name': 'Khandala',
        'category': 'Hill Station',
        'crowdLevel': 'High',
        'location': const GeoPoint(18.7618, 73.3768),
        'description': 'Hill station nearby Lonavala.',
      },
      {
        'name': 'Lavasa',
        'category': 'Hill Station',
        'crowdLevel': 'Moderate',
        'location': const GeoPoint(18.4069, 73.5074),
        'description': 'Private, planned city built near Pune.',
      },
      {
        'name': 'Tamhini Ghat',
        'category': 'Hill Station',
        'crowdLevel': 'Moderate',
        'location': const GeoPoint(18.4485, 73.4182),
        'description':
            'Mountain passage famous for scenic waterfalls in monsoon.',
      },
      {
        'name': 'Malshej Ghat',
        'category': 'Hill Station',
        'crowdLevel': 'Moderate',
        'location': const GeoPoint(19.3396, 73.7742),
        'description': 'Mountain pass in the Western Ghats range.',
      },
      {
        'name': 'Bhor',
        'category': 'Hill Station',
        'crowdLevel': 'Low',
        'location': const GeoPoint(18.1504, 73.8450),
        'description':
            'Town with historical significance and film shoot locations.',
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
