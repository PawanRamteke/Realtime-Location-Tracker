import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:location_tracking/screens/home_screen.dart';
import 'location_services/background_location_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize background location service
  await BackgroundLocationService.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Location Tracking',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      defaultTransition: Transition.fade,
      home: const HomeScreen(),
      initialBinding: BindingsBuilder(() {
        // Add your controllers here
      }),
    );
  }
}
