import '../models/heart_rate_zone.dart';
import 'constants.dart';

class HRZoneCalculator {
  /// Calculate max HR using the Tanaka formula: 208 - (0.7 × age)
  static int calculateMaxHR(int age) {
    return (208 - (0.7 * age)).round();
  }

  /// Calculate max HR using classic formula: 220 - age
  static int calculateMaxHRClassic(int age) {
    return 220 - age;
  }

  /// Generate default HR zones based on max heart rate
  static List<HeartRateZone> generateZones(int maxHR) {
    return List.generate(6, (index) {
      final percentages = HRZoneDefaults.zonePercentages[index];
      return HeartRateZone(
        zoneNumber: index,
        name: HRZoneDefaults.zoneNames[index],
        minBpm: (maxHR * percentages[0]).round(),
        maxBpm: (maxHR * percentages[1]).round(),
        minPercent: (percentages[0] * 100).round(),
        maxPercent: (percentages[1] * 100).round(),
      );
    });
  }

  /// Get the current zone for a given BPM
  static int? getCurrentZone(int bpm, List<HeartRateZone> zones) {
    for (final zone in zones) {
      if (bpm >= zone.minBpm && bpm <= zone.maxBpm) {
        return zone.zoneNumber;
      }
    }
    // Below zone 0
    if (zones.isNotEmpty && bpm < zones.first.minBpm) {
      return 0;
    }
    // Above zone 5
    if (zones.isNotEmpty && bpm > zones.last.maxBpm) {
      return 5;
    }
    return null;
  }
}
