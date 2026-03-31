import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Service to connect to Bluetooth Heart Rate sensors
class HRBluetoothService {
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<List<int>>? _hrSubscription;

  BluetoothDevice? _connectedDevice;
  bool _isScanning = false;
  int _currentHeartRate = 0;
  bool _isConnected = false;

  // Heart Rate Service UUID
  static final Guid _hrServiceUuid = Guid(
    '0000180d-0000-1000-8000-00805f9b34fb',
  );
  // Heart Rate Measurement Characteristic UUID
  static final Guid _hrMeasurementUuid = Guid(
    '00002a37-0000-1000-8000-00805f9b34fb',
  );

  BluetoothDevice? get connectedDevice => _connectedDevice;
  bool get isScanning => _isScanning;
  int get currentHeartRate => _currentHeartRate;
  bool get isConnected => _isConnected;

  // Callbacks
  void Function(int heartRate)? onHeartRateUpdate;
  void Function(bool connected)? onConnectionChanged;
  void Function(List<ScanResult> results)? onScanResults;

  Future<bool> isBluetoothAvailable() async {
    try {
      return await FlutterBluePlus.isSupported;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isBluetoothOn() async {
    try {
      final state = await FlutterBluePlus.adapterState.first;
      return state == BluetoothAdapterState.on;
    } catch (_) {
      return false;
    }
  }

  /// Start scanning for HR sensors
  Future<void> startScan({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (_isScanning) return;

    _isScanning = true;

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      // Filter to only show HR sensors (or all BLE devices)
      onScanResults?.call(results);
    });

    await FlutterBluePlus.startScan(
      withServices: [_hrServiceUuid],
      timeout: timeout,
    );

    // When scan completes
    await FlutterBluePlus.isScanning.firstWhere((scanning) => !scanning);
    _isScanning = false;
  }

  /// Stop scanning
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    _isScanning = false;
    await _scanSubscription?.cancel();
  }

  /// Connect to a specific device
  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect(
        license: License.free,
        timeout: const Duration(seconds: 10),
      );
      _connectedDevice = device;
      _isConnected = true;
      onConnectionChanged?.call(true);

      // Listen for disconnection
      _connectionSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _isConnected = false;
          _currentHeartRate = 0;
          onConnectionChanged?.call(false);
          _hrSubscription?.cancel();
        }
      });

      // Discover services and start listening to HR
      await _startHeartRateMonitoring(device);
      return true;
    } catch (e) {
      _isConnected = false;
      onConnectionChanged?.call(false);
      return false;
    }
  }

  /// Start monitoring HR from connected device
  Future<void> _startHeartRateMonitoring(BluetoothDevice device) async {
    final services = await device.discoverServices();
    for (final service in services) {
      if (service.uuid == _hrServiceUuid) {
        for (final char in service.characteristics) {
          if (char.uuid == _hrMeasurementUuid) {
            await char.setNotifyValue(true);
            _hrSubscription = char.onValueReceived.listen((value) {
              if (value.isNotEmpty) {
                _currentHeartRate = _parseHeartRate(value);
                onHeartRateUpdate?.call(_currentHeartRate);
              }
            });
            break;
          }
        }
        break;
      }
    }
  }

  /// Parse heart rate from BLE characteristic value
  int _parseHeartRate(List<int> value) {
    if (value.isEmpty) return 0;

    // Bit 0 of first byte: 0 = uint8 HR, 1 = uint16 HR
    final flags = value[0];
    final is16Bit = (flags & 0x01) == 1;

    if (is16Bit && value.length >= 3) {
      return value[1] | (value[2] << 8);
    } else if (value.length >= 2) {
      return value[1];
    }
    return 0;
  }

  /// Disconnect from current device
  Future<void> disconnect() async {
    await _hrSubscription?.cancel();
    await _connectionSubscription?.cancel();
    await _connectedDevice?.disconnect();
    _connectedDevice = null;
    _isConnected = false;
    _currentHeartRate = 0;
    onConnectionChanged?.call(false);
  }

  void dispose() {
    stopScan();
    disconnect();
  }
}
