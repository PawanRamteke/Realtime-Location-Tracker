import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../database_helper/database_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;

class StoreController extends GetxController {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final stores = <Map<String, dynamic>>[].obs;
  final activeVisits = <int, int>{}.obs; // storeId -> visitId mapping
  final markers = <Marker>{}.obs;
  BitmapDescriptor? storeIcon;

  @override
  void onInit() {
    super.onInit();
    _loadStoreIcon();
    loadStores();
  }

  Future<void> _loadStoreIcon() async {
    try {
      // Load the store icon image from assets
      final ByteData data = await rootBundle.load('assets/icons/store_marker.png');
      final Uint8List bytes = data.buffer.asUint8List();
      
      // Create a bitmap descriptor from the image bytes
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 80);
      final frame = await codec.getNextFrame();
      final image = await frame.image.toByteData(format: ui.ImageByteFormat.png);
      
      if (image != null) {
        storeIcon = BitmapDescriptor.fromBytes(image.buffer.asUint8List());
      }
    } catch (e) {
      debugPrint('Error loading store icon: $e');
      // Fallback to default marker with custom color if icon loading fails
      storeIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
    }
  }

  Future<void> loadStores() async {
    final storeList = await _dbHelper.storeLocationsHelper.getAllStoreLocations();
    stores.value = storeList;
    _updateMarkers();
  }

  void _updateMarkers() {
    markers.clear();
    for (final store in stores) {
      markers.add(
        Marker(
          markerId: MarkerId('store_${store['id']}'),
          position: LatLng(store['latitude'], store['longitude']),
          infoWindow: InfoWindow(
            title: store['name'],
            snippet: 'Radius: ${store['radius']}m',
          ),
          icon: storeIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
        ),
      );
    }
  }

  Future<void> addStore(String name, LatLng position, double radius) async {
    final storeData = {
      'name': name,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'radius': radius,
      'created_at': DateTime.now().toIso8601String(),
    };

    try {
      final id = await _dbHelper.storeLocationsHelper.insertStoreLocation(storeData);
      storeData['id'] = id;
      
      // Create a new list with the new store
      final updatedStores = [...stores, storeData];
      stores.value = updatedStores;
      
      _updateMarkers();
    } catch (e) {
      debugPrint('Error adding store: $e');
      Get.snackbar(
        'Error',
        'Failed to add store: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      rethrow;
    }
  }

  Future<void> updateStore(int id, String name, LatLng position, double radius) async {
    final storeData = {
      'name': name,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'radius': radius,
      'created_at': DateTime.now().toIso8601String(),
    };

    try {
      await _dbHelper.storeLocationsHelper.updateStoreLocation(id, storeData);
      
      // Create a new list with the updated store
      final index = stores.indexWhere((store) => store['id'] == id);
      if (index != -1) {
        final updatedStores = List<Map<String, dynamic>>.from(stores);
        updatedStores[index] = {...storeData, 'id': id};
        stores.value = updatedStores;
        _updateMarkers();
      }
    } catch (e) {
      debugPrint('Error updating store: $e');
      Get.snackbar(
        'Error',
        'Failed to update store: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      rethrow;
    }
  }

  Future<void> deleteStore(int id) async {
    try {
      await _dbHelper.storeLocationsHelper.deleteStoreLocation(id);
      
      // Create a new list without the deleted store
      final updatedStores = stores.where((store) => store['id'] != id).toList();
      stores.value = updatedStores;
      
      _updateMarkers();
    } catch (e) {
      debugPrint('Error deleting store: $e');
      Get.snackbar(
        'Error',
        'Failed to delete store: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      rethrow;
    }
  }

  Future<void> checkNearbyStores(Position position) async {
    for (final store in stores) {
      final storePosition = Position(
        latitude: store['latitude'],
        longitude: store['longitude'],
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
        floor: null,
        isMocked: false,
      );

      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        storePosition.latitude,
        storePosition.longitude,
      );

      final storeId = store['id'];
      final isInStore = distance <= store['radius'];
      final hasActiveVisit = activeVisits.containsKey(storeId);

      if (isInStore && !hasActiveVisit) {
        // User has entered the store
        final visitData = {
          'store_id': storeId,
          'entry_time': DateTime.now().toIso8601String(),
        };
        final visitId = await _dbHelper.storeLocationsHelper.insertStoreVisit(visitData);
        activeVisits[storeId] = visitId;
        
        Get.snackbar(
          'Store Visit',
          'Entered ${store['name']}',
          duration: const Duration(seconds: 3),
        );
      } else if (!isInStore && hasActiveVisit) {
        // User has left the store
        final visitId = activeVisits[storeId]!;
        final visitData = {
          'exit_time': DateTime.now().toIso8601String(),
        };
        await _dbHelper.storeLocationsHelper.updateStoreVisit(visitId, visitData);
        activeVisits.remove(storeId);

        Get.snackbar(
          'Store Visit',
          'Left ${store['name']}',
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>> getStoreVisits(int storeId) async {
    return await _dbHelper.storeLocationsHelper.getStoreVisits(storeId);
  }
} 