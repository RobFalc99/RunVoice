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
  String geminiModel;
  // Voice settings
  double speechRate;
  bool speakUnits; // Whether to speak unit names
  bool speakName; // Whether to announce the name
  String geminiApiKey;

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
    this.geminiModel = 'gemini-3.5-flash-lite',
    this.speechRate = 1.0,
    this.speakUnits = true,
    this.speakName = true,
    this.geminiApiKey = '',
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
    'geminiModel': geminiModel,
    'speechRate': speechRate,
    'speakUnits': speakUnits,
    'speakName': speakName,
    'geminiApiKey': geminiApiKey,
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
    geminiModel: json['geminiModel'] as String? ?? 'gemini-3.5-flash-lite',
    speechRate: (json['speechRate'] as num?)?.toDouble() ?? 1.0,
    speakUnits: json['speakUnits'] as bool? ?? true,
    speakName: json['speakName'] as bool? ?? true,
    geminiApiKey: json['geminiApiKey'] as String? ?? '',
  );

  String get geminiModelLabel {
    if (geminiModel == 'gemini-3.5-flash-lite') return 'Gemini 3.5 Flash-Lite';
    if (geminiModel == 'gemini-3.8-flash') return 'Gemini 3.8 Flash';
    if (geminiModel == 'gemini-3.5-flash') return 'Gemini 3.5 Flash';
    if (geminiModel == 'gemini-flash-latest') return 'Gemini Flash Latest';
    if (geminiModel == 'gemini-flash-lite-latest') return 'Gemini Flash-Lite Latest';
    if (geminiModel == 'gemini-2.5-flash') return 'Gemini 2.5 Flash';
    return geminiModel;
  }
}
