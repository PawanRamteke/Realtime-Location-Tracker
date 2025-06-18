import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:location_tracking/screens/store_management_screen.dart';
import '../controllers/home_controller.dart';
import 'map_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final HomeController controller = Get.put(HomeController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Tracking'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Obx(() => Text(
                  controller.currentLocation.value != null
                      ? 'Current Location:\nLat: ${controller.currentLocation.value?.latitude}\nLong: ${controller.currentLocation.value?.longitude}'
                      : 'No location data',
                  style: const TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                )),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: 200, // Fixed width for buttons
                child: Obx(() => controller.isTracking.value
                    ? ElevatedButton.icon(
                        onPressed: controller.stopLocationTracking,
                        icon: const Icon(Icons.stop_circle_outlined),
                        label: const Text('Stop Tracking'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: controller.startLocationTracking,
                        icon: const Icon(Icons.play_circle_outlined, color: Colors.white,),
                        label: const Text('Start Tracking'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 200,
                child: ElevatedButton.icon(
                  onPressed: () => Get.to(() => const MapScreen()),
                  icon: const Icon(Icons.map, color: Colors.white,),
                  label: const Text('View Map'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 200,
                child: ElevatedButton.icon(
                  onPressed: () => Get.to(() => StoreManagementScreen()),
                  icon: const Icon(Icons.store, color: Colors.white,),
                  label: const Text('Store Management'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 