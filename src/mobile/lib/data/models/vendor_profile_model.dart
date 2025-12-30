class VendorProfile {
  final String id;
  final String companyName;
  final String? description;
  final String? venueType;
  final int? capacity;
  final String? amenities;
  final String? priceRange;
  final String? phoneNumber;
  final String? website;
  final String? socialMediaLinks;
  final String? workingHours;
  final String? photoUrls;
  final String? serviceCategoriesCsv;
  final double? venueLatitude;
  final double? venueLongitude;
  final String? venueAddressLabel;

  VendorProfile({
    required this.id,
    required this.companyName,
    this.description,
    this.venueType,
    this.capacity,
    this.amenities,
    this.priceRange,
    this.phoneNumber,
    this.website,
    this.socialMediaLinks,
    this.workingHours,
    this.photoUrls,
    this.serviceCategoriesCsv,
    this.venueLatitude,
    this.venueLongitude,
    this.venueAddressLabel,
  });

  bool get hasLocation => venueLatitude != null && venueLongitude != null;

  List<String> get photoUrlList => _splitCsv(photoUrls);
  List<String> get serviceCategoryNames => _splitCsv(serviceCategoriesCsv);

  static List<String> _splitCsv(String? csv) {
    if (csv == null) return const <String>[];
    final trimmed = csv.trim();
    if (trimmed.isEmpty) return const <String>[];
    return trimmed
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }

  factory VendorProfile.fromJson(Map<String, dynamic> json) {
    return VendorProfile(
      id: json['id'],
      companyName: json['companyName'],
      description: json['description'],
      venueType: json['venueType'],
      capacity: json['capacity'],
      amenities: json['amenities'],
      priceRange: json['priceRange'],
      phoneNumber: json['phoneNumber'],
      website: json['website'],
      socialMediaLinks: json['socialMediaLinks'],
      workingHours: json['workingHours'],
      photoUrls: json['photoUrls'],
      serviceCategoriesCsv: json['serviceCategoriesCsv'],
      venueLatitude: (json['venueLatitude'] as num?)?.toDouble(),
      venueLongitude: (json['venueLongitude'] as num?)?.toDouble(),
      venueAddressLabel: json['venueAddressLabel'],
    );
  }
}
