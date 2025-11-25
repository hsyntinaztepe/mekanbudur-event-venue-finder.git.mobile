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
  });

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
    );
  }
}
