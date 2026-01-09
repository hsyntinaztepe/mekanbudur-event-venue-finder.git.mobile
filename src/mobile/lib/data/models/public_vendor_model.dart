class PublicVendor {
  final String userId;
  final String companyName;
  final String? description;
  final String? serviceCategoriesCsv;
  final String? photoUrls;
  final bool isVerified;
  final double? averageRating;
  final int ratingCount;
  final double? latitude;
  final double? longitude;
  final double? radius;
  final String? addressLabel;

  PublicVendor({
    required this.userId,
    required this.companyName,
    this.description,
    this.serviceCategoriesCsv,
    this.photoUrls,
    this.isVerified = false,
    this.averageRating,
    this.ratingCount = 0,
    this.latitude,
    this.longitude,
    this.radius,
    this.addressLabel,
  });

  factory PublicVendor.fromJson(Map<String, dynamic> json) {
    // Supports both legacy shapes and `/api/vendors/map` (VendorMapItem)
    // which uses `serviceCategories: []` and `coverPhotoUrl`.
    final dynamic rawCategories =
        json['serviceCategories'] ?? json['categories'] ?? json['services'];
    final String? categoriesCsv = (rawCategories is List)
        ? rawCategories
            .whereType<dynamic>()
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .join(',')
        : json['serviceCategoriesCsv']?.toString();

    final String? coverPhotoUrl = json['coverPhotoUrl']?.toString();

    double? tryParseDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    int tryParseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    final dynamic averageSource =
        json['averageRating'] ?? json['ratingAverage'];
    final dynamic countSource = json['ratingCount'] ?? json['ratingsCount'];

    final dynamic latSource = json['latitude'] ?? json['venueLatitude'];
    final dynamic lngSource = json['longitude'] ?? json['venueLongitude'];
    final dynamic radiusSource = json['radius'] ?? json['venueRadius'];
    final String? labelSource = json['addressLabel']?.toString() ??
        json['venueAddressLabel']?.toString();

    return PublicVendor(
      userId:
          (json['userId'] ?? json['vendorUserId'] ?? json['id'])?.toString() ??
              '',
      companyName: json['companyName']?.toString() ?? '',
      description: json['description']?.toString(),
      serviceCategoriesCsv: categoriesCsv,
      // `/api/vendors/map` provides `coverPhotoUrl` (single); profile provides `photoUrls` (csv)
      photoUrls: (json['photoUrls']?.toString() ?? coverPhotoUrl),
      isVerified: json['isVerified'] == true,
      averageRating: tryParseDouble(averageSource),
      ratingCount: tryParseInt(countSource),
      latitude: tryParseDouble(latSource),
      longitude: tryParseDouble(lngSource),
      radius: tryParseDouble(radiusSource),
      addressLabel: labelSource,
    );
  }

  List<String> get photoUrlList => _splitCsv(photoUrls);

  List<String> get categoryList => _splitCsv(serviceCategoriesCsv);

  static List<String> _splitCsv(String? input) {
    if (input == null) return const <String>[];
    return input
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }
}
