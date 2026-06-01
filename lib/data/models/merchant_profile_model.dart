class MerchantProfile {
  final String? id;
  final String businessName;
  final String businessLicense;
  final String taxCode;
  final List<String> storeIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MerchantProfile({
    this.id,
    required this.businessName,
    required this.businessLicense,
    required this.taxCode,
    required this.storeIds,
    this.createdAt,
    this.updatedAt,
  });

  factory MerchantProfile.fromJson(Map<String, dynamic> json) {
    return MerchantProfile(
      id: json['id'],
      businessName: json['businessName'] ?? '',
      businessLicense: json['businessLicense'] ?? '',
      taxCode: json['taxCode'] ?? '',
      storeIds: List<String>.from(json['storeIds'] ?? []),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'businessName': businessName,
      'businessLicense': businessLicense,
      'taxCode': taxCode,
      'storeIds': storeIds,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
