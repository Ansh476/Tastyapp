class CartItem {
  final String name;
  final String imageURL;
  final double price;
  int quantity;

  CartItem({
    required this.name,
    required this.imageURL,
    required this.price,
    this.quantity = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'imageURL': imageURL,
      'price': price,
      'quantity': quantity,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      name: map['name'],
      imageURL: map['imageURL'],
      price: map['price'].toDouble(),
      quantity: map['quantity'],
    );
  }
}
