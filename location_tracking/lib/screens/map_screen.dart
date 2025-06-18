import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../controllers/home_controller.dart';
import '../widgets/tracking_history_sheet.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  void _showHistoryBottomSheet(BuildContext context, HomeController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => TrackingHistorySheet(
          controller: controller,
          scrollController: scrollController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final HomeController controller = Get.find<HomeController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Tracking Map'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showHistoryBottomSheet(context, controller),
          ),
        ],
      ),
      body: Obx(() {
        final currentLocation = controller.currentLocation.value;
        if (currentLocation == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(currentLocation.latitude, currentLocation.longitude),
                zoom: 15,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: true,
              mapToolbarEnabled: true,
              polylines: Set<Polyline>.of(controller.polylines.values),
              markers: controller.markers,
              onMapCreated: (GoogleMapController mapController) {
                if (controller.mapController != null) {
                  controller.mapController!.dispose();
                }
                controller.mapController = mapController;
                controller.mapController?.animateCamera(
                  CameraUpdate.newLatLng(
                    LatLng(currentLocation.latitude, currentLocation.longitude),
                  ),
                );
              },
            ),
            if (controller.isLoading.value)
              const Center(child: CircularProgressIndicator()),
          ],
        );
      }),
    );
  }
} 