import 'dart:convert';
import 'preset.dart';
import 'alert_config.dart';

enum WorkoutStructure { continuous, intervals, pyramid, fartlek }

/// Represents a periodic alert plan that can be converted to AlertConfig
class WorkoutAlertPlan {
  final String name;
  final String metric; // 'distance', 'time', 'bpm', 'pace'
  final String trigger; // 'time', 'distance'
  final int? intervalSeconds;
  final double? intervalMeters;
  final String mode; // 'total', 'current', 'split'

  const WorkoutAlertPlan({
    required this.name,
    required this.metric,
    required this.trigger,
    this.intervalSeconds,
    this.intervalMeters,
    this.mode = 'current',
  });

  /// Convert to AlertMetric enum
  AlertMetric _toAlertMetric() {
    switch (metric.toLowerCase()) {
      case 'distance':
        return AlertMetric.distance;
      case 'time':
        return AlertMetric.time;
      case 'bpm':
        return AlertMetric.bpm;
      case 'pace':
        return AlertMetric.pace;
      case 'speed':
        return AlertMetric.speed;
      case 'hrzone':
      case 'hr_zone':
        return AlertMetric.hrZone;
      default:
        return AlertMetric.time;
    }
  }

  /// Convert to AlertMode enum
  AlertMode _toAlertMode() {
    switch (mode.toLowerCase()) {
      case 'total':
        return AlertMode.total;
      case 'interval':
        return AlertMode.interval;
      case 'lap':
        return AlertMode.lap;
      case 'current':
      default:
        return AlertMode.current;
    }
  }

  /// Convert to AlertTrigger enum
  AlertTrigger _toAlertTrigger() {
    switch (trigger.toLowerCase()) {
      case 'distance':
        return AlertTrigger.distance;
      case 'time':
      default:
        return AlertTrigger.time;
    }
  }

  /// Convert WorkoutAlertPlan to AlertConfig
  AlertConfig toAlertConfig(String idPrefix) {
    return AlertConfig(
      id: '${idPrefix}_${name.replaceAll(' ', '_').toLowerCase()}',
      name: name,
      metric: _toAlertMetric(),
      mode: _toAlertMode(),
      trigger: _toAlertTrigger(),
      intervalSeconds: intervalSeconds ?? 60,
      intervalMeters: intervalMeters ?? 1000.0,
      enabled: true,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'metric': metric,
    'trigger': trigger,
    if (intervalSeconds != null) 'interval_seconds': intervalSeconds,
    if (intervalMeters != null) 'interval_meters': intervalMeters,
    'mode': mode,
  };

  factory WorkoutAlertPlan.fromJson(Map<String, dynamic> json) =>
      WorkoutAlertPlan(
        name: json['name'] as String? ?? 'Alert',
        metric: json['metric'] as String? ?? 'time',
        trigger: json['trigger'] as String? ?? 'time',
        intervalSeconds: (json['interval_seconds'] as num?)?.round(),
        intervalMeters: (json['interval_meters'] as num?)?.toDouble(),
        mode: json['mode'] as String? ?? 'current',
      );
}

/// Represents a coaching alert plan that can be converted to CoachingAlert
class WorkoutCoachingPlan {
  final String name;
  final String metric; // 'bpm', 'pace', 'hr_zone'
  final double? minValue;
  final double? maxValue;

  const WorkoutCoachingPlan({
    required this.name,
    required this.metric,
    this.minValue,
    this.maxValue,
  });

  /// Convert to AlertMetric enum
  AlertMetric _toAlertMetric() {
    switch (metric.toLowerCase()) {
      case 'bpm':
        return AlertMetric.bpm;
      case 'pace':
        return AlertMetric.pace;
      case 'hr_zone':
      case 'hrzone':
        return AlertMetric.hrZone;
      case 'speed':
        return AlertMetric.speed;
      default:
        return AlertMetric.bpm;
    }
  }

  /// Convert WorkoutCoachingPlan to CoachingAlert
  CoachingAlert toCoachingAlert(String idPrefix) {
    final alertMetric = _toAlertMetric();
    double minV = minValue ?? 0.0;
    double maxV = maxValue ?? 200.0;

    // Se la metrica è il passo (pace), converti i valori se espressi in secondi (> 30s)
    if (alertMetric == AlertMetric.pace) {
      if (minV > 30.0) {
        minV = minV / 60.0;
      }
      if (maxV > 30.0) {
        maxV = maxV / 60.0;
      }
      if (minValue == null) minV = 3.0; // 3:00 min/km
      if (maxValue == null) maxV = 10.0; // 10:00 min/km
    }

    return CoachingAlert(
      id: '${idPrefix}_${name.replaceAll(' ', '_').toLowerCase()}',
      name: name,
      metric: alertMetric,
      minValue: minV,
      maxValue: maxV,
      enabled: true,
      speakCurrentValue: true,
      okIntervalSeconds: 60,
      outOfRangeDelaySeconds: 10,
      notifyOnReturn: true,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'metric': metric,
    if (minValue != null) 'min_value': minValue,
    if (maxValue != null) 'max_value': maxValue,
  };

  factory WorkoutCoachingPlan.fromJson(Map<String, dynamic> json) =>
      WorkoutCoachingPlan(
        name: json['name'] as String? ?? 'Coaching',
        metric: json['metric'] as String? ?? 'bpm',
        minValue: (json['min_value'] as num?)?.toDouble(),
        maxValue: (json['max_value'] as num?)?.toDouble(),
      );
}

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
  final int? targetHrBpmMin;
  final int? targetHrBpmMax;
  final int? targetPaceSecPerKmMin;
  final int? targetPaceSecPerKmMax;
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
    this.targetHrBpmMin,
    this.targetHrBpmMax,
    this.targetPaceSecPerKmMin,
    this.targetPaceSecPerKmMax,
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
    if (targetHrBpmMin != null && targetHrBpmMin! <= 0) return false;
    if (targetHrBpmMax != null && targetHrBpmMax! <= 0) return false;
    if (targetHrBpm != null && targetHrBpm! <= 0) return false;
    if (bpmTolerance != null && bpmTolerance! < 0) return false;
    if (targetPaceSecPerKmMin != null && targetPaceSecPerKmMin! <= 0) return false;
    if (targetPaceSecPerKmMax != null && targetPaceSecPerKmMax! <= 0) return false;
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
    if (targetHrBpmMin != null) map['target_hr_bpm_min'] = targetHrBpmMin;
    if (targetHrBpmMax != null) map['target_hr_bpm_max'] = targetHrBpmMax;
    if (targetPaceSecPerKmMin != null) map['target_pace_sec_per_km_min'] = targetPaceSecPerKmMin;
    if (targetPaceSecPerKmMax != null) map['target_pace_sec_per_km_max'] = targetPaceSecPerKmMax;
    if (bpmTolerance != null) map['bpm_tolerance'] = bpmTolerance;
    if (targetCadence != null) map['target_cadence'] = targetCadence;
    if (cadenceTolerance != null) map['cadence_tolerance'] = cadenceTolerance;
    return map;
  }

  factory WorkoutTarget.fromJson(Map<String, dynamic> json) {
    final metricRaw = json['metric']?.toString().toLowerCase().replaceAll('_', '').replaceAll(' ', '') ?? '';
    int? minBpm = (json['target_hr_bpm_min'] as num?)?.round() ?? (json['min_bpm'] as num?)?.round() ?? (json['target_hr_min'] as num?)?.round() ?? (json['hr_min'] as num?)?.round();
    int? maxBpm = (json['target_hr_bpm_max'] as num?)?.round() ?? (json['max_bpm'] as num?)?.round() ?? (json['target_hr_max'] as num?)?.round() ?? (json['hr_max'] as num?)?.round();
    int? centerBpm = (json['target_hr_bpm'] as num?)?.round() ?? (json['target_bpm'] as num?)?.round() ?? (json['bpm'] as num?)?.round();
    int? bpmTol = (json['bpm_tolerance'] as num?)?.round() ?? (json['tolerance'] as num?)?.round();
    if (minBpm == null && centerBpm != null && bpmTol != null) {
      minBpm = centerBpm - bpmTol;
      maxBpm = centerBpm + bpmTol;
    } else if (centerBpm == null && minBpm != null && maxBpm != null) {
      centerBpm = ((minBpm + maxBpm) / 2).round();
      bpmTol = ((maxBpm - minBpm) / 2).round();
    }
    TargetMetric metric;
    if (metricRaw.contains('zone')) {
      metric = TargetMetric.heartRateZone;
    } else if (metricRaw.contains('bpm') || metricRaw.contains('heart') || metricRaw.contains('cardio') || minBpm != null || centerBpm != null) {
      metric = TargetMetric.heartRateBpm;
    } else if (metricRaw.contains('pace') || metricRaw.contains('ritmo') || json['target_pace_sec_per_km'] != null) {
      metric = TargetMetric.pace;
    } else if (metricRaw.contains('cadence') || metricRaw.contains('cadenza')) {
      metric = TargetMetric.cadence;
    } else {
      metric = TargetMetric.none;
    }
    return WorkoutTarget(
      metric: metric,
      targetPaceSecPerKm: (json['target_pace_sec_per_km'] as num?)?.round(),
      targetPaceSecPerKmMin: (json['target_pace_sec_per_km_min'] as num?)?.round(),
      targetPaceSecPerKmMax: (json['target_pace_sec_per_km_max'] as num?)?.round(),
      paceToleranceSec: (json['pace_tolerance_sec'] as num?)?.round(),
      targetHrZoneMin: (json['target_hr_zone_min'] as num?)?.round(),
      targetHrZoneMax: (json['target_hr_zone_max'] as num?)?.round(),
      targetHrBpm: centerBpm ?? (json['target_hr_bpm'] as num?)?.round(),
      targetHrBpmMin: minBpm,
      targetHrBpmMax: maxBpm,
      bpmTolerance: bpmTol,
      targetCadence: (json['target_cadence'] as num?)?.round(),
      cadenceTolerance: (json['cadence_tolerance'] as num?)?.round(),
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

  // Avvisi periodici e di coaching (AlertConfig e CoachingAlert)
  List<AlertConfig> periodicAlerts;
  List<CoachingAlert> coachingAlerts;

  // Plans for alerts and coaching (new fields for structured definitions)
  List<WorkoutAlertPlan> periodicAlertPlans;
  List<WorkoutCoachingPlan> coachingAlertPlans;

  WorkoutStep({
    required this.id,
    required this.label,
    this.phase = StepPhase.work,
    required this.duration,
    this.target = const WorkoutTarget(),
    this.voiceCue,
    this.repeatCount = 1,
    List<WorkoutStep>? subSteps,
    List<AlertConfig>? periodicAlerts,
    List<CoachingAlert>? coachingAlerts,
    List<WorkoutAlertPlan>? periodicAlertPlans,
    List<WorkoutCoachingPlan>? coachingAlertPlans,
  }) : subSteps = subSteps ?? [],
       periodicAlerts = periodicAlerts ?? [],
       coachingAlerts = coachingAlerts ?? [],
       periodicAlertPlans = periodicAlertPlans ?? [],
       coachingAlertPlans = coachingAlertPlans ?? [];

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
    if (periodicAlerts.isNotEmpty) 'periodic_alerts': periodicAlerts.map((a) => a.toJson()).toList(),
    if (coachingAlerts.isNotEmpty) 'coaching_alerts': coachingAlerts.map((a) => a.toJson()).toList(),
    if (periodicAlertPlans.isNotEmpty) 'periodic_alert_plans': periodicAlertPlans.map((a) => a.toJson()).toList(),
    if (coachingAlertPlans.isNotEmpty) 'coaching_alert_plans': coachingAlertPlans.map((a) => a.toJson()).toList(),
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
    periodicAlerts: const [],
    coachingAlerts: const [],
    periodicAlertPlans: (json['periodic_alerts'] as List<dynamic>? ?? json['periodic_alert_plans'] as List<dynamic>?)
        ?.map((a) => WorkoutAlertPlan.fromJson(a as Map<String, dynamic>))
        .toList(),
    coachingAlertPlans: (json['coaching_alerts'] as List<dynamic>? ?? json['coaching_alert_plans'] as List<dynamic>?)
        ?.map((a) => WorkoutCoachingPlan.fromJson(a as Map<String, dynamic>))
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
  List<AlertConfig> globalAlerts;
  List<WorkoutAlertPlan> globalAlertPlans;

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
    List<AlertConfig>? globalAlerts,
    List<WorkoutAlertPlan>? globalAlertPlans,
  }) : steps = steps ?? [],
       globalAlerts = globalAlerts ?? [],
       globalAlertPlans = globalAlertPlans ?? [];

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
      dType ??= stepTotal.type;
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
    if (globalAlerts.isNotEmpty) 'global_alerts': globalAlerts.map((a) => a.toJson()).toList(),
    if (globalAlertPlans.isNotEmpty) 'global_alert_plans': globalAlertPlans.map((a) => a.toJson()).toList(),
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
      globalAlerts: const [],
      globalAlertPlans: (json['global_alerts'] as List<dynamic>? ?? json['global_alert_plans'] as List<dynamic>?)
          ?.map((a) => WorkoutAlertPlan.fromJson(a as Map<String, dynamic>))
          .toList(),
      steps: (json['steps'] as List<dynamic>?)
          ?.map((s) => WorkoutStep.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Converte il WorkoutPlan nel Preset esistente per garantire retrocompatibilità
  /// ALWAYS sets isIntervalTraining: true per interval training consistente.
  /// Nota: i target specifici (pace, HR zone, cadence) della versione 2.0 non sono
  /// completamente rappresentabili nel modello Preset legacy. Questa è una conversione best-effort.
  Preset toPreset() {
    // ALWAYS set isIntervalTraining: true for interval training structures
    final intervals = <IntervalStep>[];
    final presetGlobalAlerts = <AlertConfig>[];

    // Map globalAlerts to preset.alerts
    presetGlobalAlerts.addAll(globalAlerts);

    // Convert globalAlertPlans to AlertConfig and add to alerts
    for (final plan in globalAlertPlans) {
      presetGlobalAlerts.add(plan.toAlertConfig('global'));
    }

    if (announceSplits && !presetGlobalAlerts.any((a) => a.metric == AlertMetric.time && a.trigger == AlertTrigger.time)) {
      presetGlobalAlerts.add(AlertConfig(
        id: 'global_split_time',
        name: 'Tempo trascorso',
        metric: AlertMetric.time,
        mode: AlertMode.total,
        trigger: AlertTrigger.time,
        intervalSeconds: 300,
        enabled: true,
      ));
    }

    void flattenStep(WorkoutStep step, {int depth = 0, int? repeatIndex}) {
      // Protezione contro nidificazione eccessiva (max 10 livelli)
      if (depth > 10) return;

      if (step.subSteps.isNotEmpty) {
        for (int r = 0; r < step.repeatCount; r++) {
          for (final sub in step.subSteps) {
            flattenStep(sub, depth: depth + 1, repeatIndex: r + 1);
          }
        }
      } else {
        final stepId = repeatIndex != null ? '${step.id}_rep_$repeatIndex' : step.id;
        final coachingAlerts = <CoachingAlert>[];
        final stepAlerts = <AlertConfig>[];
        
        // Map step.periodicAlerts to IntervalStep.alerts
        stepAlerts.addAll(step.periodicAlerts);
        
        // Convert step.periodicAlertPlans to AlertConfig
        for (final plan in step.periodicAlertPlans) {
          stepAlerts.add(plan.toAlertConfig(stepId));
        }
        
        // Map step.coachingAlerts to IntervalStep.coachingAlerts (DIRECTLY)
        coachingAlerts.addAll(step.coachingAlerts);
        
        // Convert step.coachingAlertPlans to CoachingAlert
        for (final plan in step.coachingAlertPlans) {
          coachingAlerts.add(plan.toCoachingAlert(stepId));
        }
        
        // FALLBACK: Generate coaching_alerts from step.target if no explicit coaching alerts exist
        if (coachingAlerts.isEmpty && step.target.metric != TargetMetric.none) {
          if (step.target.metric == TargetMetric.heartRateBpm && (step.target.targetHrBpm != null || step.target.targetHrBpmMin != null)) {
            final minB = (step.target.targetHrBpmMin ?? (step.target.targetHrBpm! - (step.target.bpmTolerance ?? 5))).toDouble().clamp(40.0, 240.0);
            final maxB = (step.target.targetHrBpmMax ?? (step.target.targetHrBpm! + (step.target.bpmTolerance ?? 5))).toDouble().clamp(40.0, 240.0);
            coachingAlerts.add(CoachingAlert(
              id: '${stepId}_hr',
              name: 'BPM ${minB.round()}-${maxB.round()}',
              metric: AlertMetric.bpm,
              minValue: minB,
              maxValue: maxB,
              enabled: true,
              speakCurrentValue: true,
              okIntervalSeconds: 60,
              outOfRangeDelaySeconds: 10,
              notifyOnReturn: true,
            ));
            if (step.duration.inSeconds >= 60 && !stepAlerts.any((a) => a.metric == AlertMetric.bpm && a.id == '${stepId}_periodic_bpm')) {
              stepAlerts.add(AlertConfig(
                id: '${stepId}_periodic_bpm',
                name: 'Battito cardiaco',
                metric: AlertMetric.bpm,
                mode: AlertMode.current,
                trigger: AlertTrigger.time,
                intervalSeconds: step.duration.inSeconds >= 180 ? 60 : 30,
                enabled: true,
              ));
            }
          }

          if (step.target.metric == TargetMetric.pace && step.target.targetPaceSecPerKm != null) {
            final paceMinPerKm = step.target.targetPaceSecPerKm! / 60.0;
            final tolerance = (step.target.paceToleranceSec ?? 10) / 60.0;
            coachingAlerts.add(CoachingAlert(
              id: '${stepId}_pace',
              name: 'Ritmo controllato',
              metric: AlertMetric.pace,
              minValue: (paceMinPerKm - tolerance).clamp(0.0, double.infinity),
              maxValue: paceMinPerKm + tolerance,
              enabled: true,
              speakCurrentValue: true,
              okIntervalSeconds: 60,
              outOfRangeDelaySeconds: 10,
              notifyOnReturn: true,
            ));
            if (step.duration.inSeconds >= 60 && !stepAlerts.any((a) => a.metric == AlertMetric.pace && a.id == '${stepId}_periodic_pace')) {
              stepAlerts.add(AlertConfig(
                id: '${stepId}_periodic_pace',
                name: 'Ritmo',
                metric: AlertMetric.pace,
                mode: AlertMode.current,
                trigger: AlertTrigger.time,
                intervalSeconds: step.duration.inSeconds >= 180 ? 60 : 30,
                enabled: true,
              ));
            }
          } else if (step.target.metric == TargetMetric.heartRateZone && 
                     step.target.targetHrZoneMin != null && 
                     step.target.targetHrZoneMax != null) {
            coachingAlerts.add(CoachingAlert(
              id: '${stepId}_hrzone',
              name: 'Zona FC controllata',
              metric: AlertMetric.hrZone,
              minValue: step.target.targetHrZoneMin!.toDouble(),
              maxValue: step.target.targetHrZoneMax!.toDouble(),
              enabled: true,
              speakCurrentValue: false,
            ));
          }
        }

        intervals.add(IntervalStep(
          id: stepId,
          name: step.label,
          type: step.duration.isTime ? AlertTrigger.time : AlertTrigger.distance,
          durationSeconds: step.duration.inSeconds > 0 ? step.duration.inSeconds : 60,
          distanceMeters: step.duration.inMeters > 0 ? step.duration.inMeters : 1000.0,
          alerts: stepAlerts,
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
      isIntervalTraining: true, // ALWAYS set to true for consistent interval training
      intervals: intervals,
      alerts: presetGlobalAlerts,
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
          periodicAlerts: i.alerts,
          coachingAlerts: i.coachingAlerts,
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
      globalAlerts: preset.alerts,
      steps: steps,
    );
  }
}
