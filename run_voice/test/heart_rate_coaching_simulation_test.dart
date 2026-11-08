import 'package:flutter_test/flutter_test.dart';
import 'package:run_voice/models/alert_config.dart';
import 'package:run_voice/models/preset.dart';
import 'package:run_voice/services/bluetooth_service.dart';
import 'package:run_voice/services/location_service.dart';
import 'package:run_voice/services/tts_service.dart';
import 'package:run_voice/services/workout_service.dart';

class MockTtsService implements TtsService {
  final List<String> spokenMessages = [];

  @override
  void enqueue(String message) {
    spokenMessages.add(message);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockHRBluetoothService implements HRBluetoothService {
  @override
  bool isConnected = true;

  @override
  int currentHeartRate = 0;

  @override
  void Function(int heartRate)? onHeartRateUpdate;

  @override
  void Function(bool connected)? onConnectionChanged;

  void emitHeartRate(int hr) {
    currentHeartRate = hr;
    onHeartRateUpdate?.call(hr);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockLocationService implements LocationService {
  @override
  bool isTracking = false;

  @override
  double totalDistanceKm = 0;

  @override
  double currentPaceMinPerKm = 0;

  @override
  void Function(double distanceKm)? onDistanceUpdate;

  @override
  void Function(double paceMinPerKm)? onPaceUpdate;

  @override
  Future<bool> isLocationAvailable() async => true;

  @override
  Future<void> startTracking() async {
    isTracking = true;
  }

  @override
  void stopTracking() {
    isTracking = false;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MockTtsService mockTts;
  late MockHRBluetoothService mockBt;
  late MockLocationService mockLoc;
  late WorkoutService workoutService;

  setUp(() {
    mockTts = MockTtsService();
    mockBt = MockHRBluetoothService();
    mockLoc = MockLocationService();
    workoutService = WorkoutService(
      ttsService: mockTts,
      bluetoothService: mockBt,
      locationService: mockLoc,
    );
  });

  tearDown(() {
    workoutService.dispose();
  });

  group('Heart Rate Coaching Simulation (Livellatore di Battito)', () {
    test(
        'Scenario A: Target 120-130 BPM triggers promptly at 131-133 BPM, NOT waiting until 145 BPM',
        () async {
      // User sets target 120-130 BPM with default responsive outOfRangeDelay (3 seconds)
      final alert = CoachingAlert(
        id: 'hr_level_120_130',
        name: 'Controllo Battiti 120-130',
        metric: AlertMetric.bpm,
        minValue: 120,
        maxValue: 130,
        okIntervalSeconds: 60,
        outOfRangeDelaySeconds: 3,
        notifyOnReturn: true,
      );

      final preset = Preset(
        id: 'test_preset_hr',
        name: 'Test Cardio 120-130',
        announceStart: false,
        announceEnd: false,
        coachingAlerts: [alert],
      );

      await workoutService.startWorkout(preset);
      mockTts.spokenMessages.clear();

      // Simulated stream of incoming live heart rate:
      // Starts in range at 122, climbs across the ceiling (130) to 133
      // [t=0: 122, t=1: 126, t=2: 129, t=3: 131, t=4: 132, t=5: 133]
      final liveHrStream = [122, 126, 129, 131, 132, 133];

      for (int i = 0; i < liveHrStream.length; i++) {
        mockBt.emitHeartRate(liveHrStream[i]);
        await Future<void>.delayed(const Duration(milliseconds: 1050));
      }

      // Check TTS messages:
      final messages = mockTts.spokenMessages;
      expect(
        messages.any((m) => m.contains('troppo alti')),
        isTrue,
        reason:
            'Expected out-of-range "troppo alti" alert promptly around 133 BPM, but got: $messages',
      );

      // Verify that the alert did NOT wait for 145 BPM to trigger
      // At this point in simulation, HR was never higher than 133!
      expect(workoutService.currentHeartRate, equals(133));
    });

    test(
        'Scenario B: Boundary jitter (130-132 oscillations) does not prevent prompt alert',
        () async {
      // Runner is hovering on the ceiling (130-132 BPM).
      // Previously, any 130 reading reset the counter to 0 forever until 145 BPM.
      // Now hysteresis ensures the runner is alerted.
      final alert = CoachingAlert(
        id: 'hr_jitter_test',
        name: 'Controllo Battiti Jitter',
        metric: AlertMetric.bpm,
        minValue: 120,
        maxValue: 130,
        okIntervalSeconds: 60,
        outOfRangeDelaySeconds: 3,
        notifyOnReturn: true,
      );

      final preset = Preset(
        id: 'test_preset_jitter',
        name: 'Test Jitter',
        announceStart: false,
        announceEnd: false,
        coachingAlerts: [alert],
      );

      await workoutService.startWorkout(preset);
      mockTts.spokenMessages.clear();

      // Stream with border bounce:
      // t=0: 128 (in), t=1: 131 (out), t=2: 132 (out), t=3: 130 (boundary bounce), t=4: 132 (out), t=5: 133 (out)
      final jitterStream = [128, 131, 132, 130, 132, 133];

      for (int i = 0; i < jitterStream.length; i++) {
        mockBt.emitHeartRate(jitterStream[i]);
        await Future<void>.delayed(const Duration(milliseconds: 1050));
      }

      final messages = mockTts.spokenMessages;
      expect(
        messages.any((m) => m.contains('troppo alti')),
        isTrue,
        reason:
            'Border bounce at 130 BPM should not prevent alert when predominantly out of range. Got: $messages',
      );
    });

    test('Scenario C: Recovery returns to range and notifies "tutto bene"',
        () async {
      final alert = CoachingAlert(
        id: 'hr_recovery_test',
        name: 'Controllo Recupero',
        metric: AlertMetric.bpm,
        minValue: 120,
        maxValue: 130,
        okIntervalSeconds: 60,
        outOfRangeDelaySeconds: 2,
        notifyOnReturn: true,
      );

      final preset = Preset(
        id: 'test_preset_recovery',
        name: 'Test Recupero',
        announceStart: false,
        announceEnd: false,
        coachingAlerts: [alert],
      );

      await workoutService.startWorkout(preset);
      mockTts.spokenMessages.clear();

      // First force out of range to trigger "troppo alti"
      mockBt.emitHeartRate(135);
      await Future<void>.delayed(const Duration(milliseconds: 1050));
      mockBt.emitHeartRate(136);
      await Future<void>.delayed(const Duration(milliseconds: 1050));
      mockBt.emitHeartRate(137);
      await Future<void>.delayed(const Duration(milliseconds: 1050));

      expect(mockTts.spokenMessages.any((m) => m.contains('troppo alti')), isTrue);
      mockTts.spokenMessages.clear();

      // Now runner slows down and returns into safe range (125 BPM) for 3 seconds
      final recoveryStream = [128, 125, 124, 123];
      for (int hr in recoveryStream) {
        mockBt.emitHeartRate(hr);
        await Future<void>.delayed(const Duration(milliseconds: 1050));
      }

      final messages = mockTts.spokenMessages;
      expect(
        messages.any((m) => m.contains('tutto bene')),
        isTrue,
        reason:
            'Expected "tutto bene" on return into range, but got: $messages',
      );
    });

    test('Scenario D: Drops below minValue (120) alerts "troppo bassi"',
        () async {
      final alert = CoachingAlert(
        id: 'hr_low_test',
        name: 'Controllo Minimo',
        metric: AlertMetric.bpm,
        minValue: 120,
        maxValue: 130,
        okIntervalSeconds: 60,
        outOfRangeDelaySeconds: 2,
        notifyOnReturn: true,
      );

      final preset = Preset(
        id: 'test_preset_low',
        name: 'Test Basso',
        announceStart: false,
        announceEnd: false,
        coachingAlerts: [alert],
      );

      await workoutService.startWorkout(preset);
      mockTts.spokenMessages.clear();

      // Stream dropping below 120:
      final lowStream = [122, 118, 115, 114];
      for (int hr in lowStream) {
        mockBt.emitHeartRate(hr);
        await Future<void>.delayed(const Duration(milliseconds: 1050));
      }

      final messages = mockTts.spokenMessages;
      expect(
        messages.any((m) => m.contains('troppo bassi')),
        isTrue,
        reason: 'Expected "troppo bassi" when HR fell below 120. Got: $messages',
      );
    });

    test('Scenario E: Interface, callback and state activations', () async {
      bool dataUpdatedCalled = false;
      WorkoutState? lastState;

      workoutService.onDataUpdated = () {
        dataUpdatedCalled = true;
      };
      workoutService.onStateChanged = (state) {
        lastState = state;
      };

      final preset = Preset(
        id: 'test_callbacks',
        name: 'Test Callbacks',
        announceStart: false,
        announceEnd: false,
      );

      await workoutService.startWorkout(preset);
      expect(lastState, equals(WorkoutState.running));

      dataUpdatedCalled = false;
      mockBt.emitHeartRate(128);

      expect(workoutService.currentHeartRate, equals(128));
      expect(dataUpdatedCalled, isTrue);

      workoutService.pauseWorkout();
      expect(lastState, equals(WorkoutState.paused));

      workoutService.resumeWorkout();
      expect(lastState, equals(WorkoutState.running));

      await workoutService.stopWorkout();
      expect(lastState, equals(WorkoutState.idle));
    });
  });
}
