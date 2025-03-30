import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'cart_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/address_model.dart'; // Import Address model

class PersonalCartPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final cartItems = cartProvider.cartItems;

    return Scaffold(
      appBar: AppBar(
        title: Text('Personal Cart'),
      ),
      body: cartItems.isEmpty
          ? Center(child: Text('Your cart is empty.'))
          : ListView.builder(
        itemCount: cartItems.length,
        itemBuilder: (context, index) {
          final item = cartItems[index];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Image.network(
                    item.imageURL,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black), // Black text
                        ),
                        Text(
                          'Price: \₹${item.price.toStringAsFixed(2)}',
                          style: TextStyle(color: Colors.black), // Black text
                        ),
                        Text(
                          'Quantity: ${item.quantity}',
                          style: TextStyle(color: Colors.black), // Black text
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total: \₹${cartProvider.total.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black), // Black text
              ),
              ElevatedButton(
                onPressed: () {
                  _showPaymentDialog(context);
                },
                child: Text('Proceed to Order', style: TextStyle(color: Colors.white)), // White text on button
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentDialog(BuildContext context) {
    String paymentMethod = 'UPI'; // Default payment method
    String selectedAddressId = ''; // To store the selected address ID
    final userId = FirebaseAuth.instance.currentUser!.uid;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Choose Payment Method and Address', style: TextStyle(color: Colors.black)),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Choose Payment Method', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ListTile(
                      title: Text('UPI', style: TextStyle(color: Colors.black)),
                      leading: Radio(
                        value: 'UPI',
                        groupValue: paymentMethod,
                        onChanged: (value) {
                          setState(() {
                            paymentMethod = value.toString();
                          });
                        },
                      ),
                    ),
                    ListTile(
                      title: Text('COD', style: TextStyle(color: Colors.black)),
                      leading: Radio(
                        value: 'COD',
                        groupValue: paymentMethod,
                        onChanged: (value) {
                          setState(() {
                            paymentMethod = value.toString();
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 20),
                    Text('Choose Address', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('addresses')
                          .where('userId', isEqualTo: userId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return CircularProgressIndicator();
                        }

                        if (snapshot.data!.docs.isEmpty) {
                          return Text('No addresses available. Please add an address in your profile.', style: TextStyle(color: Colors.grey));
                        }

                        return Column(
                          children: snapshot.data!.docs.map((doc) {
                            Address address = Address.fromMap(doc.data() as Map<String, dynamic>);
                            String addressId = doc.id;
                            return RadioListTile(
                              title: Text(address.addressLabel, style: TextStyle(color: Colors.black)),
                              subtitle: Text('${address.flatNumber},${address.buildingComplex}, ${address.area}, ${address.city}, ${address.state} - ${address.pincode}', style: TextStyle(color: Colors.grey)),
                              value: addressId,
                              groupValue: selectedAddressId,
                              onChanged: (value) {
                                setState(() {
                                  selectedAddressId = value.toString();
                                });
                              },
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel', style: TextStyle(color: Colors.black)),
            ),
            ElevatedButton(
              onPressed: () {
                _placeOrder(context, paymentMethod, selectedAddressId);
                Navigator.of(context).pop();
              },
              child: Text('Place Order', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _placeOrder(BuildContext context, String paymentMethod, String selectedAddressId) async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final cartItems = cartProvider.cartItems;
    final userId = FirebaseAuth.instance.currentUser!.uid;

    try {
      // Retrieve the selected address from Firestore
      DocumentSnapshot addressSnapshot = await FirebaseFirestore.instance.collection('addresses').doc(selectedAddressId).get();
      Address selectedAddress = Address.fromMap(addressSnapshot.data() as Map<String, dynamic>);

      await FirebaseFirestore.instance.collection('orders').add({
        'items': cartItems.map((item) => item.toMap()).toList(),
        'total': cartProvider.total,
        'paymentMethod': paymentMethod,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': userId,
        'address': selectedAddress.toMap(), // Store the address in the order
      });

      cartProvider.clearCart(); // Clear the cart after placing the order

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order placed successfully!'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error placing order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to place order. Please try again.')),
      );
    }
  }
}
