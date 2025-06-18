import 'dart:async';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import '../database_helper/database_helper.dart';
import '../location_services/background_location_service.dart';
import 'store_controller.dart';

class HomeController extends GetxController {
  final count = 0.obs;
  final isLoading = false.obs;
  final isTracking = false.obs;
  final currentLocation = Rxn<Position>();
  StreamSubscription<Position>? positionStream;
  GoogleMapController? mapController;
  final markers = <Marker>{}.obs;
  final polylines = <PolylineId, Polyline>{}.obs;
  final List<LatLng> routeCoordinates = [];
  
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final StoreController _storeController = Get.put(StoreController());
  int? currentSessionId;
  double totalDistance = 0.0;
  DateTime? sessionStartTime;

  // Notification channel ID and name
  static const String notificationChannelId = 'location_tracking_channel';
  static const String notificationChannelName = 'Location Tracking';

  @override
  void onInit() {
    super.onInit();
    _checkLocationPermission();
    _restoreTrackingState();
  }

  @override
  void onClose() {
    stopLocationTracking();
    positionStream?.cancel();
    mapController?.dispose();
    super.onClose();
  }

  Future<bool> _requestNotificationPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      return status.isGranted;
    }
    return true; // iOS handles permissions differently
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      // Check if location services are enabled
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.snackbar(
          'Location Services Disabled',
          'Please enable location services in your device settings.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5),
        );
        return;
      }

      // Keep requesting permission until we get "Allow all the time" or user cancels
      while (true) {
        permission = await Geolocator.checkPermission();

        // If we already have the permission we need, break the loop
        if (permission == LocationPermission.always) {
          break;
        }

        if (permission == LocationPermission.denied || permission == LocationPermission.whileInUse) {
          // Show explanation dialog
          final shouldRequest = await Get.dialog<bool>(
            PopScope(
              canPop: false,
              child: AlertDialog(
                title: const Text('Location Permission Required'),
                content: const Text(
                  'This app needs access to location all the time to track your movements in the background.\n\n'
                  'Please select "Allow all the time" in the next screen.\n\n'
                  'If you only see "While using the app" option:\n'
                  '1. Select it first\n'
                  '2. We will then guide you to enable "Allow all the time"'
                ),
                actions: [
                  TextButton(
                    onPressed: () => Get.back(result: false),
                    child: const Text('CANCEL'),
                  ),
                  TextButton(
                    onPressed: () => Get.back(result: true),
                    child: const Text('CONTINUE'),
                  ),
                ],
              ),
            ),
            barrierDismissible: false, // Prevent closing by tapping outside
          ) ?? false;

          if (!shouldRequest) {
            Get.snackbar(
              'Permission Required',
              'Location permission is required for tracking. Please try again when ready.',
              snackPosition: SnackPosition.BOTTOM,
              duration: const Duration(seconds: 5),
            );
            return;
          }

          // Request permission
          permission = await Geolocator.requestPermission();
          
          // If denied, show error and exit
          if (permission == LocationPermission.denied) {
            Get.snackbar(
              'Permission Denied',
              'Location permission is required for this feature.',
              snackPosition: SnackPosition.BOTTOM,
              duration: const Duration(seconds: 5),
            );
            return;
          }
        }

        // Handle permanently denied case
        if (permission == LocationPermission.deniedForever) {
          final shouldOpenSettings = await Get.dialog<bool>(
            WillPopScope(
              onWillPop: () async => false,
              child: AlertDialog(
                title: const Text('Location Permission Required'),
                content: const Text(
                  'Location permission is permanently denied. Please enable it in settings:\n\n'
                  '1. Tap "OPEN SETTINGS" below\n'
                  '2. Find this app\n'
                  '3. Go to Permissions\n'
                  '4. Enable "Location"\n'
                  '5. Select "Allow all the time"\n\n'
                  'After enabling, return to the app and tap CONTINUE'
                ),
                actions: [
                  TextButton(
                    onPressed: () => Get.back(result: false),
                    child: const Text('CANCEL'),
                  ),
                  TextButton(
                    onPressed: () async {
                      await Geolocator.openAppSettings();
                      Get.back(result: true);
                    },
                    child: const Text('OPEN SETTINGS'),
                  ),
                ],
              ),
            ),
            barrierDismissible: false,
          ) ?? false;

          if (!shouldOpenSettings) {
            return;
          }
          
          // Wait a bit for the user to come back from settings
          await Future.delayed(const Duration(seconds: 1));
          continue; // Check permission again
        }

        // If we have whileInUse permission, specifically request background
        if (permission == LocationPermission.whileInUse) {
          final shouldRequestBackground = await Get.dialog<bool>(
            WillPopScope(
              onWillPop: () async => false,
              child: AlertDialog(
                title: const Text('Background Location Required'),
                content: const Text(
                  'Please enable "Allow all the time" in settings:\n\n'
                  '1. Tap "OPEN SETTINGS" below\n'
                  '2. Tap Location\n'
                  '3. Select "Allow all the time"\n\n'
                  'After enabling, return to the app and tap CONTINUE'
                ),
                actions: [
                  TextButton(
                    onPressed: () => Get.back(result: false),
                    child: const Text('CANCEL'),
                  ),
                  TextButton(
                    onPressed: () async {
                      await Geolocator.openAppSettings();
                      Get.back(result: true);
                    },
                    child: const Text('OPEN SETTINGS'),
                  ),
                ],
              ),
            ),
            barrierDismissible: false,
          ) ?? false;

          if (!shouldRequestBackground) {
            Get.snackbar(
              'Permission Required',
              'Background location access is required for continuous tracking.',
              snackPosition: SnackPosition.BOTTOM,
              duration: const Duration(seconds: 5),
            );
            return;
          }

          // Wait a bit for the user to come back from settings
          await Future.delayed(const Duration(seconds: 1));
          continue; // Check permission again
        }
      }

      // Get initial location
      try {
        isLoading.value = true;
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5),
        );
        currentLocation.value = position;
        debugPrint('Initial location: $position');
      } catch (e) {
        debugPrint('Error getting current location: $e');
        Get.snackbar(
          'Error',
          'Failed to get current location: $e',
          snackPosition: SnackPosition.BOTTOM,
        );
      } finally {
        isLoading.value = false;
      }
    } catch (e) {
      debugPrint('Error checking location permission: $e');
      Get.snackbar(
        'Error',
        'Failed to check location permission: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void toggleLoading() {
    isLoading.value = !isLoading.value;
  }

  void startLocationTracking() async {
    if (isTracking.value) return;

    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.snackbar(
          'Location Services Disabled',
          'Please enable location services to start tracking.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5),
        );
        return;
      }

      // Request notification permission on Android
      if (Platform.isAndroid) {
        final hasNotificationPermission = await _requestNotificationPermission();
        if (!hasNotificationPermission) {
          Get.snackbar(
            'Notification Permission',
            'Please enable notifications to track location in background',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 5),
          );
          return;
        }
      }

      // Check and request background location permission
      final permission = await Geolocator.checkPermission();
      if (Platform.isAndroid && permission != LocationPermission.always) {
        Get.snackbar(
          'Background Permission Required',
          'Please allow background location access for continuous tracking.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5),
        );
        final newPermission = await Geolocator.requestPermission();
        if (newPermission != LocationPermission.always) {
          Get.snackbar(
            'Permission Required',
            'Background location access is required for continuous tracking.',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 5),
          );
          return;
        }
      }

      // First mark any existing active sessions as inactive
      final activeSession = await _dbHelper.getActiveSession();
      if (activeSession != null) {
        await _dbHelper.markSessionAsActive(activeSession['id'], false);
      }

      isTracking.value = true;
      routeCoordinates.clear();
      polylines.clear();
      markers.clear();
      totalDistance = 0.0;
      sessionStartTime = DateTime.now();

      debugPrint('Creating new tracking session...');
      final sessionData = {
        'start_time': sessionStartTime!.toIso8601String(),
        'end_time': null,
        'distance': 0.0,
        'average_speed': 0.0,
        'is_active': 1,
      };
      debugPrint('Session data to insert: $sessionData');
      
      currentSessionId = await _dbHelper.insertTrackingSession(sessionData);
      debugPrint('Created tracking session with ID: $currentSessionId');

      // Start background tracking service and set the session ID
      await BackgroundLocationService.startTracking();
      await BackgroundLocationService.setActiveSessionId(currentSessionId!);

      Get.snackbar(
        'Tracking Started',
        'Location tracking has been activated (including background)',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      debugPrint('Error starting tracking: $e');
      isTracking.value = false;
      Get.snackbar(
        'Error',
        'Failed to start location tracking: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> stopLocationTracking() async {
    if (!isTracking.value) return;

    try {
      // Stop background tracking
      await BackgroundLocationService.stopTracking();
      
      positionStream?.cancel();
      isTracking.value = false;

      // Update tracking session with end time and stats
      if (currentSessionId != null) {
        debugPrint('Updating tracking session $currentSessionId with final stats...');
        final endTime = DateTime.now();
        final duration = endTime.difference(sessionStartTime!).inSeconds;
        final averageSpeed = duration > 0 ? (totalDistance / duration) : 0.0;

        await _dbHelper.updateTrackingSession(
          currentSessionId!,
          {
            'end_time': endTime.toIso8601String(),
            'distance': totalDistance,
            'average_speed': averageSpeed,
            'is_active': 0,
          },
        );
        debugPrint('Updated tracking session with final stats');

        // Clear the current session
        currentSessionId = null;
        sessionStartTime = null;
        routeCoordinates.clear();
        polylines.clear();
        markers.clear();
      }

      Get.snackbar(
        'Tracking Stopped',
        'Location tracking has been deactivated',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      debugPrint('Error stopping tracking: $e');
      Get.snackbar(
        'Error',
        'Failed to stop tracking properly: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> saveLocationToDatabase(Position position) async {
    if (currentSessionId == null) {
      debugPrint('No active session ID, skipping location save');
      return;
    }

    try {
      final locationData = {
        'session_id': currentSessionId,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': DateTime.now().toIso8601String(),
        'accuracy': position.accuracy,
        'altitude': position.altitude,
        'speed': position.speed,
        'speed_accuracy': position.speedAccuracy,
        'heading': position.heading,
      };
      debugPrint('Saving location to database: $locationData');
      
      final id = await _dbHelper.insertLocation(locationData);
      debugPrint('Location saved with ID: $id');

      // Update the route on the map
      _updateRoute(position);

      // Verify location was saved
      final locations = await _dbHelper.getLocationsForSession(currentSessionId!);
      debugPrint('Current locations for session $currentSessionId: ${locations.length}');
    } catch (e) {
      debugPrint('Error saving location to database: $e');
    }
  }

  void _updateRoute(Position position) {
    final latLng = LatLng(position.latitude, position.longitude);
    debugPrint('Updating route with new position: $latLng');
    debugPrint('Current route coordinates count: ${routeCoordinates.length}');
    
    // Calculate distance if we have previous coordinates
    if (routeCoordinates.isNotEmpty) {
      final previousLatLng = routeCoordinates.last;
      final distance = Geolocator.distanceBetween(
        previousLatLng.latitude,
        previousLatLng.longitude,
        latLng.latitude,
        latLng.longitude,
      );
      totalDistance += distance;
      debugPrint('Added distance: $distance m, Total distance: $totalDistance m');
    }

    routeCoordinates.add(latLng);
    debugPrint('Added new coordinate, total coordinates: ${routeCoordinates.length}');

    try {
      // Update camera position if map controller exists
      mapController?.animateCamera(
        CameraUpdate.newLatLng(latLng),
      ).catchError((error) {
        debugPrint('Error updating camera position: $error');
      });

      // Add or update current location marker
      final markerId = MarkerId('current_location');
      final marker = Marker(
        markerId: markerId,
        position: latLng,
        infoWindow: InfoWindow(
          title: 'Current Location',
          snippet: '${position.latitude}, ${position.longitude}',
        ),
      );

      // Combine current location marker with store markers
      final allMarkers = _storeController.markers.toSet();
      allMarkers.add(marker);
      markers.value = allMarkers;
      debugPrint('Updated markers count: ${markers.length}');

      // Update polyline
      const polylineId = PolylineId('route');
      final polyline = Polyline(
        polylineId: polylineId,
        color: Colors.blue,
        points: routeCoordinates,
        width: 5,
      );
      polylines[polylineId] = polyline;
      debugPrint('Updated polyline with ${routeCoordinates.length} points');

      // Check for nearby stores
      _storeController.checkNearbyStores(position);
    } catch (e) {
      debugPrint('Error updating route: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getTrackingSessions() async {
    return await _dbHelper.getAllSessions();
  }

  Future<List<Map<String, dynamic>>> getLocationHistory(int sessionId) async {
    return await _dbHelper.getLocationsForSession(sessionId);
  }

  void showHistoricalRoute(List<Map<String, dynamic>> locations) {
    if (locations.isEmpty) return;

    // Clear existing markers and polylines
    markers.clear();
    polylines.clear();
    routeCoordinates.clear();

    // Convert locations to LatLng points
    final points = locations.map((loc) => LatLng(
      loc['latitude'] as double,
      loc['longitude'] as double,
    )).toList();

    // Add all points to route coordinates
    routeCoordinates.addAll(points);

    // Add start and end markers
    final startPoint = points.first;
    final endPoint = points.last;

    markers.value = {
      Marker(
        markerId: const MarkerId('start'),
        position: startPoint,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'Start Point'),
      ),
      Marker(
        markerId: const MarkerId('end'),
        position: endPoint,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'End Point'),
      ),
    };

    // Add polyline
    final polyline = Polyline(
      polylineId: const PolylineId('historical_route'),
      color: Colors.blue,
      points: points,
      width: 5,
    );
    polylines[const PolylineId('historical_route')] = polyline;

    // Animate camera to show the entire route
    if (mapController != null) {
      final bounds = _boundsFromLatLngList(points);
      mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 50),
      );
    }
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> points) {
    double? minLat, maxLat, minLng, maxLng;

    for (final point in points) {
      if (minLat == null || point.latitude < minLat) {
        minLat = point.latitude;
      }
      if (maxLat == null || point.latitude > maxLat) {
        maxLat = point.latitude;
      }
      if (minLng == null || point.longitude < minLng) {
        minLng = point.longitude;
      }
      if (maxLng == null || point.longitude > maxLng) {
        maxLng = point.longitude;
      }
    }

    return LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );
  }

  // Method to add a new store at the current location
  Future<void> addStoreAtCurrentLocation(String name, double radius) async {
    if (currentLocation.value != null) {
      final position = LatLng(
        currentLocation.value!.latitude,
        currentLocation.value!.longitude,
      );
      await _storeController.addStore(name, position, radius);
    } else {
      Get.snackbar(
        'Error',
        'Current location not available',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Method to add a store at a specific location
  Future<void> addStoreAtLocation(String name, LatLng position, double radius) async {
    await _storeController.addStore(name, position, radius);
  }

  // Method to get store visits
  Future<List<Map<String, dynamic>>> getStoreVisits(int storeId) async {
    return await _storeController.getStoreVisits(storeId);
  }

  Future<Position?> getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      currentLocation.value = position;
      return position;
    } catch (e) {
      debugPrint('Error getting current location: $e');
      return null;
    }
  }

  Future<void> _restoreTrackingState() async {
    try {
      // Check if there's an active session in the background service
      final activeSessionId = await BackgroundLocationService.getActiveSessionId();
      final isServiceTracking = await BackgroundLocationService.isTrackingActive();

      if (activeSessionId != null && isServiceTracking) {
        // Restore tracking state
        currentSessionId = activeSessionId;
        isTracking.value = true;

        // Get the active session details
        final session = await _dbHelper.getActiveSession();
        if (session != null) {
          sessionStartTime = DateTime.parse(session['start_time']);
          
          // Restore route coordinates from saved locations
          final locations = await _dbHelper.getLocationsForSession(activeSessionId);
          routeCoordinates.clear();
          for (final location in locations) {
            routeCoordinates.add(LatLng(
              location['latitude'] as double,
              location['longitude'] as double,
            ));
          }

          // Update polylines if we have coordinates
          if (routeCoordinates.isNotEmpty) {
            const polylineId = PolylineId('route');
            final polyline = Polyline(
              polylineId: polylineId,
              color: Colors.blue,
              points: routeCoordinates,
              width: 5,
            );
            polylines[polylineId] = polyline;
          }

          debugPrint('Restored tracking state: sessionId=$activeSessionId, coordinates=${routeCoordinates.length}');
        }
      }
    } catch (e) {
      debugPrint('Error restoring tracking state: $e');
    }
  }
} 