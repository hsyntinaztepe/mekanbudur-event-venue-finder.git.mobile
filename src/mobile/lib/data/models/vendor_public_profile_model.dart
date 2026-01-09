class VendorPublicProfile {
  final String vendorUserId;
  final String profileId;
  final String companyName;
  final String displayName;
  final List<String> serviceCategories;
  final String? suitableForCsv;
  final bool isVerified;
  final String? description;
  final String? venueType;
  final int? capacity;
  final String? priceRange;
  final String? phoneNumber;
  final String? website;
  final String? photoUrls;
  final double? averageRating;
  final int ratingCount;
  final double? latitude;
  final double? longitude;
  final String? addressLabel;

  VendorPublicProfile({
    required this.vendorUserId,
    required this.profileId,
    required this.companyName,
    required this.displayName,
    required this.serviceCategories,
    required this.suitableForCsv,
    required this.isVerified,
    required this.description,
    required this.venueType,
    required this.capacity,
    required this.priceRange,
    required this.phoneNumber,
    required this.website,
    required this.photoUrls,
    required this.averageRating,
    required this.ratingCount,
    required this.latitude,
    required this.longitude,
    required this.addressLabel,
  });

  List<String> get photoUrlList => _splitCsv(photoUrls);

  static List<String> _splitCsv(String? input) {
    if (input == null) return const <String>[];
    return input
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }

  factory VendorPublicProfile.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString()) ?? 0;
    }

    final dynamic averageSource =
        json['averageRating'] ?? json['ratingAverage'];
    final dynamic countSource = json['ratingCount'] ?? json['ratingsCount'];

    return VendorPublicProfile(
      vendorUserId: json['vendorUserId']?.toString() ?? '',
      profileId: json['profileId']?.toString() ?? '',
      companyName: json['companyName']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
      serviceCategories: (json['serviceCategories'] is List)
          ? (json['serviceCategories'] as List)
              .map((e) => e.toString())
              .where((e) => e.trim().isNotEmpty)
              .toList(growable: false)
          : const <String>[],
      suitableForCsv: json['suitableForCsv']?.toString(),
      isVerified: json['isVerified'] == true,
      description: json['description']?.toString(),
      venueType: json['venueType']?.toString(),
      capacity: (json['capacity'] as num?)?.toInt(),
      priceRange: json['priceRange']?.toString(),
      phoneNumber: json['phoneNumber']?.toString(),
      website: json['website']?.toString(),
      photoUrls: json['photoUrls']?.toString(),
      averageRating: parseDouble(averageSource),
      ratingCount: parseInt(countSource),
      latitude: parseDouble(json['latitude'] ?? json['venueLatitude']),
      longitude: parseDouble(json['longitude'] ?? json['venueLongitude']),
      addressLabel: json['addressLabel']?.toString() ??
          json['venueAddressLabel']?.toString(),
    );
  }
}
