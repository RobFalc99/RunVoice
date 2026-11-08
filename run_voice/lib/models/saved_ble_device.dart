import 'dart:convert';

/// Represents a previously connected BLE Heart Rate sensor device
class SavedBleDevice {
  final String id; // MAC address on Android or UUID on iOS
  final String name;
  final DateTime lastConnected;

  const SavedBleDevice({
    required this.id,
    required this.name,
    required this.lastConnected,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'lastConnected': lastConnected.toIso8601String(),
  };

  factory SavedBleDevice.fromJson(Map<String, dynamic> json) => SavedBleDevice(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? 'Dispositivo HR',
    lastConnected:
        DateTime.tryParse(json['lastConnected'] as String? ?? '') ??
        DateTime.now(),
  );

  static List<SavedBleDevice> listFromJson(String jsonStr) {
    if (jsonStr.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(jsonStr) as List<dynamic>;
      return list
          .map((e) => SavedBleDevice.fromJson(e as Map<String, dynamic>))
          .where((d) => d.id.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static String listToJson(List<SavedBleDevice> devices) {
    return jsonEncode(devices.map((d) => d.toJson()).toList());
  }

  SavedBleDevice copyWith({
    String? id,
    String? name,
    DateTime? lastConnected,
  }) => SavedBleDevice(
    id: id ?? this.id,
    name: name ?? this.name,
    lastConnected: lastConnected ?? this.lastConnected,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedBleDevice &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
