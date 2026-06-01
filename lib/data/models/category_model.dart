class Category {
  final String? id;
  final String? storeId;
  final String name;
  final String? icon;
  final int order;
  final String? imageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Category({
    this.id,
    this.storeId,
    required this.name,
    this.icon,
    required this.order,
    this.imageUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      storeId: json['storeId'],
      name: json['name'] ?? '',
      icon: json['icon'],
      order: json['order'] ?? 0,
      imageUrl: json['imageUrl'],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'storeId': storeId,
      'name': name,
      'icon': icon,
      'order': order,
      'imageUrl': imageUrl,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
