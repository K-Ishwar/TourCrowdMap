# TourCrowdMap 🌍🚀

**Discover Places. Dodge Crowds.**

TourCrowdMap is an intelligent travel application designed to solve the problem of overcrowding at popular tourist destinations. By leveraging real-time data and smart heuristics, it empowers travelers to make informed decisions about **where** to go and **when** to visit.

---

## 🌟 Key Features

### 🏰 Real-Time Crowd Intelligence
- **Live Crowd Ticker**: A dynamic home screen ticker that streams real-time crowd status (Low, Moderate, High) for popular locations directly from the Cloud Firestore database.
- **Interactive Heatmaps**: Visual map layers that highlight congested areas in red and peaceful spots in green, allowing users to scan the city at a glance.
- **Smart Forecasting & Suggestions**: Intelligent logic that calculates the "Best Time to Visit" based on location type constraints (e.g., suggesting a visit to a Fort on a weekday morning or a Temple in the afternoon).

### 🤖 AI-Powered Planning
- **Smart Itinerary Planner**: A generative tool that creates personalized day-plans based on the user's preferred "Vibe" (Peaceful vs. Popular) and available time.
- **Context-Aware Chatbot**: An in-app assistant that understands context (e.g., remembering which place you just asked about) to answer queries about timings, location, and hidden gems.
- **Dynamic Routing**: Deep integration with Google Maps for seamless navigation to selected spots.

### 🎨 Modern & Immersive UI
- **Glassmorphism Design**: A premium aesthetic featuring frosted glass elements, vibrant gradients, and fluid animations.
- **Interactive Maps**: Custom marker implementation with distinct visual states for different crowd levels.

---

## 🛠️ Technology Stack

- **Framework**: [Flutter](https://flutter.dev) (Dart)
- **Backend**: [Firebase](https://firebase.google.com)
  - **Cloud Firestore**: Real-time NoSQL database for locations and user data.
  - **Firebase Auth**: Secure user authentication.
- **State Management**: standard Flutter state management & specific services.
- **Routing**: `go_router` for declarative routing.
- **Maps**: `flutter_map` with `latlong2`.
- **Animations**: `flutter_animate` for UI effects.

---

## 🚀 Getting Started

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/yourusername/TourCrowdMap.git
    cd TourCrowdMap
    ```

2.  **Install Dependencies**:
    ```bash
    flutter pub get
    ```

3.  **Firebase Setup**:
    - Ensure you have the `firebase_options.dart` configuration file in `lib/`.
    - If not, use `flutterfire configure` to connect to your Firebase project.

4.  **Run the App**:
    ```bash
    flutter run
    ```
