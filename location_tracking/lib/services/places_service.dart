import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart';

class PlacesService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';
  static const String _apiKey = 'AIzaSyDcCpcOye1PW7OXdQk2AGVdTFEh40p18zg'; // Replace with your API key

  Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    if (query.isEmpty) return [];

    final url = Uri.parse(
      '$_baseUrl/autocomplete/json?input=$query&key=$_apiKey&types=address'
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return List<Map<String, dynamic>>.from(
            data['predictions'].map((prediction) => {
              'place_id': prediction['place_id'],
              'description': prediction['description'],
            })
          );
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error searching places: $e');
      return [];
    }
  }

  Future<LatLng?> getPlaceLocation(String placeId) async {
    final url = Uri.parse(
      '$_baseUrl/details/json?place_id=$placeId&key=$_apiKey'
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final location = data['result']['geometry']['location'];
          return LatLng(location['lat'], location['lng']);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting place location: $e');
      return null;
    }
  }
} 