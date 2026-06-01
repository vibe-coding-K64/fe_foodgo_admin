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
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      address: json['address'] ?? '',
      taxCode: json['taxCode'] ?? '',
      businessLicense: json['businessLicense'] ?? '',
      coverImageUrl: json['coverImageUrl'],
      logoUrl: json['logoUrl'],
      bankAccountNumber: json['bankAccountNumber'],
      bankName: json['bankName'],
      isAcceptingOrders: json['acceptingOrders'] ?? true,
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
    };
  }
}
