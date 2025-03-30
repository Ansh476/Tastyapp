import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/address_model.dart'; // Import Address model

class AddressPage extends StatefulWidget {
  @override
  _AddressPageState createState() => _AddressPageState();
}

class _AddressPageState extends State<AddressPage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Addresses'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('addresses')
            .where('userId', isEqualTo: _auth.currentUser!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('No addresses yet. Add one!'),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var addressData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              Address address = Address.fromMap(addressData);
              String docId = snapshot.data!.docs[index].id;

              return Card(
                margin: EdgeInsets.all(10),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(address.addressLabel, style: TextStyle(fontWeight: FontWeight.bold,color: Colors.black)),
                          Text(address.flatNumber, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                          Text(address.area, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                          Text('${address.city}, ${address.state} - ${address.pincode}',style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {
                              _editAddressDialog(context, address, docId);
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              _deleteAddress(docId);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          _addAddressDialog(context);
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Future<void> _addAddressDialog(BuildContext context) async {
    final _addressLabelController = TextEditingController();
    final _flatNumberController = TextEditingController();
    final _buildingComplexController = TextEditingController();
    final _areaTownController = TextEditingController();
    final _cityController = TextEditingController();
    final _stateController = TextEditingController();
    final _pincodeController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New Address'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _addressLabelController,
                  decoration: InputDecoration(labelText: 'Address Label'),
                ),
                TextFormField(
                  controller: _flatNumberController,
                  decoration: InputDecoration(labelText: 'Flat Number'),
                ),
                TextFormField(
                  controller: _buildingComplexController, // Add this
                  decoration: InputDecoration(labelText: 'Building/Complex'),
                ),
                TextFormField(
                  controller: _areaTownController,
                  decoration: InputDecoration(labelText: 'Area/Town'),
                ),
                TextFormField(
                  controller: _cityController,
                  decoration: InputDecoration(labelText: 'City'),
                ),
                TextFormField(
                  controller: _stateController,
                  decoration: InputDecoration(labelText: 'State'),
                ),
                TextFormField(
                  controller: _pincodeController,
                  decoration: InputDecoration(labelText: 'Pincode'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Save Address'),
              onPressed: () {
                _saveAddress(
                  _addressLabelController.text,
                  _flatNumberController.text,
                  _buildingComplexController.text,
                  _areaTownController.text,
                  _cityController.text,
                  _stateController.text,
                  _pincodeController.text,
                );
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _editAddressDialog(BuildContext context, Address address, String docId) async {
    final _addressLabelController = TextEditingController(text: address.addressLabel);
    final _flatNumberController = TextEditingController(text: address.flatNumber);
    final _buildingComplexController = TextEditingController(text: address.buildingComplex);
    final _areaTownController = TextEditingController(text: address.area);
    final _cityController = TextEditingController(text: address.city);
    final _stateController = TextEditingController(text: address.state);
    final _pincodeController = TextEditingController(text: address.pincode);

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Address'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _addressLabelController,
                  decoration: InputDecoration(labelText: 'Address Label'),
                ),
                TextFormField(
                  controller: _flatNumberController,
                  decoration: InputDecoration(labelText: 'Flat Number'),
                ),
                TextFormField(
                  controller: _buildingComplexController, // Add this
                  decoration: InputDecoration(labelText: 'Building/Complex'),
                ),
                TextFormField(
                  controller: _areaTownController,
                  decoration: InputDecoration(labelText: 'Area/Town'),
                ),
                TextFormField(
                  controller: _cityController,
                  decoration: InputDecoration(labelText: 'City'),
                ),
                TextFormField(
                  controller: _stateController,
                  decoration: InputDecoration(labelText: 'State'),
                ),
                TextFormField(
                  controller: _pincodeController,
                  decoration: InputDecoration(labelText: 'Pincode'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Update Address'),
              onPressed: () {
                _updateAddress(
                  docId,
                  _addressLabelController.text,
                  _flatNumberController.text,
                  _buildingComplexController.text,
                  _areaTownController.text,
                  _cityController.text,
                  _stateController.text,
                  _pincodeController.text,
                );
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveAddress(
      String addressLabel,
      String flatNumber,
      String buildingComplex,
      String area,
      String city,
      String state,
      String pincode,
      ) async {
    try {
      final userId = _auth.currentUser!.uid;
      Address newAddress = Address(
        userId: userId,
        addressLabel: addressLabel,
        flatNumber: flatNumber,
        buildingComplex: buildingComplex,
        area: area,
        city: city,
        state: state,
        pincode: pincode,
      );

      await _firestore.collection('addresses').add(newAddress.toMap());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Address saved!')));
    } catch (e) {
      print('Error saving address: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save address')));
    }
  }

  Future<void> _updateAddress(
      String docId,
      String addressLabel,
      String flatNumber,
      String buildingComplex,
      String area,
      String city,
      String state,
      String pincode,
      ) async {
    try {
      final addressRef = _firestore.collection('addresses').doc(docId);
      await addressRef.update({
        'addressLabel': addressLabel,
        'flatNumber': flatNumber,
        'area': area,
        'city': city,
        'state': state,
        'pincode': pincode,
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Address updated!')));
    } catch (e) {
      print('Error updating address: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update address')));
    }
  }

  Future<void> _deleteAddress(String docId) async {
    try {
      await _firestore.collection('addresses').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Address deleted!')));
    } catch (e) {
      print('Error deleting address: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete address')));
    }
  }
}
