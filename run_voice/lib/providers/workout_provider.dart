import 'package:flutter/material.dart';
import '../models/preset.dart';
import '../services/workout_service.dart';
import '../services/tts_service.dart';
import '../services/bluetooth_service.dart';
import '../services/location_service.dart';
import '../models/heart_rate_zone.dart';

class WorkoutProvider extends ChangeNotifier {
  late WorkoutService _service;
  WorkoutState _state = WorkoutState.idle;
  int _heartRate = 0;
  int? _currentZone;
  double _distanceKm = 0;
  double _paceMinPerKm = 0;
  double _speedKmh = 0;
  Duration _elapsedTime = Duration.zero;
  Preset? _activePreset;
  int _currentIntervalIndex = 0;
  double _currentIntervalStartDistanceKm = 0.0;
  Duration _currentIntervalStartTime = Duration.zero;

  WorkoutProvider({
    required TtsService ttsService,
    required HRBluetoothService bluetoothService,
    required LocationService locationService,
  }) {
    _service = WorkoutService(
      ttsService: ttsService,
      bluetoothService: bluetoothService,
      locationService: locationService,
    );

    _service.onStateChanged = (state) {
      _state = state;
      notifyListeners();
    };

    _service.onDataUpdated = () {
      _heartRate = _service.currentHeartRate;
      _currentZone = _service.currentZone;
      _distanceKm = _service.distanceKm;
      _paceMinPerKm = _service.paceMinPerKm;
      _speedKmh = _service.speedKmh;
      _elapsedTime = _service.elapsedTime;
      _currentIntervalIndex = _service.currentIntervalIndex;
      _currentIntervalStartDistanceKm = _service.currentIntervalStartDistanceKm;
      _currentIntervalStartTime = _service.currentIntervalStartTime;
      notifyListeners();
    };
  }

  WorkoutState get state => _state;
  int get heartRate => _heartRate;
  int? get currentZone => _currentZone;
  double get distanceKm => _distanceKm;
  double get paceMinPerKm => _paceMinPerKm;
  double get speedKmh => _speedKmh;
  Duration get elapsedTime => _elapsedTime;
  Preset? get activePreset => _activePreset;
  int get currentIntervalIndex => _currentIntervalIndex;
  double get currentIntervalStartDistanceKm => _currentIntervalStartDistanceKm;
  Duration get currentIntervalStartTime => _currentIntervalStartTime;
  bool get isRunning => _state == WorkoutState.running;
  bool get isPaused => _state == WorkoutState.paused;
  bool get isActive =>
      _state == WorkoutState.running || _state == WorkoutState.paused;

  void setHRZones(List<HeartRateZone> zones) {
    _service.setHRZones(zones);
  }

  Future<Map<String, bool>> checkSensors() async {
    return await _service.checkSensors();
  }

  Future<void> startWorkout(
    Preset preset, {
    bool speakUnits = true,
    String? userName,
    bool speakName = true,
  }) async {
    _activePreset = preset;
    await _service.startWorkout(
      preset,
      speakUnits: speakUnits,
      userName: userName,
      speakName: speakName,
    );
  }

  void pauseWorkout() {
    _service.pauseWorkout();
  }

  void resumeWorkout() {
    _service.resumeWorkout();
  }

  Future<void> stopWorkout() async {
    await _service.stopWorkout();
    _activePreset = null;
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
