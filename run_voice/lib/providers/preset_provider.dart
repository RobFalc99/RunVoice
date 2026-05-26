import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/preset.dart';
import '../models/alert_config.dart';

class PresetProvider extends ChangeNotifier {
  List<Preset> _presets = [];
  String? _selectedPresetId;
  static const String _storageKey = 'presets';
  static const String _selectedKey = 'selected_preset_id';
  final _uuid = const Uuid();

  List<Preset> get presets => _presets;
  Preset? get selectedPreset =>
      _presets.where((p) => p.id == _selectedPresetId).firstOrNull;
  String? get selectedPresetId => _selectedPresetId;

  Future<void> loadPresets() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString != null) {
      final list = jsonDecode(jsonString) as List<dynamic>;
      _presets = list
          .map((e) => Preset.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    _selectedPresetId = prefs.getString(_selectedKey);

    // Create a default preset if none exist
    if (_presets.isEmpty) {
      await _createDefaultPreset();
    }
    notifyListeners();
  }

  Future<void> _createDefaultPreset() async {
    final preset = Preset(
      id: _uuid.v4(),
      name: 'Corsa Base',
      description: 'Preset base con avvisi tempo, distanza e battito',
      alerts: [
        AlertConfig(
          id: _uuid.v4(),
          name: 'Battito Cardiaco',
          metric: AlertMetric.bpm,
          mode: AlertMode.current,
          intervalSeconds: 120,
        ),
        AlertConfig(
          id: _uuid.v4(),
          name: 'Distanza',
          metric: AlertMetric.distance,
          mode: AlertMode.total,
          intervalSeconds: 300,
        ),
        AlertConfig(
          id: _uuid.v4(),
          name: 'Passo',
          metric: AlertMetric.pace,
          mode: AlertMode.current,
          intervalSeconds: 180,
        ),
      ],
      coachingAlerts: [
        CoachingAlert(
          id: _uuid.v4(),
          name: 'Zona 2 (Fondo)',
          metric: AlertMetric.hrZone,
          minValue: 2,
          maxValue: 2.9,
          okIntervalSeconds: 300,
          outOfRangeDelaySeconds: 15,
          enabled: false,
        ),
      ],
    );
    _presets.add(preset);
    _selectedPresetId = preset.id;
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(_presets.map((p) => p.toJson()).toList());
    await prefs.setString(_storageKey, jsonString);
    if (_selectedPresetId != null) {
      await prefs.setString(_selectedKey, _selectedPresetId!);
    }
  }

  void selectPreset(String id) {
    _selectedPresetId = id;
    _save();
    notifyListeners();
  }

  Future<Preset> createPreset({
    required String name,
    String description = '',
  }) async {
    final preset = Preset(id: _uuid.v4(), name: name, description: description);
    _presets.add(preset);
    await _save();
    notifyListeners();
    return preset;
  }

  Future<void> updatePreset(Preset preset) async {
    final index = _presets.indexWhere((p) => p.id == preset.id);
    if (index != -1) {
      _presets[index] = preset;
      await _save();
      notifyListeners();
    }
  }

  Future<void> deletePreset(String id) async {
    _presets.removeWhere((p) => p.id == id);
    if (_selectedPresetId == id) {
      _selectedPresetId = _presets.isNotEmpty ? _presets.first.id : null;
    }
    await _save();
    notifyListeners();
  }

  Future<Preset> duplicatePreset(String id) async {
    final original = _presets.firstWhere((p) => p.id == id);
    final copy = original.copyWith(
      id: _uuid.v4(),
      name: '${original.name} (Copia)',
    );
    _presets.add(copy);
    await _save();
    notifyListeners();
    return copy;
  }

  /// Add an alert to a preset
  Future<void> addAlertToPreset(String presetId, AlertConfig alert) async {
    final index = _presets.indexWhere((p) => p.id == presetId);
    if (index != -1) {
      _presets[index].alerts.add(alert);
      _presets[index].updatedAt = DateTime.now();
      await _save();
      notifyListeners();
    }
  }

  /// Remove an alert from a preset
  Future<void> removeAlertFromPreset(String presetId, String alertId) async {
    final index = _presets.indexWhere((p) => p.id == presetId);
    if (index != -1) {
      _presets[index].alerts.removeWhere((a) => a.id == alertId);
      _presets[index].updatedAt = DateTime.now();
      await _save();
      notifyListeners();
    }
  }

  /// Update an alert within a preset
  Future<void> updateAlertInPreset(String presetId, AlertConfig alert) async {
    final index = _presets.indexWhere((p) => p.id == presetId);
    if (index != -1) {
      final alertIndex = _presets[index].alerts.indexWhere(
        (a) => a.id == alert.id,
      );
      if (alertIndex != -1) {
        _presets[index].alerts[alertIndex] = alert;
        _presets[index].updatedAt = DateTime.now();
        await _save();
        notifyListeners();
      }
    }
  }

  /// Add a coaching alert to a preset
  Future<void> addCoachingAlertToPreset(
    String presetId,
    CoachingAlert alert,
  ) async {
    final index = _presets.indexWhere((p) => p.id == presetId);
    if (index != -1) {
      _presets[index].coachingAlerts.add(alert);
      _presets[index].updatedAt = DateTime.now();
      await _save();
      notifyListeners();
    }
  }

  /// Remove a coaching alert from a preset
  Future<void> removeCoachingAlertFromPreset(
    String presetId,
    String alertId,
  ) async {
    final index = _presets.indexWhere((p) => p.id == presetId);
    if (index != -1) {
      _presets[index].coachingAlerts.removeWhere((a) => a.id == alertId);
      _presets[index].updatedAt = DateTime.now();
      await _save();
      notifyListeners();
    }
  }

  /// Update a coaching alert within a preset
  Future<void> updateCoachingAlertInPreset(
    String presetId,
    CoachingAlert alert,
  ) async {
    final index = _presets.indexWhere((p) => p.id == presetId);
    if (index != -1) {
      final alertIndex = _presets[index].coachingAlerts.indexWhere(
        (a) => a.id == alert.id,
      );
      if (alertIndex != -1) {
        _presets[index].coachingAlerts[alertIndex] = alert;
        _presets[index].updatedAt = DateTime.now();
        await _save();
        notifyListeners();
      }
    }
  }

  // INTERVALS
  Future<void> addIntervalToPreset(String presetId, IntervalStep step) async {
    final index = _presets.indexWhere((p) => p.id == presetId);
    if (index != -1) {
      _presets[index].intervals.add(step);
      _presets[index].updatedAt = DateTime.now();
      await _save();
      notifyListeners();
    }
  }

  Future<void> removeIntervalFromPreset(String presetId, String stepId) async {
    final index = _presets.indexWhere((p) => p.id == presetId);
    if (index != -1) {
      _presets[index].intervals.removeWhere((s) => s.id == stepId);
      _presets[index].updatedAt = DateTime.now();
      await _save();
      notifyListeners();
    }
  }

  Future<void> updateIntervalInPreset(
    String presetId,
    IntervalStep step,
  ) async {
    final index = _presets.indexWhere((p) => p.id == presetId);
    if (index != -1) {
      final stepIndex = _presets[index].intervals.indexWhere(
        (s) => s.id == step.id,
      );
      if (stepIndex != -1) {
        _presets[index].intervals[stepIndex] = step;
        _presets[index].updatedAt = DateTime.now();
        await _save();
        notifyListeners();
      }
    }
  }

  Future<void> duplicateIntervalInPreset(
    String presetId,
    IntervalStep step,
  ) async {
    final index = _presets.indexWhere((p) => p.id == presetId);
    if (index != -1) {
      final copy = step.copyWith(id: _uuid.v4());
      _presets[index].intervals.add(copy);
      _presets[index].updatedAt = DateTime.now();
      await _save();
      notifyListeners();
    }
  }
}
