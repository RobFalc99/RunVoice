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
    // Load Gemini API key from environment if not already set
    if (_profile.geminiApiKey.isEmpty) {
      const compileKey = String.fromEnvironment('GEMINI_API_KEY');
      if (compileKey.isNotEmpty) {
        _profile.geminiApiKey = compileKey;
      }
    }
    if (_profile.geminiModel.isEmpty || _profile.geminiModel == 'gemini-2.5-flash') {
      _profile.geminiModel = 'gemini-3.5-flash-lite';
    }
    // Initialize zones if empty
    // Initialize zones if empty and maxHR is set
    if (_profile.hrZones.isEmpty && _profile.maxHeartRate > 0) {
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

  void updateSpeechRate(double rate) {
    _profile.speechRate = rate;
    saveProfile();
  }

  void updateSpeakUnits(bool value) {
    _profile.speakUnits = value;
    saveProfile();
  }

  void updateSpeakName(bool value) {
    _profile.speakName = value;
    saveProfile();
  }

  void updateGeminiApiKey(String key) {
    _profile.geminiApiKey = key.trim();
    saveProfile();
  }

  void updateGeminiModel(String model) {
    _profile.geminiModel = model;
    saveProfile();
  }

  /// Recalculate zones from max HR
  void recalculateZones() {
    if (_profile.maxHeartRate > 0) {
      _profile.hrZones = HRZoneCalculator.generateZones(_profile.maxHeartRate);
    }
    saveProfile();
  }

  /// Calculate max HR from age and recalculate zones
  void calculateFromAge({bool useTanaka = true}) {
    if (_profile.age <= 0) return;
    if (useTanaka) {
      _profile.maxHeartRate = HRZoneCalculator.calculateMaxHR(_profile.age);
    } else {
      _profile.maxHeartRate = HRZoneCalculator.calculateMaxHRClassic(
        _profile.age,
      );
    }
    recalculateZones();
  }

  /// Update a specific zone with cascading boundaries
  void updateZone(int zoneNumber, {int? minBpm, int? maxBpm}) {
    final zones = _profile.hrZones;
    final zoneIndex = zones.indexWhere((z) => z.zoneNumber == zoneNumber);
    if (zoneIndex == -1) return;

    if (maxBpm != null) {
      zones[zoneIndex].maxBpm = maxBpm;
      // Cascade: set next zone's minBpm = maxBpm + 1
      if (zoneIndex + 1 < zones.length) {
        zones[zoneIndex + 1].minBpm = maxBpm + 1;
      }
    }
    if (minBpm != null) {
      zones[zoneIndex].minBpm = minBpm;
      // Cascade: set previous zone's maxBpm = minBpm - 1
      if (zoneIndex - 1 >= 0) {
        zones[zoneIndex - 1].maxBpm = minBpm - 1;
      }
    }
    saveProfile();
  }
}
