import 'package:flutter/foundation.dart';

class CartItem {
  final String productId;
  final String productName;
  final int price;
  int quantity;

  CartItem({
    required this.productId,
    required this.productName,
    required this.price,
    this.quantity = 1,
  });
}

class CartModel extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  int get totalPrice => items.fold(
      0, (total, current) => total + current.price * current.quantity);

  void addItemToCart(CartItem item) {
    final existingItemIndex =
        _items.indexWhere((cartItem) => cartItem.productId == item.productId);

    printItems(_items);

    if (existingItemIndex != -1) {
      // If the item is already in the cart, update its quantity
      print("item already exists in cart, ${item.productName}");
      _items[existingItemIndex].quantity += 1;
    } else {
      // Otherwise, add the item to the cart
      print("adding item to cart, ${item.productName}");
      _items.add(item);
    }

    notifyListeners(); // Notify listeners about the change
  }

  void removeItem({required String itemId}) {
    final existingItemIndex =
        _items.indexWhere((cartItem) => cartItem.productId == itemId);

    if (existingItemIndex != -1) {
      CartItem foundItem =
          _items.firstWhere((item) => item.productId == itemId);

      if (foundItem.quantity > 1) {
        _items[existingItemIndex].quantity -= 1;
      } else {
        _items.remove(foundItem);
      }
    } else {
      print("Item does not exist in cart");
    }

    notifyListeners();
  }

  bool isEmpty() {
    return _items.isEmpty;
  }

  void printItems(List<CartItem> items) {
    for (var item in _items) {
      print("Item Id {${item.productId}}");
      print("Item Name ${item.productName}");
    }
  }
}
