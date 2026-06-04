class OrderItem {
  final String name;
  final String options;
  final int quantity;
  final double price;

  OrderItem({
    required this.name,
    required this.options,
    required this.quantity,
    required this.price,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      name: json['name'] ?? '',
      options: json['options'] ?? '',
      quantity: json['quantity'] ?? 1,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'options': options,
      'quantity': quantity,
      'price': price,
    };
  }
}

class Order {
  final String? id;
  final String storeId;
  final String storeName;
  final String code;
  final String customerName;
  final String customerPhone;
  final String deliveryAddress;
  final String driverName;
  final String driverPhone;
  final List<OrderItem> items;
  final double totalAmount;
  final double shippingFee;
  final double discountAmount;
  final double finalAmount;
  final String paymentMethod;
  final String status;
  final DateTime? createdAt;

  Order({
    this.id,
    required this.storeId,
    required this.storeName,
    required this.code,
    required this.customerName,
    required this.customerPhone,
    required this.deliveryAddress,
    required this.driverName,
    required this.driverPhone,
    required this.items,
    required this.totalAmount,
    required this.shippingFee,
    required this.discountAmount,
    required this.finalAmount,
    required this.paymentMethod,
    required this.status,
    this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    var itemsList = json['items'] as List? ?? [];
    return Order(
      id: json['id'],
      storeId: json['storeId'] ?? '',
      storeName: json['storeName'] ?? '',
      code: json['code'] ?? '',
      customerName: json['customerName'] ?? json['receiverName'] ?? '',
      customerPhone: json['customerPhone'] ?? json['receiverPhone'] ?? '',
      deliveryAddress: json['deliveryAddress'] ?? '',
      driverName: json['driverName'] ?? '',
      driverPhone: json['driverPhone'] ?? '',
      items: itemsList.map((i) => OrderItem.fromJson(i)).toList(),
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      shippingFee: (json['shippingFee'] as num?)?.toDouble() ?? (json['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      discountAmount: ((json['discountAmount'] as num?)?.toDouble() ?? 0.0) +
          ((json['shopDiscountAmount'] as num?)?.toDouble() ?? 0.0) +
          ((json['freeshipDiscountAmount'] as num?)?.toDouble() ?? 0.0),
      finalAmount: (json['finalAmount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['paymentMethod'] ?? 'Tiền mặt',
      status: json['status'] == 'Đang chuẩn bị' ? 'Đang chế biến' : (json['status'] ?? 'Chờ xác nhận'),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']).toLocal() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'storeId': storeId,
      'storeName': storeName,
      'code': code,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'deliveryAddress': deliveryAddress,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'items': items.map((i) => i.toJson()).toList(),
      'totalAmount': totalAmount,
      'shippingFee': shippingFee,
      'discountAmount': discountAmount,
      'finalAmount': finalAmount,
      'paymentMethod': paymentMethod,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
