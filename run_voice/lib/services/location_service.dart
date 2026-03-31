import 'dart:async';
import 'package:geolocator/geolocator.dart';

class LocationService {
  StreamSubscription<Position>? _positionSubscription;
  Position? _lastPosition;
  Position? _previousPosition;
  double _totalDistanceMeters = 0;
  bool _isTracking = false;
  DateTime? _lastPositionTime;

  double get totalDistanceKm => _totalDistanceMeters / 1000;
  double get totalDistanceMeters => _totalDistanceMeters;
  bool get isTracking => _isTracking;
  Position? get lastPosition => _lastPosition;

  // Current pace in min/km
  double _currentPaceMinPerKm = 0;
  double get currentPaceMinPerKm => _currentPaceMinPerKm;

  // Callbacks
  void Function(Position position)? onPositionUpdate;
  void Function(double distanceKm)? onDistanceUpdate;
  void Function(double paceMinPerKm)? onPaceUpdate;

  /// Check if GPS/location services are available and enabled
  Future<bool> isLocationAvailable() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (_) {
      return false;
    }
  }

  /// Request location permissions
  Future<bool> requestPermissions() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        return false;
      }

      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (_) {
      return false;
    }
  }

  /// Get current GPS status
  Future<LocationPermission> getPermissionStatus() async {
    return await Geolocator.checkPermission();
  }

  /// Start tracking position
  Future<void> startTracking() async {
    if (_isTracking) return;

    final hasPermission = await requestPermissions();
    if (!hasPermission) return;

    _totalDistanceMeters = 0;
    _lastPosition = null;
    _previousPosition = null;
    _currentPaceMinPerKm = 0;
    _isTracking = true;

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // Update every 5 meters
    );

    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (position) {
            _previousPosition = _lastPosition;
            _lastPosition = position;
            final now = DateTime.now();

            if (_previousPosition != null) {
              final distance = Geolocator.distanceBetween(
                _previousPosition!.latitude,
                _previousPosition!.longitude,
                position.latitude,
                position.longitude,
              );

              // Only count if distance is reasonable (filter GPS noise)
              if (distance > 1 && distance < 100) {
                _totalDistanceMeters += distance;
                onDistanceUpdate?.call(totalDistanceKm);

                // Calculate pace
                if (_lastPositionTime != null) {
                  final timeElapsed = now
                      .difference(_lastPositionTime!)
                      .inSeconds;
                  if (timeElapsed > 0 && distance > 0) {
                    // Speed in m/s
                    final speedMs = distance / timeElapsed;
                    // Pace in min/km
                    if (speedMs > 0.5) {
                      // Only calculate pace if actually moving
                      _currentPaceMinPerKm = (1000 / speedMs) / 60;
                      onPaceUpdate?.call(_currentPaceMinPerKm);
                    }
                  }
                }
              }
            }

            _lastPositionTime = now;
            onPositionUpdate?.call(position);
          },
        );
  }

  /// Stop tracking
  void stopTracking() {
    _isTracking = false;
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  /// Reset all tracking data
  void reset() {
    _totalDistanceMeters = 0;
    _lastPosition = null;
    _previousPosition = null;
    _currentPaceMinPerKm = 0;
    _lastPositionTime = null;
  }

  void dispose() {
    stopTracking();
  }
}
