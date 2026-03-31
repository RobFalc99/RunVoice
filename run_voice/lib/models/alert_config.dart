import 'dart:convert';

enum AlertType { heartRateZone, distance, pace, time }

extension AlertTypeExtension on AlertType {
  String get displayName {
    switch (this) {
      case AlertType.heartRateZone:
        return 'Heart Rate Zone';
      case AlertType.distance:
        return 'Distance';
      case AlertType.pace:
        return 'Pace';
      case AlertType.time:
        return 'Time';
    }
  }

  String get icon {
    switch (this) {
      case AlertType.heartRateZone:
        return 'favorite';
      case AlertType.distance:
        return 'straighten';
      case AlertType.pace:
        return 'speed';
      case AlertType.time:
        return 'timer';
    }
  }

  String get description {
    switch (this) {
      case AlertType.heartRateZone:
        return 'Announce current heart rate and zone';
      case AlertType.distance:
        return 'Announce total distance covered';
      case AlertType.pace:
        return 'Announce current pace (min/km)';
      case AlertType.time:
        return 'Announce elapsed time';
    }
  }
}

class AlertConfig {
  final String id;
  String name;
  AlertType type;
  int intervalSeconds; // How often the alert fires
  bool enabled;
  String? customMessage; // Custom TTS message template

  AlertConfig({
    required this.id,
    required this.name,
    required this.type,
    this.intervalSeconds = 60,
    this.enabled = true,
    this.customMessage,
  });

  /// Build the TTS message based on current workout data
  String buildMessage({
    int? heartRate,
    int? heartRateZone,
    double? distanceKm,
    double? paceMinPerKm,
    Duration? elapsedTime,
  }) {
    switch (type) {
      case AlertType.heartRateZone:
        if (heartRate == null) return 'Heart rate sensor not available';
        final zoneText = heartRateZone != null ? ', zone $heartRateZone' : '';
        return 'Heart rate: $heartRate BPM$zoneText';
      case AlertType.distance:
        if (distanceKm == null) return 'Distance not available';
        return 'Distance: ${distanceKm.toStringAsFixed(2)} kilometers';
      case AlertType.pace:
        if (paceMinPerKm == null ||
            paceMinPerKm.isInfinite ||
            paceMinPerKm.isNaN) {
          return 'Pace not available';
        }
        final minutes = paceMinPerKm.floor();
        final seconds = ((paceMinPerKm - minutes) * 60).round();
        return 'Pace: $minutes minutes ${seconds.toString().padLeft(2, '0')} seconds per kilometer';
      case AlertType.time:
        if (elapsedTime == null) return 'Time not available';
        final hours = elapsedTime.inHours;
        final mins = elapsedTime.inMinutes.remainder(60);
        final secs = elapsedTime.inSeconds.remainder(60);
        if (hours > 0) {
          return 'Time: $hours hours $mins minutes $secs seconds';
        }
        return 'Time: $mins minutes $secs seconds';
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.index,
    'intervalSeconds': intervalSeconds,
    'enabled': enabled,
    'customMessage': customMessage,
  };

  factory AlertConfig.fromJson(Map<String, dynamic> json) => AlertConfig(
    id: json['id'] as String,
    name: json['name'] as String,
    type: AlertType.values[json['type'] as int],
    intervalSeconds: json['intervalSeconds'] as int? ?? 60,
    enabled: json['enabled'] as bool? ?? true,
    customMessage: json['customMessage'] as String?,
  );

  String toJsonString() => jsonEncode(toJson());

  AlertConfig copyWith({
    String? id,
    String? name,
    AlertType? type,
    int? intervalSeconds,
    bool? enabled,
    String? customMessage,
  }) => AlertConfig(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    intervalSeconds: intervalSeconds ?? this.intervalSeconds,
    enabled: enabled ?? this.enabled,
    customMessage: customMessage ?? this.customMessage,
  );
}
