class MenuItem {
  final String id;
  final String name;
  final double price;
  final String category;
  final bool isAvailable;
  final String? imageUrl;

  MenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.isAvailable,
    this.imageUrl,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Unnamed Item',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] as String? ?? 'General',
      isAvailable: json['is_available'] as bool? ?? true,
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'category': category,
      'is_available': isAvailable,
      'image_url': imageUrl,
    };
  }
}
