import 'dart:async';
import '../models/alert_config.dart';
import '../models/preset.dart';
import '../models/heart_rate_zone.dart';
import '../utils/hr_zone_calculator.dart';
import 'tts_service.dart';
import 'bluetooth_service.dart';
import 'location_service.dart';

enum WorkoutState { idle, ready, running, paused }

class WorkoutService {
  final TtsService _ttsService;
  final HRBluetoothService _bluetoothService;
  final LocationService _locationService;

  WorkoutState _state = WorkoutState.idle;
  Preset? _activePreset;
  DateTime? _startTime;
  DateTime? _pauseTime;
  Duration _pausedDuration = Duration.zero;
  Timer? _workoutTimer;
  final Map<String, Timer> _alertTimers = {};
  List<HeartRateZone> _hrZones = [];

  // Current workout data
  int _currentHeartRate = 0;
  int? _currentZone;
  double _distanceKm = 0;
  double _paceMinPerKm = 0;
  Duration _elapsedTime = Duration.zero;

  // Callbacks
  void Function(WorkoutState state)? onStateChanged;
  void Function()? onDataUpdated;

  WorkoutService({
    required TtsService ttsService,
    required HRBluetoothService bluetoothService,
    required LocationService locationService,
  }) : _ttsService = ttsService,
       _bluetoothService = bluetoothService,
       _locationService = locationService;

  WorkoutState get state => _state;
  Preset? get activePreset => _activePreset;
  int get currentHeartRate => _currentHeartRate;
  int? get currentZone => _currentZone;
  double get distanceKm => _distanceKm;
  double get paceMinPerKm => _paceMinPerKm;
  Duration get elapsedTime => _elapsedTime;
  bool get isRunning => _state == WorkoutState.running;
  bool get isPaused => _state == WorkoutState.paused;

  void setHRZones(List<HeartRateZone> zones) {
    _hrZones = zones;
  }

  /// Check if sensors are ready
  Future<Map<String, bool>> checkSensors() async {
    final gpsAvailable = await _locationService.isLocationAvailable();
    final btConnected = _bluetoothService.isConnected;

    return {'gps': gpsAvailable, 'heartRate': btConnected};
  }

  /// Start workout with given preset
  Future<void> startWorkout(Preset preset) async {
    _activePreset = preset;
    _startTime = DateTime.now();
    _pausedDuration = Duration.zero;
    _currentHeartRate = 0;
    _currentZone = null;
    _distanceKm = 0;
    _paceMinPerKm = 0;
    _elapsedTime = Duration.zero;

    // Setup Bluetooth HR callbacks
    _bluetoothService.onHeartRateUpdate = (hr) {
      _currentHeartRate = hr;
      if (_hrZones.isNotEmpty) {
        _currentZone = HRZoneCalculator.getCurrentZone(hr, _hrZones);
      }
      onDataUpdated?.call();
    };

    // Setup Location callbacks
    _locationService.onDistanceUpdate = (dist) {
      _distanceKm = dist;
      onDataUpdated?.call();
    };

    _locationService.onPaceUpdate = (pace) {
      _paceMinPerKm = pace;
      onDataUpdated?.call();
    };

    // Start location tracking
    await _locationService.startTracking();

    // Start elapsed time timer
    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_state == WorkoutState.running) {
        _elapsedTime = DateTime.now().difference(_startTime!) - _pausedDuration;
        onDataUpdated?.call();
      }
    });

    // Setup alert timers
    _setupAlertTimers(preset);

    _state = WorkoutState.running;
    onStateChanged?.call(_state);

    // Announce workout start
    _ttsService.enqueue('Allenamento iniziato. Buona corsa!');
  }

  /// Setup periodic alert timers
  void _setupAlertTimers(Preset preset) {
    for (final alert in preset.alerts) {
      if (!alert.enabled) continue;

      final timer = Timer.periodic(Duration(seconds: alert.intervalSeconds), (
        _,
      ) {
        if (_state == WorkoutState.running) {
          _fireAlert(alert);
        }
      });
      _alertTimers[alert.id] = timer;
    }
  }

  /// Fire a specific alert
  void _fireAlert(AlertConfig alert) {
    final message = alert.buildMessage(
      heartRate: _currentHeartRate > 0 ? _currentHeartRate : null,
      heartRateZone: _currentZone,
      distanceKm: _distanceKm,
      paceMinPerKm: _paceMinPerKm > 0 ? _paceMinPerKm : null,
      elapsedTime: _elapsedTime,
    );
    _ttsService.enqueue(message);
  }

  /// Pause workout
  void pauseWorkout() {
    if (_state != WorkoutState.running) return;
    _pauseTime = DateTime.now();
    _state = WorkoutState.paused;
    onStateChanged?.call(_state);
    _ttsService.enqueue('Allenamento in pausa');
  }

  /// Resume workout
  void resumeWorkout() {
    if (_state != WorkoutState.paused || _pauseTime == null) return;
    _pausedDuration += DateTime.now().difference(_pauseTime!);
    _pauseTime = null;
    _state = WorkoutState.running;
    onStateChanged?.call(_state);
    _ttsService.enqueue('Allenamento ripreso');
  }

  /// Stop workout
  Future<void> stopWorkout() async {
    // Cancel all timers
    _workoutTimer?.cancel();
    for (final timer in _alertTimers.values) {
      timer.cancel();
    }
    _alertTimers.clear();

    // Stop tracking
    _locationService.stopTracking();

    // Announce end
    final totalTime = _formatDuration(_elapsedTime);
    _ttsService.enqueue(
      'Allenamento terminato. Tempo totale: $totalTime. '
      'Distanza: ${_distanceKm.toStringAsFixed(2)} chilometri.',
    );

    _state = WorkoutState.idle;
    onStateChanged?.call(_state);
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '$hours ore $minutes minuti $seconds secondi';
    }
    return '$minutes minuti $seconds secondi';
  }

  void dispose() {
    _workoutTimer?.cancel();
    for (final timer in _alertTimers.values) {
      timer.cancel();
    }
    _alertTimers.clear();
    _bluetoothService.onHeartRateUpdate = null;
    _locationService.onDistanceUpdate = null;
    _locationService.onPaceUpdate = null;
  }
}
