class VendorRatingSummary {
  final double? averageRating;
  final int ratingCount;
  final int? myRating;

  VendorRatingSummary({
    required this.averageRating,
    required this.ratingCount,
    required this.myRating,
  });

  factory VendorRatingSummary.fromJson(Map<String, dynamic> json) {
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

    return VendorRatingSummary(
      averageRating:
          parseDouble(json['averageRating'] ?? json['ratingAverage']),
      ratingCount: parseInt(json['ratingCount'] ?? json['ratingsCount']),
      myRating: (json['myRating'] as num?)?.toInt(),
    );
  }
}
