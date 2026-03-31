import 'dart:convert';
import 'alert_config.dart';

class Preset {
  final String id;
  String name;
  String description;
  List<AlertConfig> alerts;
  DateTime createdAt;
  DateTime updatedAt;

  Preset({
    required this.id,
    required this.name,
    this.description = '',
    List<AlertConfig>? alerts,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : alerts = alerts ?? [],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  int get activeAlertCount => alerts.where((a) => a.enabled).length;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'alerts': alerts.map((a) => a.toJson()).toList(),
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
  }) => Preset(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    alerts: alerts ?? this.alerts.map((a) => a.copyWith()).toList(),
    createdAt: createdAt,
    updatedAt: DateTime.now(),
  );
}
