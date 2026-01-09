class VendorReview {
  final String id;
  final String vendorUserId;
  final String userId;
  final String userDisplayName;
  final String comment;
  final DateTime createdAtUtc;
  final DateTime? updatedAtUtc;

  VendorReview({
    required this.id,
    required this.vendorUserId,
    required this.userId,
    required this.userDisplayName,
    required this.comment,
    required this.createdAtUtc,
    required this.updatedAtUtc,
  });

  factory VendorReview.fromJson(Map<String, dynamic> json) {
    return VendorReview(
      id: json['id']?.toString() ?? '',
      vendorUserId: json['vendorUserId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      userDisplayName: json['userDisplayName']?.toString() ?? 'Kullanıcı',
      comment: json['comment']?.toString() ?? '',
      createdAtUtc: DateTime.parse(json['createdAtUtc']?.toString() ?? ''),
      updatedAtUtc: json['updatedAtUtc'] == null
          ? null
          : DateTime.tryParse(json['updatedAtUtc']?.toString() ?? ''),
    );
  }
}
