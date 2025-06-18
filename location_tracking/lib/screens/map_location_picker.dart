import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:get/get.dart';
import '../controllers/location_picker_controller.dart';

class MapLocationPicker extends StatelessWidget {
  final LatLng? initialLocation;

  MapLocationPicker({super.key, this.initialLocation}) {
    final controller = Get.put(LocationPickerController());
    if (initialLocation != null) {
      controller.updateLocation(initialLocation!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LocationPickerController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Store Location'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Obx(() => TextButton(
            onPressed: controller.selectedLocation.value != null
                ? () => Navigator.pop(context, controller.selectedLocation.value)
                : null,
            child: const Text('Confirm'),
          )),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initialLocation ??
                  const LatLng(0, 0), // Default position if none provided
              zoom: 15,
            ),
            onMapCreated: (GoogleMapController mapController) {
              controller.mapController = mapController;
              if (initialLocation == null) {
                // If no initial location, center on user's current location
                controller.moveToCurrentLocation();
              }
            },
            markers: controller.markers,
            onCameraMove: controller.onCameraMove,
            onCameraIdle: controller.onCameraIdle,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
          // Search bar
          // Positioned(
          //   top: 16,
          //   left: 16,
          //   right: 16,
          //   child: Column(
          //     children: [
          //       Card(
          //         child: TextField(
          //           decoration: InputDecoration(
          //             hintText: 'Search location',
          //             prefixIcon: const Icon(Icons.search),
          //             suffixIcon: Obx(() => controller.searchQuery.isNotEmpty
          //               ? IconButton(
          //                   icon: const Icon(Icons.clear),
          //                   onPressed: () {
          //                     controller.searchQuery.value = '';
          //                     controller.searchResults.clear();
          //                   },
          //                 )
          //               : const SizedBox.shrink(),
          //             ),
          //             border: InputBorder.none,
          //             contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          //           ),
          //           onChanged: (value) {
          //             controller.searchQuery.value = value;
          //             controller.searchPlaces(value);
          //           },
          //         ),
          //       ),
          //       // Search results
          //       Obx(() => controller.searchResults.isNotEmpty
          //         ? Card(
          //             child: Container(
          //               constraints: const BoxConstraints(maxHeight: 200),
          //               child: ListView.builder(
          //                 shrinkWrap: true,
          //                 itemCount: controller.searchResults.length,
          //                 itemBuilder: (context, index) {
          //                   final place = controller.searchResults[index];
          //                   return ListTile(
          //                     title: Text(place['description']),
          //                     onTap: () {
          //                       controller.selectPlace(
          //                         place['place_id'],
          //                         place['description'],
          //                       );
          //                       controller.searchResults.clear();
          //                       controller.searchQuery.value = '';
          //                       FocusScope.of(context).unfocus();
          //                     },
          //                   );
          //                 },
          //               ),
          //             ),
          //           )
          //         : const SizedBox.shrink(),
          //       ),
          //     ],
          //   ),
          // ),
          // Center indicator
          Center(
            child: Icon(
              Icons.location_pin,
              size: 40,
              color: Theme.of(context).primaryColor,
            ),
          ),
          // Location info card
          Obx(() => controller.selectedLocation.value != null
            ? Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (controller.selectedAddress.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              controller.selectedAddress.value,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                        Text(
                          'Selected Location:\nLat: ${controller.selectedLocation.value!.latitude.toStringAsFixed(6)}\nLng: ${controller.selectedLocation.value!.longitude.toStringAsFixed(6)}',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink()
          ),
        ],
      ),
    );
  }
} 