class Bid {
  final String id;
  final String eventListingId;
  final double amount;
  final String? message;
  final String status;
  final DateTime createdAt;

  Bid({
    required this.id,
    required this.eventListingId,
    required this.amount,
    this.message,
    required this.status,
    required this.createdAt,
  });

  factory Bid.fromJson(Map<String, dynamic> json) {
    return Bid(
      id: json['id'],
      eventListingId: json['eventListingId'],
      amount: (json['totalAmount'] as num).toDouble(),
      message: json['message'],
      status: json['status'],
      createdAt: DateTime.parse(json['createdAtUtc']),
    );
  }
}
