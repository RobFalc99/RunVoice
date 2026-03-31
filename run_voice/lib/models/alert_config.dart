/// Type of metric being tracked
enum AlertMetric { distance, time, speed, pace, bpm, hrZone }

extension AlertMetricExtension on AlertMetric {
  String get displayName {
    switch (this) {
      case AlertMetric.distance:
        return 'Distanza';
      case AlertMetric.time:
        return 'Tempo';
      case AlertMetric.speed:
        return 'Velocità';
      case AlertMetric.pace:
        return 'Ritmo';
      case AlertMetric.bpm:
        return 'BPM';
      case AlertMetric.hrZone:
        return 'Zona FC';
    }
  }

  String get iconName {
    switch (this) {
      case AlertMetric.distance:
        return 'straighten';
      case AlertMetric.time:
        return 'timer';
      case AlertMetric.speed:
        return 'speed';
      case AlertMetric.pace:
        return 'directions_run';
      case AlertMetric.bpm:
        return 'favorite';
      case AlertMetric.hrZone:
        return 'area_chart';
    }
  }

  /// The unit spoken/displayed for this metric
  String get unit {
    switch (this) {
      case AlertMetric.distance:
        return 'km';
      case AlertMetric.time:
        return '';
      case AlertMetric.speed:
        return 'km/h';
      case AlertMetric.pace:
        return 'min/km';
      case AlertMetric.bpm:
        return 'BPM';
      case AlertMetric.hrZone:
        return '';
    }
  }
}

/// The aggregation mode for the alert
enum AlertMode {
  total, // Complessivo
  interval, // Intervallo
  lap, // Giro
  current, // Attuale
}

extension AlertModeExtension on AlertMode {
  String get displayName {
    switch (this) {
      case AlertMode.total:
        return 'Complessivo';
      case AlertMode.interval:
        return 'Intervallo';
      case AlertMode.lap:
        return 'Giro';
      case AlertMode.current:
        return 'Attuale';
    }
  }
}

/// A standard periodic alert that announces a metric value
class AlertConfig {
  final String id;
  String name; // The text spoken by TTS
  AlertMetric metric;
  AlertMode mode;
  int intervalSeconds;
  double lapDistanceKm; // Only used when mode == lap
  bool enabled;

  AlertConfig({
    required this.id,
    required this.name,
    required this.metric,
    this.mode = AlertMode.current,
    this.intervalSeconds = 60,
    this.lapDistanceKm = 1.0,
    this.enabled = true,
  });

  /// Build the TTS message based on current workout data
  String buildMessage({
    int? heartRate,
    int? heartRateZone,
    double? distanceKm,
    double? paceMinPerKm,
    double? speedKmh,
    Duration? elapsedTime,
    // Lap data
    double? lapDistanceCurrent,
    double? lapPace,
    double? lapSpeed,
    Duration? lapTime,
    // Interval data
    double? intervalDistance,
    double? intervalPace,
    double? intervalSpeed,
    Duration? intervalTime,
    bool speakUnits = true,
  }) {
    final value = _getValue(
      heartRate: heartRate,
      heartRateZone: heartRateZone,
      distanceKm: distanceKm,
      paceMinPerKm: paceMinPerKm,
      speedKmh: speedKmh,
      elapsedTime: elapsedTime,
      lapDistanceCurrent: lapDistanceCurrent,
      lapPace: lapPace,
      lapSpeed: lapSpeed,
      lapTime: lapTime,
      intervalDistance: intervalDistance,
      intervalPace: intervalPace,
      intervalSpeed: intervalSpeed,
      intervalTime: intervalTime,
    );

    if (value == null) return '$name: non disponibile';

    final unitText = speakUnits ? ' ${metric.unit}' : '';
    return '$name: $value$unitText';
  }

  String? _getValue({
    int? heartRate,
    int? heartRateZone,
    double? distanceKm,
    double? paceMinPerKm,
    double? speedKmh,
    Duration? elapsedTime,
    double? lapDistanceCurrent,
    double? lapPace,
    double? lapSpeed,
    Duration? lapTime,
    double? intervalDistance,
    double? intervalPace,
    double? intervalSpeed,
    Duration? intervalTime,
  }) {
    switch (metric) {
      case AlertMetric.bpm:
        if (heartRate == null || heartRate == 0) return null;
        return '$heartRate';
      case AlertMetric.hrZone:
        if (heartRateZone == null) return null;
        return 'zona $heartRateZone';
      case AlertMetric.distance:
        final dist = _pickByMode(
          distanceKm,
          intervalDistance,
          lapDistanceCurrent,
          distanceKm,
        );
        if (dist == null) return null;
        return dist.toStringAsFixed(2);
      case AlertMetric.time:
        final time = _pickDurationByMode(
          elapsedTime,
          intervalTime,
          lapTime,
          elapsedTime,
        );
        if (time == null) return null;
        return _formatDuration(time);
      case AlertMetric.speed:
        final spd = _pickByMode(speedKmh, intervalSpeed, lapSpeed, speedKmh);
        if (spd == null || spd <= 0) return null;
        return spd.toStringAsFixed(1);
      case AlertMetric.pace:
        final p = _pickByMode(
          paceMinPerKm,
          intervalPace,
          lapPace,
          paceMinPerKm,
        );
        if (p == null || p <= 0 || p.isInfinite || p.isNaN) return null;
        final minutes = p.floor();
        final seconds = ((p - minutes) * 60).round();
        return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
  }

  double? _pickByMode(
    double? total,
    double? interval,
    double? lap,
    double? current,
  ) {
    switch (mode) {
      case AlertMode.total:
        return total;
      case AlertMode.interval:
        return interval;
      case AlertMode.lap:
        return lap;
      case AlertMode.current:
        return current;
    }
  }

  Duration? _pickDurationByMode(
    Duration? total,
    Duration? interval,
    Duration? lap,
    Duration? current,
  ) {
    switch (mode) {
      case AlertMode.total:
        return total;
      case AlertMode.interval:
        return interval;
      case AlertMode.lap:
        return lap;
      case AlertMode.current:
        return current;
    }
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '$h ore $m minuti $s secondi';
    return '$m minuti $s secondi';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'metric': metric.index,
    'mode': mode.index,
    'intervalSeconds': intervalSeconds,
    'lapDistanceKm': lapDistanceKm,
    'enabled': enabled,
  };

  factory AlertConfig.fromJson(Map<String, dynamic> json) => AlertConfig(
    id: json['id'] as String,
    name: json['name'] as String,
    metric: AlertMetric.values[json['metric'] as int? ?? 0],
    mode: AlertMode.values[json['mode'] as int? ?? 0],
    intervalSeconds: json['intervalSeconds'] as int? ?? 60,
    lapDistanceKm: (json['lapDistanceKm'] as num?)?.toDouble() ?? 1.0,
    enabled: json['enabled'] as bool? ?? true,
  );

  AlertConfig copyWith({
    String? id,
    String? name,
    AlertMetric? metric,
    AlertMode? mode,
    int? intervalSeconds,
    double? lapDistanceKm,
    bool? enabled,
  }) => AlertConfig(
    id: id ?? this.id,
    name: name ?? this.name,
    metric: metric ?? this.metric,
    mode: mode ?? this.mode,
    intervalSeconds: intervalSeconds ?? this.intervalSeconds,
    lapDistanceKm: lapDistanceKm ?? this.lapDistanceKm,
    enabled: enabled ?? this.enabled,
  );
}

/// A coaching alert that monitors a metric against a range
class CoachingAlert {
  final String id;
  String name;
  AlertMetric metric; // speed, pace, bpm, hrZone
  double minValue;
  double maxValue;
  int okIntervalSeconds; // How often to say "all good"
  int outOfRangeDelaySeconds; // How long out of range before alerting
  bool enabled;

  CoachingAlert({
    required this.id,
    required this.name,
    required this.metric,
    required this.minValue,
    required this.maxValue,
    this.okIntervalSeconds = 120,
    this.outOfRangeDelaySeconds = 10,
    this.enabled = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'metric': metric.index,
    'minValue': minValue,
    'maxValue': maxValue,
    'okIntervalSeconds': okIntervalSeconds,
    'outOfRangeDelaySeconds': outOfRangeDelaySeconds,
    'enabled': enabled,
  };

  factory CoachingAlert.fromJson(Map<String, dynamic> json) => CoachingAlert(
    id: json['id'] as String,
    name: json['name'] as String,
    metric: AlertMetric.values[json['metric'] as int? ?? 0],
    minValue: (json['minValue'] as num?)?.toDouble() ?? 0,
    maxValue: (json['maxValue'] as num?)?.toDouble() ?? 200,
    okIntervalSeconds: json['okIntervalSeconds'] as int? ?? 120,
    outOfRangeDelaySeconds: json['outOfRangeDelaySeconds'] as int? ?? 10,
    enabled: json['enabled'] as bool? ?? true,
  );

  CoachingAlert copyWith({
    String? id,
    String? name,
    AlertMetric? metric,
    double? minValue,
    double? maxValue,
    int? okIntervalSeconds,
    int? outOfRangeDelaySeconds,
    bool? enabled,
  }) => CoachingAlert(
    id: id ?? this.id,
    name: name ?? this.name,
    metric: metric ?? this.metric,
    minValue: minValue ?? this.minValue,
    maxValue: maxValue ?? this.maxValue,
    okIntervalSeconds: okIntervalSeconds ?? this.okIntervalSeconds,
    outOfRangeDelaySeconds:
        outOfRangeDelaySeconds ?? this.outOfRangeDelaySeconds,
    enabled: enabled ?? this.enabled,
  );

  /// Get current value for this coaching metric
  double? getCurrentValue({
    int? heartRate,
    int? heartRateZone,
    double? speedKmh,
    double? paceMinPerKm,
  }) {
    switch (metric) {
      case AlertMetric.bpm:
        return heartRate?.toDouble();
      case AlertMetric.hrZone:
        return heartRateZone?.toDouble();
      case AlertMetric.speed:
        return speedKmh;
      case AlertMetric.pace:
        return paceMinPerKm;
      default:
        return null;
    }
  }

  /// Build coaching message
  String buildMessage(double currentValue, {bool speakUnits = true}) {
    final unitText = speakUnits ? ' ${metric.unit}' : '';
    if (currentValue >= minValue && currentValue <= maxValue) {
      return '$name: tutto bene';
    } else if (currentValue < minValue) {
      final diff = (minValue - currentValue).toStringAsFixed(1);
      return '$name: troppo basso, di $diff$unitText sotto il minimo';
    } else {
      final diff = (currentValue - maxValue).toStringAsFixed(1);
      return '$name: troppo alto, di $diff$unitText sopra il massimo';
    }
  }
}
