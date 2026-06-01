class BannerModel {
  final String? id;
  final String title;
  final String imageUrl;
  final String? storeId;
  final String? storeName;
  final bool isActive;
  final int order;
  final String? createdAt;
  final String? updatedAt;

  BannerModel({
    this.id,
    required this.title,
    required this.imageUrl,
    this.storeId,
    this.storeName,
    required this.isActive,
    required this.order,
    this.createdAt,
    this.updatedAt,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'],
      title: json['title'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      storeId: json['storeId'],
      storeName: json['storeName'],
      isActive: json['isActive'] ?? true,
      order: json['order'] ?? 0,
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'imageUrl': imageUrl,
      'storeId': storeId,
      'storeName': storeName,
      'isActive': isActive,
      'order': order,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
