import 'package:flutter/foundation.dart';
import '../models/cart_model.dart';

class CartProvider extends ChangeNotifier {
  List<CartItem> _cartItems = [];

  List<CartItem> get cartItems => _cartItems;

  void addItem(CartItem item) {
    final existingItemIndex = _cartItems.indexWhere((cartItem) => cartItem.name == item.name);
    if (existingItemIndex >= 0) {
      _cartItems[existingItemIndex].quantity++;
    } else {
      _cartItems.add(item);
    }
    notifyListeners();
  }

  void removeItem(CartItem item) {
    final existingItemIndex = _cartItems.indexWhere((cartItem) => cartItem.name == item.name);
    if (existingItemIndex >= 0) {
      if (_cartItems[existingItemIndex].quantity > 1) {
        _cartItems[existingItemIndex].quantity--;
      } else {
        _cartItems.removeAt(existingItemIndex);
      }
    }
    notifyListeners();
  }

  double get total {
    return _cartItems.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  // Method to get quantity of a specific item
  int getQuantity(String itemName) {
    final existingItem = _cartItems.firstWhere((item) => item.name == itemName, orElse: () => CartItem(name: '', imageURL: '', price: 0.0, quantity: 0));
    return existingItem.quantity;
  }
}
