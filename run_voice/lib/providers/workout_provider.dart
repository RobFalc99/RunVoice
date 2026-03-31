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
  Duration _elapsedTime = Duration.zero;
  Preset? _activePreset;

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
      _elapsedTime = _service.elapsedTime;
      notifyListeners();
    };
  }

  WorkoutState get state => _state;
  int get heartRate => _heartRate;
  int? get currentZone => _currentZone;
  double get distanceKm => _distanceKm;
  double get paceMinPerKm => _paceMinPerKm;
  Duration get elapsedTime => _elapsedTime;
  Preset? get activePreset => _activePreset;
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

  Future<void> startWorkout(Preset preset) async {
    _activePreset = preset;
    await _service.startWorkout(preset);
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
