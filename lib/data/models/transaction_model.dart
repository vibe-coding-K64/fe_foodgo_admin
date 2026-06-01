class Transaction {
  final String? id;
  final String walletId;
  final String userId;
  final String type; // order_payment, withdrawal, refund
  final double amount;
  final double fee;
  final double netAmount;
  final String description;
  final String? orderId;
  final String status; // pending, completed, failed
  final DateTime? createdAt;

  Transaction({
    this.id,
    required this.walletId,
    required this.userId,
    required this.type,
    required this.amount,
    required this.fee,
    required this.netAmount,
    this.description = '',
    this.orderId,
    required this.status,
    this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      walletId: json['walletId'] ?? '',
      userId: json['userId'] ?? '',
      type: json['type'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      fee: (json['fee'] ?? 0).toDouble(),
      netAmount: (json['netAmount'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      orderId: json['orderId'],
      status: json['status'] ?? 'pending',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'walletId': walletId,
      'userId': userId,
      'type': type,
      'amount': amount,
      'fee': fee,
      'netAmount': netAmount,
      'description': description,
      'orderId': orderId,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
