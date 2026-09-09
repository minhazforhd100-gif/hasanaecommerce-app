class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? oldPrice;
  final String imageUrl;
  final String category;
  final bool inStock;
  final double rating;
  final int reviewCount;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.oldPrice,
    required this.imageUrl,
    required this.category,
    this.inStock = true,
    this.rating = 0,
    this.reviewCount = 0,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    double numValue(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
    return Product(
      id: '${json['id'] ?? json['sku'] ?? ''}',
      name: '${json['name'] ?? json['title'] ?? ''}',
      description: '${json['description'] ?? ''}',
      price: numValue(json['price']),
      oldPrice: json['old_price'] == null ? null : numValue(json['old_price']),
      imageUrl: '${json['image'] ?? json['image_url'] ?? ''}',
      category: '${json['category'] ?? ''}',
      inStock: json['in_stock'] != false,
      rating: numValue(json['rating']),
      reviewCount: int.tryParse('${json['review_count'] ?? 0}') ?? 0,
    );
  }
}
