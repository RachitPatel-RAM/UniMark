import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';

enum LocationAccuracy {
  unknown,
  low,
  medium,
  high,
  best,
}

class LocationProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();
  
  Position? _currentPosition;
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasPermission = false;
  bool _isLocationEnabled = false;
  LocationAccuracy _currentAccuracy = LocationAccuracy.unknown;
  bool _isMockLocation = false;
  
  // Location tracking
  StreamSubscription<Position>? _positionStreamSubscription;
  
  // Distance calculations
  double? _lastCalculatedDistance;
  Position? _targetPosition;

  // Getters
  Position? get currentPosition => _currentPosition;
  Position? get currentLocation => _currentPosition; // Alias for compatibility
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasPermission => _hasPermission;
  bool get isLocationEnabled => _isLocationEnabled;
  LocationAccuracy get currentAccuracy => _currentAccuracy;
  bool get isMockLocation => _isMockLocation;
  bool get isTracking => _positionStreamSubscription != null;
  double? get lastCalculatedDistance => _lastCalculatedDistance;
  Position? get targetPosition => _targetPosition;
  
  // Location status
  bool get isLocationReady => _hasPermission && _isLocationEnabled && !_isMockLocation;
  bool get isAccurate => _currentAccuracy == LocationAccuracy.high || _currentAccuracy == LocationAccuracy.best;

  LocationProvider() {
    _initializeLocation();
  }

  // Initialize location services
  Future<void> _initializeLocation() async {
    await checkLocationStatus();
  }

  // Check overall location status
  Future<void> checkLocationStatus() async {
    try {
      _setLoading(true);
      _clearError();

      // Check if location services are enabled
      _isLocationEnabled = await Geolocator.isLocationServiceEnabled();
      
      if (!_isLocationEnabled) {
        _setError('Location services are disabled. Please enable GPS.');
        _setLoading(false);
        return;
      }

      // Check and request permissions
      _hasPermission = await _locationService.checkLocationPermission();
      
      if (!_hasPermission) {
        _hasPermission = await _locationService.requestLocationPermission();
        
        if (!_hasPermission) {
          _setError('Location permission denied. Please grant location access.');
          _setLoading(false);
          return;
        }
      }

      // Get current position if we have permission
      if (_hasPermission && _isLocationEnabled) {
        await getCurrentLocation();
      }
    } catch (e) {
      _setError('Failed to initialize location services.');
    } finally {
      _setLoading(false);
    }
  }

  // Get current location
  Future<bool> getCurrentLocation() async {
    try {
      _setLoading(true);
      _clearError();

      if (!_hasPermission || !_isLocationEnabled) {
        await checkLocationStatus();
        if (!_hasPermission || !_isLocationEnabled) {
          _setLoading(false);
          return false;
        }
      }

      _currentPosition = await _locationService.getCurrentLocation();
      
      if (_currentPosition != null) {
        _currentAccuracy = _currentPosition!.accuracy < 10 
            ? LocationAccuracy.high 
            : _currentPosition!.accuracy < 50 
                ? LocationAccuracy.medium 
                : LocationAccuracy.low;
        
        // Check for mock location
        _isMockLocation = await _locationService.isMockLocation(_currentPosition!);
        
        if (_isMockLocation) {
          _setError('Mock location detected. Please disable fake GPS apps.');
          return false;
        }
        
        // Calculate distance to target if set
        if (_targetPosition != null) {
          _calculateDistanceToTarget();
        }
        
        return true;
      } else {
        _setError('Unable to get current location. Please try again.');
        return false;
      }
    } catch (e) {
      _setError('Failed to get your current location.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Start location tracking
  Future<bool> startLocationTracking() async {
    try {
      if (isTracking) {
        return true;
      }

      if (!_hasPermission || !_isLocationEnabled) {
        await checkLocationStatus();
        if (!_hasPermission || !_isLocationEnabled) {
          return false;
        }
      }

      final positionStream = _locationService.getLocationStream();
      
      _positionStreamSubscription = positionStream.listen(
        (Position position) {
          _currentPosition = position;
          
          _currentAccuracy = position.accuracy < 10 
              ? LocationAccuracy.high 
              : position.accuracy < 50 
                  ? LocationAccuracy.medium 
                  : LocationAccuracy.low;
          
          // Calculate distance to target if set
          if (_targetPosition != null) {
            _calculateDistanceToTarget();
          }
          
          notifyListeners();
        },
        onError: (error) {
          _setError('Location tracking failed.');
          stopLocationTracking();
        },
      );

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Could not start location tracking.');
      return false;
    }
  }

  // Stop location tracking
  void stopLocationTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    notifyListeners();
  }

  // Set target position for distance calculations
  void setTargetPosition(double latitude, double longitude) {
    _targetPosition = Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
    
    if (_currentPosition != null) {
      _calculateDistanceToTarget();
    }
    
    notifyListeners();
  }

  // Clear target position
  void clearTargetPosition() {
    _targetPosition = null;
    _lastCalculatedDistance = null;
    notifyListeners();
  }

  // Calculate distance to target
  void _calculateDistanceToTarget() {
    if (_currentPosition != null && _targetPosition != null) {
      _lastCalculatedDistance = _locationService.calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        _targetPosition!.latitude,
        _targetPosition!.longitude,
      );
    }
  }

  // Check if within radius of target
  bool isWithinRadius(double radiusMeters) {
    if (_lastCalculatedDistance == null) {
      return false;
    }
    return _lastCalculatedDistance! <= radiusMeters;
  }

  // Calculate distance between two points
  double calculateDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    return _locationService.calculateDistance(lat1, lon1, lat2, lon2);
  }

  // Check if location is accurate enough
  Future<bool> isLocationAccurate() async {
    try {
      return await _locationService.isLocationAccurate();
    } catch (e) {
      return false;
    }
  }

  // Request location permission
  Future<bool> requestLocationPermission() async {
    try {
      _hasPermission = await _locationService.requestLocationPermission();
      notifyListeners();
      return _hasPermission;
    } catch (e) {
      _setError('Failed to request location permission.');
      return false;
    }
  }

  // Open location settings
  Future<bool> openLocationSettings() async {
    try {
      return await _locationService.openLocationSettings();
    } catch (e) {
      _setError('Could not open location settings.');
      return false;
    }
  }

  // Open app settings
  Future<bool> openAppSettings() async {
    try {
      return await _locationService.openAppSettings();
    } catch (e) {
      _setError('Could not open app settings.');
      return false;
    }
  }

  // Refresh location status
  Future<void> refreshLocationStatus() async {
    await checkLocationStatus();
  }

  // Get location status message
  String getLocationStatusMessage() {
    if (!_isLocationEnabled) {
      return 'Location services are disabled. Please enable GPS.';
    }
    
    if (!_hasPermission) {
      return 'Location permission not granted. Please allow location access.';
    }
    
    if (_isMockLocation) {
      return 'Mock location detected. Please disable fake GPS apps.';
    }
    
    if (_currentPosition == null) {
      return 'Unable to get current location. Please try again.';
    }
    
    if (!isAccurate) {
      return 'Location accuracy is low. Please move to an open area.';
    }
    
    return 'Location is ready.';
  }

  // Get accuracy description
  String getAccuracyDescription() {
    switch (_currentAccuracy) {
      case LocationAccuracy.high:
      case LocationAccuracy.best:
        return 'High (${_currentPosition?.accuracy.toInt() ?? 0}m)';
      case LocationAccuracy.medium:
        return 'Medium (${_currentPosition?.accuracy.toInt() ?? 0}m)';
      case LocationAccuracy.low:
        return 'Low (${_currentPosition?.accuracy.toInt() ?? 0}m)';
      default:
        return 'Unknown';
    }
  }

  // Get distance description
  String getDistanceDescription() {
    if (_lastCalculatedDistance == null) {
      return 'Distance unknown';
    }
    
    if (_lastCalculatedDistance! < 1000) {
      return '${_lastCalculatedDistance!.toInt()}m away';
    } else {
      return '${(_lastCalculatedDistance! / 1000).toStringAsFixed(1)}km away';
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }

  // Clear all data
  void clear() {
    stopLocationTracking();
    _currentPosition = null;
    _targetPosition = null;
    _lastCalculatedDistance = null;
    _currentAccuracy = LocationAccuracy.unknown;
    _isMockLocation = false;
    _clearError();
    notifyListeners();
  }

  @override
  void dispose() {
    stopLocationTracking();
    super.dispose();
  }
}