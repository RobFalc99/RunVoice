import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:run_voice/models/saved_ble_device.dart';
import 'package:run_voice/providers/bluetooth_provider.dart';
import 'package:run_voice/services/bluetooth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockHRBluetoothServiceForTest implements HRBluetoothService {
  @override
  bool isConnected = false;

  @override
  int currentHeartRate = 0;

  @override
  void Function(int heartRate)? onHeartRateUpdate;

  @override
  void Function(bool connected)? onConnectionChanged;

  @override
  void Function(List<ScanResult> results)? onScanResults;

  String? lastConnectedDeviceId;

  @override
  Future<bool> connectToDeviceId(String deviceId) async {
    lastConnectedDeviceId = deviceId;
    isConnected = true;
    onConnectionChanged?.call(true);
    return true;
  }

  @override
  Future<void> disconnect() async {
    isConnected = false;
    onConnectionChanged?.call(false);
  }

  void dispose() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SavedBleDevice Model', () {
    test('JSON serialization & deserialization', () {
      final now = DateTime(2026, 11, 8, 8, 30);
      final device = SavedBleDevice(
        id: 'AA:BB:CC:DD:EE:FF',
        name: 'Polar H10 123456',
        lastConnected: now,
      );

      final json = device.toJson();
      expect(json['id'], equals('AA:BB:CC:DD:EE:FF'));
      expect(json['name'], equals('Polar H10 123456'));
      expect(json['lastConnected'], equals(now.toIso8601String()));

      final restored = SavedBleDevice.fromJson(json);
      expect(restored.id, equals(device.id));
      expect(restored.name, equals(device.name));
      expect(restored.lastConnected, equals(device.lastConnected));
    });

    test('listToJson and listFromJson helpers', () {
      final list = [
        SavedBleDevice(
          id: '11:22:33:44:55:66',
          name: 'Garmin HRM-Pro',
          lastConnected: DateTime.now(),
        ),
        SavedBleDevice(
          id: 'AA:BB:CC:DD:EE:FF',
          name: 'Polar H10',
          lastConnected: DateTime.now(),
        ),
      ];

      final jsonStr = SavedBleDevice.listToJson(list);
      final restoredList = SavedBleDevice.listFromJson(jsonStr);

      expect(restoredList.length, equals(2));
      expect(restoredList[0].name, equals('Garmin HRM-Pro'));
      expect(restoredList[1].id, equals('AA:BB:CC:DD:EE:FF'));
    });
  });

  group('BluetoothProvider Saved Devices Management', () {
    late MockHRBluetoothServiceForTest mockService;
    late BluetoothProvider provider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'saved_ble_devices': SavedBleDevice.listToJson([
          SavedBleDevice(
            id: 'AA:BB:CC:DD:EE:FF',
            name: 'Polar H10',
            lastConnected: DateTime(2026, 11, 1),
          ),
        ]),
      });

      mockService = MockHRBluetoothServiceForTest();
      provider = BluetoothProvider(service: mockService);
      // Wait microtask for _loadSavedDevices to finish
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });

    tearDown(() {
      provider.dispose();
    });

    test('loads saved devices from SharedPreferences on initialization', () {
      expect(provider.savedDevices.length, equals(1));
      expect(provider.savedDevices.first.id, equals('AA:BB:CC:DD:EE:FF'));
      expect(provider.savedDevices.first.name, equals('Polar H10'));
    });

    test('connectToSavedDevice directly connects and updates state', () async {
      final target = provider.savedDevices.first;
      final ok = await provider.connectToSavedDevice(target);

      expect(ok, isTrue);
      expect(provider.isConnected, isTrue);
      expect(provider.connectedDeviceId, equals('AA:BB:CC:DD:EE:FF'));
      expect(provider.connectedDeviceName, equals('Polar H10'));
      expect(mockService.lastConnectedDeviceId, equals('AA:BB:CC:DD:EE:FF'));
    });

    test('removeSavedDevice removes device from storage and list', () async {
      expect(provider.savedDevices.length, equals(1));
      await provider.removeSavedDevice('AA:BB:CC:DD:EE:FF');

      expect(provider.savedDevices.isEmpty, isTrue);
    });
  });
}
