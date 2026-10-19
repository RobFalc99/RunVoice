import 'package:flutter_test/flutter_test.dart';
import 'package:run_voice/models/workout_plan.dart';

void main() {
  group('WorkoutDuration', () {
    test('displayString handles time correctly', () {
      final duration = WorkoutDuration(type: 'time_seconds', value: 125);
      expect(duration.displayString, '2 min e 5 s');
    });

    test('displayString handles time without seconds', () {
      final duration = WorkoutDuration(type: 'time_seconds', value: 120);
      expect(duration.displayString, '2 min');
    });

    test('displayString handles distance in km without decimals', () {
      final duration = WorkoutDuration(type: 'distance_meters', value: 5000);
      expect(duration.displayString, '5 km');
    });

    test('displayString handles distance in km with decimals', () {
      final duration = WorkoutDuration(type: 'distance_meters', value: 5500);
      expect(duration.displayString, '5.50 km');
    });

    test('displayString handles distance in meters', () {
      final duration = WorkoutDuration(type: 'distance_meters', value: 500);
      expect(duration.displayString, '500 m');
    });
  });

  group('WorkoutTarget', () {
    test('isValid rejects negative pace', () {
      final target = WorkoutTarget(
        metric: TargetMetric.pace,
        targetPaceSecPerKm: -1,
      );
      expect(target.isValid, false);
    });

    test('isValid rejects zero pace', () {
      final target = WorkoutTarget(
        metric: TargetMetric.pace,
        targetPaceSecPerKm: 0,
      );
      expect(target.isValid, false);
    });

    test('isValid accepts valid pace', () {
      final target = WorkoutTarget(
        metric: TargetMetric.pace,
        targetPaceSecPerKm: 300,
        paceToleranceSec: 10,
      );
      expect(target.isValid, true);
    });

    test('isValid rejects HR zone with min > max', () {
      final target = WorkoutTarget(
        metric: TargetMetric.heartRateZone,
        targetHrZoneMin: 5,
        targetHrZoneMax: 2,
      );
      expect(target.isValid, false);
    });

    test('isValid accepts valid HR zone', () {
      final target = WorkoutTarget(
        metric: TargetMetric.heartRateZone,
        targetHrZoneMin: 2,
        targetHrZoneMax: 4,
      );
      expect(target.isValid, true);
    });

    test('displayPace formats correctly', () {
      final target = WorkoutTarget(
        metric: TargetMetric.pace,
        targetPaceSecPerKm: 300,
      );
      expect(target.displayPace, '05:00 /km');
    });

    test('displayHeartRateZone shows range', () {
      final target = WorkoutTarget(
        metric: TargetMetric.heartRateZone,
        targetHrZoneMin: 2,
        targetHrZoneMax: 4,
      );
      expect(target.displayHeartRateZone, '2-4');
    });

    test('displayHeartRate with tolerance', () {
      final target = WorkoutTarget(
        metric: TargetMetric.heartRateBpm,
        targetHrBpm: 150,
        bpmTolerance: 5,
      );
      expect(target.displayHeartRate, '145-155 bpm');
    });

    test('displayCadence with tolerance', () {
      final target = WorkoutTarget(
        metric: TargetMetric.cadence,
        targetCadence: 180,
        cadenceTolerance: 10,
      );
      expect(target.displayCadence, '170-190 rpm');
    });

    test('toJson includes cadence fields', () {
      final target = WorkoutTarget(
        metric: TargetMetric.cadence,
        targetCadence: 180,
        cadenceTolerance: 5,
      );
      final json = target.toJson();
      expect(json['target_cadence'], 180);
      expect(json['cadence_tolerance'], 5);
    });

    test('fromJson reconstructs cadence correctly', () {
      final json = {
        'metric': 'cadence',
        'target_cadence': 180,
        'cadence_tolerance': 5,
      };
      final target = WorkoutTarget.fromJson(json);
      expect(target.metric, TargetMetric.cadence);
      expect(target.targetCadence, 180);
      expect(target.cadenceTolerance, 5);
    });
  });

  group('WorkoutStep', () {
    test('totalDuration calculates simple step with repeats', () {
      final step = WorkoutStep(
        id: 'step1',
        label: 'Run',
        duration: WorkoutDuration(type: 'distance_meters', value: 5000),
        repeatCount: 3,
      );
      final total = step.totalDuration;
      expect(total.value, 15000);
      expect(total.type, 'distance_meters');
    });

    test('maxNestingDepth returns 0 for simple step', () {
      final step = WorkoutStep(
        id: 'step1',
        label: 'Run',
        duration: WorkoutDuration(type: 'distance_meters', value: 5000),
      );
      expect(step.maxNestingDepth, 0);
    });

    test('maxNestingDepth returns depth for nested steps', () {
      final substep = WorkoutStep(
        id: 'substep1',
        label: 'Inner',
        duration: WorkoutDuration(type: 'distance_meters', value: 1000),
      );
      final step = WorkoutStep(
        id: 'step1',
        label: 'Outer',
        duration: WorkoutDuration(type: 'distance_meters', value: 5000),
        subSteps: [substep],
      );
      expect(step.maxNestingDepth, 1);
    });

    test('isValid rejects empty label', () {
      final step = WorkoutStep(
        id: 'step1',
        label: '',
        duration: WorkoutDuration(type: 'distance_meters', value: 5000),
      );
      expect(step.isValid, false);
    });

    test('isValid accepts valid step', () {
      final step = WorkoutStep(
        id: 'step1',
        label: 'Run',
        duration: WorkoutDuration(type: 'distance_meters', value: 5000),
      );
      expect(step.isValid, true);
    });

    test('toJson includes repeat_count only when > 1', () {
      final step = WorkoutStep(
        id: 'step1',
        label: 'Run',
        duration: WorkoutDuration(type: 'distance_meters', value: 5000),
        repeatCount: 1,
      );
      final json = step.toJson();
      expect(json.containsKey('repeat_count'), false);
    });

    test('toJson includes sub_steps when present', () {
      final substep = WorkoutStep(
        id: 'substep1',
        label: 'Inner',
        duration: WorkoutDuration(type: 'distance_meters', value: 1000),
      );
      final step = WorkoutStep(
        id: 'step1',
        label: 'Outer',
        duration: WorkoutDuration(type: 'distance_meters', value: 5000),
        subSteps: [substep],
      );
      final json = step.toJson();
      expect(json.containsKey('sub_steps'), true);
      expect((json['sub_steps'] as List).length, 1);
    });
  });

  group('WorkoutPlan JSON Serialization Tests', () {
    test('Serializza e deserializza correttamente un allenamento a ripetute', () {
      final jsonSample = {
        'version': '1.0',
        'id': 'test_workout_1',
        'name': '5x1000m Veloce',
        'description': 'Test ripetute con recupero',
        'structure': 'intervals',
        'voice_coaching': {
          'announce_start': true,
          'announce_splits': true,
          'announce_end': true,
        },
        'steps': [
          {
            'id': 'step_warmup',
            'label': 'Riscaldamento',
            'phase': 'warmup',
            'duration': {'type': 'distance_meters', 'value': 2000.0},
            'target': {'metric': 'heartRateZone', 'target_hr_zone_min': 1, 'target_hr_zone_max': 2},
            'voice_cue': 'Inizia riscaldamento',
          },
          {
            'id': 'step_block_repeats',
            'label': 'Ripetute 5x1000m',
            'phase': 'work',
            'duration': {'type': 'distance_meters', 'value': 1000.0},
            'repeat_count': 5,
            'sub_steps': [
              {
                'id': 'fast_1000',
                'label': 'Tratto Veloce',
                'phase': 'work',
                'duration': {'type': 'distance_meters', 'value': 1000.0},
                'target': {
                  'metric': 'pace',
                  'target_pace_sec_per_km': 255,
                  'pace_tolerance_sec': 5,
                },
              },
              {
                'id': 'rec_90s',
                'label': 'Recupero',
                'phase': 'recovery',
                'duration': {'type': 'time_seconds', 'value': 90.0},
                'target': {'metric': 'heartRateZone', 'target_hr_zone_min': 1, 'target_hr_zone_max': 2},
              }
            ],
          }
        ],
      };

      final plan = WorkoutPlan.fromJson(jsonSample);

      expect(plan.name, '5x1000m Veloce');
      expect(plan.structure, WorkoutStructure.intervals);
      expect(plan.steps.length, 2);
      expect(plan.steps[0].duration.isDistance, true);
      expect(plan.steps[0].duration.inKilometers, 2.0);

      // Blocco ripetute
      final repeatBlock = plan.steps[1];
      expect(repeatBlock.repeatCount, 5);
      expect(repeatBlock.subSteps.length, 2);
      expect(repeatBlock.subSteps[0].target.metric, TargetMetric.pace);
      expect(repeatBlock.subSteps[0].target.displayPace, '04:15 /km');
      expect(repeatBlock.subSteps[1].duration.isTime, true);
      expect(repeatBlock.subSteps[1].duration.inSeconds, 90);

      // Conversione verso Preset per retrocompatibilità
      final preset = plan.toPreset();
      expect(preset.name, plan.name);
      expect(preset.isIntervalTraining, true);
      // 1 riscaldamento + 5 * 2 = 11 step appiattiti
      expect(preset.intervals.length, 11);
    });

    test('isValid rejects plan with empty name', () {
      final plan = WorkoutPlan(
        id: 'plan1',
        name: '',
        steps: [
          WorkoutStep(
            id: 'step1',
            label: 'Run',
            duration: WorkoutDuration(type: 'distance_meters', value: 5000),
          ),
        ],
      );
      expect(plan.isValid, false);
    });

    test('isValid rejects plan with no steps', () {
      final plan = WorkoutPlan(
        id: 'plan1',
        name: 'My Plan',
        steps: [],
      );
      expect(plan.isValid, false);
    });

    test('totalDuration sums all steps correctly', () {
      final plan = WorkoutPlan(
        id: 'plan1',
        name: 'My Plan',
        steps: [
          WorkoutStep(
            id: 'step1',
            label: 'Run1',
            duration: WorkoutDuration(type: 'distance_meters', value: 2000),
          ),
          WorkoutStep(
            id: 'step2',
            label: 'Run2',
            duration: WorkoutDuration(type: 'distance_meters', value: 3000),
          ),
        ],
      );
      expect(plan.totalDuration.value, 5000);
    });

    test('maxNestingDepth calculates correctly', () {
      final plan = WorkoutPlan(
        id: 'plan1',
        name: 'My Plan',
        steps: [
          WorkoutStep(
            id: 'step1',
            label: 'Outer',
            duration: WorkoutDuration(type: 'distance_meters', value: 5000),
            subSteps: [
              WorkoutStep(
                id: 'step1_1',
                label: 'Inner',
                duration: WorkoutDuration(type: 'distance_meters', value: 1000),
              ),
            ],
          ),
        ],
      );
      expect(plan.maxNestingDepth, 1);
    });

    test('toPrettyJson formats JSON with indentation', () {
      final plan = WorkoutPlan(
        id: 'plan1',
        name: 'My Plan',
        steps: [
          WorkoutStep(
            id: 'step1',
            label: 'Run',
            duration: WorkoutDuration(type: 'distance_meters', value: 5000),
          ),
        ],
      );
      final prettyJson = plan.toPrettyJson();
      expect(prettyJson.contains('"name": "My Plan"'), true);
      expect(prettyJson.contains('  '), true); // Check for indentation
    });

    test('Supporta target metrica per cadenza', () {
      final jsonSample = {
        'version': '1.0',
        'id': 'cadence_workout',
        'name': 'Allenamento Cadenza',
        'description': 'Test cadenza',
        'structure': 'continuous',
        'voice_coaching': {
          'announce_start': true,
          'announce_splits': true,
          'announce_end': true,
        },
        'steps': [
          {
            'id': 'cadence_step',
            'label': 'Corsa con cadenza target',
            'phase': 'work',
            'duration': {'type': 'distance_meters', 'value': 5000.0},
            'target': {
              'metric': 'cadence',
              'target_cadence': 180,
              'cadence_tolerance': 5,
            },
          }
        ],
      };

      final plan = WorkoutPlan.fromJson(jsonSample);
      expect(plan.steps[0].target.metric, TargetMetric.cadence);
      expect(plan.steps[0].target.targetCadence, 180);
      expect(plan.steps[0].target.cadenceTolerance, 5);
      expect(plan.steps[0].target.displayCadence, '175-185 rpm');
    });

    test('Zone cardiache hanno min e max separati', () {
      final jsonSample = {
        'version': '1.0',
        'id': 'hrzone_workout',
        'name': 'Allenamento Zona FC',
        'description': 'Test zone cardiache',
        'structure': 'continuous',
        'voice_coaching': {
          'announce_start': true,
          'announce_splits': true,
          'announce_end': true,
        },
        'steps': [
          {
            'id': 'hrzone_step',
            'label': 'Corsa aerobica',
            'phase': 'work',
            'duration': {'type': 'time_seconds', 'value': 1800.0},
            'target': {
              'metric': 'heartRateZone',
              'target_hr_zone_min': 2,
              'target_hr_zone_max': 3,
            },
          }
        ],
      };

      final plan = WorkoutPlan.fromJson(jsonSample);
      expect(plan.steps[0].target.metric, TargetMetric.heartRateZone);
      expect(plan.steps[0].target.targetHrZoneMin, 2);
      expect(plan.steps[0].target.targetHrZoneMax, 3);
      expect(plan.steps[0].target.displayHeartRateZone, '2-3');
    });
  });
}
