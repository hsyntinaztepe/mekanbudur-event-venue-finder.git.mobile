class PlaceModel {
  final String id;
  final String refType;
  final String refId;
  final double latitude;
  final double longitude;
  final double? radius;
  final String? addressLabel;

  PlaceModel({
    required this.id,
    required this.refType,
    required this.refId,
    required this.latitude,
    required this.longitude,
    this.radius,
    this.addressLabel,
  });

  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    return PlaceModel(
      id: json['id'].toString(),
      refType: json['refType']?.toString() ?? 'Listing',
      refId: json['refId']?.toString() ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radius: (json['radius'] as num?)?.toDouble(),
      addressLabel: json['addressLabel']?.toString(),
    );
  }
}
