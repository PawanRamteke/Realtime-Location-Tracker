import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../database_helper/database_helper.dart';
import '../controllers/home_controller.dart';

class BackgroundLocationService {
  static const String ACTIVE_SESSION_KEY = 'active_session_id';
  static const String IS_TRACKING_KEY = 'is_tracking';
  
  static const MethodChannel _channel = MethodChannel('com.example.location_tracking/location');
  static final DatabaseHelper _databaseHelper = DatabaseHelper();
  static int? _activeSessionId;
  static bool _isTracking = false;

  static Future<void> initialize() async {
    _channel.setMethodCallHandler(_handleMethodCall);
    await _restoreTrackingState();
  }

  static Future<void> _restoreTrackingState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _activeSessionId = prefs.getInt(ACTIVE_SESSION_KEY);
      _isTracking = prefs.getBool(IS_TRACKING_KEY) ?? false;

      if (_isTracking && _activeSessionId != null) {
        // Restart tracking if it was active when the app was killed
        await _requestPermissions();
        await _startNativeService();
      }
    } catch (e) {
      print('Error restoring tracking state: $e');
    }
  }

  static Future<void> _requestPermissions() async {
    if (!Platform.isAndroid) return;

    // Request notification permission
    await Permission.notification.request();

    // Request background location permission
    await Permission.locationAlways.request();

    // Request ignore battery optimization
    if (await Permission.ignoreBatteryOptimizations.status.isDenied) {
      await Permission.ignoreBatteryOptimizations.request();
    }
  }

  static Future<void> _saveTrackingState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_activeSessionId != null) {
        await prefs.setInt(ACTIVE_SESSION_KEY, _activeSessionId!);
      } else {
        await prefs.remove(ACTIVE_SESSION_KEY);
      }
      await prefs.setBool(IS_TRACKING_KEY, _isTracking);
    } catch (e) {
      print('Error saving tracking state: $e');
    }
  }

  static Future<void> startTracking() async {
    if (_isTracking) return;

    try {
      // Request all necessary permissions
      await _requestPermissions();

      // Check location service
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      _isTracking = true;
      await _saveTrackingState();

      // Start native service
      await _startNativeService();

    } catch (e) {
      print('Error starting tracking: $e');
      _isTracking = false;
      _activeSessionId = null;
      await _saveTrackingState();
      rethrow;
    }
  }

  static Future<void> _startNativeService() async {
    try {
      await _channel.invokeMethod('startLocationService');
      print('Native location service started successfully');
    } catch (e) {
      print('Error starting native service: $e');
      rethrow;
    }
  }

  static Future<void> stopTracking() async {
    if (!_isTracking) return;

    try {
      // Stop native service
      await _channel.invokeMethod('stopLocationService');

      if (_activeSessionId != null) {
        await _databaseHelper.updateTrackingSession(_activeSessionId!, {
          'end_time': DateTime.now().toIso8601String(),
          'is_active': 0,
        });
        _activeSessionId = null;
      }

      _isTracking = false;
      await _saveTrackingState();
    } catch (e) {
      print('Error stopping tracking: $e');
      rethrow;
    }
  }

  static Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onLocationUpdate':
        debugPrint('Received location update from native service: ${call.arguments}');
        await _handleLocationUpdate(call.arguments);
        break;
      default:
        debugPrint('Unknown method ${call.method}');
    }
  }

  static Future<void> _handleLocationUpdate(dynamic locationData) async {
    if (_activeSessionId == null || !_isTracking) {
      debugPrint('Skipping location update: activeSessionId=$_activeSessionId, isTracking=$_isTracking');
      return;
    }

    try {
      // Create a Position object to update the route
      final position = Position(
        latitude: locationData['latitude'],
        longitude: locationData['longitude'],
        timestamp: DateTime.now(),
        accuracy: locationData['accuracy'] ?? 0.0,
        altitude: locationData['altitude'] ?? 0.0,
        heading: 0.0,
        speed: locationData['speed'] ?? 0.0,
        speedAccuracy: 0.0,
        floor: null,
        isMocked: false,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );

      // Get the HomeController instance and update the route
      final homeController = Get.find<HomeController>();
      homeController.currentLocation.value = position;
      await homeController.saveLocationToDatabase(position);

      debugPrint('Location update processed through HomeController');
    } catch (e, stackTrace) {
      debugPrint('Error handling location update: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  static Future<bool> isTrackingActive() async {
    try {
      return await _channel.invokeMethod('isServiceRunning') ?? false;
    } catch (e) {
      print('Error checking service status: $e');
      return false;
    }
  }

  static Future<int?> getActiveSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(ACTIVE_SESSION_KEY);
  }

  static Future<void> setActiveSessionId(int sessionId) async {
    _activeSessionId = sessionId;
    await _saveTrackingState();
  }
} 