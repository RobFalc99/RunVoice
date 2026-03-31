import 'dart:convert';
import 'heart_rate_zone.dart';

class UserProfile {
  String firstName;
  String lastName;
  int age;
  int maxHeartRate;
  String avatarIcon;
  List<HeartRateZone> hrZones;
  String selectedVoice;
  String? connectedSensorId;
  String? connectedSensorName;
  // Voice settings
  double speechRate; // 1.0, 1.25, 1.5, 1.75, 2.0
  bool speakUnits; // Whether to speak unit names

  UserProfile({
    this.firstName = '',
    this.lastName = '',
    this.age = 0,
    this.maxHeartRate = 0,
    this.avatarIcon = 'directions_run',
    List<HeartRateZone>? hrZones,
    this.selectedVoice = '',
    this.connectedSensorId,
    this.connectedSensorName,
    this.speechRate = 1.0,
    this.speakUnits = true,
  }) : hrZones = hrZones ?? [];

  String get displayName {
    if (firstName.isEmpty && lastName.isEmpty) return 'Runner';
    return '$firstName $lastName'.trim();
  }

  String toJsonString() => jsonEncode(toJson());

  Map<String, dynamic> toJson() => {
    'firstName': firstName,
    'lastName': lastName,
    'age': age,
    'maxHeartRate': maxHeartRate,
    'avatarIcon': avatarIcon,
    'hrZones': hrZones.map((z) => z.toJson()).toList(),
    'selectedVoice': selectedVoice,
    'connectedSensorId': connectedSensorId,
    'connectedSensorName': connectedSensorName,
    'speechRate': speechRate,
    'speakUnits': speakUnits,
  };

  factory UserProfile.fromJsonString(String jsonString) =>
      UserProfile.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    firstName: json['firstName'] as String? ?? '',
    lastName: json['lastName'] as String? ?? '',
    age: json['age'] as int? ?? 0,
    maxHeartRate: json['maxHeartRate'] as int? ?? 0,
    avatarIcon: json['avatarIcon'] as String? ?? 'directions_run',
    hrZones: (json['hrZones'] as List<dynamic>?)
        ?.map((z) => HeartRateZone.fromJson(z as Map<String, dynamic>))
        .toList(),
    selectedVoice: json['selectedVoice'] as String? ?? '',
    connectedSensorId: json['connectedSensorId'] as String?,
    connectedSensorName: json['connectedSensorName'] as String?,
    speechRate: (json['speechRate'] as num?)?.toDouble() ?? 1.0,
    speakUnits: json['speakUnits'] as bool? ?? true,
  );
}
