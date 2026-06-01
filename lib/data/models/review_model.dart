class Review {
  final String? id;
  final String storeId;
  final String orderId;
  final String customerId;
  final String customerName;
  final double rating;
  final String comment;
  final String? merchantReply;
  final DateTime? createdAt;
  final DateTime? repliedAt;

  Review({
    this.id,
    required this.storeId,
    required this.orderId,
    required this.customerId,
    required this.customerName,
    required this.rating,
    required this.comment,
    this.merchantReply,
    this.createdAt,
    this.repliedAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      storeId: json['storeId'] ?? '',
      orderId: json['orderId'] ?? '',
      customerId: json['customerId'] ?? '',
      customerName: json['customerName'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      comment: json['comment'] ?? '',
      merchantReply: json['merchantReply'],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      repliedAt: json['repliedAt'] != null ? DateTime.tryParse(json['repliedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'storeId': storeId,
      'orderId': orderId,
      'customerId': customerId,
      'customerName': customerName,
      'rating': rating,
      'comment': comment,
      'merchantReply': merchantReply,
      'createdAt': createdAt?.toIso8601String(),
      'repliedAt': repliedAt?.toIso8601String(),
    };
  }
}
