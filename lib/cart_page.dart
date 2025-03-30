import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'cart_provider.dart';
import 'personal_cart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cart_model.dart';

class CartPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Cart'),
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PersonalCartPage()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('cart').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          return GridView.builder(
            padding: EdgeInsets.all(10),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var category = snapshot.data!.docs[index];
              return CategoryCard(category: category);
            },
          );
        },
      ),
    );
  }
}

class CategoryCard extends StatelessWidget {
  final QueryDocumentSnapshot category;

  CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    String categoryName = category.id;
    String imagePath = 'assets/${categoryName}.png'; // Category image should be named categoryName.png and present in assets.

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ItemList(categoryName: categoryName),
          ),
        );
      },
      child: Card(
        elevation: 5,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              imagePath,
              width: 130, // Increased image width
              height: 130, // Increased image height
              fit: BoxFit.cover,
            ),
            SizedBox(height: 10),
            Text(
              categoryName.toUpperCase(),
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black), // Black text
            ),
          ],
        ),
      ),
    );
  }
}

class ItemList extends StatelessWidget {
  final String categoryName;

  ItemList({required this.categoryName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${categoryName.toUpperCase()}'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('cart').doc(categoryName).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var categoryData = snapshot.data!.data() as Map<String, dynamic>;
          List<dynamic> items = categoryData['items'];

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              Map<String, dynamic> item = items[index];
              return ItemCard(item: item, categoryName: categoryName);
            },
          );
        },
      ),
    );
  }
}

class ItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final String categoryName;

  ItemCard({required this.item, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Image.network(
              item['imageURL'],
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'],
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black), // Black text
                  ),
                  Text(
                    '\₹${item['price'].toStringAsFixed(2)}',
                    style: TextStyle(color: Colors.black), // Black text
                  ),
                ],
              ),
            ),
            QuantityControl(item: item, cartProvider: cartProvider),
          ],
        ),
      ),
    );
  }
}

class QuantityControl extends StatefulWidget {
  final Map<String, dynamic> item;
  final CartProvider cartProvider;

  QuantityControl({required this.item, required this.cartProvider});

  @override
  _QuantityControlState createState() => _QuantityControlState();
}

class _QuantityControlState extends State<QuantityControl> {
  late int quantity;

  @override
  void initState() {
    super.initState();
    // Initialize quantity based on what's in the cart
    quantity = widget.cartProvider.getQuantity(widget.item['name']);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.remove, color: Colors.black), // Black icon
          onPressed: quantity > 0
              ? () {
            setState(() {
              quantity--;
            });
            widget.cartProvider.removeItem(
              CartItem(
                name: widget.item['name'],
                imageURL: widget.item['imageURL'],
                price: widget.item['price'].toDouble(),
                quantity: 1,
              ),
            );
          }
              : null,
        ),
        Text('$quantity', style: TextStyle(color: Colors.black)), // Black text
        IconButton(
          icon: Icon(Icons.add, color: Colors.black), // Black icon
          onPressed: () {
            setState(() {
              quantity++;
            });
            widget.cartProvider.addItem(
              CartItem(
                name: widget.item['name'],
                imageURL: widget.item['imageURL'],
                price: widget.item['price'].toDouble(),
                quantity: 1,
              ),
            );
          },
        ),
      ],
    );
  }
}
