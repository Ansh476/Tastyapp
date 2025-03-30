import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Import intl package for date formatting
import '../models/address_model.dart';

class OrdersPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Orders'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No orders found.', style: TextStyle(color: Colors.black))); // Black text
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var order = snapshot.data!.docs[index];
              var orderData = order.data() as Map<String, dynamic>;
              try {
                List<dynamic> items = List<Map<String, dynamic>>.from(orderData['items']);
                // Format the timestamp using intl package
                final timestamp = orderData['timestamp'] as Timestamp;
                final dateTime = timestamp.toDate();
                final formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(dateTime); // Format as needed

                // Retrieve Address
                Address orderAddress = Address.fromMap(orderData['address'] as Map<String, dynamic>);

                return Card(
                  margin: EdgeInsets.all(10),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Order Placed On: $formattedDate', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)), // Use formatted date
                        SizedBox(height: 10),
                        Text('Deliver To:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                        Text(
                          '${orderAddress.addressLabel}',
                          style: TextStyle(color: Colors.black),
                        ),
                        Text(
                          '${orderAddress.flatNumber},${orderAddress.buildingComplex}, ${orderAddress.area}',
                          style: TextStyle(color: Colors.black),
                        ),
                        Text(
                          '${orderAddress.city}, ${orderAddress.state} - ${orderAddress.pincode}',
                          style: TextStyle(color: Colors.black),
                        ),
                        SizedBox(height: 10),
                        Text('Items:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                        Column(
                          children: items.map((item) => ListTile(
                            leading: Image.network(item['imageURL'], width: 50, height: 50),
                            title: Text(item['name'], style: TextStyle(color: Colors.black)),
                            subtitle: Text(
                              'Quantity: ${item['quantity']}, Price: \₹${item['price']}',
                              style: TextStyle(color: Colors.black),
                            ),
                          )).toList(),
                        ),
                        SizedBox(height: 10),
                        Text('Total: \₹${orderData['total']}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                        Text('Payment Method: ${orderData['paymentMethod']}', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.black)),
                      ],
                    ),
                  ),
                );
              } catch (e) {
                print('Error building order card: $e');
                return Card(
                  margin: EdgeInsets.all(10),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('Error loading order', style: TextStyle(color: Colors.black)),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}
