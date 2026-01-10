import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:tour_crowd_map/config/router.dart';
import 'package:tour_crowd_map/core/theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TourCrowdMap',
      theme: appTheme,
      darkTheme: darkTheme, // Auto Dark Mode
      themeMode: ThemeMode.system, // Respect system/browser setting
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
