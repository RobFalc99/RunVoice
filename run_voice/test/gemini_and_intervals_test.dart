import 'package:flutter_test/flutter_test.dart';
import 'package:run_voice/models/user_profile.dart';
import 'package:run_voice/models/preset.dart';
import 'package:run_voice/models/alert_config.dart';
import 'package:run_voice/models/workout_plan.dart';
import 'package:run_voice/services/gemini_service.dart';

void main() {
  group('UserProfile Gemini API Key', () {
    test('default geminiApiKey is empty', () {
      final profile = UserProfile();
      expect(profile.geminiApiKey, isEmpty);
    });

    test('serializes and deserializes geminiApiKey correctly', () {
      final profile = UserProfile();
      profile.geminiApiKey = 'AIzaSyTestKey123';
      final jsonString = profile.toJsonString();
      final restored = UserProfile.fromJsonString(jsonString);
      expect(restored.geminiApiKey, equals('AIzaSyTestKey123'));
    });
  });

  group('UserProfile Gemini Model', () {
    test('default geminiModel is gemini-3.5-flash-lite', () {
      final profile = UserProfile();
      expect(profile.geminiModel, equals('gemini-3.5-flash-lite'));
    });

    test('geminiModelLabel returns correct label for gemini-3.5-flash-lite', () {
      final profile = UserProfile();
      profile.geminiModel = 'gemini-3.5-flash-lite';
      expect(profile.geminiModelLabel, equals('Gemini 3.5 Flash-Lite'));
    });

    test('geminiModelLabel returns correct label for gemini-3.8-flash', () {
      final profile = UserProfile();
      profile.geminiModel = 'gemini-3.8-flash';
      expect(profile.geminiModelLabel, equals('Gemini 3.8 Flash'));
    });

    test('serializes and deserializes geminiModel correctly', () {
      final profile = UserProfile();
      profile.geminiModel = 'gemini-3.8-flash';
      final jsonString = profile.toJsonString();
      final restored = UserProfile.fromJsonString(jsonString);
      expect(restored.geminiModel, equals('gemini-3.8-flash'));
      expect(restored.geminiModelLabel, equals('Gemini 3.8 Flash'));
    });
  });

  group('GeminiService Validation', () {
    test('empty key returns success: false', () async {
      final res = await GeminiService.testApiKey('');
      expect(res.success, isFalse);
      expect(res.message, contains('vuota'));
    });

    test('whitespace key returns success: false', () async {
      final res = await GeminiService.testApiKey('   ');
      expect(res.success, isFalse);
      expect(res.message, contains('vuota'));
    });
  });

  group('GeminiService Curated Models', () {
    test('curatedModels contains gemini-3.5-flash-lite', () {
      expect(
        GeminiService.curatedModels.any((m) => m.id == 'gemini-3.5-flash-lite'),
        isTrue,
      );
    });

    test('curatedModels contains gemini-3.8-flash', () {
      expect(
        GeminiService.curatedModels.any((m) => m.id == 'gemini-3.8-flash'),
        isTrue,
      );
    });

    test('gemini-3.5-flash-lite model has correct metadata', () {
      final model = GeminiService.curatedModels
          .firstWhere((m) => m.id == 'gemini-3.5-flash-lite');
      expect(model.label, equals('Gemini 3.5 Flash-Lite'));
      expect(model.badge, contains('Consigliato'));
    });

    test('gemini-3.8-flash model has correct metadata', () {
      final model =
          GeminiService.curatedModels.firstWhere((m) => m.id == 'gemini-3.8-flash');
      expect(model.label, equals('Gemini 3.8 Flash'));
      expect(model.badge, contains('Novità'));
    });
  });

  group('IntervalStep Formatting & Serialization', () {
    test('formats distance duration correctly', () {
      final step1 = IntervalStep(
        id: '1',
        name: 'Ripetuta 1km',
        type: AlertTrigger.distance,
        distanceMeters: 1000,
      );
      expect(step1.displayDuration, equals('1.0 km'));

      final step2 = IntervalStep(
        id: '2',
        name: 'Scatto 400m',
        type: AlertTrigger.distance,
        distanceMeters: 400,
      );
      expect(step2.displayDuration, equals('400 metri'));
    });

    test('formats time duration correctly', () {
      final step1 = IntervalStep(
        id: '1',
        name: 'Recupero 90s',
        type: AlertTrigger.time,
        durationSeconds: 90,
      );
      expect(step1.displayDuration, equals('1 min e 30 sec'));

      final step2 = IntervalStep(
        id: '2',
        name: 'Recupero 2m',
        type: AlertTrigger.time,
        durationSeconds: 120,
      );
      expect(step2.displayDuration, equals('2 minuti'));
    });

    test('serializes and deserializes step correctly', () {
      final step = IntervalStep(
        id: 'step_test',
        name: 'Test Step',
        type: AlertTrigger.distance,
        distanceMeters: 800,
      );
      final json = step.toJson();
      final restored = IntervalStep.fromJson(json);
      expect(restored.id, equals('step_test'));
      expect(restored.name, equals('Test Step'));
      expect(restored.type, equals(AlertTrigger.distance));
      expect(restored.distanceMeters, equals(800));
    });
  });

  group('WorkoutTarget & toPreset Alerts Generation', () {
    test('WorkoutTarget parses snake_case heart_rate_bpm and min/max bpm correctly', () {
      final json = {
        'metric': 'heart_rate_bpm',
        'min_bpm': 145,
        'max_bpm': 155,
      };
      final target = WorkoutTarget.fromJson(json);
      expect(target.metric, equals(TargetMetric.heartRateBpm));
      expect(target.targetHrBpmMin, equals(145));
      expect(target.targetHrBpmMax, equals(155));
      expect(target.targetHrBpm, equals(150));
      expect(target.bpmTolerance, equals(5));
    });

    test('WorkoutTarget parses target_hr_bpm with bpm_tolerance and computes min/max', () {
      final json = {
        'metric': 'heart_rate_bpm',
        'target_hr_bpm': 127,
        'bpm_tolerance': 8,
      };
      final target = WorkoutTarget.fromJson(json);
      expect(target.metric, equals(TargetMetric.heartRateBpm));
      expect(target.targetHrBpmMin, equals(119));
      expect(target.targetHrBpmMax, equals(135));
    });

    test('WorkoutPlan.toPreset generates coachingAlerts and step periodic alerts for BPM steps', () {
      // Create a WorkoutPlan with 2 steps
      final step1 = WorkoutStep(
        id: 'step1',
        label: 'warmup',
        phase: StepPhase.warmup,
        duration: const WorkoutDuration(type: 'time_seconds', value: 600),
        target: WorkoutTarget(
          metric: TargetMetric.heartRateBpm,
          targetHrBpmMin: 120,
          targetHrBpmMax: 135,
          targetHrBpm: 127,
          bpmTolerance: 7,
        ),
      );

      final step2 = WorkoutStep(
        id: 'step2',
        label: 'work',
        phase: StepPhase.work,
        duration: const WorkoutDuration(type: 'time_seconds', value: 120),
        target: WorkoutTarget(
          metric: TargetMetric.heartRateBpm,
          targetHrBpmMin: 145,
          targetHrBpmMax: 155,
          targetHrBpm: 150,
          bpmTolerance: 5,
        ),
      );

      final plan = WorkoutPlan(
        id: 'test_plan',
        name: 'Test Plan',
        structure: WorkoutStructure.intervals,
        steps: [step1, step2],
      );

      final preset = plan.toPreset();

      // Verify first interval (warmup 600s, target 120-135 bpm)
      expect(preset.intervals.length, equals(2));
      expect(preset.intervals[0].coachingAlerts.length, equals(1));
      expect(preset.intervals[0].coachingAlerts[0].metric, equals(AlertMetric.bpm));
      expect(preset.intervals[0].coachingAlerts[0].minValue, equals(120.0));
      expect(preset.intervals[0].coachingAlerts[0].maxValue, equals(135.0));

      expect(preset.intervals[0].alerts.length, equals(1));
      expect(preset.intervals[0].alerts[0].metric, equals(AlertMetric.bpm));
      expect(preset.intervals[0].alerts[0].intervalSeconds, equals(60));

      // Verify second interval (work 120s, target 145-155 bpm)
      expect(preset.intervals[1].coachingAlerts.length, equals(1));
      expect(preset.intervals[1].coachingAlerts[0].metric, equals(AlertMetric.bpm));
      expect(preset.intervals[1].coachingAlerts[0].minValue, equals(145.0));
      expect(preset.intervals[1].coachingAlerts[0].maxValue, equals(155.0));

      expect(preset.intervals[1].alerts.length, equals(1));
      expect(preset.intervals[1].alerts[0].metric, equals(AlertMetric.bpm));
      expect(preset.intervals[1].alerts[0].intervalSeconds, equals(30));
    });
  });
}
