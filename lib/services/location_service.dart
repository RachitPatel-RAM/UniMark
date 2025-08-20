import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // Check and request location permissions
  Future<bool> requestLocationPermission() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled. Please enable location services.');
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied. Please enable them in settings.');
      }

      return true;
    } catch (e) {
      throw Exception('Location permission error: $e');
    }
  }

  // Get current location with high accuracy
  Future<Position> getCurrentLocation() async {
    try {
      bool hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        throw Exception('Location permission not granted');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      return position;
    } catch (e) {
      throw Exception('Failed to get current location: $e');
    }
  }

  // Calculate distance between two points in meters
  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  // Check if student is within allowed radius of session location
  Future<bool> isWithinSessionRadius(
    double sessionLat,
    double sessionLon,
    double allowedRadiusMeters,
  ) async {
    try {
      Position currentPosition = await getCurrentLocation();
      
      double distance = calculateDistance(
        currentPosition.latitude,
        currentPosition.longitude,
        sessionLat,
        sessionLon,
      );

      return distance <= allowedRadiusMeters;
    } catch (e) {
      throw Exception('Failed to check location: $e');
    }
  }

  // Get distance from session location
  Future<double> getDistanceFromSession(
    double sessionLat,
    double sessionLon,
  ) async {
    try {
      Position currentPosition = await getCurrentLocation();
      
      return calculateDistance(
        currentPosition.latitude,
        currentPosition.longitude,
        sessionLat,
        sessionLon,
      );
    } catch (e) {
      throw Exception('Failed to calculate distance: $e');
    }
  }

  // Get location with retry mechanism
  Future<Position> getLocationWithRetry({int maxRetries = 3}) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        return await getCurrentLocation();
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          throw Exception('Failed to get location after $maxRetries attempts: $e');
        }
        
        // Wait before retry
        await Future.delayed(Duration(seconds: attempts * 2));
      }
    }
    
    throw Exception('Failed to get location');
  }

  // Check if location is mock/fake
  Future<bool> isLocationMocked() async {
    try {
      Position position = await getCurrentLocation();
      return position.isMocked;
    } catch (e) {
      return true; // If we can't check, assume it's mocked for security
    }
  }

  // Get location accuracy
  Future<double> getLocationAccuracy() async {
    try {
      Position position = await getCurrentLocation();
      return position.accuracy;
    } catch (e) {
      return double.infinity;
    }
  }

  // Check if location accuracy is acceptable
  Future<bool> isLocationAccuracyAcceptable({double maxAccuracyMeters = 50.0}) async {
    try {
      double accuracy = await getLocationAccuracy();
      return accuracy <= maxAccuracyMeters;
    } catch (e) {
      return false;
    }
  }

  // Format distance for display
  String formatDistance(double distanceMeters) {
    if (distanceMeters < 1000) {
      return '${distanceMeters.toStringAsFixed(0)} m';
    } else {
      double distanceKm = distanceMeters / 1000;
      return '${distanceKm.toStringAsFixed(2)} km';
    }
  }

  // Get bearing between two points
  double getBearing(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    double dLon = (lon2 - lon1) * (pi / 180);
    double lat1Rad = lat1 * (pi / 180);
    double lat2Rad = lat2 * (pi / 180);
    
    double y = sin(dLon) * cos(lat2Rad);
    double x = cos(lat1Rad) * sin(lat2Rad) - sin(lat1Rad) * cos(lat2Rad) * cos(dLon);
    
    double bearing = atan2(y, x) * (180 / pi);
    return (bearing + 360) % 360;
  }

  // Get compass direction from bearing
  String getCompassDirection(double bearing) {
    const directions = [
      'N', 'NNE', 'NE', 'ENE',
      'E', 'ESE', 'SE', 'SSE',
      'S', 'SSW', 'SW', 'WSW',
      'W', 'WNW', 'NW', 'NNW'
    ];
    
    int index = ((bearing + 11.25) / 22.5).floor() % 16;
    return directions[index];
  }

  // Check if GPS is enabled and accurate
  Future<Map<String, dynamic>> getLocationStatus() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();
      
      bool hasPermission = permission == LocationPermission.always ||
                          permission == LocationPermission.whileInUse;
      
      double? accuracy;
      bool? isMocked;
      
      if (serviceEnabled && hasPermission) {
        try {
          Position position = await getCurrentLocation();
          accuracy = position.accuracy;
          isMocked = position.isMocked;
        } catch (e) {
          // Location might not be available
        }
      }
      
      return {
        'serviceEnabled': serviceEnabled,
        'hasPermission': hasPermission,
        'accuracy': accuracy,
        'isMocked': isMocked,
        'isReady': serviceEnabled && hasPermission && (isMocked != true),
      };
    } catch (e) {
      return {
        'serviceEnabled': false,
        'hasPermission': false,
        'accuracy': null,
        'isMocked': null,
        'isReady': false,
        'error': e.toString(),
      };
    }
  }

  // Stream location updates
  Stream<Position> getLocationStream() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );
    
    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }
}