class PublicVendor {
  final String userId;
  final String companyName;
  final String? description;
  final String? serviceCategoriesCsv;
  final String? photoUrls;
  final bool isVerified;

  PublicVendor({
    required this.userId,
    required this.companyName,
    this.description,
    this.serviceCategoriesCsv,
    this.photoUrls,
    this.isVerified = false,
  });

  factory PublicVendor.fromJson(Map<String, dynamic> json) {
    return PublicVendor(
      userId: json['userId']?.toString() ?? '',
      companyName: json['companyName']?.toString() ?? '',
      description: json['description']?.toString(),
      serviceCategoriesCsv: json['serviceCategoriesCsv']?.toString(),
      photoUrls: json['photoUrls']?.toString(),
      isVerified: json['isVerified'] == true,
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
