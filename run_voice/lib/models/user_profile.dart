import 'dart:convert';
import 'heart_rate_zone.dart';

class UserProfile {
  String firstName;
  String lastName;
  int age;
  int maxHeartRate;
  String avatarIcon; // Material icon name
  List<HeartRateZone> hrZones;
  String selectedVoice;
  String? connectedSensorId;
  String? connectedSensorName;

  UserProfile({
    this.firstName = '',
    this.lastName = '',
    this.age = 30,
    this.maxHeartRate = 190,
    this.avatarIcon = 'directions_run',
    List<HeartRateZone>? hrZones,
    this.selectedVoice = '',
    this.connectedSensorId,
    this.connectedSensorName,
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
  };

  factory UserProfile.fromJsonString(String jsonString) =>
      UserProfile.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    firstName: json['firstName'] as String? ?? '',
    lastName: json['lastName'] as String? ?? '',
    age: json['age'] as int? ?? 30,
    maxHeartRate: json['maxHeartRate'] as int? ?? 190,
    avatarIcon: json['avatarIcon'] as String? ?? 'directions_run',
    hrZones: (json['hrZones'] as List<dynamic>?)
        ?.map((z) => HeartRateZone.fromJson(z as Map<String, dynamic>))
        .toList(),
    selectedVoice: json['selectedVoice'] as String? ?? '',
    connectedSensorId: json['connectedSensorId'] as String?,
    connectedSensorName: json['connectedSensorName'] as String?,
  );
}
