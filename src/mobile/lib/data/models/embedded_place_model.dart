class EmbeddedPlace {
  const EmbeddedPlace({
    required this.key,
    required this.name,
    required this.category,
    required this.assetPath,
    this.address,
    this.latitude,
    this.longitude,
  });

  final String key;
  final String name;
  final String category;
  final String assetPath;
  final String? address;
  final double? latitude;
  final double? longitude;

  bool get hasCoordinates => latitude != null && longitude != null;
}
