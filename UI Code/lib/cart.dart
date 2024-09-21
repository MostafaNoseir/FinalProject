// ignore_for_file: unused_local_variable

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Define the cart page as a StatefulWidget
class cart_page extends StatefulWidget {
  const cart_page({super.key});

  @override
  State<cart_page> createState() => cart_page_state();
}

class cart_page_state extends State<cart_page> {
  List<Map<String, dynamic>> cart = [];  // List to hold cart items
  double totalPrice = 0.0;  // Variable to hold total price

  @override
  void initState() {
    super.initState();
    // Fetch cart data from Firebase or pass data from previous page if available
  }

  // Function to update the quantity of an item in the cart
  void updateQuantity(int index, double newQuantity) {
    setState(() {
      if (newQuantity == 0) {
        // Remove the item if quantity is set to 0
        cart.removeAt(index);
      } else {
        // Update the quantity of the item
        cart[index]['quantity'] = newQuantity;
      }

      // Recalculate the total price after updating the quantity
      totalPrice = cart.fold(0.0, (double sum, item) {
        return sum + (item['price'] * item['quantity']);
      });
    });
  }

  // Function to remove an item from the cart
  void removeItem(int index) {
    setState(() {
      totalPrice -= (cart[index]['price'] * cart[index]['quantity']);  // Deduct the item's total price
      cart.removeAt(index);  // Remove the item from the cart
    });
  }

  // Function to save the cart data to Firebase
  Future<void> saveCartToFirebase() async {
    // Save the cart and total price to Firestore for authenticated users
  }

  // Function to clear the cart and reset the total price
  void clearCart() {
    setState(() {
      cart = [];  // Empty the cart
      totalPrice = 0.0;  // Reset the total price
    });
  }

  // Function to update the item quantity in the store data
  // void updateStoreQuantity() async {
  //   User? user = FirebaseAuth.instance.currentUser;

  //   if (user != null) {
  //     // Fetch store data from Firestore
  //     final storeData = await FirebaseFirestore.instance.collection('store').get();

  //     // Iterate through each item in the store and reset the quantity to 0
  //     for (var doc in storeData.docs) {
  //       final item = doc.data();
  //       item['quantity'] = 0;  // Reset quantity

  //       // Update the store data with new quantity
  //       FirebaseFirestore.instance.collection('store').doc(doc.id).update(item);
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text(
            'Your Cart',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        backgroundColor: Colors.redAccent,  // Set AppBar color
      ),
      body: Column(
        children: [
          // Display the cart items in a scrollable list
          Expanded(
            child: ListView.builder(
              itemCount: cart.length,  // Number of items in the cart
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(cart[index]['name']),  // Item name
                  subtitle: Row(
                    children: [
                      // Display price and quantity
                      Text('${cart[index]['price']} EGP x ${cart[index]['quantity']}'),
                      const Spacer(),
                      // Button to decrease the quantity
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          if (cart[index]['quantity'] > 0) {
                            updateQuantity(index, cart[index]['quantity'] - 1);  // Reduce quantity
                          }
                        },
                      ),
                      // Input field for entering quantity manually
                      SizedBox(
                        width: 30,
                        child: TextField(
                          keyboardType: TextInputType.number,  // Only allow number input
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.all(5),
                          ),
                          onChanged: (value) {
                            final newQuantity = double.tryParse(value);  // Convert input to number
                            if (newQuantity == null) {
                              // Show error if input is not valid
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('Invalid Input'),
                                    content: const Text('Please enter numeric numbers only.'),
                                    actions: <Widget>[
                                      TextButton(
                                        child: const Text('OK'),
                                        onPressed: () {
                                          Navigator.of(context).pop();  // Close dialog
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            } else if (newQuantity >= 0) {
                              updateQuantity(index, newQuantity);  // Update quantity
                            }
                          },
                        ),
                      ),
                      // Button to increase the quantity
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          updateQuantity(index, cart[index]['quantity'] + 1);  // Increase quantity
                        },
                      ),
                      // Button to delete the item
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          removeItem(index);  // Remove the item
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Display total price
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Total Price: $totalPrice EGP',  // Show total price
              style: const TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Button to proceed to checkout
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () async {
                await saveCartToFirebase();  // Save cart data to Firebase
                // updateStoreQuantity();  // Update store quantities
                clearCart();  // Clear the cart
                Navigator.pushNamed(context, '/checkout');  // Navigate to checkout page
              },
              child: const Text('Proceed to Checkout'),
            ),
          ),
        ],
      ),
    );
  }
}
