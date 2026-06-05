import 'package:intl/intl.dart';

class Voucher {
  final String? id;
  final String? storeId;
  final String code;
  final int type; // 1: %, 2: cash
  final double value;
  final double minOrder;
  final int limitCount;
  final int usedCount;
  final DateTime expiryDate;
  final bool isActive;

  Voucher({
    this.id,
    this.storeId,
    required this.code,
    required this.type,
    required this.value,
    required this.minOrder,
    required this.limitCount,
    required this.usedCount,
    required this.expiryDate,
    required this.isActive,
  });

  factory Voucher.fromJson(Map<String, dynamic> json) {
    return Voucher(
      id: json['id'],
      storeId: json['storeId'],
      code: json['code'] ?? '',
      type: json['type'] ?? 1,
      value: (json['value'] ?? 0).toDouble(),
      minOrder: (json['minOrder'] ?? json['minOrderValue'] ?? 0).toDouble(),
      limitCount: json['limitCount'] ?? 0,
      usedCount: json['usedCount'] ?? 0,
      expiryDate: json['expiryDate'] != null 
          ? DateTime.tryParse(json['expiryDate']) ?? DateTime.now() 
          : DateTime.now(),
      isActive: json['isActive'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'storeId': storeId,
      'code': code,
      'type': type,
      'value': value,
      'minOrder': minOrder,
      'minOrderValue': minOrder,
      'limitCount': limitCount,
      'usedCount': usedCount,
      'expiryDate': expiryDate.toIso8601String(),
      'isActive': isActive,
    };
  }

  String get expiryDateFormatted {
    return DateFormat('dd/MM/yyyy').format(expiryDate);
  }

  String get discountText {
    if (type == 1) {
      return 'Giảm ${value.toInt()}%';
    } else {
      return 'Giảm ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(value)}';
    }
  }

  String get minOrderText {
    return 'Đơn tối thiểu ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(minOrder)}';
  }
}
