import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:run_voice/models/preset.dart';
import 'package:run_voice/models/workout_plan.dart';
import 'package:run_voice/providers/preset_provider.dart';
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

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockLocationService implements LocationService {
  @override
  bool isTracking = false;

  @override
  double totalDistanceKm = 5.25;

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
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Fixes v0.2.1 Tests', () {
    test('WorkoutPlan.fromJson resolves generic "workout_custom" to unique ID', () {
      final json1 = {
        'id': 'workout_custom',
        'name': 'Test Workout 1',
        'structure': 'intervals',
        'steps': <dynamic>[],
      };
      final json2 = {
        'id': 'workout_custom',
        'name': 'Test Workout 2',
        'structure': 'intervals',
        'steps': <dynamic>[],
      };

      final plan1 = WorkoutPlan.fromJson(json1);
      final plan2 = WorkoutPlan.fromJson(json2);

      expect(plan1.id, isNot('workout_custom'));
      expect(plan1.id.startsWith('workout_'), isTrue);
      expect(plan2.id, isNot('workout_custom'));
      expect(plan2.id.startsWith('workout_'), isTrue);
    });

    test('PresetProvider deduplicates presets with identical IDs on load', () async {
      SharedPreferences.setMockInitialValues({
        'presets': jsonEncode([
          {
            'id': 'duplicate_id',
            'name': 'Preset 1',
            'description': '',
            'alerts': [],
            'coachingAlerts': [],
            'isIntervalTraining': false,
            'intervals': [],
            'announceStart': true,
            'announceEnd': true,
            'announceSummary': true,
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          },
          {
            'id': 'duplicate_id',
            'name': 'Preset 2',
            'description': '',
            'alerts': [],
            'coachingAlerts': [],
            'isIntervalTraining': false,
            'intervals': [],
            'announceStart': true,
            'announceEnd': true,
            'announceSummary': true,
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          },
        ]),
        'selected_preset_id': 'duplicate_id',
      });

      final provider = PresetProvider();
      await provider.loadPresets();

      expect(provider.presets.length, 2);
      expect(provider.presets[0].id, isNot(provider.presets[1].id));
      expect(provider.selectedPresetId, isNotNull);
    });

    test('PresetProvider.addPreset generates new unique ID on collision', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = PresetProvider();
      await provider.loadPresets();

      final existingPreset = provider.presets.first;
      final collidingPreset = Preset(
        id: existingPreset.id,
        name: 'Colliding Preset',
      );

      await provider.addPreset(collidingPreset);

      expect(provider.presets.length, 2);
      expect(provider.presets[0].id, isNot(provider.presets[1].id));
      expect(provider.presets.last.name, 'Colliding Preset');
    });

    test('WorkoutService respects announceEnd and announceSummary flags on stopWorkout', () async {
      final tts = MockTtsService();
      final bluetooth = MockHRBluetoothService();
      final location = MockLocationService();
      final service = WorkoutService(
        ttsService: tts,
        bluetoothService: bluetooth,
        locationService: location,
      );

      // 1. Both disabled: silence on stop
      final silentPreset = Preset(
        id: 'p_silent',
        name: 'Silent End',
        announceStart: true,
        announceEnd: false,
        announceSummary: false,
      );

      await service.startWorkout(silentPreset);
      tts.spokenMessages.clear();
      await service.stopWorkout();

      expect(tts.spokenMessages.isEmpty, isTrue);

      // 2. Only announceEnd enabled: "Allenamento terminato." without stats
      final endOnlyPreset = Preset(
        id: 'p_end_only',
        name: 'End Only',
        announceStart: true,
        announceEnd: true,
        announceSummary: false,
      );

      await service.startWorkout(endOnlyPreset);
      tts.spokenMessages.clear();
      await service.stopWorkout();

      expect(tts.spokenMessages.length, 1);
      expect(tts.spokenMessages.first, 'Allenamento terminato.');

      // 3. Both enabled: full summary
      final fullPreset = Preset(
        id: 'p_full',
        name: 'Full End',
        announceStart: true,
        announceEnd: true,
        announceSummary: true,
      );

      await service.startWorkout(fullPreset);
      tts.spokenMessages.clear();
      await service.stopWorkout();

      expect(tts.spokenMessages.length, 1);
      expect(tts.spokenMessages.first.contains('Allenamento terminato.'), isTrue);
      expect(tts.spokenMessages.first.contains('Tempo totale:'), isTrue);
    });

    test('WorkoutService respects announceStart: false', () async {
      final tts = MockTtsService();
      final bluetooth = MockHRBluetoothService();
      final location = MockLocationService();
      final service = WorkoutService(
        ttsService: tts,
        bluetoothService: bluetooth,
        locationService: location,
      );

      final noStartPreset = Preset(
        id: 'p_nostart',
        name: 'No Start',
        announceStart: false,
        announceEnd: true,
        announceSummary: true,
      );

      await service.startWorkout(noStartPreset);
      expect(tts.spokenMessages.isEmpty, isTrue);
    });
  });
}
