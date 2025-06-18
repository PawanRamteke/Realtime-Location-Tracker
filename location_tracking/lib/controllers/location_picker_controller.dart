import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/places_service.dart';
import 'home_controller.dart';

class LocationPickerController extends GetxController {
  final selectedLocation = Rxn<LatLng>();
  final markers = <Marker>{}.obs;
  final searchResults = <Map<String, dynamic>>[].obs;
  final isSearching = false.obs;
  final searchQuery = ''.obs;
  final selectedAddress = ''.obs;

  GoogleMapController? mapController;
  final HomeController homeController = Get.find();
  final PlacesService _placesService = PlacesService();

  void updateLocation(LatLng location) {
    selectedLocation.value = location;
    updateMarker();
  }

  void updateMarker() {
    if (selectedLocation.value == null) return;

    markers.clear();
    markers.add(
      Marker(
        markerId: const MarkerId('selected_location'),
        position: selectedLocation.value!,
        draggable: false,
      ),
    );
  }

  void onCameraMove(CameraPosition position) {
    updateLocation(position.target);
  }

  void onCameraIdle() {
    // This is called when the camera stops moving
    if (selectedLocation.value != null) {
      updateMarker();
    }
  }

  Future<void> moveToCurrentLocation() async {
    final position = await homeController.getCurrentLocation();
    if (position != null && mapController != null) {
      final latLng = LatLng(position.latitude, position.longitude);
      mapController!.animateCamera(
        CameraUpdate.newLatLng(latLng),
      );
      updateLocation(latLng);
    }
  }

  Future<void> searchPlaces(String query) async {
    if (query.isEmpty) {
      searchResults.clear();
      return;
    }

    isSearching.value = true;
    try {
      final results = await _placesService.searchPlaces(query);
      searchResults.value = results;
    } finally {
      isSearching.value = false;
    }
  }

  Future<void> selectPlace(String placeId, String address) async {
    final location = await _placesService.getPlaceLocation(placeId);
    if (location != null && mapController != null) {
      selectedAddress.value = address;
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(location, 15),
      );
      updateLocation(location);
    }
  }
}
