import 'dart:convert';
import 'alert_config.dart';

class IntervalStep {
  final String id;
  String name; // ex: "Corsa intensa", "Recupero"
  AlertTrigger type; // time or distance
  int durationSeconds;
  double distanceMeters;
  List<AlertConfig> alerts;
  List<CoachingAlert> coachingAlerts;

  IntervalStep({
    required this.id,
    required this.name,
    this.type = AlertTrigger.distance,
    this.durationSeconds = 60,
    this.distanceMeters = 1000,
    List<AlertConfig>? alerts,
    List<CoachingAlert>? coachingAlerts,
  }) : alerts = alerts ?? [],
       coachingAlerts = coachingAlerts ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.index,
    'durationSeconds': durationSeconds,
    'distanceMeters': distanceMeters,
    'alerts': alerts.map((a) => a.toJson()).toList(),
    'coachingAlerts': coachingAlerts.map((c) => c.toJson()).toList(),
  };

  factory IntervalStep.fromJson(Map<String, dynamic> json) => IntervalStep(
    id: json['id'] as String,
    name: json['name'] as String,
    type: AlertTrigger.values[json['type'] as int? ?? 0],
    durationSeconds: json['durationSeconds'] as int? ?? 60,
    distanceMeters: (json['distanceMeters'] as num?)?.toDouble() ?? 1000,
    alerts: (json['alerts'] as List<dynamic>?)
        ?.map((a) => AlertConfig.fromJson(a as Map<String, dynamic>))
        .toList(),
    coachingAlerts: (json['coachingAlerts'] as List<dynamic>?)
        ?.map((c) => CoachingAlert.fromJson(c as Map<String, dynamic>))
        .toList(),
  );

  IntervalStep copyWith({
    String? id,
    String? name,
    AlertTrigger? type,
    int? durationSeconds,
    double? distanceMeters,
    List<AlertConfig>? alerts,
    List<CoachingAlert>? coachingAlerts,
  }) => IntervalStep(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    durationSeconds: durationSeconds ?? this.durationSeconds,
    distanceMeters: distanceMeters ?? this.distanceMeters,
    alerts: alerts ?? this.alerts.map((a) => a.copyWith()).toList(),
    coachingAlerts: coachingAlerts ?? this.coachingAlerts.map((c) => c.copyWith()).toList(),
  );

  String get displayDuration {
    if (type == AlertTrigger.time) {
      final m = durationSeconds ~/ 60;
      final s = durationSeconds % 60;
      if (m > 0 && s > 0) return '$m min e $s sec';
      if (m > 0) return '$m minuti';
      return '$s secondi';
    } else {
      if (distanceMeters >= 1000) {
        return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
      }
      return '${distanceMeters.round()} metri';
    }
  }
}

class Preset {
  final String id;
  String name;
  String description;
  List<AlertConfig> alerts;
  List<CoachingAlert> coachingAlerts;

  // Settings for intervals
  bool isIntervalTraining;
  List<IntervalStep> intervals;

  // Voice announcement settings
  bool announceStart;
  bool announceEnd;
  bool announceSummary;
  DateTime createdAt;
  DateTime updatedAt;

  Preset({
    required this.id,
    required this.name,
    this.description = '',
    List<AlertConfig>? alerts,
    List<CoachingAlert>? coachingAlerts,
    this.isIntervalTraining = false,
    List<IntervalStep>? intervals,
    this.announceStart = true,
    this.announceEnd = true,
    this.announceSummary = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : alerts = alerts ?? [],
       coachingAlerts = coachingAlerts ?? [],
       intervals = intervals ?? [],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  int get activeAlertCount => alerts.where((a) => a.enabled).length;
  int get activeCoachingCount => coachingAlerts.where((a) => a.enabled).length;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'alerts': alerts.map((a) => a.toJson()).toList(),
    'coachingAlerts': coachingAlerts.map((a) => a.toJson()).toList(),
    'isIntervalTraining': isIntervalTraining,
    'intervals': intervals.map((i) => i.toJson()).toList(),
    'announceStart': announceStart,
    'announceEnd': announceEnd,
    'announceSummary': announceSummary,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Preset.fromJson(Map<String, dynamic> json) => Preset(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String? ?? '',
    alerts: (json['alerts'] as List<dynamic>?)
        ?.map((a) => AlertConfig.fromJson(a as Map<String, dynamic>))
        .toList(),
    coachingAlerts: (json['coachingAlerts'] as List<dynamic>?)
        ?.map((a) => CoachingAlert.fromJson(a as Map<String, dynamic>))
        .toList(),
    isIntervalTraining: json['isIntervalTraining'] as bool? ?? false,
    intervals: (json['intervals'] as List<dynamic>?)
        ?.map((i) => IntervalStep.fromJson(i as Map<String, dynamic>))
        .toList(),
    announceStart: json['announceStart'] as bool? ?? true,
    announceEnd: json['announceEnd'] as bool? ?? true,
    announceSummary: json['announceSummary'] as bool? ?? true,
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : null,
    updatedAt: json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'] as String)
        : null,
  );

  String toJsonString() => jsonEncode(toJson());

  factory Preset.fromJsonString(String jsonString) =>
      Preset.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);

  Preset copyWith({
    String? id,
    String? name,
    String? description,
    List<AlertConfig>? alerts,
    List<CoachingAlert>? coachingAlerts,
    bool? isIntervalTraining,
    List<IntervalStep>? intervals,
    bool? announceStart,
    bool? announceEnd,
    bool? announceSummary,
  }) => Preset(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    alerts: alerts ?? this.alerts.map((a) => a.copyWith()).toList(),
    coachingAlerts:
        coachingAlerts ?? this.coachingAlerts.map((a) => a.copyWith()).toList(),
    isIntervalTraining: isIntervalTraining ?? this.isIntervalTraining,
    intervals: intervals ?? this.intervals.map((i) => i.copyWith()).toList(),
    announceStart: announceStart ?? this.announceStart,
    announceEnd: announceEnd ?? this.announceEnd,
    announceSummary: announceSummary ?? this.announceSummary,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
  );
}
