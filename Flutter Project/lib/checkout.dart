import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Authentication
import 'package:flutter/material.dart'; // Import Flutter's UI components
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Cloud Firestore for database operations

class checkout_page extends StatefulWidget { 
  const checkout_page({super.key});

  @override
  State<checkout_page> createState() => checkout_page_state();
}

class checkout_page_state extends State<checkout_page> {
  double totalPrice = 0.0; // Variable to store the total price

  @override
  void initState() {
    super.initState();
    fetchCartData(); // Fetch cart data when the page is initialized
  }

  // Fetch cart data for the current user from Firestore
  Future<void> fetchCartData() async {
    User? user = FirebaseAuth.instance.currentUser; // Get the current user

    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('carts')
          .doc(user.uid)
          .get(); // Retrieve the user's cart data from Firestore

      if (doc.exists) {
        setState(() {
          totalPrice = doc['totalPrice']; // Set the total price from Firestore data
        });
      } else {
        print('No cart found for the user.'); // Log if no cart is found
      }
    }
  }

  // Complete the purchase and record the transaction in Firestore
  Future<void> completePurchase() async {
    User? user = FirebaseAuth.instance.currentUser; // Get the current user

    if (user != null) {
      // Update Firestore with the total price and timestamp for the user's transaction
      await FirebaseFirestore.instance
          .collection('User_transactions')
          .doc(user.uid)
          .set({
        'totalPrice': totalPrice,
        'timestamp': Timestamp.now(), // Add the current time of the transaction
      });

      // Show a confirmation dialog after the purchase is complete
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Transaction Complete'),
            content: Text(
                'Total Price of $totalPrice EGP has been withdrawn from your credit card.'), // Display transaction details
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                  Navigator.pushNamed(context, '/welcome_user'); // Navigate to welcome page
                },
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout Page'),
        backgroundColor: Colors.green, // Set the app bar color to green
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
          children: [
            // Display the total price
            Text(
              'Total Price: $totalPrice EGP',
              style: const TextStyle(fontSize: 24), // Set the font size
            ),
            const SizedBox(height: 20), // Add some space between the text and button
            ElevatedButton(
              onPressed: completePurchase, // Trigger the completePurchase function
              child: const Text('Confirm Purchase'), // Button label
            ),
          ],
        ),
      ),
    );
  }
}
