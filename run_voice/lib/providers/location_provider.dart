import 'package:flutter/material.dart';
import '../services/location_service.dart';

class LocationProvider extends ChangeNotifier {
  final LocationService _service = LocationService();
  bool _isAvailable = false;
  // ignore: prefer_final_fields
  bool _isTracking = false;
  // ignore: prefer_final_fields
  double _distanceKm = 0;
  // ignore: prefer_final_fields
  double _paceMinPerKm = 0;

  LocationService get service => _service;
  bool get isAvailable => _isAvailable;
  bool get isTracking => _isTracking;
  double get distanceKm => _distanceKm;
  double get paceMinPerKm => _paceMinPerKm;

  LocationProvider() {
    _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    _isAvailable = await _service.isLocationAvailable();
    notifyListeners();
  }

  Future<void> checkAvailability() async {
    _isAvailable = await _service.isLocationAvailable();
    notifyListeners();
  }

  Future<bool> requestPermissions() async {
    final result = await _service.requestPermissions();
    _isAvailable = result;
    notifyListeners();
    return result;
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
