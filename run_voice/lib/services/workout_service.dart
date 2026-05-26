import 'dart:async';
import '../models/alert_config.dart';
import '../models/preset.dart';
import '../models/heart_rate_zone.dart';
import '../utils/hr_zone_calculator.dart';
import 'tts_service.dart';
import 'bluetooth_service.dart';
import 'location_service.dart';

enum WorkoutState { idle, ready, running, paused }

class WorkoutHistoryRecord {
  final int timeSeconds;
  final double distanceKm;
  final int heartRate;

  WorkoutHistoryRecord({
    required this.timeSeconds,
    required this.distanceKm,
    required this.heartRate,
  });
}

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
  final Map<String, double> _alertDistanceCheckpoints = {};
  final Map<String, Timer> _stepAlertTimers = {};
  final Map<String, double> _stepAlertDistanceCheckpoints = {};
  final Map<String, int> _coachingOutDuration = {};
  final Map<String, int> _coachingOkDuration = {};
  final Map<String, bool> _coachingWasOut = {};
  List<HeartRateZone> _hrZones = [];
  final List<WorkoutHistoryRecord> _history = [];

  // Current workout data
  int _currentHeartRate = 0;
  int? _currentZone;
  double _distanceKm = 0;
  double _paceMinPerKm = 0;
  double _speedKmh = 0;
  Duration _elapsedTime = Duration.zero;

  bool _speakUnits = true;

  int _currentIntervalIndex = 0;
  double _currentIntervalStartDistanceKm = 0;
  Duration _currentIntervalStartTime = Duration.zero;

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
  double get speedKmh => _speedKmh;
  Duration get elapsedTime => _elapsedTime;
  bool get isRunning => _state == WorkoutState.running;
  bool get isPaused => _state == WorkoutState.paused;
  int get currentIntervalIndex => _currentIntervalIndex;
  double get currentIntervalStartDistanceKm => _currentIntervalStartDistanceKm;
  Duration get currentIntervalStartTime => _currentIntervalStartTime;

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
  Future<void> startWorkout(
    Preset preset, {
    bool speakUnits = true,
    String? userName,
    bool speakName = true,
  }) async {
    _speakUnits = speakUnits;
    _activePreset = preset;
    _startTime = DateTime.now();
    _pausedDuration = Duration.zero;
    _currentHeartRate = 0;
    _currentZone = null;
    _distanceKm = 0;
    _paceMinPerKm = 0;
    _speedKmh = 0;
    _elapsedTime = Duration.zero;
    _coachingOutDuration.clear();
    _coachingOkDuration.clear();
    _coachingWasOut.clear();
    _alertDistanceCheckpoints.clear();
    _history.clear();

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
      // Calculate speed from pace
      if (_paceMinPerKm > 0 && !_paceMinPerKm.isInfinite) {
        _speedKmh = 60 / _paceMinPerKm;
      }

      if (_activePreset?.isIntervalTraining == true) {
        _evaluateIntervals();
        _checkStepDistanceAlerts();
      } else {
        _checkDistanceAlerts();
      }
      onDataUpdated?.call();
    };

    _locationService.onPaceUpdate = (pace) {
      _paceMinPerKm = pace;
      if (pace > 0 && !pace.isInfinite) {
        _speedKmh = 60 / pace;
      }
      onDataUpdated?.call();
    };

    // Start location tracking
    await _locationService.startTracking();

    // Start elapsed time timer
    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_state == WorkoutState.running) {
        _elapsedTime = DateTime.now().difference(_startTime!) - _pausedDuration;

        _history.add(WorkoutHistoryRecord(
          timeSeconds: _elapsedTime.inSeconds,
          distanceKm: _distanceKm,
          heartRate: _currentHeartRate,
        ));

        if (_activePreset?.isIntervalTraining == true) {
          _evaluateIntervals();
          _evaluateStepCoachingAlerts();
        } else {
          _evaluateCoachingAlerts();
        }

        onDataUpdated?.call();
      }
    });

    _state = WorkoutState.running;
    onStateChanged?.call(_state);

    if (_activePreset!.isIntervalTraining &&
        _activePreset!.intervals.isNotEmpty) {
      _currentIntervalIndex = 0;
      _currentIntervalStartDistanceKm = 0;
      _currentIntervalStartTime = Duration.zero;

      if (_activePreset!.announceStart) {
        final prefix =
            (speakName && userName != null && userName.isNotEmpty)
                ? 'Ciao $userName. '
                : '';
        _ttsService.enqueue(
          '${prefix}Allenamento iniziato. Prima fase: ${_activePreset!.intervals.first.name}',
        );
      }
      _setupIntervalSpecificAlerts();
    } else {
      _setupAlertTimers(preset);
      _initDistanceCheckpoints(preset);
      if (_activePreset!.announceStart) {
        final prefix =
            (speakName && userName != null && userName.isNotEmpty)
                ? 'Ciao $userName. '
                : '';
        _ttsService.enqueue('${prefix}Allenamento iniziato. Buona corsa!');
      }
    }
  }

  void _evaluateIntervals() {
    if (_activePreset == null ||
        !_activePreset!.isIntervalTraining ||
        _activePreset!.intervals.isEmpty) {
      return;
    }
    if (_currentIntervalIndex >= _activePreset!.intervals.length) return;

    final currentStep = _activePreset!.intervals[_currentIntervalIndex];
    bool stepCompleted = false;

    if (currentStep.type == AlertTrigger.time) {
      final elapsedInStep = _elapsedTime - _currentIntervalStartTime;
      if (elapsedInStep.inSeconds >= currentStep.durationSeconds) {
        stepCompleted = true;
      }
    } else if (currentStep.type == AlertTrigger.distance) {
      final distanceInStep = _distanceKm - _currentIntervalStartDistanceKm;
      if (distanceInStep * 1000 >= currentStep.distanceMeters) {
        stepCompleted = true;
      }
    }

    if (stepCompleted) {
      _currentIntervalIndex++;

      if (_currentIntervalIndex < _activePreset!.intervals.length) {
        final nextStep = _activePreset!.intervals[_currentIntervalIndex];
        _ttsService.enqueue('Fase completata. Inizia: ${nextStep.name}');
        _currentIntervalStartDistanceKm = _distanceKm;
        _currentIntervalStartTime = _elapsedTime;
        _setupIntervalSpecificAlerts();
      } else {
        _ttsService.enqueue('Tutte le ripetute sono state completate.');
        _cleanupIntervalSpecificAlerts();
      }
    }
  }

  /// Initialize distance checkpoints for distance-triggered alerts
  void _initDistanceCheckpoints(Preset preset) {
    for (final alert in preset.alerts) {
      if (!alert.enabled) continue;
      if (alert.trigger == AlertTrigger.distance) {
        _alertDistanceCheckpoints[alert.id] = alert.intervalMeters / 1000;
      }
    }
  }

  /// Check if any distance-based alerts should fire
  void _checkDistanceAlerts() {
    if (_activePreset == null) return;
    for (final alert in _activePreset!.alerts) {
      if (!alert.enabled || alert.trigger != AlertTrigger.distance) continue;

      final checkpoint = _alertDistanceCheckpoints[alert.id];
      if (checkpoint == null) continue;

      if (_distanceKm >= checkpoint) {
        _fireAlert(alert);
        // Set next checkpoint
        _alertDistanceCheckpoints[alert.id] =
            checkpoint + (alert.intervalMeters / 1000);
      }
    }
  }

  double? _calculateWindowedValue(CoachingAlert alert) {
    final windowSecs = alert.calculationWindowSeconds;
    if (windowSecs == null || windowSecs <= 0 || _history.isEmpty) {
      return alert.getCurrentValue(
        heartRate: _currentHeartRate > 0 ? _currentHeartRate : null,
        heartRateZone: _currentZone,
        speedKmh: _speedKmh > 0 ? _speedKmh : null,
        paceMinPerKm: _paceMinPerKm > 0 ? _paceMinPerKm : null,
      );
    }

    final targetTime = _elapsedTime.inSeconds - windowSecs;
    final actualTargetTime = targetTime < 0 ? 0 : targetTime;

    // Find the record closest to actualTargetTime
    WorkoutHistoryRecord? oldRecord;
    int minDiff = 999999;
    for (final record in _history) {
      final diff = (record.timeSeconds - actualTargetTime).abs();
      if (diff < minDiff) {
        minDiff = diff;
        oldRecord = record;
      }
    }

    if (oldRecord == null) {
      return alert.getCurrentValue(
        heartRate: _currentHeartRate > 0 ? _currentHeartRate : null,
        heartRateZone: _currentZone,
        speedKmh: _speedKmh > 0 ? _speedKmh : null,
        paceMinPerKm: _paceMinPerKm > 0 ? _paceMinPerKm : null,
      );
    }

    final deltaDistance = _distanceKm - oldRecord.distanceKm;
    final deltaTimeSeconds = _elapsedTime.inSeconds - oldRecord.timeSeconds;

    switch (alert.metric) {
      case AlertMetric.pace:
        if (deltaDistance <= 0.001 || deltaTimeSeconds <= 0) return null;
        // pace = (minutes) / km
        return (deltaTimeSeconds / 60.0) / deltaDistance;

      case AlertMetric.speed:
        if (deltaTimeSeconds <= 0) return null;
        return deltaDistance / (deltaTimeSeconds / 3600.0);

      case AlertMetric.bpm:
        // Average heart rate over the window
        final recentRecords = _history.where((r) => r.timeSeconds >= actualTargetTime && r.heartRate > 0).toList();
        if (recentRecords.isEmpty) return null;
        final sum = recentRecords.fold<int>(0, (prev, r) => prev + r.heartRate);
        return sum / recentRecords.length;

      case AlertMetric.hrZone:
        // Average heart rate and convert to zone
        final recentRecords = _history.where((r) => r.timeSeconds >= actualTargetTime && r.heartRate > 0).toList();
        if (recentRecords.isEmpty) return null;
        final sum = recentRecords.fold<int>(0, (prev, r) => prev + r.heartRate);
        final avgHeartRate = (sum / recentRecords.length).round();
        if (_hrZones.isNotEmpty) {
          return HRZoneCalculator.getCurrentZone(avgHeartRate, _hrZones)?.toDouble();
        }
        return null;

      default:
        return null;
    }
  }

  /// Evaluate coaching alerts every second
  void _evaluateCoachingAlerts() {
    if (_activePreset == null) return;
    for (var alert in _activePreset!.coachingAlerts) {
      if (!alert.enabled) continue;

      final value = _calculateWindowedValue(alert);

      if (value == null) {
        _coachingOutDuration[alert.id] = 0;
        _coachingOkDuration[alert.id] = 0;
        continue;
      }

      if (value >= alert.minValue && value <= alert.maxValue) {
        // In range
        _coachingOkDuration[alert.id] =
            (_coachingOkDuration[alert.id] ?? 0) + 1;

        final wasOut = _coachingWasOut[alert.id] ?? false;
        bool shouldNotify = false;

        if (alert.notifyOnReturn && wasOut) {
          if (_coachingOkDuration[alert.id]! >= alert.outOfRangeDelaySeconds) {
            shouldNotify = true;
          }
        } else {
          if (_coachingOkDuration[alert.id]! >= alert.okIntervalSeconds) {
            shouldNotify = true;
          }
        }

        if (shouldNotify) {
          _ttsService.enqueue(
            alert.buildMessage(value, speakUnits: _speakUnits),
          );
          _coachingOkDuration[alert.id] = 0;
          _coachingWasOut[alert.id] = false;
        }
      } else {
        // Out of range
        _coachingWasOut[alert.id] = true;
        _coachingOkDuration[alert.id] = 0;
        _coachingOutDuration[alert.id] =
            (_coachingOutDuration[alert.id] ?? 0) + 1;

        if (_coachingOutDuration[alert.id]! >= alert.outOfRangeDelaySeconds) {
          _ttsService.enqueue(
            alert.buildMessage(value, speakUnits: _speakUnits),
          );
          _coachingOutDuration[alert.id] = 0;
        }
      }
    }
  }

  /// Setup periodic time-based alert timers
  void _setupAlertTimers(Preset preset) {
    for (final alert in preset.alerts) {
      if (!alert.enabled) continue;
      if (alert.trigger != AlertTrigger.time) continue;

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
      speedKmh: _speedKmh > 0 ? _speedKmh : null,
      elapsedTime: _elapsedTime,
      speakUnits: _speakUnits,
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
    _alertDistanceCheckpoints.clear();
    _cleanupIntervalSpecificAlerts();

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
    _cleanupIntervalSpecificAlerts();
    _bluetoothService.onHeartRateUpdate = null;
    _locationService.onDistanceUpdate = null;
    _locationService.onPaceUpdate = null;
  }

  void _setupIntervalSpecificAlerts() {
    _cleanupIntervalSpecificAlerts();

    if (_activePreset == null || _state != WorkoutState.running) return;
    if (_currentIntervalIndex >= _activePreset!.intervals.length) return;

    final currentStep = _activePreset!.intervals[_currentIntervalIndex];

    for (final alert in currentStep.alerts) {
      if (!alert.enabled) continue;
      if (alert.trigger == AlertTrigger.time) {
        final timer = Timer.periodic(Duration(seconds: alert.intervalSeconds), (_) {
          if (_state == WorkoutState.running) {
            _fireStepAlert(alert);
          }
        });
        _stepAlertTimers[alert.id] = timer;
      } else if (alert.trigger == AlertTrigger.distance) {
        _stepAlertDistanceCheckpoints[alert.id] = alert.intervalMeters / 1000.0;
      }
    }
  }

  void _cleanupIntervalSpecificAlerts() {
    for (final timer in _stepAlertTimers.values) {
      timer.cancel();
    }
    _stepAlertTimers.clear();
    _stepAlertDistanceCheckpoints.clear();
  }

  void _checkStepDistanceAlerts() {
    if (_activePreset == null || _currentIntervalIndex >= _activePreset!.intervals.length) return;
    final currentStep = _activePreset!.intervals[_currentIntervalIndex];
    final distanceInStep = _distanceKm - _currentIntervalStartDistanceKm;

    for (final alert in currentStep.alerts) {
      if (!alert.enabled || alert.trigger != AlertTrigger.distance) continue;

      final checkpoint = _stepAlertDistanceCheckpoints[alert.id];
      if (checkpoint == null) continue;

      if (distanceInStep >= checkpoint) {
        _fireStepAlert(alert);
        _stepAlertDistanceCheckpoints[alert.id] = checkpoint + (alert.intervalMeters / 1000.0);
      }
    }
  }

  void _evaluateStepCoachingAlerts() {
    if (_activePreset == null || _currentIntervalIndex >= _activePreset!.intervals.length) return;
    final currentStep = _activePreset!.intervals[_currentIntervalIndex];

    for (var alert in currentStep.coachingAlerts) {
      if (!alert.enabled) continue;

      final value = _calculateWindowedValue(alert);

      if (value == null) {
        _coachingOutDuration[alert.id] = 0;
        _coachingOkDuration[alert.id] = 0;
        continue;
      }

      if (value >= alert.minValue && value <= alert.maxValue) {
        _coachingOkDuration[alert.id] = (_coachingOkDuration[alert.id] ?? 0) + 1;

        final wasOut = _coachingWasOut[alert.id] ?? false;
        bool shouldNotify = false;

        if (alert.notifyOnReturn && wasOut) {
          if (_coachingOkDuration[alert.id]! >= alert.outOfRangeDelaySeconds) {
            shouldNotify = true;
          }
        } else {
          if (_coachingOkDuration[alert.id]! >= alert.okIntervalSeconds) {
            shouldNotify = true;
          }
        }

        if (shouldNotify) {
          _ttsService.enqueue(alert.buildMessage(value, speakUnits: _speakUnits));
          _coachingOkDuration[alert.id] = 0;
          _coachingWasOut[alert.id] = false;
        }
      } else {
        _coachingWasOut[alert.id] = true;
        _coachingOkDuration[alert.id] = 0;
        _coachingOutDuration[alert.id] = (_coachingOutDuration[alert.id] ?? 0) + 1;

        if (_coachingOutDuration[alert.id]! >= alert.outOfRangeDelaySeconds) {
          _ttsService.enqueue(alert.buildMessage(value, speakUnits: _speakUnits));
          _coachingOutDuration[alert.id] = 0;
        }
      }
    }
  }

  void _fireStepAlert(AlertConfig alert) {
    final intervalDistance = _distanceKm - _currentIntervalStartDistanceKm;
    final intervalTime = _elapsedTime - _currentIntervalStartTime;
    double? intervalPace;
    double? intervalSpeed;
    if (intervalDistance > 0) {
      intervalPace = (intervalTime.inSeconds / 60) / intervalDistance;
      if (intervalPace > 0 && !intervalPace.isInfinite) {
        intervalSpeed = 60 / intervalPace;
      }
    }

    final message = alert.buildMessage(
      heartRate: _currentHeartRate > 0 ? _currentHeartRate : null,
      heartRateZone: _currentZone,
      distanceKm: _distanceKm,
      paceMinPerKm: _paceMinPerKm > 0 ? _paceMinPerKm : null,
      speedKmh: _speedKmh > 0 ? _speedKmh : null,
      elapsedTime: _elapsedTime,
      intervalDistance: intervalDistance,
      intervalPace: intervalPace,
      intervalSpeed: intervalSpeed,
      intervalTime: intervalTime,
      speakUnits: _speakUnits,
    );
    _ttsService.enqueue(message);
  }
}
