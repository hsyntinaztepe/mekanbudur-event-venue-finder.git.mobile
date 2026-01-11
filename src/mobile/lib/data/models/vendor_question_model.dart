class VendorQuestion {
  final String id;
  final String vendorUserId;
  final String userId;
  final String userDisplayName;
  final String question;
  final String? answer;
  final DateTime createdAt;
  final DateTime? answeredAt;

  VendorQuestion({
    required this.id,
    required this.vendorUserId,
    required this.userId,
    required this.userDisplayName,
    required this.question,
    this.answer,
    required this.createdAt,
    this.answeredAt,
  });

  factory VendorQuestion.fromJson(Map<String, dynamic> json) {
    return VendorQuestion(
      id: json['id'] ?? '',
      vendorUserId: json['vendorUserId'] ?? '',
      userId: json['userId'] ?? '',
      userDisplayName: json['userDisplayName'] ?? 'Kullanıcı',
      question: json['question'] ?? '',
      answer: json['answer'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      answeredAt: json['answeredAt'] != null
          ? DateTime.tryParse(json['answeredAt'])
          : null,
    );
  }
}
