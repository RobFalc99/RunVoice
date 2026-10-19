import 'dart:convert';
import 'preset.dart';
import 'alert_config.dart';

enum WorkoutStructure { continuous, intervals, pyramid, fartlek }

enum StepPhase { warmup, work, recovery, cooldown, open }

enum TargetMetric { none, pace, heartRateZone, heartRateBpm, cadence }

class WorkoutDuration {
  final String type; // 'time_seconds' or 'distance_meters'
  final double value;

  const WorkoutDuration({required this.type, required this.value});

  bool get isTime => type == 'time_seconds';
  bool get isDistance => type == 'distance_meters';

  int get inSeconds => isTime ? value.round() : 0;
  double get inMeters => isDistance ? value : 0.0;
  double get inKilometers => isDistance ? value / 1000.0 : 0.0;

  Map<String, dynamic> toJson() => {
    'type': type,
    'value': value,
  };

  factory WorkoutDuration.fromJson(Map<String, dynamic> json) => WorkoutDuration(
    type: json['type'] as String? ?? 'distance_meters',
    value: (json['value'] as num?)?.toDouble() ?? 1000.0,
  );

  String get displayString {
    if (isTime) {
      final s = value.round();
      final m = s ~/ 60;
      final remS = s % 60;
      if (m > 0 && remS > 0) return '$m min e $remS s';
      if (m > 0) return '$m min';
      return '$s s';
    } else {
      if (value >= 1000) {
        final km = value / 1000.0;
        // Mostra decimali solo se non è un numero intero
        final display = km == km.toInt() 
            ? km.toInt().toString() 
            : km.toStringAsFixed(2);
        return '$display km';
      }
      return '${value.round()} m';
    }
  }
}

class WorkoutTarget {
  final TargetMetric metric;
  final int? targetPaceSecPerKm;
  final int? paceToleranceSec;
  final int? targetHrZoneMin;
  final int? targetHrZoneMax;
  final int? targetHrBpm;
  final int? bpmTolerance;
  final int? targetCadence;
  final int? cadenceTolerance;

  const WorkoutTarget({
    this.metric = TargetMetric.none,
    this.targetPaceSecPerKm,
    this.paceToleranceSec,
    this.targetHrZoneMin,
    this.targetHrZoneMax,
    this.targetHrBpm,
    this.bpmTolerance,
    this.targetCadence,
    this.cadenceTolerance,
  });

  bool get isValid {
    // Validazione: i valori numerici non devono essere negativi
    if (targetPaceSecPerKm != null && targetPaceSecPerKm! <= 0) return false;
    if (paceToleranceSec != null && paceToleranceSec! < 0) return false;
    if (targetHrZoneMin != null && targetHrZoneMin! <= 0) return false;
    if (targetHrZoneMax != null && targetHrZoneMax! <= 0) return false;
    if (targetHrZoneMin != null && targetHrZoneMax != null && targetHrZoneMin! > targetHrZoneMax!) {
      return false;
    }
    if (targetHrBpm != null && targetHrBpm! <= 0) return false;
    if (bpmTolerance != null && bpmTolerance! < 0) return false;
    if (targetCadence != null && targetCadence! <= 0) return false;
    if (cadenceTolerance != null && cadenceTolerance! < 0) return false;
    return true;
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'metric': metric.name};
    if (targetPaceSecPerKm != null) map['target_pace_sec_per_km'] = targetPaceSecPerKm;
    if (paceToleranceSec != null) map['pace_tolerance_sec'] = paceToleranceSec;
    if (targetHrZoneMin != null) map['target_hr_zone_min'] = targetHrZoneMin;
    if (targetHrZoneMax != null) map['target_hr_zone_max'] = targetHrZoneMax;
    if (targetHrBpm != null) map['target_hr_bpm'] = targetHrBpm;
    if (bpmTolerance != null) map['bpm_tolerance'] = bpmTolerance;
    if (targetCadence != null) map['target_cadence'] = targetCadence;
    if (cadenceTolerance != null) map['cadence_tolerance'] = cadenceTolerance;
    return map;
  }

  factory WorkoutTarget.fromJson(Map<String, dynamic> json) {
    final metricStr = json['metric'] as String? ?? 'none';
    final metric = TargetMetric.values.firstWhere(
      (m) => m.name == metricStr,
      orElse: () => TargetMetric.none,
    );
    return WorkoutTarget(
      metric: metric,
      targetPaceSecPerKm: json['target_pace_sec_per_km'] as int?,
      paceToleranceSec: json['pace_tolerance_sec'] as int?,
      targetHrZoneMin: json['target_hr_zone_min'] as int?,
      targetHrZoneMax: json['target_hr_zone_max'] as int?,
      targetHrBpm: json['target_hr_bpm'] as int?,
      bpmTolerance: json['bpm_tolerance'] as int?,
      targetCadence: json['target_cadence'] as int?,
      cadenceTolerance: json['cadence_tolerance'] as int?,
    );
  }

  String get displayPace {
    if (targetPaceSecPerKm == null) return '--:--';
    final m = targetPaceSecPerKm! ~/ 60;
    final s = targetPaceSecPerKm! % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')} /km';
  }

  String get displayHeartRateZone {
    if (targetHrZoneMin == null || targetHrZoneMax == null) return '--';
    return '${targetHrZoneMin!}-${targetHrZoneMax!}';
  }

  String get displayHeartRate {
    if (targetHrBpm == null) return '--';
    if (bpmTolerance == null || bpmTolerance! <= 0) {
      return '${targetHrBpm!} bpm';
    }
    return '${targetHrBpm! - bpmTolerance!}-${targetHrBpm! + bpmTolerance!} bpm';
  }

  String get displayCadence {
    if (targetCadence == null) return '--';
    if (cadenceTolerance == null || cadenceTolerance! <= 0) {
      return '${targetCadence!} rpm';
    }
    return '${targetCadence! - cadenceTolerance!}-${targetCadence! + cadenceTolerance!} rpm';
  }
}

class WorkoutStep {
  final String id;
  String label;
  StepPhase phase;
  WorkoutDuration duration;
  WorkoutTarget target;
  String? voiceCue;

  // Ripetizioni nidificate
  int repeatCount;
  List<WorkoutStep> subSteps;

  WorkoutStep({
    required this.id,
    required this.label,
    this.phase = StepPhase.work,
    required this.duration,
    this.target = const WorkoutTarget(),
    this.voiceCue,
    this.repeatCount = 1,
    List<WorkoutStep>? subSteps,
  }) : subSteps = subSteps ?? [];

  bool get isRepeatBlock => repeatCount > 1 || subSteps.isNotEmpty;

  /// Calcola la durata totale dello step (incluse ripetizioni nidificate)
  WorkoutDuration get totalDuration {
    if (subSteps.isEmpty) {
      return WorkoutDuration(type: duration.type, value: duration.value * repeatCount);
    }

    // Se ha sub-steps, calcola la somma ricorsiva
    double totalValue = 0;
    String dType = duration.type;

    for (final sub in subSteps) {
      final subTotal = sub.totalDuration;
      if (subTotal.type == dType) {
        totalValue += subTotal.value;
      } else {
        // Tipi misti: priorità a 'time_seconds'
        dType = 'time_seconds';
        totalValue += subTotal.value;
      }
    }

    return WorkoutDuration(type: dType, value: totalValue * repeatCount);
  }

  /// Restituisce la profondità massima di nidificazione
  int get maxNestingDepth {
    if (subSteps.isEmpty) return 0;
    return 1 + subSteps.map((s) => s.maxNestingDepth).reduce((a, b) => a > b ? a : b);
  }

  bool get isValid {
    // Validazione base
    if (label.isEmpty) return false;
    if (repeatCount < 1) return false;
    if (!target.isValid) return false;

    // Validazione sub-steps ricorsiva
    if (subSteps.isEmpty && repeatCount <= 1) {
      // Solo step singolo: durata/target ok
      return true;
    }

    for (final sub in subSteps) {
      if (!sub.isValid) return false;
    }

    return true;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'phase': phase.name,
    'duration': duration.toJson(),
    'target': target.toJson(),
    if (voiceCue != null) 'voice_cue': voiceCue,
    if (repeatCount > 1) 'repeat_count': repeatCount,
    if (subSteps.isNotEmpty) 'sub_steps': subSteps.map((s) => s.toJson()).toList(),
  };

  factory WorkoutStep.fromJson(Map<String, dynamic> json) => WorkoutStep(
    id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
    label: json['label'] as String? ?? 'Fase',
    phase: StepPhase.values.firstWhere(
      (p) => p.name == (json['phase'] as String? ?? 'work'),
      orElse: () => StepPhase.work,
    ),
    duration: json['duration'] != null
        ? WorkoutDuration.fromJson(json['duration'] as Map<String, dynamic>)
        : const WorkoutDuration(type: 'distance_meters', value: 1000),
    target: json['target'] != null
        ? WorkoutTarget.fromJson(json['target'] as Map<String, dynamic>)
        : const WorkoutTarget(),
    voiceCue: json['voice_cue'] as String?,
    repeatCount: json['repeat_count'] as int? ?? 1,
    subSteps: (json['sub_steps'] as List<dynamic>?)
        ?.map((s) => WorkoutStep.fromJson(s as Map<String, dynamic>))
        .toList(),
  );
}

class WorkoutPlan {
  final String version;
  final String id;
  String name;
  String description;
  WorkoutStructure structure;
  bool announceStart;
  bool announceSplits;
  bool announceEnd;
  List<WorkoutStep> steps;

  WorkoutPlan({
    this.version = '1.0',
    required this.id,
    required this.name,
    this.description = '',
    this.structure = WorkoutStructure.continuous,
    this.announceStart = true,
    this.announceSplits = true,
    this.announceEnd = true,
    List<WorkoutStep>? steps,
  }) : steps = steps ?? [];

  bool get isValid {
    if (name.isEmpty) return false;
    if (steps.isEmpty) return false;
    
    // Verifica ricorsiva di tutti gli step
    for (final step in steps) {
      if (!step.isValid) return false;
    }
    
    return true;
  }

  /// Calcola la durata totale dell'allenamento
  WorkoutDuration get totalDuration {
    if (steps.isEmpty) {
      return const WorkoutDuration(type: 'distance_meters', value: 0);
    }

    double totalValue = 0;
    String? dType;

    for (final step in steps) {
      final stepTotal = step.totalDuration;
      if (dType == null) {
        dType = stepTotal.type;
      }
      if (stepTotal.type == dType) {
        totalValue += stepTotal.value;
      }
    }

    return WorkoutDuration(type: dType ?? 'distance_meters', value: totalValue);
  }

  /// Restituisce la profondità massima di nidificazione degli step
  int get maxNestingDepth {
    if (steps.isEmpty) return 0;
    return steps.map((s) => s.maxNestingDepth).reduce((a, b) => a > b ? a : b);
  }

  Map<String, dynamic> toJson() => {
    'version': version,
    'id': id,
    'name': name,
    'description': description,
    'structure': structure.name,
    'voice_coaching': {
      'announce_start': announceStart,
      'announce_splits': announceSplits,
      'announce_end': announceEnd,
    },
    'steps': steps.map((s) => s.toJson()).toList(),
  };

  String toPrettyJson() {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(toJson());
  }

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) {
    final coaching = json['voice_coaching'] as Map<String, dynamic>? ?? {};
    final structStr = json['structure'] as String? ?? 'continuous';
    final structure = WorkoutStructure.values.firstWhere(
      (s) => s.name == structStr,
      orElse: () => WorkoutStructure.continuous,
    );

    return WorkoutPlan(
      version: json['version'] as String? ?? '1.0',
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] as String? ?? 'Nuovo Allenamento',
      description: json['description'] as String? ?? '',
      structure: structure,
      announceStart: coaching['announce_start'] as bool? ?? true,
      announceSplits: coaching['announce_splits'] as bool? ?? true,
      announceEnd: coaching['announce_end'] as bool? ?? true,
      steps: (json['steps'] as List<dynamic>?)
          ?.map((s) => WorkoutStep.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Converte il WorkoutPlan nel Preset esistente per garantire retrocompatibilità
  /// Nota: i target specifici (pace, HR zone, cadence) della versione 2.0 non sono
  /// completamente rappresentabili nel modello Preset legacy. Questa è una conversione best-effort.
  Preset toPreset() {
    final isIntervals = structure != WorkoutStructure.continuous || steps.any((s) => s.isRepeatBlock);
    final intervals = <IntervalStep>[];

    void flattenStep(WorkoutStep step, {int depth = 0}) {
      // Protezione contro nidificazione eccessiva (max 10 livelli)
      if (depth > 10) return;

      if (step.subSteps.isNotEmpty) {
        for (int r = 0; r < step.repeatCount; r++) {
          for (final sub in step.subSteps) {
            flattenStep(sub, depth: depth + 1);
          }
        }
      } else {
        // Crea coaching alerts dal target del step
        final coachingAlerts = <CoachingAlert>[];
        
        if (step.target.metric == TargetMetric.pace && step.target.targetPaceSecPerKm != null) {
          final paceMinPerKm = step.target.targetPaceSecPerKm! / 60.0;
          final tolerance = (step.target.paceToleranceSec ?? 5) / 60.0;
          coachingAlerts.add(CoachingAlert(
            id: '${step.id}_pace',
            name: 'Ritmo controllato',
            metric: AlertMetric.pace,
            minValue: (paceMinPerKm - tolerance).clamp(0.0, double.infinity),
            maxValue: paceMinPerKm + tolerance,
            enabled: true,
            speakCurrentValue: false,
          ));
        } else if (step.target.metric == TargetMetric.heartRateBpm && step.target.targetHrBpm != null) {
          final tolerance = step.target.bpmTolerance ?? 5;
          coachingAlerts.add(CoachingAlert(
            id: '${step.id}_hr',
            name: 'Frequenza cardiaca controllata',
            metric: AlertMetric.bpm,
            minValue: (step.target.targetHrBpm! - tolerance).toDouble().clamp(0.0, double.infinity),
            maxValue: (step.target.targetHrBpm! + tolerance).toDouble(),
            enabled: true,
            speakCurrentValue: false,
          ));
        } else if (step.target.metric == TargetMetric.heartRateZone && 
                   step.target.targetHrZoneMin != null && 
                   step.target.targetHrZoneMax != null) {
          coachingAlerts.add(CoachingAlert(
            id: '${step.id}_hrzone',
            name: 'Zona FC controllata',
            metric: AlertMetric.hrZone,
            minValue: step.target.targetHrZoneMin!.toDouble(),
            maxValue: step.target.targetHrZoneMax!.toDouble(),
            enabled: true,
            speakCurrentValue: false,
          ));
        }

        intervals.add(IntervalStep(
          id: step.id,
          name: step.label,
          type: step.duration.isTime ? AlertTrigger.time : AlertTrigger.distance,
          durationSeconds: step.duration.inSeconds > 0 ? step.duration.inSeconds : 60,
          distanceMeters: step.duration.inMeters > 0 ? step.duration.inMeters : 1000.0,
          coachingAlerts: coachingAlerts,
        ));
      }
    }

    for (final s in steps) {
      flattenStep(s);
    }

    return Preset(
      id: id,
      name: name,
      description: description,
      isIntervalTraining: isIntervals,
      intervals: intervals,
      announceStart: announceStart,
      announceEnd: announceEnd,
      announceSummary: announceSplits,
    );
  }

  /// Crea un WorkoutPlan a partire da un Preset esistente (retrocompatibilità)
  /// Ricostruisce i target dagli AlertConfig e CoachingAlert del Preset
  factory WorkoutPlan.fromPreset(Preset preset) {
    final List<WorkoutStep> steps = [];
    
    if (preset.isIntervalTraining && preset.intervals.isNotEmpty) {
      for (final i in preset.intervals) {
        // Ricostruisci il target dagli alerting config
        WorkoutTarget target = const WorkoutTarget();
        
        if (i.coachingAlerts.isNotEmpty) {
          final coachingAlert = i.coachingAlerts.first;
          if (coachingAlert.metric == AlertMetric.pace) {
            // Converte pace minPerKm a sec/km (midpoint della range)
            final avgPaceMin = (coachingAlert.minValue + coachingAlert.maxValue) / 2;
            final avgPaceSec = (avgPaceMin * 60).toInt();
            final tolerance = ((coachingAlert.maxValue - coachingAlert.minValue) * 30).toInt();
            target = WorkoutTarget(
              metric: TargetMetric.pace,
              targetPaceSecPerKm: avgPaceSec,
              paceToleranceSec: tolerance,
            );
          } else if (coachingAlert.metric == AlertMetric.bpm) {
            final avgHr = ((coachingAlert.minValue + coachingAlert.maxValue) / 2).toInt();
            final tolerance = ((coachingAlert.maxValue - coachingAlert.minValue) / 2).toInt();
            target = WorkoutTarget(
              metric: TargetMetric.heartRateBpm,
              targetHrBpm: avgHr,
              bpmTolerance: tolerance,
            );
          } else if (coachingAlert.metric == AlertMetric.hrZone) {
            target = WorkoutTarget(
              metric: TargetMetric.heartRateZone,
              targetHrZoneMin: coachingAlert.minValue.toInt(),
              targetHrZoneMax: coachingAlert.maxValue.toInt(),
            );
          }
        }
        
        steps.add(WorkoutStep(
          id: i.id,
          label: i.name,
          phase: StepPhase.work,
          duration: i.type == AlertTrigger.time
              ? WorkoutDuration(type: 'time_seconds', value: i.durationSeconds.toDouble())
              : WorkoutDuration(type: 'distance_meters', value: i.distanceMeters),
          target: target,
        ));
      }
    } else {
      // Default: allenamento continuo da 5km
      steps.add(WorkoutStep(
        id: 'continuous_main',
        label: 'Corsa Continua',
        phase: StepPhase.work,
        duration: const WorkoutDuration(type: 'distance_meters', value: 5000),
        target: const WorkoutTarget(),
      ));
    }

    return WorkoutPlan(
      id: preset.id,
      name: preset.name,
      description: preset.description,
      structure: preset.isIntervalTraining ? WorkoutStructure.intervals : WorkoutStructure.continuous,
      announceStart: preset.announceStart,
      announceSplits: preset.announceSummary,
      announceEnd: preset.announceEnd,
      steps: steps,
    );
  }
}
