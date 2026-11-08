import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_ble_device.dart';
import '../services/bluetooth_service.dart';

class BluetoothProvider extends ChangeNotifier {
  static const String _storageKey = 'saved_ble_devices';

  final HRBluetoothService _service;
  List<ScanResult> _scanResults = [];
  List<SavedBleDevice> _savedDevices = [];
  bool _isScanning = false;
  bool _isConnected = false;
  int _heartRate = 0;
  String? _connectedDeviceName;
  String? _connectedDeviceId;
  String? _connectingDeviceId;

  HRBluetoothService get service => _service;
  List<ScanResult> get scanResults => _scanResults;
  List<SavedBleDevice> get savedDevices => List.unmodifiable(_savedDevices);
  bool get isScanning => _isScanning;
  bool get isConnected => _isConnected;
  int get heartRate => _heartRate;
  String? get connectedDeviceName => _connectedDeviceName;
  String? get connectedDeviceId => _connectedDeviceId;
  String? get connectingDeviceId => _connectingDeviceId;
  bool get isConnecting => _connectingDeviceId != null;

  BluetoothProvider({HRBluetoothService? service})
      : _service = service ?? HRBluetoothService() {
    _initCallbacks();
    _loadSavedDevices();
  }

  void _initCallbacks() {
    _service.onHeartRateUpdate = (hr) {
      _heartRate = hr;
      notifyListeners();
    };

    _service.onConnectionChanged = (connected) {
      _isConnected = connected;
      if (!connected) {
        _connectedDeviceName = null;
        _connectedDeviceId = null;
        _heartRate = 0;
      }
      notifyListeners();
    };

    _service.onScanResults = (results) {
      _scanResults = results;
      notifyListeners();
    };
  }

  Future<void> _loadSavedDevices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        _savedDevices = SavedBleDevice.listFromJson(jsonStr);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _saveDevicesToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        SavedBleDevice.listToJson(_savedDevices),
      );
    } catch (_) {}
  }

  Future<void> _recordDeviceConnected(String id, String name) async {
    final cleanName = name.trim().isNotEmpty ? name.trim() : 'Dispositivo HR';
    final existingIndex = _savedDevices.indexWhere((d) => d.id == id);
    if (existingIndex >= 0) {
      _savedDevices.removeAt(existingIndex);
    }
    _savedDevices.insert(
      0,
      SavedBleDevice(
        id: id,
        name: cleanName,
        lastConnected: DateTime.now(),
      ),
    );
    if (_savedDevices.length > 5) {
      _savedDevices = _savedDevices.sublist(0, 5);
    }
    await _saveDevicesToStorage();
    notifyListeners();
  }

  Future<void> removeSavedDevice(String deviceId) async {
    _savedDevices.removeWhere((d) => d.id == deviceId);
    await _saveDevicesToStorage();
    notifyListeners();
  }

  bool isDeviceDiscovered(String deviceId) {
    return _scanResults.any((r) => r.device.remoteId.str == deviceId);
  }

  bool isDeviceConnecting(String deviceId) => _connectingDeviceId == deviceId;

  Future<bool> isAvailable() async {
    return await _service.isBluetoothAvailable();
  }

  Future<bool> isOn() async {
    return await _service.isBluetoothOn();
  }

  Future<void> startScan() async {
    _isScanning = true;
    _scanResults = [];
    notifyListeners();
    await _service.startScan();
    _isScanning = false;
    notifyListeners();
  }

  Future<void> stopScan() async {
    await _service.stopScan();
    _isScanning = false;
    notifyListeners();
  }

  Future<bool> connectToDevice(ScanResult result) async {
    final devId = result.device.remoteId.str;
    final devName = result.device.platformName.isNotEmpty
        ? result.device.platformName
        : 'Dispositivo HR';

    _connectingDeviceId = devId;
    notifyListeners();

    final success = await _service.connectToDevice(result.device);
    _connectingDeviceId = null;

    if (success) {
      _connectedDeviceName = devName;
      _connectedDeviceId = devId;
      _isConnected = true;
      await _recordDeviceConnected(devId, devName);
    } else {
      notifyListeners();
    }
    return success;
  }

  Future<bool> connectToSavedDevice(SavedBleDevice savedDevice) async {
    _connectingDeviceId = savedDevice.id;
    notifyListeners();

    // If device was found in scan results, connect directly through that reference
    final matchingScan = _scanResults
        .where((r) => r.device.remoteId.str == savedDevice.id)
        .firstOrNull;

    bool success = false;
    if (matchingScan != null) {
      success = await _service.connectToDevice(matchingScan.device);
    } else {
      success = await _service.connectToDeviceId(savedDevice.id);
    }

    _connectingDeviceId = null;

    if (success) {
      _connectedDeviceName = savedDevice.name;
      _connectedDeviceId = savedDevice.id;
      _isConnected = true;
      await _recordDeviceConnected(savedDevice.id, savedDevice.name);
    } else {
      notifyListeners();
    }
    return success;
  }

  Future<void> disconnect() async {
    await _service.disconnect();
    _connectedDeviceName = null;
    _connectedDeviceId = null;
    _isConnected = false;
    _heartRate = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
