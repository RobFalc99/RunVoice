import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../utils/hr_zone_calculator.dart';

class UserProvider extends ChangeNotifier {
  UserProfile _profile = UserProfile();
  static const String _storageKey = 'user_profile';

  UserProfile get profile => _profile;

  Future<void> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString != null) {
      _profile = UserProfile.fromJsonString(jsonString);
    }
    // Initialize zones if empty
    if (_profile.hrZones.isEmpty) {
      _profile.hrZones = HRZoneCalculator.generateZones(_profile.maxHeartRate);
    }
    notifyListeners();
  }

  Future<void> saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, _profile.toJsonString());
    notifyListeners();
  }

  void updateName(String firstName, String lastName) {
    _profile.firstName = firstName;
    _profile.lastName = lastName;
    saveProfile();
  }

  void updateAge(int age) {
    _profile.age = age;
    saveProfile();
  }

  void updateMaxHeartRate(int maxHR) {
    _profile.maxHeartRate = maxHR;
    saveProfile();
  }

  void updateAvatarIcon(String icon) {
    _profile.avatarIcon = icon;
    saveProfile();
  }

  void updateSelectedVoice(String voice) {
    _profile.selectedVoice = voice;
    saveProfile();
  }

  void updateConnectedSensor(String? id, String? name) {
    _profile.connectedSensorId = id;
    _profile.connectedSensorName = name;
    saveProfile();
  }

  /// Recalculate zones from max HR
  void recalculateZones() {
    _profile.hrZones = HRZoneCalculator.generateZones(_profile.maxHeartRate);
    saveProfile();
  }

  /// Calculate max HR from age and recalculate zones
  void calculateFromAge({bool useTanaka = true}) {
    if (useTanaka) {
      _profile.maxHeartRate = HRZoneCalculator.calculateMaxHR(_profile.age);
    } else {
      _profile.maxHeartRate = HRZoneCalculator.calculateMaxHRClassic(
        _profile.age,
      );
    }
    recalculateZones();
  }

  /// Update a specific zone
  void updateZone(int zoneNumber, {int? minBpm, int? maxBpm}) {
    final zoneIndex = _profile.hrZones.indexWhere(
      (z) => z.zoneNumber == zoneNumber,
    );
    if (zoneIndex != -1) {
      if (minBpm != null) _profile.hrZones[zoneIndex].minBpm = minBpm;
      if (maxBpm != null) _profile.hrZones[zoneIndex].maxBpm = maxBpm;
      saveProfile();
    }
  }
}
