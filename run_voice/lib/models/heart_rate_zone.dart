class HeartRateZone {
  final int zoneNumber;
  final String name;
  int minBpm;
  int maxBpm;
  int minPercent;
  int maxPercent;

  HeartRateZone({
    required this.zoneNumber,
    required this.name,
    required this.minBpm,
    required this.maxBpm,
    required this.minPercent,
    required this.maxPercent,
  });

  Map<String, dynamic> toJson() => {
    'zoneNumber': zoneNumber,
    'name': name,
    'minBpm': minBpm,
    'maxBpm': maxBpm,
    'minPercent': minPercent,
    'maxPercent': maxPercent,
  };

  factory HeartRateZone.fromJson(Map<String, dynamic> json) => HeartRateZone(
    zoneNumber: json['zoneNumber'] as int,
    name: json['name'] as String,
    minBpm: json['minBpm'] as int,
    maxBpm: json['maxBpm'] as int,
    minPercent: json['minPercent'] as int,
    maxPercent: json['maxPercent'] as int,
  );

  HeartRateZone copyWith({
    int? zoneNumber,
    String? name,
    int? minBpm,
    int? maxBpm,
    int? minPercent,
    int? maxPercent,
  }) => HeartRateZone(
    zoneNumber: zoneNumber ?? this.zoneNumber,
    name: name ?? this.name,
    minBpm: minBpm ?? this.minBpm,
    maxBpm: maxBpm ?? this.maxBpm,
    minPercent: minPercent ?? this.minPercent,
    maxPercent: maxPercent ?? this.maxPercent,
  );
}
