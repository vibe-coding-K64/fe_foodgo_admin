class Store {
  final String? id;
  final String name;
  final String description;
  final String address;
  final String taxCode;
  final String businessLicense;
  final String? coverImageUrl; // Thay vì backUrl
  final String? logoUrl; // Thay vì avtUrl
  final String? bankAccountNumber;
  final String? bankName;
  final bool isAcceptingOrders; // Bật/Tắt nhận đơn
  final double? rating;
  final int? reviewCount;

  Store({
    this.id,
    required this.name,
    this.description = '',
    required this.address,
    this.taxCode = '',
    this.businessLicense = '',
    this.coverImageUrl,
    this.logoUrl,
    this.bankAccountNumber,
    this.bankName,
    this.isAcceptingOrders = true,
    this.rating,
    this.reviewCount,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      address: json['address'] ?? '',
      taxCode: json['taxCode'] ?? '',
      businessLicense: json['businessLicense'] ?? '',
      coverImageUrl: json['coverImageUrl'] ?? json['backUrl'],
      logoUrl: json['logoUrl'] ?? json['avtUrl'],
      bankAccountNumber: json['bankAccountNumber'],
      bankName: json['bankName'],
      isAcceptingOrders: json['acceptingOrders'] ?? json['isOpen'] ?? true,
      rating: (json['rating'] as num?)?.toDouble(),
      reviewCount: (json['reviewCount'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'address': address,
      'taxCode': taxCode,
      'businessLicense': businessLicense,
      'coverImageUrl': coverImageUrl,
      'logoUrl': logoUrl,
      'bankAccountNumber': bankAccountNumber,
      'bankName': bankName,
      'acceptingOrders': isAcceptingOrders,
      'rating': rating,
      'reviewCount': reviewCount,
    };
  }
}
