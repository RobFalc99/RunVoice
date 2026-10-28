import 'package:flutter_test/flutter_test.dart';
import 'package:run_voice/models/alert_config.dart';
import 'package:run_voice/models/preset.dart';
import 'package:run_voice/models/workout_plan.dart';
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

  void emitPace(double pace) {
    currentPaceMinPerKm = pace;
    onPaceUpdate?.call(pace);
  }

  void emitDistance(double dist) {
    totalDistanceKm = dist;
    onDistanceUpdate?.call(dist);
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

  group('WorkoutService Coaching in Phased Workouts (Ripetute)', () {
    test('alerts out of range when HR exceeds step target during recovery', () async {
      // Step 1: Sprint (10s, target 150-160 BPM)
      // Step 2: Recovery (20s, target 110-120 BPM)
      final preset = Preset(
        id: 'test_interval',
        name: 'Ripetute Test',
        isIntervalTraining: true,
        announceStart: false,
        announceEnd: false,
        intervals: [
          IntervalStep(
            id: 'step_sprint',
            name: 'Sprint',
            type: AlertTrigger.time,
            durationSeconds: 10,
            coachingAlerts: [
              CoachingAlert(
                id: 'sprint_hr',
                name: 'Cardio Sprint',
                metric: AlertMetric.bpm,
                minValue: 150,
                maxValue: 160,
                okIntervalSeconds: 30,
                outOfRangeDelaySeconds: 5,
                notifyOnReturn: true,
              ),
            ],
          ),
          IntervalStep(
            id: 'step_recovery',
            name: 'Recupero',
            type: AlertTrigger.time,
            durationSeconds: 20,
            coachingAlerts: [
              CoachingAlert(
                id: 'recovery_hr',
                name: 'Cardio Recupero',
                metric: AlertMetric.bpm,
                minValue: 110,
                maxValue: 120,
                okIntervalSeconds: 30,
                outOfRangeDelaySeconds: 5,
                notifyOnReturn: true,
              ),
            ],
          ),
        ],
      );

      await workoutService.startWorkout(preset);
      mockTts.spokenMessages.clear();

      // Start Sprint at 155 BPM (in range)
      mockBt.emitHeartRate(155);

      // Advance 10 seconds to finish sprint step
      await Future<void>.delayed(const Duration(milliseconds: 10500));

      // Now we should be in recovery step (index 1)
      expect(workoutService.currentIntervalIndex, equals(1));
      mockTts.spokenMessages.clear();

      // During recovery, HR is 140 BPM (OUT OF RANGE: max is 120)
      mockBt.emitHeartRate(140);

      // Wait 7 seconds (outOfRangeDelaySeconds is 5)
      await Future<void>.delayed(const Duration(milliseconds: 7000));

      // Must announce out-of-range: 'B P M troppo alti'
      // MUST NOT say 'tutto bene'!
      final messages = mockTts.spokenMessages;
      expect(messages.any((m) => m.contains('troppo alti')), isTrue,
          reason: 'Expected "troppo alti" alert when HR was 140 in 110-120 range, but got: $messages');
      expect(messages.any((m) => m.contains('tutto bene')), isFalse,
          reason: 'Did not expect "tutto bene" when out of range, but got: $messages');
    });

    test('global preset coaching alert must NOT say "tutto bene" when interval step is out of range', () async {
      // Preset has a broad global coaching alert (100-180 BPM, e.g. general safe zone)
      // Interval Step 1 is recovery with target (110-120 BPM)
      // When HR is 140 BPM, the runner is out of the interval range.
      // The app must NOT say "tutto bene" from the global alert!
      final preset = Preset(
        id: 'test_global_conflict',
        name: 'Ripetute con Global Alert',
        isIntervalTraining: true,
        announceStart: false,
        announceEnd: false,
        coachingAlerts: [
          CoachingAlert(
            id: 'global_hr',
            name: 'Cardio Globale',
            metric: AlertMetric.bpm,
            minValue: 100,
            maxValue: 180,
            okIntervalSeconds: 3, // Fires fast for test
            outOfRangeDelaySeconds: 5,
            notifyOnReturn: false,
          ),
        ],
        intervals: [
          IntervalStep(
            id: 'step_recovery_strict',
            name: 'Recupero Stretto',
            type: AlertTrigger.time,
            durationSeconds: 20,
            coachingAlerts: [
              CoachingAlert(
                id: 'recovery_strict_hr',
                name: 'Recupero',
                metric: AlertMetric.bpm,
                minValue: 110,
                maxValue: 120,
                okIntervalSeconds: 30,
                outOfRangeDelaySeconds: 4,
                notifyOnReturn: true,
              ),
            ],
          ),
        ],
      );

      await workoutService.startWorkout(preset);
      mockTts.spokenMessages.clear();

      // HR is 140 BPM (in global 100-180 range, but OUT OF STEP 110-120 range!)
      mockBt.emitHeartRate(140);

      // Wait 6 seconds
      await Future<void>.delayed(const Duration(milliseconds: 6500));

      final messages = mockTts.spokenMessages;
      // Should NOT say "tutto bene"
      expect(messages.any((m) => m.contains('tutto bene')), isFalse,
          reason: 'Global alert should NOT say "tutto bene" when interval phase has active target and is out of range. Got: $messages');
      // Should announce step out of range
      expect(messages.any((m) => m.contains('troppo alti')), isTrue,
          reason: 'Should alert "troppo alti" for the interval step. Got: $messages');
    });

    test('pace coaching alert created from plan converts units and alerts out of range correctly', () async {
      // Test pace alert generated from plan with target 4:30 - 5:00 min/km (270s - 300s)
      final plan = WorkoutCoachingPlan(
        name: 'Ritmo ripetuta',
        metric: 'pace',
        minValue: 270, // in seconds from AI prompt
        maxValue: 300,
      );

      final alert = plan.toCoachingAlert('step1');
      // Values must be in minutes per km (4.5 to 5.0)
      expect(alert.minValue, closeTo(4.5, 0.01),
          reason: 'minValue was 270 seconds, should convert to 4.5 min/km');
      expect(alert.maxValue, closeTo(5.0, 0.01),
          reason: 'maxValue was 300 seconds, should convert to 5.0 min/km');
    });

    test('interval transitions reset coaching timers so repeat blocks do not carry stale state', () async {
      final alert1 = CoachingAlert(
        id: 'repeat_sprint_hr',
        name: 'Sprint Cardio',
        metric: AlertMetric.bpm,
        minValue: 150,
        maxValue: 160,
        okIntervalSeconds: 30,
        outOfRangeDelaySeconds: 4,
        notifyOnReturn: true,
      );

      final preset = Preset(
        id: 'test_repeat_reset',
        name: 'Ripetute Multiple',
        isIntervalTraining: true,
        announceStart: false,
        announceEnd: false,
        intervals: [
          // Rep 1 Sprint
          IntervalStep(
            id: 'sprint_1',
            name: 'Sprint 1',
            type: AlertTrigger.time,
            durationSeconds: 5,
            coachingAlerts: [alert1],
          ),
          // Rep 1 Rest
          IntervalStep(
            id: 'rest_1',
            name: 'Rest 1',
            type: AlertTrigger.time,
            durationSeconds: 5,
            coachingAlerts: [
              CoachingAlert(
                id: 'repeat_rest_hr',
                name: 'Rest Cardio',
                metric: AlertMetric.bpm,
                minValue: 110,
                maxValue: 120,
                okIntervalSeconds: 30,
                outOfRangeDelaySeconds: 4,
                notifyOnReturn: true,
              ),
            ],
          ),
          // Rep 2 Sprint (same alert ID because it was flattened from a repeat count)
          IntervalStep(
            id: 'sprint_2',
            name: 'Sprint 2',
            type: AlertTrigger.time,
            durationSeconds: 10,
            coachingAlerts: [alert1],
          ),
        ],
      );

      await workoutService.startWorkout(preset);

      // Rep 1: HR is 170 (out of range, timer starts building)
      mockBt.emitHeartRate(170);
      await Future<void>.delayed(const Duration(milliseconds: 3000)); // 3 seconds out of range

      // During rest 1, set HR to 115 BPM (in range for Rest)
      mockBt.emitHeartRate(115);

      // Finish rep 1 and rest 1 (5s + 5s = 10s total)
      await Future<void>.delayed(const Duration(milliseconds: 8000));
      expect(workoutService.currentIntervalIndex, equals(2)); // Now in Sprint 2!

      mockTts.spokenMessages.clear();

      // At start of Sprint 2, HR is in range (155 BPM) for 2 seconds
      mockBt.emitHeartRate(155);
      await Future<void>.delayed(const Duration(milliseconds: 2000));

      // Then HR goes out of range (170 BPM)
      mockBt.emitHeartRate(170);
      // Wait only 2 seconds: if state was stale (3s from rep 1), 2s would trigger alert at 5s!
      // But it should take full outOfRangeDelaySeconds (4 seconds).
      await Future<void>.delayed(const Duration(milliseconds: 2000));
      expect(mockTts.spokenMessages.any((m) => m.contains('troppo alti')), isFalse,
          reason: 'Should not have triggered out-of-range yet because timer should have reset when entering Sprint 2. Got: ${mockTts.spokenMessages}');

      // Now wait another 3 seconds (total 5s > 4s out of range in Sprint 2)
      await Future<void>.delayed(const Duration(milliseconds: 3000));
      expect(mockTts.spokenMessages.any((m) => m.contains('troppo alti')), isTrue,
          reason: 'Should trigger out-of-range after full 4s delay in Sprint 2');
    });
  });
}
