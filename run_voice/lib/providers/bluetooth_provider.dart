import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/bluetooth_service.dart';

class BluetoothProvider extends ChangeNotifier {
  final HRBluetoothService _service = HRBluetoothService();
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  bool _isConnected = false;
  int _heartRate = 0;
  String? _connectedDeviceName;
  String? _connectedDeviceId;

  HRBluetoothService get service => _service;
  List<ScanResult> get scanResults => _scanResults;
  bool get isScanning => _isScanning;
  bool get isConnected => _isConnected;
  int get heartRate => _heartRate;
  String? get connectedDeviceName => _connectedDeviceName;
  String? get connectedDeviceId => _connectedDeviceId;

  BluetoothProvider() {
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
    final success = await _service.connectToDevice(result.device);
    if (success) {
      _connectedDeviceName = result.device.platformName.isNotEmpty
          ? result.device.platformName
          : 'Unknown Device';
      _connectedDeviceId = result.device.remoteId.str;
      _isConnected = true;
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
