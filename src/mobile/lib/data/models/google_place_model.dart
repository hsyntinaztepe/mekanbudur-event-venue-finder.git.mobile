class GooglePlaceModel {
  GooglePlaceModel({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final String address;
  final double latitude;
  final double longitude;

  factory GooglePlaceModel.fromJson(Map<String, dynamic> json) {
    return GooglePlaceModel(
      name: json['name']?.toString().trim() ?? 'Bilinmeyen Mekan',
      address: json['address']?.toString().trim() ?? 'Adres paylaşılmadı',
      latitude: (json['lat'] as num).toDouble(),
      longitude: (json['lng'] as num).toDouble(),
    );
  }
}
