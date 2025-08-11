// lib/services/location_service.dart
import 'package:geolocator/geolocator.dart';

class LocationService {
  // Check if location permission is granted
  Future<bool> checkPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse || 
           permission == LocationPermission.always;
  }

  // Request location permission
  Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.requestPermission();
    return permission == LocationPermission.whileInUse || 
           permission == LocationPermission.always;
  }

  // Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Get current position
  Future<Position?> getCurrentPosition() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      // Check permissions
      bool hasPermission = await checkPermission();
      if (!hasPermission) {
        bool granted = await requestPermission();
        if (!granted) {
          throw Exception('Location permission denied');
        }
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 30),
      );

      return position;
    } catch (e) {
      throw Exception('Failed to get location: ${e.toString()}');
    }
  }

  // Calculate distance between two points in meters
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  // Check if position is within radius of target location
  bool isWithinRadius(
    Position currentPosition,
    double targetLatitude,
    double targetLongitude,
    double radiusInMeters,
  ) {
    double distance = calculateDistance(
      currentPosition.latitude,
      currentPosition.longitude,
      targetLatitude,
      targetLongitude,
    );
    return distance <= radiusInMeters;
  }
}