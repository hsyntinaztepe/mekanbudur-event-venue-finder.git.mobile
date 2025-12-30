class TurkiyeDistrict {
  final String name;
  final double? latitude;
  final double? longitude;

  const TurkiyeDistrict({
    required this.name,
    this.latitude,
    this.longitude,
  });

  factory TurkiyeDistrict.fromJson(Map<String, dynamic> json) {
    final rawName = json['name'];
    final name = rawName is String ? rawName.trim() : '';
    final coords = _extractCoordinates(json);
    return TurkiyeDistrict(
      name: name,
      latitude: _toDouble(
        coords?['latitude'] ??
            coords?['lat'] ??
            json['latitude'] ??
            json['lat'],
      ),
      longitude: _toDouble(
        coords?['longitude'] ??
            coords?['lng'] ??
            coords?['lon'] ??
            json['longitude'] ??
            json['lng'] ??
            json['lon'],
      ),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static Map<String, dynamic>? _extractCoordinates(Map<String, dynamic> json) {
    final raw = json['coordinates'] ?? json['coordinate'];
    if (raw is Map<String, dynamic>) return raw;
    return null;
  }
}

class TurkiyeProvince {
  final int? id;
  final String name;
  final double? latitude;
  final double? longitude;
  final List<TurkiyeDistrict> districts;

  const TurkiyeProvince({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.districts,
  });

  factory TurkiyeProvince.fromJson(Map<String, dynamic> json) {
    final rawName = json['name'];
    final name = rawName is String ? rawName.trim() : '';
    final districtsJson = json['districts'];
    final districts = districtsJson is List
        ? districtsJson
            .whereType<Map<String, dynamic>>()
            .map(TurkiyeDistrict.fromJson)
            .where((d) => d.name.isNotEmpty)
            .toList()
        : <TurkiyeDistrict>[];
    districts.sort((a, b) => a.name.compareTo(b.name));
    final coords = TurkiyeDistrict._extractCoordinates(json);

    return TurkiyeProvince(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}'),
      name: name,
      latitude: TurkiyeDistrict._toDouble(
        coords?['latitude'] ??
            coords?['lat'] ??
            json['latitude'] ??
            json['lat'],
      ),
      longitude: TurkiyeDistrict._toDouble(
        coords?['longitude'] ??
            coords?['lng'] ??
            coords?['lon'] ??
            json['longitude'] ??
            json['lng'] ??
            json['lon'],
      ),
      districts: districts,
    );
  }
}
