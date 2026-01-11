import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Context Memory
  String? _lastContextPlaceName;

  Future<String> getResponse(String message) async {
    final lowerMsg = message.toLowerCase().trim();

    // 0. Update Context if a location is explicitly named
    final detectedLocation = await _findBestMatchLocation(lowerMsg);
    if (detectedLocation != null) {
      final data = detectedLocation.data() as Map<String, dynamic>;
      _lastContextPlaceName = data['name'];
    }

    // 1. Small Talk & Personality
    if (_isGreeting(lowerMsg)) {
      return _getRandomGreeting();
    }
    if (lowerMsg.contains('how are you')) {
      return "I'm purely digital, but feeling **100% operational**! 🚀 Ready to explore Pune?";
    }
    if (lowerMsg.contains('bad') ||
        lowerMsg.contains('stupid') ||
        lowerMsg.contains('dumb')) {
      return "Ouch! 🤖 I'm still learning. Try searching for specific places by name!";
    }

    // 2. Crowd / Status Query
    if (lowerMsg.contains('crowd') ||
        lowerMsg.contains('busy') ||
        lowerMsg.contains('rush')) {
      return await _handleCrowdQuery(detectedLocation);
    }

    // 3. Best Time / Visiting Hours
    if (lowerMsg.contains('time') ||
        lowerMsg.contains('open') ||
        lowerMsg.contains('when') ||
        lowerMsg.contains('tomorrow')) {
      return await _handleTimeQuery(detectedLocation);
    }

    // 3b. Affirmative Context (e.g. "Yes" response to "Do you want to know best time?")
    if (lowerMsg == 'yes' ||
        lowerMsg == 'sure' ||
        lowerMsg.contains('yes please') ||
        lowerMsg.contains('yes for tomorrow')) {
      if (_lastContextPlaceName != null) {
        return await _handleTimeQuery(null);
      }
    }

    // 4. "Where is" / Location Query
    if (lowerMsg.contains('where') ||
        lowerMsg.contains('location') ||
        lowerMsg.contains('navigate')) {
      return await _handleLocationQuery(detectedLocation);
    }

    // 5. Category / Vibe Matching
    if (lowerMsg.contains('sunset')) {
      return await _suggestPlace(category: 'Nature', vibe: 'sunset');
    }
    if (lowerMsg.contains('trek') || lowerMsg.contains('fort')) {
      return await _suggestPlace(category: 'Fort');
    }
    if (lowerMsg.contains('history') || lowerMsg.contains('museum')) {
      return await _suggestPlace(category: 'Museum');
    }
    if (lowerMsg.contains('peace') ||
        lowerMsg.contains('quiet') ||
        lowerMsg.contains('calm')) {
      return await _suggestPlace(constraint: 'Low Crowd');
    }
    if (lowerMsg.contains('food') || lowerMsg.contains('cafe')) {
      return "Check out the **Core Area** of Pune for legendary cafes like Goodluck or Vohuman! ☕";
    }

    // 6. Direct Location Mention (General Info) - If they just say "Shaniwar Wada"
    if (detectedLocation != null) {
      final data = detectedLocation.data() as Map<String, dynamic>;
      return "Ah, **${data['name']}**! It's a ${data['category'] ?? 'great spot'}. The crowd is currently **${data['crowdLevel']}**. Do you want to know the best time to visit?";
    }

    // 7. Fallback Smart Suggestions
    if (lowerMsg.contains('lonavala')) {
      return "Lonavala is wonderful! Try visiting **Tiger's Point** or **Bhushi Dam**. I can track crowds there if you search for them!";
    }

    return _getSmartFallback();
  }

  // --- Handlers ---

  Future<String> _handleCrowdQuery(DocumentSnapshot? loc) async {
    final target = loc ?? await _getContextLocation();
    if (target == null) {
      return "Which place are you asking about? Try 'How is the crowd at **Shaniwar Wada**?'.";
    }

    final data = target.data() as Map<String, dynamic>;
    final level = data['crowdLevel'] ?? 'Unknown';
    return "Currently, **${data['name']}** has **$level** crowd levels. 📊";
  }

  Future<String> _handleTimeQuery(DocumentSnapshot? loc) async {
    final target = loc ?? await _getContextLocation();
    if (target == null) {
      return "For which place? Tell me a name like **Sinhagad** or **Dagadusheth**.";
    }

    final data = target.data() as Map<String, dynamic>;
    final time = data['bestTimeToVisit'] ?? 'early morning';
    return "The best time to visit **${data['name']}** is **$time** to avoid the rush. ⏰";
  }

  Future<String> _handleLocationQuery(DocumentSnapshot? loc) async {
    final target = loc ?? await _getContextLocation();
    if (target == null) {
      return "I can help you find places! Just ask 'Where is **Aga Khan Palace**?'.";
    }

    final data = target.data() as Map<String, dynamic>;
    // In a real app, we'd trigger a map camera move here via a callback, but for text:
    return "**${data['name']}** is located in the **${data['category']}** zone. You can tap the 📍 icon on the map to navigate there! 🗺️";
  }

  // --- Helpers ---

  Future<DocumentSnapshot?> _getContextLocation() async {
    if (_lastContextPlaceName == null) return null;
    return await _findBestMatchLocation(_lastContextPlaceName!);
  }

  Future<DocumentSnapshot?> _findBestMatchLocation(String input) async {
    // 1. Get all names
    final snapshot = await _db.collection('locations').get();
    DocumentSnapshot? bestMatch;
    // ignore: unused_local_variable
    int bestScore = 0;

    for (var doc in snapshot.docs) {
      final name = (doc.data()['name'] as String).toLowerCase();
      // Exact substring match
      if (input.contains(name)) {
        // Return immediately if strong match (long name) or if input is short
        if (name.length > 4) return doc;
        bestMatch = doc;
        bestScore = 100;
        continue;
      }

      // Token Match (input: "Fort", name: "Sinhagad Fort")
      final tokens = name.split(' ');
      for (var token in tokens) {
        if (token.length > 3 && input.contains(token)) {
          bestMatch = doc; // Weak match
          bestScore = 50;
        }
      }
    }
    return bestMatch;
  }

  Future<String> _suggestPlace({
    String? constraint,
    String? category,
    String? vibe,
  }) async {
    Query query = _db.collection('locations');
    if (constraint == 'Low Crowd') {
      query = query.where('crowdLevel', isEqualTo: 'Low');
    }
    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }

    final snapshot = await query.get();
    if (snapshot.docs.isEmpty) {
      return "I couldn't find a perfect match right now, but exploring the map always helps!";
    }

    final doc = snapshot.docs[Random().nextInt(snapshot.docs.length)];
    final data = doc.data() as Map<String, dynamic>;
    final name = data['name'];

    if (vibe != null) return "For **$vibe**, I highly recommend **$name**. 🌅";
    if (constraint != null) return "**$name** is super peaceful right now! 🍃";
    return "You should definitely check out **$name**! ✨";
  }

  bool _isGreeting(String msg) {
    return msg == 'hi' ||
        msg == 'hello' ||
        msg.startsWith('hey') ||
        msg.contains('good morning') ||
        msg.contains('namaste');
  }

  String _getRandomGreeting() {
    final greetings = [
      "Hello! 👋 I'm your smart guide. Ask me about crowds, timings, or hidden gems!",
      "Hi there! 🤖 Ready to explore Pune? Ask me 'Where should I go for sunset?'",
      "Namaste! 🙏 How can I help you navigate the city today?",
    ];
    return greetings[Random().nextInt(greetings.length)];
  }

  String _getSmartFallback() {
    final tips = [
      "I'm not sure about that, but I know a lot about **Forts** and **Temples**!",
      "Try asking 'Where is [PlaceName]' or 'Best time to visit [PlaceName]'.",
      "I'm still learning! But I can tell you where the crowd is low right now. Just ask!",
      "If you're looking for Lonavala, try asking about **Lohagad Fort** or **Visapur**.",
    ];
    return tips[Random().nextInt(tips.length)];
  }
}
