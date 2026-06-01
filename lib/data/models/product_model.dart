class ProductOption {
  final String name;
  final double price;

  ProductOption({required this.name, required this.price});

  factory ProductOption.fromJson(Map<String, dynamic> json) {
    return ProductOption(
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
    };
  }
}

class ProductOptionGroup {
  final String name;
  final bool isRequired;
  final int maxChoices;
  final List<ProductOption> options;

  ProductOptionGroup({
    required this.name, 
    this.isRequired = false,
    this.maxChoices = 1,
    required this.options
  });

  factory ProductOptionGroup.fromJson(Map<String, dynamic> json) {
    return ProductOptionGroup(
      name: json['name'] ?? '',
      isRequired: json['isRequired'] ?? false,
      maxChoices: json['maxChoices'] ?? 1,
      options: (json['options'] as List?)?.map((item) => ProductOption.fromJson(item)).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'isRequired': isRequired,
      'maxChoices': maxChoices,
      'options': options.map((e) => e.toJson()).toList(),
    };
  }
}

class Product {
  final String? id;
  final String storeId;
  final String categoryId;
  final String categoryName;
  final String name;
  final String description;
  final double basePrice;
  final String? imageUrl;
  final bool isOutOfStock;
  final bool isFeatured;
  final List<ProductOptionGroup>? optionGroups;

  Product({
    this.id,
    required this.storeId,
    required this.categoryId,
    required this.categoryName,
    required this.name,
    required this.description,
    required this.basePrice,
    this.imageUrl,
    this.isOutOfStock = false,
    this.isFeatured = false,
    this.optionGroups,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      storeId: json['storeId'] ?? '',
      categoryId: json['categoryId'] ?? '',
      categoryName: json['categoryName'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      basePrice: (json['basePrice'] ?? 0).toDouble(),
      imageUrl: json['imageUrl'],
      isOutOfStock: json['outOfStock'] ?? json['isOutOfStock'] ?? false,
      isFeatured: json['featured'] ?? json['isFeatured'] ?? false,
      optionGroups: (json['optionGroups'] as List?)?.map((item) => ProductOptionGroup.fromJson(item)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'storeId': storeId,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'name': name,
      'description': description,
      'basePrice': basePrice,
      'imageUrl': imageUrl,
      'outOfStock': isOutOfStock,
      'featured': isFeatured,
      'optionGroups': optionGroups?.map((e) => e.toJson()).toList(),
    };
  }
}
